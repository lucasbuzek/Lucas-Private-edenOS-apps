import Foundation

/// Atomic JSON store with a rolling backup (".bak") so a failed write never destroys the last good file.
public struct JSONFileStore<T: Codable> {
    public let url: URL
    public init(url: URL) { self.url = url }
    public enum StoreError: Error { case corrupt }

    public func save(_ value: T) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let enc = JSONEncoder(); enc.outputFormatting = [.sortedKeys]
        let data = try enc.encode(value)
        let bak = url.appendingPathExtension("bak")
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: bak)
            try? FileManager.default.copyItem(at: url, to: bak)
        }
        try data.write(to: url, options: .atomic)
    }

    /// Loads the file; if corrupt, falls back to the backup; nil if neither exists.
    public func load() throws -> T? {
        let dec = JSONDecoder()
        if let d = try? Data(contentsOf: url) {
            if let v = try? dec.decode(T.self, from: d) { return v }
            if let d2 = try? Data(contentsOf: url.appendingPathExtension("bak")), let v = try? dec.decode(T.self, from: d2) { return v }
            throw StoreError.corrupt
        }
        return nil
    }
}

public struct LearnerProgress: Codable, Equatable, Sendable {
    public var schemaVersion = 1
    public var mastery: [String: Mastery] = [:]
    public var attempts: [String: Int] = [:]
    public var streakDays = 0
    public var lastPracticeDay: String?   // yyyy-MM-dd
    public init() {}
    public mutating func recordAttempt(movementID: String, score: ScoreAccumulator, day: String) {
        let n = (attempts[movementID] ?? 0) + 1; attempts[movementID] = n
        let cur = mastery[movementID] ?? .discovered
        mastery[movementID] = MasteryRules.next(current: cur, attempts: n, accuracy: score.accuracy, coverage: score.coverage)
        if lastPracticeDay != day { streakDays = (lastPracticeDay == Self.previous(day)) ? streakDays + 1 : 1; lastPracticeDay = day }
    }
    static func previous(_ day: String) -> String? {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.timeZone = TimeZone(identifier: "UTC"); f.locale = Locale(identifier: "en_US_POSIX")
        guard let d = f.date(from: day) else { return nil }
        return f.string(from: d.addingTimeInterval(-86400))
    }
}
