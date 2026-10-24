import Foundation

/// Portable local-first content container. Current format version 2 (ND-004).
/// v1 (legacy) used key `moves` and had no per-keyframe `hold`; migration preserves content exactly.
public struct SwayPack: Codable, Equatable, Sendable {
    public static let currentVersion = 2
    public static let maxBytes = 25 * 1024 * 1024
    public var formatVersion: Int
    public var id: String
    public var title: String
    public var author: String?
    public var movements: [MovementDefinition]
    public var combinations: [Combination]
    /// Licensed music is REFERENCED (title/artist/catalog id), never embedded.
    public var musicReferences: [MusicReference]
    public var checksum: String

    public struct MusicReference: Codable, Equatable, Sendable {
        public var title: String, artist: String?, catalogID: String?, bpm: Double?, grid: MusicGrid?
        public init(title: String, artist: String? = nil, catalogID: String? = nil, bpm: Double? = nil, grid: MusicGrid? = nil) {
            self.title = title; self.artist = artist; self.catalogID = catalogID; self.bpm = bpm; self.grid = grid
        }
    }

    public init(id: String, title: String, author: String? = nil, movements: [MovementDefinition] = [],
                combinations: [Combination] = [], musicReferences: [MusicReference] = []) {
        self.formatVersion = Self.currentVersion; self.id = id; self.title = title; self.author = author
        self.movements = movements; self.combinations = combinations; self.musicReferences = musicReferences; self.checksum = ""
        self.checksum = computeChecksum()
    }

    public enum PackError: Error, Equatable {
        case tooLarge, notJSON, unsupportedVersion(Int), missingField(String), checksumMismatch, invalidMovement(String), duplicateID(String), danglingReference(String), invalidTempo
    }

    func canonicalPayload() -> Data {
        var copy = self; copy.checksum = ""
        let enc = JSONEncoder(); enc.outputFormatting = [.sortedKeys]
        return (try? enc.encode(copy)) ?? Data()
    }
    func computeChecksum() -> String { Self.fnv1a64(canonicalPayload()) }

    /// FNV-1a 64-bit: portable integrity (not security) check.
    static func fnv1a64(_ d: Data) -> String {
        var h: UInt64 = 0xcbf29ce484222325
        for b in d { h ^= UInt64(b); h = h &* 0x100000001b3 }
        return String(format: "%016llx", h)
    }

    public func validate() throws {
        var ids = Set<String>()
        for m in movements {
            guard ids.insert(m.id).inserted else { throw PackError.duplicateID(m.id) }
            do { try m.validate() } catch { throw PackError.invalidMovement(m.id) }
        }
        for c in combinations {
            guard ids.insert(c.id).inserted else { throw PackError.duplicateID(c.id) }
        }
        let all = ids
        for c in combinations {
            for s in c.steps where !all.contains(s.movementID) { throw PackError.danglingReference(s.movementID) }
            for ch in c.children where !all.contains(ch) { throw PackError.danglingReference(ch) }
        }
        for r in musicReferences { if let b = r.bpm, !(30...300).contains(b) { throw PackError.invalidTempo } }
    }

    public func export() throws -> Data {
        var p = self; p.checksum = p.computeChecksum()
        try p.validate()
        let enc = JSONEncoder(); enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try enc.encode(p)
    }

    public static func `import`(_ data: Data) throws -> SwayPack {
        guard data.count <= maxBytes else { throw PackError.tooLarge }
        guard var obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { throw PackError.notJSON }
        guard let v = obj["formatVersion"] as? Int else { throw PackError.missingField("formatVersion") }
        guard v >= 1 && v <= currentVersion else { throw PackError.unsupportedVersion(v) }
        let migrated = v < currentVersion
        if migrated { obj = try migrate(obj, from: v) }
        let decodeData = migrated ? try JSONSerialization.data(withJSONObject: obj) : data
        let pack: SwayPack
        do { pack = try JSONDecoder().decode(SwayPack.self, from: decodeData) }
        catch let DecodingError.keyNotFound(k, _) { throw PackError.missingField(k.stringValue) }
        catch { throw PackError.notJSON }
        if !migrated { guard pack.checksum == pack.computeChecksum() else { throw PackError.checksumMismatch } }
        try pack.validate()
        var out = pack; out.checksum = out.computeChecksum()
        return out
    }

    /// v1 -> v2: rename `moves`->`movements`, add `hold:false`, `level`, `revision`, `combinations`, `musicReferences`.
    static func migrate(_ o: [String: Any], from v: Int) throws -> [String: Any] {
        var out = o
        if v == 1 {
            guard var moves = (o["movements"] ?? o["moves"]) as? [[String: Any]] else { throw PackError.missingField("moves") }
            for i in moves.indices {
                if var kfs = moves[i]["keyframes"] as? [[String: Any]] {
                    for j in kfs.indices where kfs[j]["hold"] == nil { kfs[j]["hold"] = false }
                    moves[i]["keyframes"] = kfs
                }
                if moves[i]["level"] == nil { moves[i]["level"] = "move" }
                if moves[i]["revision"] == nil { moves[i]["revision"] = 1 }
            }
            out["moves"] = nil; out["movements"] = moves
            if out["combinations"] == nil { out["combinations"] = [Any]() }
            if out["musicReferences"] == nil { out["musicReferences"] = [Any]() }
            if out["checksum"] == nil { out["checksum"] = "" }
        }
        out["formatVersion"] = currentVersion
        return out
    }
}
