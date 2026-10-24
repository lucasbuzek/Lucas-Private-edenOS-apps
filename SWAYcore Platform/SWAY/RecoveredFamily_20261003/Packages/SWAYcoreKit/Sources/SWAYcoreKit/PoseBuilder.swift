import Foundation

/// Forward-kinematic pose authoring (ND-003). Authored content is angle presets; positions derive from FK
/// on the common proportions so Blender clips, runtime retargeting and matching share one truth.
public struct SegAngle: Codable, Equatable, Sendable {
    public var abd: Double   // degrees from straight-down toward the outside (frontal plane)
    public var fwd: Double   // degrees from straight-down toward forward (+z)
    public init(_ abd: Double, _ fwd: Double = 0) { self.abd = abd; self.fwd = fwd }
    func direction(side: Double) -> Vec3 {
        let a = abd * .pi / 180, f = fwd * .pi / 180
        let v = Vec3(side * sin(a), -cos(a), 0)
        return Vec3(v.x, v.y * cos(f), -v.y * sin(f)).normalized
    }
}

public struct LimbPose: Codable, Equatable, Sendable {
    public var upper: SegAngle, lower: SegAngle
    public init(_ upper: SegAngle, _ lower: SegAngle) { self.upper = upper; self.lower = lower }
}

public struct Stance: Codable, Equatable, Sendable {
    public var armL: LimbPose, armR: LimbPose, legL: LimbPose, legR: LimbPose
    public var lean: Double  // torso lean toward subject-left, degrees
    public init(armL: LimbPose, armR: LimbPose, legL: LimbPose, legR: LimbPose, lean: Double = 0) {
        self.armL = armL; self.armR = armR; self.legL = legL; self.legR = legR; self.lean = lean
    }
}

public enum Proportions {
    public static let upperArm = 0.55, foreArm = 0.5, hand = 0.2
    public static let thigh = 0.9, shin = 0.85, foot = 0.3
    public static let shoulderX = 0.38, shoulderY = 0.92, hipX = 0.15
    public static let rest: [SWAYJoint: Vec3] = PoseBuilder.build(.neutral).samples.reduce(into: [:]) { acc, kv in
        if let j = SWAYJoint(rawValue: kv.key) { acc[j] = kv.value.position }
    }
}

public enum PoseBuilder {
    public static func build(_ s: Stance) -> Pose {
        var p = Pose()
        let lean = s.lean * .pi / 180
        func torso(_ y: Double) -> Vec3 { Vec3(sin(lean) * y, cos(lean) * y, 0) }  // lean toward +x (subject left)
        let hips = Vec3(0, 0, 0)
        p[.hips] = JointSample(hips); p[.root] = JointSample(Vec3(0, -0.05, 0))
        p[.spine] = JointSample(torso(0.35)); p[.chest] = JointSample(torso(0.7)); p[.neck] = JointSample(torso(1.0))
        p[.head] = JointSample(torso(1.12) ); p[.headEnd] = JointSample(torso(1.45))
        for (side, sx, arm, leg) in [(1.0, "L", s.armL, s.legL), (-1.0, "R", s.armR, s.legR)] {
            func J(_ n: String) -> SWAYJoint { SWAYJoint(rawValue: n + sx)! }
            let sh = torso(Proportions.shoulderY) + Vec3(side * Proportions.shoulderX, 0, 0)
            let el = sh + arm.upper.direction(side: side) * Proportions.upperArm
            let wr = el + arm.lower.direction(side: side) * Proportions.foreArm
            let hd = wr + arm.lower.direction(side: side) * Proportions.hand
            p[J("shoulder")] = JointSample(sh); p[J("elbow")] = JointSample(el)
            p[J("wrist")] = JointSample(wr); p[J("hand")] = JointSample(hd)
            let hp = Vec3(side * Proportions.hipX, 0, 0)
            let kn = hp + leg.upper.direction(side: side) * Proportions.thigh
            let an = kn + leg.lower.direction(side: side) * Proportions.shin
            // Foot points forward, tilted with the shin's forward component.
            let toes = an + Vec3(0, 0, Proportions.foot)
            p[J("hip")] = JointSample(hp); p[J("knee")] = JointSample(kn)
            p[J("ankle")] = JointSample(an); p[J("toes")] = JointSample(toes)
        }
        return p
    }
}

public extension Stance {
    static let neutral = Stance(armL: Arm.down, armR: Arm.down, legL: Leg.stand, legR: Leg.stand)
}

/// Named limb presets: movement content is authored by composing these (and custom angles).
public enum Arm {
    public static let down    = LimbPose(SegAngle(8), SegAngle(6))
    public static let side    = LimbPose(SegAngle(90), SegAngle(90))
    public static let high    = LimbPose(SegAngle(160), SegAngle(170))
    public static let forward = LimbPose(SegAngle(10, 90), SegAngle(10, 90))
    public static let flex    = LimbPose(SegAngle(75), SegAngle(10, 140))
    public static let swingIn = LimbPose(SegAngle(20, 40), SegAngle(15, 70))
    public static let swingOut = LimbPose(SegAngle(30, -30), SegAngle(30, -10))
    public static let hipHand = LimbPose(SegAngle(35), SegAngle(-15, 20))
    public static let cross   = LimbPose(SegAngle(-10, 50), SegAngle(-60, 60))
    public static let diagUp  = LimbPose(SegAngle(135), SegAngle(140))
    public static let wave    = LimbPose(SegAngle(60), SegAngle(150))
}
public enum Leg {
    public static let stand   = LimbPose(SegAngle(2), SegAngle(1))
    public static let wide    = LimbPose(SegAngle(22), SegAngle(18))
    public static let lift    = LimbPose(SegAngle(0, 90), SegAngle(0, 5))
    public static let liftLow = LimbPose(SegAngle(0, 40), SegAngle(0, 10))
    public static let squat   = LimbPose(SegAngle(14, 75), SegAngle(10, -10))
    public static let lunge   = LimbPose(SegAngle(40, 20), SegAngle(30, 5))
    public static let lungeBent = LimbPose(SegAngle(35, 70), SegAngle(15, -5))
    public static let touch   = LimbPose(SegAngle(30), SegAngle(35))
    public static let back    = LimbPose(SegAngle(2, -30), SegAngle(2, -45))
    public static let crossed = LimbPose(SegAngle(-12), SegAngle(-12))
    public static let kick    = LimbPose(SegAngle(0, 70), SegAngle(0, 85))
    public static let jumpOut = LimbPose(SegAngle(30), SegAngle(28))
}
