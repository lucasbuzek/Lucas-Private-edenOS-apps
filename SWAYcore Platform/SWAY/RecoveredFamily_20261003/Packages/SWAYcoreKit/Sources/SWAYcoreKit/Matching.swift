import Foundation

public enum UnknownReason: String, Codable, Equatable, Sendable { case noObservation, stale, lowConfidence, insufficientCoverage, noReference, outOfFrame, notReady, cameraDisabled }

public enum MatchResult: Equatable, Sendable {
    case match(error: Double)
    case notMatched(error: Double)
    case unknown(UnknownReason)
    public var earnsCredit: Bool { if case .match = self { return true }; return false }
}

public struct MatchConfig: Sendable {
    public var maxAge: TimeInterval = 0.5
    public var minSegmentConfidence = 0.35
    public var minSegments = 5
    public var matchDegrees = 35.0
    public var minProjectedLength = 0.25   // ignore segments the 2D camera cannot resolve (foreshortened)
    public var frameMargin = 0.02
    public init() {}
}

public enum Matcher {
    /// Compares observed 2D segment directions with expected pose projected to the image plane.
    /// Never returns .match without enough fresh, confident evidence.
    public static func compare(expected: Pose?, observed: TrackingObservation?, now: TimeInterval, config: MatchConfig = MatchConfig()) -> MatchResult {
        guard let expected else { return .unknown(.noReference) }
        guard let observed else { return .unknown(.noObservation) }
        guard now - observed.timestamp <= config.maxAge, now >= observed.timestamp else { return .unknown(.stale) }
        for s in observed.raw.values where s.confidence >= PoseNormalizer.minConfidence {
            let p = s.position
            if p.x < -0.5 || p.x > 1.5 || p.y < -0.5 || p.y > 1.5 { return .unknown(.outOfFrame) }
        }
        guard let obsPose = PoseNormalizer.normalize(observed.raw) else { return .unknown(.lowConfidence) }
        var errors: [Double] = []
        for (a, b) in Skeleton.matchSegments {
            guard let oa = obsPose[a], let ob = obsPose[b], oa.confidence >= config.minSegmentConfidence, ob.confidence >= config.minSegmentConfidence,
                  let ea = expected[a], let eb = expected[b] else { continue }
            let e = Vec3((eb.position - ea.position).x, (eb.position - ea.position).y, 0)
            let o = Vec3((ob.position - oa.position).x, (ob.position - oa.position).y, 0)
            let full = (eb.position - ea.position).length
            guard full > 1e-6, e.length / full >= config.minProjectedLength, o.length > 1e-6 else { continue }
            let c = max(-1, min(1, e.normalized.dot(o.normalized)))
            errors.append(acos(c) * 180 / .pi)
        }
        guard errors.count >= config.minSegments else { return .unknown(.insufficientCoverage) }
        let mean = errors.reduce(0, +) / Double(errors.count)
        return mean <= config.matchDegrees ? .match(error: mean) : .notMatched(error: mean)
    }
}

/// Scoring never counts unknown as success or failure; reports coverage instead.
public struct ScoreAccumulator: Codable, Equatable, Sendable {
    public private(set) var matched = 0, notMatched = 0, unknown = 0
    public init() {}
    public mutating func record(_ r: MatchResult) {
        switch r { case .match: matched += 1; case .notMatched: notMatched += 1; case .unknown: unknown += 1 }
    }
    public var judged: Int { matched + notMatched }
    public var coverage: Double { let t = judged + unknown; return t == 0 ? 0 : Double(judged) / Double(t) }
    /// nil when nothing could be judged: UNKNOWN, not zero and not full marks.
    public var accuracy: Double? { judged == 0 ? nil : Double(matched) / Double(judged) }
    public var stars: Int? {
        guard let a = accuracy, coverage >= 0.3 else { return nil }
        return a >= 0.9 ? 3 : a >= 0.7 ? 2 : a >= 0.4 ? 1 : 0
    }
}

public struct MasteryRules {
    public static func next(current: Mastery, attempts: Int, accuracy: Double?, coverage: Double) -> Mastery {
        guard let accuracy, coverage >= 0.3 else { return current }  // no evidence, no progression
        switch current {
        case .discovered: return attempts >= 1 ? .learning : .discovered
        case .learning: return accuracy >= 0.6 && attempts >= 2 ? .familiar : .learning
        case .familiar: return accuracy >= 0.85 && attempts >= 4 ? .mastered : .familiar
        case .mastered: return .mastered
        }
    }
}

/// Tracking presence is separate from session lifecycle: loss never corrupts the session.
public struct TrackingPresence: Equatable, Sendable {
    public var fadeSeconds: TimeInterval = 1.0
    public var lostAfter: TimeInterval = 0.6
    public private(set) var lastGood: TimeInterval?
    public init() {}
    public mutating func observe(_ o: TrackingObservation?, minJoints: Int = 8) {
        guard let o, o.raw.values.filter({ $0.confidence >= PoseNormalizer.minConfidence }).count >= minJoints else { return }
        lastGood = o.timestamp
    }
    public func isLost(at now: TimeInterval) -> Bool { guard let g = lastGood else { return true }; return now - g > lostAfter }
    /// Opacity multiplier for graphical YOU: 1 while tracked, fading to 0 after loss.
    public func youConfidence(at now: TimeInterval) -> Double {
        guard let g = lastGood else { return 0 }
        let since = now - g - lostAfter
        return since <= 0 ? 1 : max(0, 1 - since / fadeSeconds)
    }
}
