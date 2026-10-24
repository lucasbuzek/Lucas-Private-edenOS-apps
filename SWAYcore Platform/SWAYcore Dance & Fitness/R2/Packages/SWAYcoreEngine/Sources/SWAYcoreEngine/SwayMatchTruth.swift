import Foundation

public enum SwayUnknownReason: String, Sendable, Equatable {
    case lowDetectorConfidence, insufficientJointCoverage, staleObservation, noReference, noObservation
}

/// MATCH (good/partial) / NOT MATCHED / UNKNOWN. Only sufficient, fresh, confident evidence can yield a non-unknown outcome.
public enum SwayMatchOutcome: Equatable, Sendable {
    case good, partial, notMatched
    case unknown(SwayUnknownReason)
    public var isUnknown: Bool { if case .unknown = self { return true }; return false }
    /// Earns score credit only when evidence supports a match.
    public var earnsCredit: Bool { self == .good || self == .partial }
}

public struct SwayMatchConfig: Sendable {
    public var minDetectorConfidence = 0.30      // LEGACY
    public var goodThreshold = 0.72              // LEGACY
    public var partialThreshold = 0.42           // LEGACY
    public var maxObservationAge: TimeInterval = 0.35   // LEGACY (workout view guard)
    public var minComparableJoints = 3           // NEW (defect D-001/D-002 repair)
    public var minReferenceCoverage = 0.5        // NEW: comparable / reference joints
    public init() {}
}

public struct SwayMatchResult: Equatable, Sendable {
    public var outcome: SwayMatchOutcome
    public var timing: Double, shape: Double, continuity: Double, confidence: Double, total: Double
    public var comparableJoints: Int
    public var coverage: Double
}

public enum SwayMatchTruth {
    /// Weights (timing .35, shape .35, continuity .30) and thresholds are the recovered legacy values.
    public static func score(referenceAngles: [String: Double], observedAngles: [String: Double], timingError: Double,
                             detectorConfidence: Double, previousTotal: Double?, observationAge: TimeInterval? = nil,
                             config: SwayMatchConfig = SwayMatchConfig()) -> SwayMatchResult {
        func unknown(_ r: SwayUnknownReason, joints: Int = 0, cov: Double = 0) -> SwayMatchResult {
            SwayMatchResult(outcome: .unknown(r), timing: 0, shape: 0, continuity: 0, confidence: detectorConfidence, total: 0, comparableJoints: joints, coverage: cov)
        }
        if referenceAngles.isEmpty { return unknown(.noReference) }
        if observedAngles.isEmpty { return unknown(.noObservation) }
        if let age = observationAge, age > config.maxObservationAge || age < 0 { return unknown(.staleObservation) }
        guard detectorConfidence.isFinite, detectorConfidence >= config.minDetectorConfidence else { return unknown(.lowDetectorConfidence) }
        let diffs = referenceAngles.compactMap { k, v in observedAngles[k].map { abs($0 - v) } }
        let coverage = Double(diffs.count) / Double(referenceAngles.count)
        guard diffs.count >= config.minComparableJoints, coverage >= config.minReferenceCoverage else {
            return unknown(.insufficientJointCoverage, joints: diffs.count, cov: coverage)
        }
        let mean = diffs.reduce(0, +) / Double(diffs.count)
        let shape = max(0, 1 - mean / 90)
        let timing = max(0, 1 - abs(timingError) / 0.35)
        let continuity = previousTotal.map { max(0, 1 - abs($0 - shape)) } ?? 1
        let total = (timing * 0.35 + shape * 0.35 + continuity * 0.30) * detectorConfidence
        let outcome: SwayMatchOutcome = total >= config.goodThreshold ? .good : (total >= config.partialThreshold ? .partial : .notMatched)
        return SwayMatchResult(outcome: outcome, timing: timing, shape: shape, continuity: continuity, confidence: detectorConfidence,
                               total: total, comparableJoints: diffs.count, coverage: coverage)
    }
}
