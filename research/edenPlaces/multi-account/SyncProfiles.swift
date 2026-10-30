import Foundation

/// Additive model: each saved profile owns its own local root, permissions, history and schedule.
/// No account/token is created here. A configured Rclone remote is a reference, not verified identity.
public enum PlacesProvider: String, Codable, CaseIterable, Sendable {
    case dropbox, googleDrive, oneDrive, box, webDAV, s3, cloudflareR2
    public var rcloneType: String {
        switch self {
        case .dropbox: return "dropbox"
        case .googleDrive: return "drive"
        case .oneDrive: return "onedrive"
        case .box: return "box"
        case .webDAV: return "webdav"
        case .s3, .cloudflareR2: return "s3"
        }
    }
}

public enum ProfileValidationError: Error, Equatable {
    case invalidAccount, invalidRoot, invalidGrant, duplicateAccount, overlappingLocalRoots
    case ambiguousFolderGrant, invalidSchedule, noSyncPermission, profileLimit, duplicateProfileID
}

public struct PlacesSyncProfile: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var provider: PlacesProvider
    public var remoteSource: String
    public var remoteName: String
    public var label: String
    public var localRoot: String
    public var folderGrants: [PlacesFolderPermission]
    public var automatic = false
    public var intervalMinutes = 30
    public init(id: UUID = UUID(), provider: PlacesProvider, remoteSource: String,
                remoteName: String, label: String, localRoot: String,
                folderGrants: [PlacesFolderPermission] = [], automatic: Bool = false,
                intervalMinutes: Int = 30) {
        self.id=id; self.provider=provider; self.remoteSource=remoteSource
        self.remoteName=remoteName; self.label=label; self.localRoot=localRoot
        self.folderGrants=folderGrants; self.automatic=automatic
        self.intervalMinutes=intervalMinutes
    }
    public var accountKey: String { remoteSource + "|" + remoteName }
    public var root: String { URL(fileURLWithPath: localRoot).standardizedFileURL.path }
    public func validate() throws {
        guard remoteSource == "managed" || remoteSource == "system",
              !remoteName.isEmpty,
              remoteName.range(of:"^[A-Za-z0-9_-]+$",options:.regularExpression) != nil,
              !label.isEmpty, label.count <= 48,
              !label.unicodeScalars.contains(where: { $0.value < 32 || ($0.value >= 0x7F && $0.value <= 0x9F) || ($0.value == 0x200E || $0.value == 0x200F) || ($0.value >= 0x202A && $0.value <= 0x202E) || ($0.value >= 0x2066 && $0.value <= 0x2069) })
        else { throw ProfileValidationError.invalidAccount }
        guard intervalMinutes >= 15 && intervalMinutes <= 1440 else {
            throw ProfileValidationError.invalidSchedule
        }
        do { try PathSafety.validateLocalRoot(localRoot) }
        catch { throw ProfileValidationError.invalidRoot }
        if automatic && !folderGrants.contains(where: { $0.mode == .sync }) {
            throw ProfileValidationError.noSyncPermission
        }
        var paths=Set<String>()
        for grant in folderGrants {
            do { guard try PathSafety.normalizedRelativePath(grant.path) == grant.path else { throw ProfileValidationError.invalidGrant } }
            catch { throw ProfileValidationError.invalidGrant }
            if !paths.insert(grant.path).inserted { throw ProfileValidationError.ambiguousFolderGrant }
        }
        let active = folderGrants.filter { $0.mode != .off }.map(\.path).sorted()
        for i in active.indices { for j in active.indices where i < j {
            if active[j].hasPrefix(active[i] + "/") { throw ProfileValidationError.ambiguousFolderGrant }
        }}
    }
}

