import Foundation

public enum SwayCoachPhase: String, Codable, CaseIterable, Sendable { case watch, copy, match, combo, score, unlock, dance }
public enum SwayCountTruth: String, Codable, Sendable { case match = "MATCH", notMatched = "NOT MATCHED", unknown = "UNKNOWN" }
public enum SwayMastery: String, Codable, CaseIterable, Sendable { case discovered, learning, familiar, mastered }
public enum SwaySessionOutcome: String, Codable, Sendable { case completed, endedEarly }

public struct SwayCountResult: Codable, Equatable, Sendable {
    public var count: Int
    public var truth: SwayCountTruth
    public var score: Int
    public init(count: Int, truth: SwayCountTruth, score: Int) { self.count = count; self.truth = truth; self.score = max(0, min(100, score)) }
}

/// Pure workout reducer. UNKNOWN never breaks or grows combo and is excluded from score.
public struct SwayWorkoutEngine: Sendable {
    public private(set) var phase: SwayCoachPhase = .watch
    public private(set) var results: [SwayCountResult] = []
    public private(set) var combo = 0
    public private(set) var maxCombo = 0
    public private(set) var moveIndex = 0
    public private(set) var isPaused = false
    public private(set) var outcome: SwaySessionOutcome?

    public init() {}
    public var score: Int {
        let known = results.filter { $0.truth != .unknown }
        return known.isEmpty ? 0 : known.map(\.score).reduce(0, +) / known.count
    }
    public mutating func setPhase(_ value: SwayCoachPhase) { guard outcome == nil else { return }; phase = value }
    public mutating func record(_ result: SwayCountResult, calibrationReady: Bool) {
        guard calibrationReady, !isPaused, outcome == nil else { return }
        results.append(result)
        switch result.truth {
        case .match: combo += 1; maxCombo = max(maxCombo, combo)
        case .notMatched: combo = 0
        case .unknown: break
        }
    }
    public mutating func nextMove() { guard !isPaused, outcome == nil else { return }; moveIndex += 1 }
    public mutating func pause() { guard outcome == nil else { return }; isPaused = true }
    public mutating func resume() { guard outcome == nil else { return }; isPaused = false }
    public mutating func end(_ value: SwaySessionOutcome) { outcome = value; isPaused = true }
    public mutating func restart() { self = SwayWorkoutEngine() }

    public static func mastery(successfulKnownCounts: Int) -> SwayMastery {
        switch successfulKnownCounts { case 0: return .discovered; case 1..<16: return .learning; case 16..<64: return .familiar; default: return .mastered }
    }
}
