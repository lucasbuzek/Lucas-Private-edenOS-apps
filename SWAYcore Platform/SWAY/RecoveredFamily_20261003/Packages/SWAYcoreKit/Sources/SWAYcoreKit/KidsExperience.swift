import Foundation

/// Kid Dancers boundaries (ND-011). Only safe necessary settings; NO parental-account schema, age-band curriculum,
/// games or reward economy is invented here (not recovered canon).
public struct KidsSettings: Codable, Equatable, Sendable {
    public var cameraMatchingEnabled = false        // off by default; enabling requires adult gate
    public var voice: VoiceLevel = .normal
    public var practiceBPMCap = 100.0               // slower, still user-adjustable by the adult gate
    public var recordingEnabled = false             // explicit recording is never on by default
    public init() {}
}
public enum KidsPolicy {
    /// Network/analytics/account collection is not part of this product.
    public static let collectsPersonalData = false
    public static let usesNetworkForCore = false
    /// Content filter: simple/easy complexity and not high-intensity.
    public static func suitable(_ m: MovementDefinition) -> Bool { m.complexity.rawValue <= Complexity.easy.rawValue && m.intensity != .high }
    public static func library() -> [MovementDefinition] { MoveLibrary.all.filter(suitable) }
    /// Adult gate: arithmetic challenge that a young child is unlikely to solve; deterministic by seed for tests.
    public static func adultGate(seed: Int) -> (question: String, answer: Int) {
        let a = 12 + (seed * 7) % 13, b = 6 + (seed * 5) % 9
        return ("\(a) × \(b)", a * b)
    }
    /// Feedback strings: short, effort-oriented, and never claim camera evidence that does not exist.
    public static func feedback(score: ScoreAccumulator, cameraEnabled: Bool) -> String {
        guard cameraEnabled else { return "You danced along! Great job moving." }
        guard let a = score.accuracy, score.coverage >= 0.3 else { return "Nice try! Let's move where the camera can see you." }
        return a >= 0.7 ? "Amazing moves!" : a >= 0.4 ? "You're getting it! Try again!" : "Good effort! Watch and copy once more."
    }
}