public struct PlacesFolderPermission: Codable, Equatable, Sendable {
    public enum Mode: String, Codable, Sendable { case off, download, sync }
    public var path: String
    public var mode: Mode
    public var recursive: Bool
    public init(_ path: String, mode: Mode = .off, recursive: Bool = false) throws {
        self.path = try PathSafety.normalizedRelativePath(path)
        self.mode = mode
        self.recursive = recursive
    }
    enum CodingKeys: String, CodingKey { case path, mode, recursive }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.path = try c.decode(String.self, forKey: .path)
        self.mode = try c.decode(Mode.self, forKey: .mode)
        self.recursive = try c.decodeIfPresent(Bool.self, forKey: .recursive) ?? false
    }
}

public struct PlacesProfileRegistry: Codable, Equatable {
    public var profiles: [PlacesSyncProfile]
    public init(profiles: [PlacesSyncProfile] = []) throws {
        self.profiles = profiles
        try validate()
    }
    public mutating func replace(_ profile: PlacesSyncProfile) throws {
        var next = profiles
        if let i=next.firstIndex(where: { $0.id==profile.id }) { next[i]=profile }
        else { next.append(profile) }
        try PlacesProfileRegistry(profiles: next).validate()
        profiles = next
    }
    public mutating func disable(_ id: UUID) throws {
        try validate()
        guard let i=profiles.firstIndex(where: { $0.id==id }) else { return }
        profiles[i].automatic=false
        // Revocation is persistent. The worker MUST reload this registry before each transfer.
        profiles[i].folderGrants = try profiles[i].folderGrants.map { try PlacesFolderPermission($0.path, mode: .off, recursive: $0.recursive) }
        try validate()
    }
    public func validate() throws {
        guard profiles.count <= 32 else { throw ProfileValidationError.profileLimit }
        guard Set(profiles.map(\.id)).count == profiles.count else { throw ProfileValidationError.duplicateProfileID }
        for profile in profiles { try profile.validate() }
        for i in profiles.indices { for j in profiles.indices where i < j {
            let a=profiles[i],b=profiles[j]
            // No two profiles may write inside each other's local trees, even with different clouds.
            if a.root==b.root || a.root.hasPrefix(b.root+"/") || b.root.hasPrefix(a.root+"/") {
                throw ProfileValidationError.overlappingLocalRoots
            }
            // Prevent competing automatic uploaders for the same cloud account.
            if a.accountKey==b.accountKey && a.automatic && b.automatic {
                throw ProfileValidationError.duplicateAccount
            }
        }}
    }
    public func due(at date: Date, lastRun: [UUID: Date]) -> [PlacesSyncProfile] {
        profiles.filter { p in
            p.automatic && p.folderGrants.contains(where: { $0.mode == .sync }) &&
            (lastRun[p.id].map { date.timeIntervalSince($0) >= Double(p.intervalMinutes * 60) } ?? true)
        }
    }
}
/// Persist configuration separately from the existing single-account Dropbox Lite settings.
/// Credential secrets, access tokens, cloud file data and provider emails are never serialized here.
public enum PlacesProfilesPersistence {
    public static func load(from url: URL) throws -> PlacesProfileRegistry {
        guard FileManager.default.fileExists(atPath:url.path) else { return try PlacesProfileRegistry() }
        let registry=try JSONDecoder().decode(PlacesProfileRegistry.self,from:Data(contentsOf:url))
        try registry.validate()
        return registry
    }
    public static func save(_ registry:PlacesProfileRegistry,to url:URL) throws {
        try registry.validate()
        let fm=FileManager.default
        try fm.createDirectory(at:url.deletingLastPathComponent(),withIntermediateDirectories:true)
        // Never write through a file/symlink path into another location.
        var cursor = url.standardizedFileURL
        while true {
            if (try? fm.destinationOfSymbolicLink(atPath:cursor.path)) != nil { throw ProfileValidationError.invalidRoot }
            if cursor.path == "/" { break }
            let next = cursor.deletingLastPathComponent()
            if next.path == cursor.path { break }
            cursor = next
        }
        let data=try JSONEncoder().encode(registry)
        try data.write(to:url,options:.atomic)
        try fm.setAttributes([.posixPermissions:NSNumber(value:0o600)],ofItemAtPath:url.path)
    }
}