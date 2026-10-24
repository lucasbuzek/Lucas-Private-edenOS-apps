import Foundation

public enum CoachID: String, CaseIterable, Codable, Sendable { case lucia, nandi, thabo, zuri, kyle }
public enum VoiceLevel: Int, Codable, Sendable { case off, minimal, normal, detailed }
public enum CueKind: String, Codable, Sendable { case countdown, nextMove, moveStart, reposition, stepIntoView, praise, correction, pause, finish }

/// One CoachCue drives visual text, spoken text, timing and priority (same meaning, different phrasing).
public struct CoachCue: Equatable, Sendable {
    public var kind: CueKind
    public var priority: Int
    public var visual: String
    public var spoken: String?
    public var time: TimeInterval
    /// Evidence-dependent cues (praise/correction) must carry the evidence they rest on.
    public var evidence: MatchResult?
}

public enum CueFactory {
    public static func praise(accuracy: Double?, coverage: Double, now: TimeInterval, level: VoiceLevel, coach: CoachID) -> CoachCue? {
        guard let a = accuracy, coverage >= 0.3, a >= 0.7 else { return nil }   // never timer-fired
        let word = coach == .thabo ? "Strong." : "Nice."
        return CoachCue(kind: .praise, priority: 2, visual: word.uppercased(), spoken: level == .off ? nil : word, time: now, evidence: .match(error: 0))
    }
    public static func reposition(now: TimeInterval, level: VoiceLevel) -> CoachCue {
        CoachCue(kind: .reposition, priority: 9, visual: "STEP INTO VIEW", spoken: level.rawValue >= VoiceLevel.minimal.rawValue ? "Step back into view." : nil, time: now, evidence: .unknown(.outOfFrame))
    }
    public static func countdown(_ n: Int, now: TimeInterval, level: VoiceLevel) -> CoachCue {
        CoachCue(kind: .countdown, priority: 8, visual: "\(n)", spoken: level == .off ? nil : "\(n)", time: now, evidence: nil)
    }
    public static func nextMove(_ name: String, now: TimeInterval, level: VoiceLevel) -> CoachCue {
        CoachCue(kind: .nextMove, priority: 5, visual: "NEXT: \(name.uppercased())", spoken: level.rawValue >= VoiceLevel.normal.rawValue ? "Next, \(name)." : nil, time: now, evidence: nil)
    }
}
