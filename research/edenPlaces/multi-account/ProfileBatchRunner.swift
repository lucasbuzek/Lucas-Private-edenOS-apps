import Foundation
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

/// One short-lived scheduled batch. No daemon. No provider tokens in this state directory.
public struct PlacesProfileBatchReceipt: Equatable {
    public var completedProfileIDs: [UUID]=[]
    public var failedProfileIDs: [UUID]=[]
    public var reports: [UUID:PlacesTransferReport]=[:]
    public init() {}
}

public final class PlacesBatchRunLock {
    private let fd: Int32
    public init(path:URL) throws {
        try FileManager.default.createDirectory(at:path.deletingLastPathComponent(),withIntermediateDirectories:true)
        fd = open(path.path,O_CREAT|O_RDWR|O_NOFOLLOW,S_IRUSR|S_IWUSR)
        guard fd >= 0 else { throw PlacesTransferFailure.unsafeFile }
        guard flock(fd, LOCK_EX|LOCK_NB)==0 else {
            close(fd)
            throw PlacesTransferFailure.conflictingExistingFile
        }
    }
    deinit { flock(fd,LOCK_UN);close(fd) }
}

public struct PlacesBatchState: Codable {
    public var lastRun:[UUID:Date]=[:]
    public init() {}
}

public struct PlacesProfileBatchRunner {
    public let registryURL:URL
    public let dataDirectory:URL
    public let providerFactory:(PlacesSyncProfile) throws -> any PlacesSafeProvider
    public init(registryURL:URL,dataDirectory:URL,
                providerFactory:@escaping(PlacesSyncProfile)throws->any PlacesSafeProvider) {
        self.registryURL=registryURL
        self.dataDirectory=dataDirectory
        self.providerFactory=providerFactory
    }
    public func runDue(now:Date=Date()) throws -> PlacesProfileBatchReceipt {
        try FileManager.default.createDirectory(at:dataDirectory,withIntermediateDirectories:true)
        let lock=try PlacesBatchRunLock(path:dataDirectory.appendingPathComponent("batch.lock"))
        defer { withExtendedLifetime(lock) {} }
        let initial=try PlacesProfilesPersistence.load(from:registryURL)
        let stateFile=dataDirectory.appendingPathComponent("last-run.json")
        var state=try decode(PlacesBatchState.self,at:stateFile) ?? PlacesBatchState()
        var receipt=PlacesProfileBatchReceipt()
        for p in initial.due(at:now,lastRun:state.lastRun) {
            do {
                let current=try PlacesProfilesPersistence.load(from:registryURL)
                guard current.profiles.contains(p), p.automatic else {
                    throw PlacesTransferFailure.unauthorized
                }
                let ledgerURL=dataDirectory.appendingPathComponent(p.id.uuidString+"-ledger.json")
                var ledger=try decode(PlacesTransferLedger.self,at:ledgerURL) ?? PlacesTransferLedger()
                let provider=try providerFactory(p)
                let valid:(PlacesSyncProfile,PlacesFolderPermission) throws -> Bool={ profile,grant in
                    let latest=try PlacesProfilesPersistence.load(from:registryURL)
                    guard let allowed=latest.profiles.first(where:{$0.id==profile.id}) else {return false}
                    return allowed==profile && allowed.automatic &&
                           allowed.folderGrants.contains(grant) && grant.mode != .off
                }
                let coordinator=PlacesSafeSyncCoordinator(provider:provider,authorized:valid,
                    stillCurrent:valid,save:{ updated in try write(updated,to:ledgerURL) })
                let report=try coordinator.execute(profile:p,ledger:&ledger,dryRun:false)
                receipt.reports[p.id]=report
                receipt.completedProfileIDs.append(p.id)
                state.lastRun[p.id]=now
                try write(state,to:stateFile)
            } catch {
                // One provider/account failure must not silently change another's permissions or files.
                receipt.failedProfileIDs.append(p.id)
            }
        }
        return receipt
    }
    private func decode<T:Decodable>(_ type:T.Type,at url:URL) throws -> T? {
        guard FileManager.default.fileExists(atPath:url.path) else { return nil }
        try PlacesSyncSafePaths.ensureNoSymlink(url)
        return try JSONDecoder().decode(type,from:Data(contentsOf:url))
    }
    private func write<T:Encodable>(_ value:T,to url:URL) throws {
        try PlacesSyncSafePaths.ensureNoSymlink(url)
        let bytes=try JSONEncoder().encode(value)
        try bytes.write(to:url,options:.atomic)
        try FileManager.default.setAttributes([.posixPermissions:NSNumber(value:0o600)],ofItemAtPath:url.path)
    }
}