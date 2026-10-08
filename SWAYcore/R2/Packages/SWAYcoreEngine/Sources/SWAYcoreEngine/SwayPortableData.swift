import Foundation

public struct SwayPack: Codable, Equatable, Sendable {
    public static let currentVersion = 1
    public var format = "swaypack"
    public var version = currentVersion
    public var title: String
    public var moves: [SwayMoveDefinition]
    public var parameters: [String: SwayMoveParameters]
    public init(title: String, moves: [SwayMoveDefinition], parameters: [String: SwayMoveParameters] = [:]) { self.title = title; self.moves = moves; self.parameters = parameters }
    public func validated() throws -> SwayPack {
        guard format == "swaypack" else { throw SwayPackValidationError.invalidFormat }
        guard version == Self.currentVersion else { throw SwayPackValidationError.unsupportedVersion }
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, moves.count <= 5000,
              Set(moves.map(\.id)).count == moves.count,
              moves.allSatisfy({ !$0.id.isEmpty && !$0.name.isEmpty && (1...64).contains($0.counts) }) else { throw SwayPackValidationError.invalidContent }
        return self
    }
    public func encoded() throws -> Data { _ = try validated(); return try JSONEncoder().encode(self) }
    public static func decode(_ data: Data) throws -> SwayPack { try JSONDecoder().decode(SwayPack.self, from: data).validated() }
}
public enum SwayPackValidationError: Error { case invalidFormat, unsupportedVersion, invalidContent }

public struct SwayPersistedState: Codable, Equatable, Sendable {
    public static let schemaVersion = 2
    public var schema = schemaVersion
    public var learnedMoveIDs: Set<String> = []
    public var selectedCoachID = "lucia"
    public var packs: [SwayPack] = []
    public init() {}
    enum CodingKeys: String, CodingKey { case schema, learnedMoveIDs, selectedCoachID, packs }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schema = Self.schemaVersion
        learnedMoveIDs = try c.decodeIfPresent(Set<String>.self, forKey: .learnedMoveIDs) ?? []
        selectedCoachID = try c.decodeIfPresent(String.self, forKey: .selectedCoachID) ?? "lucia"
        packs = try c.decodeIfPresent([SwayPack].self, forKey: .packs) ?? []
    }
}

/// Atomic local-first persistence with a last-known-good backup and migration defaults.
public struct SwayLocalStore: Sendable {
    public var url: URL
    public init(url: URL) { self.url = url }
    public func save(_ state: SwayPersistedState) throws {
        let data = try JSONEncoder().encode(state)
        let manager = FileManager.default
        try manager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if manager.fileExists(atPath: url.path) { try? manager.copyItem(at: url, to: backupURL, replacing: true) }
        try data.write(to: url, options: .atomic)
    }
    public func load() -> SwayPersistedState {
        for candidate in [url, backupURL] {
            if let data = try? Data(contentsOf: candidate), let state = try? JSONDecoder().decode(SwayPersistedState.self, from: data) { return state }
        }
        return SwayPersistedState()
    }
    private var backupURL: URL { url.appendingPathExtension("backup") }
}

private extension FileManager {
    func copyItem(at source: URL, to destination: URL, replacing: Bool) throws {
        if replacing, fileExists(atPath: destination.path) { try removeItem(at: destination) }
        try copyItem(at: source, to: destination)
    }
}
