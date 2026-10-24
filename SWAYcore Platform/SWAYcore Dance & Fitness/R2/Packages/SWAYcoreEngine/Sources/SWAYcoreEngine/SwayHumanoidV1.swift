import Foundation

/// SWAYHumanoid-v1 — the 23-joint common rig contract (AssetPipeline/contracts/SWAYHumanoid-v1.json is the file authority).
public enum SwayHumanoidV1 {
    public static let contractName = "SWAYHumanoid-v1"
    public static let joints: [String] = [
        "Root", "Hips", "Spine", "Spine1", "Chest", "Neck", "Head",
        "LeftShoulder", "LeftUpperArm", "LeftLowerArm", "LeftHand",
        "RightShoulder", "RightUpperArm", "RightLowerArm", "RightHand",
        "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "LeftToe",
        "RightUpperLeg", "RightLowerLeg", "RightFoot", "RightToe"]
    public static let requiredAnimations: [String] = [
        "sway_idle_v1", "sway_march_v1", "sway_step_touch_v1", "sway_grapevine_v1", "sway_knee_lift_v1",
        "sway_squat_v1", "sway_side_lunge_v1", "sway_jumping_jack_v1", "sway_body_roll_v1", "sway_pivot_turn_v1"]

    public static let parent: [String: String] = {
        var p: [String: String] = ["Hips": "Root", "Spine": "Hips", "Spine1": "Spine", "Chest": "Spine1", "Neck": "Chest", "Head": "Neck"]
        for s in ["Left", "Right"] {
            p[s + "Shoulder"] = "Chest"; p[s + "UpperArm"] = s + "Shoulder"; p[s + "LowerArm"] = s + "UpperArm"; p[s + "Hand"] = s + "LowerArm"
            p[s + "UpperLeg"] = "Hips"; p[s + "LowerLeg"] = s + "UpperLeg"; p[s + "Foot"] = s + "LowerLeg"; p[s + "Toe"] = s + "Foot"
        }
        return p
    }()

    /// Structural validation of a character's joints/clips. Returns human-readable issues (empty == structurally valid).
    public static func validate(joints names: [String], clips: [String]) -> [String] {
        var issues: [String] = []
        let set = Set(names)
        if set.count != names.count { issues.append("duplicate joints: \(Dictionary(grouping: names, by: { $0 }).filter { $1.count > 1 }.keys.sorted())") }
        let missing = Set(joints).subtracting(set); if !missing.isEmpty { issues.append("missing joints: \(missing.sorted())") }
        let extra = set.subtracting(joints); if !extra.isEmpty { issues.append("non-contract joints: \(extra.sorted())") }
        let missingClips = Set(requiredAnimations).subtracting(clips); if !missingClips.isEmpty { issues.append("missing clips: \(missingClips.sorted())") }
        return issues
    }
    public static func isValidHierarchy() -> Bool {
        for j in joints where j != "Root" { guard let p = parent[j], joints.contains(p) else { return false } }
        // acyclic: every joint reaches Root
        for j in joints { var cur = j, steps = 0; while cur != "Root" { guard let p = parent[cur], steps < 32 else { return false }; cur = p; steps += 1 } }
        return true
    }
}

public struct SwayMappedJoint: Equatable, Sendable {
    public var point: SwayPoint
    public var confidence: Double
    /// true when the joint is geometrically derived/proxied, not directly observed by the estimator.
    public var derived: Bool
}

/// Maps estimator joints (Apple Vision 2D names, canonicalised) into SWAYHumanoid-v1. Apple's joint set never redefines the contract.
/// Joints that cannot be observed or soundly derived (Toe) are OMITTED: absence is UNKNOWN, never invented.
public enum SwayPoseMapper {
    public static let minConfidence = 0.25
    public static func map(_ vision: [String: (point: SwayPoint, confidence: Double)]) -> [String: SwayMappedJoint] {
        func ok(_ k: String) -> (point: SwayPoint, confidence: Double)? { if let v = vision[k], v.confidence >= minConfidence { return v }; return nil }
        func lerp(_ a: SwayPoint, _ b: SwayPoint, _ t: Double) -> SwayPoint { SwayPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t) }
        var out: [String: SwayMappedJoint] = [:]
        if let r = ok("root") {
            out["Root"] = .init(point: r.point, confidence: r.confidence, derived: false)
            out["Hips"] = .init(point: r.point, confidence: r.confidence, derived: false)
            if let n = ok("neck") {
                let c = min(r.confidence, n.confidence)
                out["Spine"] = .init(point: lerp(r.point, n.point, 0.25), confidence: c, derived: true)
                out["Spine1"] = .init(point: lerp(r.point, n.point, 0.50), confidence: c, derived: true)
                out["Chest"] = .init(point: lerp(r.point, n.point, 0.75), confidence: c, derived: true)
            }
        }
        if let n = ok("neck") { out["Neck"] = .init(point: n.point, confidence: n.confidence, derived: false) }
        if let h = ok("nose") { out["Head"] = .init(point: h.point, confidence: h.confidence, derived: true) }   // nose proxies the head joint
        for (side, v) in [("Left", "left"), ("Right", "right")] {
            if let s = ok(v + "Shoulder") {
                out[side + "UpperArm"] = .init(point: s.point, confidence: s.confidence, derived: false)
                if let n = ok("neck") { out[side + "Shoulder"] = .init(point: lerp(n.point, s.point, 0.5), confidence: min(n.confidence, s.confidence), derived: true) }
            }
            if let e = ok(v + "Elbow") { out[side + "LowerArm"] = .init(point: e.point, confidence: e.confidence, derived: false) }
            if let w = ok(v + "Wrist") { out[side + "Hand"] = .init(point: w.point, confidence: w.confidence, derived: false) }
            if let h = ok(v + "Hip") { out[side + "UpperLeg"] = .init(point: h.point, confidence: h.confidence, derived: false) }
            if let k = ok(v + "Knee") { out[side + "LowerLeg"] = .init(point: k.point, confidence: k.confidence, derived: false) }
            if let a = ok(v + "Ankle") { out[side + "Foot"] = .init(point: a.point, confidence: a.confidence, derived: false) }
        }
        return out
    }
}
