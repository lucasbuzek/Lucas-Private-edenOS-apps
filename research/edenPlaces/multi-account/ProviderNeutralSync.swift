import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

public struct PlacesRemoteBlob: Equatable {
    public let name: String
    public let sha256: String
    public let bytes: Int64
    public init(name: String, sha256: String, bytes: Int64) {
        self.name=name; self.sha256=sha256.lowercased(); self.bytes=bytes
    }
}

/// Every backend MUST perform atomic conditional creation on upload, with no overwrite.
/// It MUST report content SHA-256, not a DropboxHash, ETag or cloud MD5.
/// A plain rclone copyto --ignore-existing implementation does not satisfy this contract.
public protocol PlacesSafeProvider {
    var providerType: PlacesProvider { get }
    func snapshot(folder: String) throws -> [PlacesRemoteBlob]
    func download(folder: String, name: String, into stagingFile: URL) throws
    func createOnly(folder: String, name: String, from local: URL) throws
}

public enum PlacesTransferFailure: Error, Equatable {
    case providerMismatch, unauthorized, unsafeFile, corruptProviderListing, changedDuringTransfer
    case conflictingExistingFile, tooManyEntries, legacyBaselinePendingReview
}

public struct PlacesTransferLedger: Codable, Equatable {
    public var previouslySeen: [String: [String: String]] = [:]
    public init() {}
}
public struct PlacesTransferReport: Equatable {
    public var downloads=0, uploads=0, matched=0, conflicts=0
    public init() {}
}

public enum PlacesFileDigest {
    public static func sha256(_ url: URL) throws -> String {
#if canImport(CryptoKit)
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hash=SHA256()
        while true {
            let block=try handle.read(upToCount: 1_048_576) ?? Data()
            if block.isEmpty { break }
            hash.update(data:block)
        }
        return hash.finalize().map { String(format:"%02x",$0) }.joined()
#else
        // Linux-only test harness, NOT part of macOS runtime.
        let task=Process()
        task.executableURL=URL(fileURLWithPath:"/usr/bin/sha256sum")
        task.arguments=[url.path]
        let pipe=Pipe();task.standardOutput=pipe;task.standardError=Pipe()
        try task.run(); task.waitUntilExit()
        guard task.terminationStatus==0 else { throw PlacesTransferFailure.unsafeFile }
        let out=String(decoding:pipe.fileHandleForReading.readDataToEndOfFile(),as:UTF8.self)
        guard let sum=out.split(separator:" ").first, sum.count==64 else { throw PlacesTransferFailure.unsafeFile }
        return String(sum)
#endif
    }
}

public enum PlacesSyncSafePaths {
    public static func ensureNoSymlink(_ url: URL) throws {
        guard url.isFileURL else { throw PlacesTransferFailure.unsafeFile }
        var cursor=url.standardizedFileURL
        while true {
            if (try? FileManager.default.destinationOfSymbolicLink(atPath:cursor.path)) != nil {
                throw PlacesTransferFailure.unsafeFile
            }
            if cursor.path=="/" { break }
            let parent=cursor.deletingLastPathComponent()
            if parent.path==cursor.path { break }
            cursor=parent
        }
    }
    public static func folder(profile: PlacesSyncProfile, grant: PlacesFolderPermission,
                              create: Bool) throws -> URL {
        try profile.validate()
        try PathSafety.validateLocalRoot(profile.localRoot)
        var url=URL(fileURLWithPath:profile.localRoot,isDirectory:true).standardizedFileURL
        try ensureNoSymlink(url)
        if create { try FileManager.default.createDirectory(at:url,withIntermediateDirectories:true) }
        for piece in grant.path.split(separator:"/") {
            try PathSafety.validateFileName(String(piece))
            url.appendPathComponent(String(piece),isDirectory:true)
            try ensureNoSymlink(url)
            if create { try FileManager.default.createDirectory(at:url,withIntermediateDirectories:false) }
        }
        return url
    }
}

