import Foundation

/// Bundled movement content (ND-006): 26 authored moves, including the ten recovered proof-clip moves.
/// All content is authored as 4 key stances expanded to 8 counts; nothing here is a demo placeholder.
public enum MoveLibrary {
    typealias S = Stance
    static func st(_ aL: LimbPose, _ aR: LimbPose, _ lL: LimbPose, _ lR: LimbPose, lean: Double = 0) -> Stance {
        Stance(armL: aL, armR: aR, legL: lL, legR: lR, lean: lean)
    }

    static func make(_ id: String, _ name: String, _ cx: Complexity, _ inten: Intensity, low: Bool = false, instruction: String,
                     _ k: [Stance]) -> MovementDefinition {
        let poses = k.map(PoseBuilder.build)
        var frames: [CountKeyframe] = []
        for i in 0..<4 {
            let a = poses[i], b = poses[(i + 1) % 4]
            frames.append(CountKeyframe(count: 2 * i + 1, pose: a))
            frames.append(CountKeyframe(count: 2 * i + 2, pose: Pose.lerp(a, b, 0.5)))
        }
        return MovementDefinition(id: id, name: name, complexity: cx, intensity: inten, lowImpact: low, keyframes: frames, instruction: instruction)
    }

    public static let all: [MovementDefinition] = {
        let d = Arm.down, L = Leg.stand
        return [
            make("sway_idle_v1", "Easy Sway", .simple, .low, low: true, instruction: "Shift weight side to side with relaxed arms.",
                 [st(d, d, L, L, lean: 4), st(d, d, L, L), st(d, d, L, L, lean: -4), st(d, d, L, L)]),
            make("sway_march_v1", "March", .simple, .medium, low: true, instruction: "Lift knees and swing opposite arms.",
                 [st(Arm.swingOut, Arm.swingIn, Leg.liftLow, L), st(d, d, L, L), st(Arm.swingIn, Arm.swingOut, L, Leg.liftLow), st(d, d, L, L)]),
            make("sway_step_touch_v1", "Step Touch", .simple, .low, low: true, instruction: "Step out, touch together, repeat to the other side.",
                 [st(Arm.flex, Arm.flex, Leg.touch, L), st(Arm.flex, Arm.flex, L, L), st(Arm.flex, Arm.flex, L, Leg.touch), st(Arm.flex, Arm.flex, L, L)]),
            make("sway_grapevine_v1", "Grapevine", .moderate, .medium, instruction: "Step side, cross behind, step side, touch.",
                 [st(Arm.side, Arm.side, Leg.touch, L), st(Arm.side, Arm.side, Leg.crossed, Leg.back), st(Arm.side, Arm.side, Leg.touch, L), st(Arm.hipHand, Arm.hipHand, L, Leg.touch)]),
            make("sway_knee_lift_v1", "Knee Lift", .easy, .medium, instruction: "Drive one knee up, switch.",
                 [st(Arm.swingIn, Arm.swingOut, Leg.lift, L), st(d, d, L, L), st(Arm.swingOut, Arm.swingIn, L, Leg.lift), st(d, d, L, L)]),
            make("sway_squat_v1", "Squat", .easy, .high, instruction: "Sit back and down, chest up, stand tall.",
                 [st(Arm.forward, Arm.forward, Leg.squat, Leg.squat), st(Arm.forward, Arm.forward, Leg.squat, Leg.squat), st(d, d, L, L), st(d, d, L, L)]),
            make("sway_side_lunge_v1", "Side Lunge", .moderate, .high, instruction: "Step wide, bend one knee, push back.",
                 [st(Arm.forward, Arm.forward, Leg.lunge, Leg.wide, lean: 6), st(Arm.forward, Arm.forward, L, L), st(Arm.forward, Arm.forward, Leg.wide, Leg.lunge, lean: -6), st(Arm.forward, Arm.forward, L, L)]),
            make("sway_jumping_jack_v1", "Jumping Jack", .easy, .high, instruction: "Jump feet wide with arms overhead, then return.",
                 [st(Arm.high, Arm.high, Leg.jumpOut, Leg.jumpOut), st(d, d, L, L), st(Arm.high, Arm.high, Leg.jumpOut, Leg.jumpOut), st(d, d, L, L)]),
            make("sway_body_roll_v1", "Body Roll", .complex, .low, instruction: "Roll from chest through hips in a wave.",
                 [st(Arm.flex, Arm.flex, Leg.squat, Leg.squat, lean: 8), st(Arm.hipHand, Arm.hipHand, L, L), st(Arm.flex, Arm.flex, Leg.squat, Leg.squat, lean: -8), st(Arm.hipHand, Arm.hipHand, L, L)]),
            make("sway_pivot_turn_v1", "Pivot Turn", .complex, .medium, instruction: "Step forward and pivot a half turn.",
                 [st(Arm.cross, Arm.swingOut, Leg.touch, L), st(Arm.side, Arm.side, L, Leg.back), st(Arm.swingOut, Arm.cross, L, Leg.touch), st(Arm.side, Arm.side, Leg.back, L)]),
            make("sway_punch_v1", "Forward Punch", .simple, .medium, instruction: "Alternate punches forward with a firm stance.",
                 [st(Arm.forward, Arm.flex, Leg.wide, Leg.wide), st(Arm.flex, Arm.flex, Leg.wide, Leg.wide), st(Arm.flex, Arm.forward, Leg.wide, Leg.wide), st(Arm.flex, Arm.flex, Leg.wide, Leg.wide)]),
            make("sway_reach_up_v1", "Reach Up", .simple, .low, low: true, instruction: "Reach both arms overhead, then lower.",
                 [st(Arm.high, Arm.high, L, L), st(Arm.side, Arm.side, L, L), st(Arm.high, Arm.high, L, L), st(d, d, L, L)]),
            make("sway_bounce_v1", "Hip-Hop Bounce", .easy, .medium, instruction: "Bounce through the knees with loose bent arms.",
                 [st(Arm.flex, Arm.flex, Leg.squat, Leg.squat), st(Arm.flex, Arm.flex, L, L), st(Arm.flex, Arm.flex, Leg.squat, Leg.squat), st(Arm.flex, Arm.flex, L, L)]),
            make("sway_cross_body_v1", "Cross-Body Reach", .moderate, .medium, instruction: "Reach one arm across the body, alternate.",
                 [st(Arm.cross, Arm.down, Leg.wide, Leg.wide, lean: -4), st(d, d, Leg.wide, Leg.wide), st(Arm.down, Arm.cross, Leg.wide, Leg.wide, lean: 4), st(d, d, Leg.wide, Leg.wide)]),
            make("sway_box_step_v1", "Box Step", .moderate, .low, low: true, instruction: "Step forward, side, together, then back, side, together.",
                 [st(Arm.hipHand, Arm.hipHand, Leg.liftLow, L), st(Arm.hipHand, Arm.hipHand, Leg.touch, L), st(Arm.hipHand, Arm.hipHand, L, Leg.back), st(Arm.hipHand, Arm.hipHand, L, Leg.touch)]),
            make("sway_heel_dig_v1", "Heel Dig", .simple, .low, low: true, instruction: "Dig one heel forward, alternate.",
                 [st(Arm.swingIn, Arm.swingIn, Leg.liftLow, L), st(d, d, L, L), st(Arm.swingIn, Arm.swingIn, L, Leg.liftLow), st(d, d, L, L)]),
            make("sway_kick_v1", "Front Kick", .moderate, .high, instruction: "Kick forward with control, alternate legs.",
                 [st(Arm.forward, Arm.side, Leg.kick, L), st(d, d, L, L), st(Arm.side, Arm.forward, L, Leg.kick), st(d, d, L, L)]),
            make("sway_back_lunge_v1", "Back Lunge", .easy, .high, instruction: "Step back, lower, return.",
                 [st(Arm.hipHand, Arm.hipHand, Leg.lungeBent, Leg.back), st(d, d, L, L), st(Arm.hipHand, Arm.hipHand, Leg.back, Leg.lungeBent), st(d, d, L, L)]),
            make("sway_clap_up_v1", "Overhead Clap", .simple, .low, low: true, instruction: "Clap overhead on the beat.",
                 [st(Arm.high, Arm.high, L, L), st(Arm.diagUp, Arm.diagUp, L, L), st(Arm.high, Arm.high, L, L), st(Arm.diagUp, Arm.diagUp, L, L)]),
            make("sway_side_bend_v1", "Side Bend", .simple, .low, low: true, instruction: "Reach overhead and bend side to side.",
                 [st(Arm.high, Arm.high, Leg.wide, Leg.wide, lean: 14), st(Arm.high, Arm.high, Leg.wide, Leg.wide), st(Arm.high, Arm.high, Leg.wide, Leg.wide, lean: -14), st(Arm.high, Arm.high, Leg.wide, Leg.wide)]),
            make("sway_two_step_v1", "Two-Step", .simple, .low, low: true, instruction: "Step-close-step to one side and back.",
                 [st(Arm.flex, Arm.flex, Leg.touch, L), st(Arm.flex, Arm.flex, L, L), st(Arm.flex, Arm.flex, L, Leg.touch), st(Arm.flex, Arm.flex, L, L)]),
            make("sway_cha_cha_v1", "Cha-Cha", .moderate, .medium, instruction: "Rock step then quick triple step.",
                 [st(Arm.hipHand, Arm.hipHand, Leg.liftLow, L, lean: 3), st(Arm.hipHand, Arm.hipHand, L, Leg.back), st(Arm.hipHand, Arm.hipHand, L, Leg.touch), st(Arm.hipHand, Arm.hipHand, Leg.touch, L)]),
            make("sway_disco_point_v1", "Disco Point", .easy, .medium, instruction: "Point one arm up and across, hand on hip, switch.",
                 [st(Arm.diagUp, Arm.hipHand, Leg.touch, L, lean: 6), st(Arm.hipHand, Arm.hipHand, L, L), st(Arm.hipHand, Arm.diagUp, L, Leg.touch, lean: -6), st(Arm.hipHand, Arm.hipHand, L, L)]),
            make("sway_running_man_v1", "Running Man", .expert, .high, instruction: "Slide one foot back while lifting the other knee, arms pumping.",
                 [st(Arm.swingOut, Arm.swingIn, Leg.lift, Leg.back), st(d, d, L, L), st(Arm.swingIn, Arm.swingOut, Leg.back, Leg.lift), st(d, d, L, L)]),
            make("sway_shoulder_press_v1", "Shoulder Press", .simple, .medium, instruction: "Press both hands from shoulders to overhead.",
                 [st(Arm.flex, Arm.flex, Leg.wide, Leg.wide), st(Arm.high, Arm.high, Leg.wide, Leg.wide), st(Arm.flex, Arm.flex, Leg.wide, Leg.wide), st(Arm.high, Arm.high, Leg.wide, Leg.wide)]),
            make("sway_seated_tap_v1", "Low-Impact Tap", .simple, .low, low: true, instruction: "Tap one toe out to the side, alternate, arms relaxed.",
                 [st(Arm.swingIn, Arm.swingIn, Leg.touch, L), st(d, d, L, L), st(Arm.swingIn, Arm.swingIn, L, Leg.touch), st(d, d, L, L)])
        ]
    }()

    public static var byID: [String: MovementDefinition] { Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) }) }
}
