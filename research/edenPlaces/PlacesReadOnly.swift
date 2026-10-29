import Foundation

/// Non-recursive metadata browsing of an explicitly selected Rclone remote.
/// No implicit transfer, folder grant, credential handling, or account ownership claim.
public enum PlacesReadOnly {
    public enum Failure: LocalizedError, Equatable {
        case invalidRemote, invalidEntries, excessiveEntries
        public var errorDescription: String? {
            switch self {
            case .invalidRemote: return "Select a configured storage account"
            case .invalidEntries: return "Provider returned unsafe or malformed directory metadata"
            case .excessiveEntries: return "Directory is too large for this bounded preview"
            }
        }
    }
    public struct Entry: Equatable, Identifiable {
        public let id: String
        public let name: String
        public let isDirectory: Bool
        public let size: Int64?
        public let path: String
    }
    public struct Snapshot: Equatable {
        public let accountKey: String
        public let path: String
        public let entries: [Entry]
    }
    private struct RclonePlace: Decodable {
        let Name: String
        let IsDir: Bool
        let Size: Int64?
        let IsLink: Bool?
    }

    public static func invocation(remote: String, path: String) throws -> RcloneInvocation {
        guard PathSafety.validRemoteName(remote) else { throw Failure.invalidRemote }
        let safePath = try path.isEmpty ? "" : PathSafety.normalizedRelativePath(path)
        return RcloneInvocation(["lsjson", "\(remote):\(safePath)", "--max-depth", "1"])
    }

    /// The caller must bind execute to an engine using the selected RemoteSource.
    public static func inspect(source: RemoteSource, remote: String, path: String,
                               execute: (RcloneInvocation) throws -> Data) throws -> Snapshot {
        let command = try invocation(remote: remote, path: path)
        let raw = try execute(command)
        guard raw.count <= 2_000_000 else { throw Failure.excessiveEntries }
        let decoded: [RclonePlace]
        do { decoded = try JSONDecoder().decode([RclonePlace].self, from: raw) }
        catch { throw Failure.invalidEntries }
        guard decoded.count <= 1000 else { throw Failure.excessiveEntries }
        let accountKey = source.rawValue + "|" + remote
        let entries: [Entry] = try decoded.enumerated().map { index, record in
            guard (try? PathSafety.validateFileName(record.Name)) != nil,
                  record.IsLink != true, record.Size == nil || record.Size! >= 0
            else { throw Failure.invalidEntries }
            return Entry(id: "\(accountKey)|\(path)|\(index)", name: record.Name,
                         isDirectory: record.IsDir, size: record.IsDir ? nil : record.Size,
                         path: path.isEmpty ? record.Name : path + "/" + record.Name)
        }
        return Snapshot(accountKey: accountKey, path: path, entries: entries)
    }
}