public struct PlacesSafeSyncCoordinator {
    public let provider: any PlacesSafeProvider
    public let authorized: (PlacesSyncProfile, PlacesFolderPermission) throws -> Bool
    public let stillCurrent: (PlacesSyncProfile, PlacesFolderPermission) throws -> Bool
    public let save: (PlacesTransferLedger) throws -> Void
    public init(provider: any PlacesSafeProvider,
                authorized: @escaping (PlacesSyncProfile, PlacesFolderPermission) throws -> Bool,
                stillCurrent: @escaping (PlacesSyncProfile, PlacesFolderPermission) throws -> Bool,
                save: @escaping (PlacesTransferLedger) throws -> Void) {
        self.provider=provider;self.authorized=authorized;self.stillCurrent=stillCurrent;self.save=save
    }
    public func execute(profile: PlacesSyncProfile,
                        ledger: inout PlacesTransferLedger, dryRun: Bool = true) throws -> PlacesTransferReport {
        try profile.validate()
        guard provider.providerType==profile.provider else { throw PlacesTransferFailure.providerMismatch }
        var report=PlacesTransferReport()
        for grant in profile.folderGrants where grant.mode != .off {
            guard try authorized(profile,grant),try stillCurrent(profile,grant) else {
                throw PlacesTransferFailure.unauthorized
            }
            let location=try PlacesSyncSafePaths.folder(profile:profile,grant:grant,create:false)
            let remote=try vettedRemote(provider.snapshot(folder:grant.path))
            let local=try localFiles(at:location)
            let scope=profile.id.uuidString + "|" + profile.accountKey + "|" + profile.root + "|" + grant.path
            let old=ledger.previouslySeen[scope] ?? [:]
            let names=Set(remote.keys).union(local.keys).sorted()
            var next=old
            for name in names {
                guard try stillCurrent(profile,grant) else { throw PlacesTransferFailure.unauthorized }
                let remoteHash=remote[name]?.sha256, localHash=local[name]
                if let rh=remoteHash,let lh=localHash, rh==lh {
                    report.matched+=1
                    if !dryRun { next[name]=rh;ledger.previouslySeen[scope]=next;try save(ledger) }
                } else if remoteHash != nil && localHash != nil || old[name] != nil {
                    report.conflicts+=1
                } else if remoteHash != nil {
                    if dryRun { report.downloads+=1;continue }
                    // Start with a fully verified remote object version; no file is published until it matches.
                    guard let before=try vettedRemote(provider.snapshot(folder:grant.path))[name],
                          before==remote[name] else { report.conflicts+=1;continue }
                    guard try stillCurrent(profile,grant) else { throw PlacesTransferFailure.unauthorized }
                    let target=try PlacesSyncSafePaths.folder(profile:profile,grant:grant,create:true)
                        .appendingPathComponent(name,isDirectory:false)
                    try PlacesSyncSafePaths.ensureNoSymlink(target)
                    if FileManager.default.fileExists(atPath:target.path) { report.conflicts+=1;continue }
                    let stage=target.deletingLastPathComponent().appendingPathComponent(".edenplaces-stage-"+UUID().uuidString)
                    defer { try? FileManager.default.removeItem(at:stage) }
                    try provider.download(folder:grant.path,name:name,into:stage)
                    try PlacesSyncSafePaths.ensureNoSymlink(stage)
                    guard try PlacesFileDigest.sha256(stage)==before.sha256,
                          (try FileManager.default.attributesOfItem(atPath:stage.path)[.size] as? NSNumber)?.int64Value == before.bytes,
                          try vettedRemote(provider.snapshot(folder:grant.path))[name]==before else {
                        throw PlacesTransferFailure.changedDuringTransfer
                    }
                    guard try stillCurrent(profile,grant) else { throw PlacesTransferFailure.unauthorized }
                    // Hard-link atomic create: an existing local destination cannot be silently overwritten.
                    try FileManager.default.linkItem(at:stage,to:target)
                    try FileManager.default.removeItem(at:stage)
                    report.downloads+=1;next[name]=before.sha256
                    ledger.previouslySeen[scope]=next;try save(ledger)
                } else if localHash != nil && grant.mode == .sync {
                    if dryRun { report.uploads+=1;continue }
                    guard try stillCurrent(profile,grant) else { throw PlacesTransferFailure.unauthorized }
                    guard try vettedRemote(provider.snapshot(folder:grant.path))[name]==nil,
                          try PlacesFileDigest.sha256(location.appendingPathComponent(name))==localHash else {
                        report.conflicts+=1;continue
                    }
                    // Provider must guarantee create-if-absent atomically; unsupported backends fail closed.
                    try provider.createOnly(folder:grant.path,name:name,from:location.appendingPathComponent(name))
                    guard try vettedRemote(provider.snapshot(folder:grant.path))[name]?.sha256==localHash else {
                        throw PlacesTransferFailure.changedDuringTransfer
                    }
                    report.uploads+=1;next[name]=localHash!
                    ledger.previouslySeen[scope]=next;try save(ledger)
                }
            }
        }
        return report
    }
    private func vettedRemote(_ list:[PlacesRemoteBlob]) throws -> [String:PlacesRemoteBlob] {
        guard list.count<=1000 else { throw PlacesTransferFailure.tooManyEntries }
        var names=Set<String>();var lower=Set<String>();var result=[String:PlacesRemoteBlob]()
        for e in list {
            guard (try? PathSafety.validateFileName(e.name)) != nil, !e.name.hasPrefix(".edenplaces-stage-"), e.bytes>=0,
                  e.sha256.count==64,e.sha256.allSatisfy(\.isHexDigit),
                  names.insert(e.name).inserted,
                  lower.insert(e.name.folding(options:[.caseInsensitive,.diacriticInsensitive],locale:.current)).inserted
            else { throw PlacesTransferFailure.corruptProviderListing }
            result[e.name]=e
        }
        return result
    }
    private func localFiles(at location:URL) throws -> [String:String] {
        let fm=FileManager.default
        guard fm.fileExists(atPath:location.path) else { return [:] }
        try PlacesSyncSafePaths.ensureNoSymlink(location)
        let urls=try fm.contentsOfDirectory(at:location,includingPropertiesForKeys:[.isRegularFileKey,.isSymbolicLinkKey])
        guard urls.count<=1000 else { throw PlacesTransferFailure.tooManyEntries }
        var result=[String:String]();var lower=Set<String>()
        for file in urls {
            let name=file.lastPathComponent
            if name.hasPrefix(".edenplaces-stage-") { continue }
            guard (try? PathSafety.validateFileName(name)) != nil else { throw PlacesTransferFailure.unsafeFile }
            try PlacesSyncSafePaths.ensureNoSymlink(file)
            let metadata=try file.resourceValues(forKeys:[.isRegularFileKey,.isSymbolicLinkKey])
            if metadata.isRegularFile != true { continue }
            guard metadata.isSymbolicLink != true,
                  lower.insert(name.folding(options:[.caseInsensitive,.diacriticInsensitive],locale:.current)).inserted
            else { throw PlacesTransferFailure.unsafeFile }
            result[name]=try PlacesFileDigest.sha256(file)
        }
        return result
    }
}