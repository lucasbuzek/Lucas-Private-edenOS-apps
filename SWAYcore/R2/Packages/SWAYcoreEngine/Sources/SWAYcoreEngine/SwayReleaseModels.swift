import Foundation

public enum SwayBeatStyle: String, Codable, CaseIterable, Sendable { case pop, latin, hipHop, edm, tropical }
public struct SwayBeatEvent: Equatable, Sendable { public var time: TimeInterval; public var accent: Double }
public enum SwayGeneratedBeatEngine {
    public static func events(style: SwayBeatStyle, bpm: Double, intensity: Double, count: Int) -> [SwayBeatEvent] {
        let seconds = SwayTimelineMath.secondsPerBeat(bpm: bpm)
        let level = min(1, max(0, intensity))
        return (0..<max(0, count)).map { i in SwayBeatEvent(time: Double(i) * seconds, accent: i % 4 == 0 ? 1 : 0.35 + level * 0.5) }
    }
}
public enum SwayProviderAuthorization: String, Codable, Sendable { case notDetermined, authorized, denied, restricted, unavailable }
public protocol SwayMusicProviding { var authorization: SwayProviderAuthorization { get }; var isOfflineCapable: Bool { get } }

public struct SwaySessionRecord: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID; public var date: Date; public var activeSeconds: TimeInterval; public var moveCount: Int; public var activeCalories: Double; public var outcome: SwaySessionOutcome
    public init(id: UUID = UUID(), date: Date, activeSeconds: TimeInterval, moveCount: Int, activeCalories: Double, outcome: SwaySessionOutcome) { self.id = id; self.date = date; self.activeSeconds = activeSeconds; self.moveCount = moveCount; self.activeCalories = activeCalories; self.outcome = outcome }
}
public enum SwayProgressMath {
    public static func completedCount(_ records: [SwaySessionRecord]) -> Int { records.filter { $0.outcome == .completed }.count }
    public static func weeklySeconds(_ records: [SwaySessionRecord], now: Date, calendar: Calendar = .current) -> TimeInterval {
        guard let start = calendar.date(byAdding: .day, value: -7, to: now) else { return 0 }
        return records.filter { $0.date >= start && $0.date <= now }.map(\.activeSeconds).reduce(0, +)
    }
    public static func streak(_ records: [SwaySessionRecord], now: Date, calendar: Calendar = .current) -> Int {
        let days = Set(records.map { calendar.startOfDay(for: $0.date) })
        var day = calendar.startOfDay(for: now), result = 0
        while days.contains(day) { result += 1; guard let prior = calendar.date(byAdding: .day, value: -1, to: day) else { break }; day = prior }
        return result
    }
}

public enum SwayCharacterIdentifier: String, Codable, CaseIterable, Sendable { case lucia, nandi, thabo, zuri, kyle, yourDancer }
public struct SwayCoachMetadata: Equatable, Sendable { public var id: SwayCharacterIdentifier; public var name: String; public var style: String; public var defaultWorkoutID: String }
public enum SwayCharacterRegistry {
    public static let all: [SwayCoachMetadata] = [
        .init(id: .lucia, name: "Lucia", style: "Latin", defaultWorkoutID: "latin-vibes"),
        .init(id: .nandi, name: "Nandi", style: "Afro Groove", defaultWorkoutID: "full-body-groove"),
        .init(id: .thabo, name: "Thabo", style: "Hip Hop", defaultWorkoutID: "full-body-groove"),
        .init(id: .zuri, name: "Zuri", style: "Pop", defaultWorkoutID: "foundation-flow"),
        .init(id: .kyle, name: "Kyle", style: "Cardio", defaultWorkoutID: "full-body-groove"),
        .init(id: .yourDancer, name: "YOUR DANCER", style: "Your Style", defaultWorkoutID: "foundation-flow")]
}
