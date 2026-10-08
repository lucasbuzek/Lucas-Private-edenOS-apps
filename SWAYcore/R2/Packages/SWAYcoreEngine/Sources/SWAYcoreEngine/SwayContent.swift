import Foundation

public enum SwayDifficulty: Int, Codable, CaseIterable, Sendable { case beginner = 1, easy, moderate, hard, expert }
public struct SwayMoveDefinition: Identifiable, Codable, Hashable, Sendable {
    public var id: String; public var name: String; public var instruction: String; public var counts: Int; public var difficulty: SwayDifficulty
    public init(id: String, name: String, instruction: String, counts: Int = 8, difficulty: SwayDifficulty = .beginner) { self.id = id; self.name = name; self.instruction = instruction; self.counts = counts; self.difficulty = difficulty }
}
public struct SwayVariationDefinition: Identifiable, Codable, Sendable { public var id: String; public var moveID: String; public var parameters: SwayMoveParameters }
public struct SwayCombinationDefinition: Identifiable, Codable, Sendable { public var id: String; public var variationIDs: [String] }
public struct SwayRoutineDefinition: Identifiable, Codable, Sendable { public var id: String; public var combinationIDs: [String] }
public struct SwayWorkoutDefinition: Identifiable, Codable, Sendable { public var id: String; public var name: String; public var routineIDs: [String]; public var difficulty: SwayDifficulty }
public struct SwayChallengeDefinition: Identifiable, Codable, Sendable { public var id: String; public var workoutIDs: [String] }
public struct SwayProgramDefinition: Identifiable, Codable, Sendable { public var id: String; public var challengeIDs: [String] }
public enum SwayArmStyle: String, Codable, CaseIterable, Sendable { case relaxed, reach, pump, freestyle }
public struct SwayMoveParameters: Codable, Equatable, Sendable {
    public var bpm: Double; public var range: Double; public var armStyle: SwayArmStyle; public var intensity: Double
    public init(bpm: Double, range: Double, armStyle: SwayArmStyle, intensity: Double) { self.bpm = bpm; self.range = range; self.armStyle = armStyle; self.intensity = intensity }
}

public enum SwayAuthoredLibrary {
    public static let moves: [SwayMoveDefinition] = [
        ("march","March","Lift alternating knees under your hips"),("step-touch","Step Touch","Step wide and touch the other foot in"),("hip-sway","Hip Sway","Shift weight and let the hips follow"),("heel-dig","Heel Dig","Place alternating heels forward"),("knee","Knee Lift","Lift each knee toward the chest"),("double-step","Double Step","Travel twice in each direction"),("grapevine","Grapevine","Cross behind while travelling sideways"),("arm-reach","Arm Reach","Reach overhead with alternating arms"),("v-step","V-Step","Step wide forward then narrow back"),("side-tap","Side Tap","Tap each foot to the side"),("box-step","Box Step","Trace a square with four steps"),("mambo","Mambo Step","Rock forward and recover"),("cha-cha","Cha-Cha Basic","Triple step then change direction"),("squat-pulse","Squat Pulse","Sit back and pulse with control"),("side-lunge","Side Lunge","Bend one knee while the other stays long"),("cross-step","Cross Step","Cross one foot over and open"),("body-roll","Body Roll","Ripple from chest through hips"),("jumping-jack","Dance Jack","Open and close feet with matching arms"),("skater","Skater","Travel side to side on one foot"),("pivot-turn","Pivot Turn","Step and rotate with a stable core"),
        ("kick-ball-change","Kick-Ball-Change","Kick, step on the ball, then change weight"),("salsa-basic","Salsa Basic","Rock forward and back across eight counts"),("jazz-square","Jazz Square","Cross and step around a four-point square"),("power-knee","Power Knee","Drive the knee up with pulling arms"),("lateral-hop","Lateral Hop","Hop side to side with soft landings"),("low-jack","Low Jack","Step wide without jumping and sweep arms")
    ].map { SwayMoveDefinition(id: $0.0, name: $0.1, instruction: $0.2) }
    public static let workouts: [SwayWorkoutDefinition] = [
        .init(id: "foundation-flow", name: "Foundation Flow", routineIDs: ["foundation"], difficulty: .beginner),
        .init(id: "latin-vibes", name: "Latin Vibes", routineIDs: ["latin"], difficulty: .moderate),
        .init(id: "full-body-groove", name: "Full Body Groove", routineIDs: ["full-body"], difficulty: .hard)
    ]
    public static func moves(maxDifficulty: SwayDifficulty) -> [SwayMoveDefinition] { moves.filter { $0.difficulty.rawValue <= maxDifficulty.rawValue } }
}
