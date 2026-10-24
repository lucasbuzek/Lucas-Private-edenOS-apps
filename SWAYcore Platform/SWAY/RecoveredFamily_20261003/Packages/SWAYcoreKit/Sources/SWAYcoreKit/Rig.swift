import Foundation

/// Runtime character manifest emitted by the Blender pipeline and consumed by apps/validators.
public struct CharacterManifest: Codable, Equatable, Sendable {
    public var contract: String            // "SWAYHumanoid-v2"
    public var characterID: String
    public var displayName: String
    public var asset: String               // runtime file name, e.g. lucia.usdz
    public var blendSource: String
    public var upAxis: String              // "Y"
    public var metersPerUnit: Double
    public var heightMeters: Double
    public var joints: [String]
    public var meshes: [String]
    public var materials: [String]
    public var textures: [String]
    public var clips: [String]
    public var triangleCount: Int
    public var maxSkinInfluences: Int
    public var visualQuality: String       // "UNREVIEWED" until a human accepts it; never auto-"ACCEPTED"
}

public enum RigContract {
    public static let contractName = "SWAYHumanoid-v2"
    public static let requiredJoints = SWAYJoint.allCases.map(\.rawValue)
    public static let proofClips = ["sway_idle_v1", "sway_march_v1", "sway_step_touch_v1", "sway_grapevine_v1", "sway_knee_lift_v1",
                                    "sway_squat_v1", "sway_side_lunge_v1", "sway_jumping_jack_v1", "sway_body_roll_v1", "sway_pivot_turn_v1"]
    public static let requiredCharacters = ["lucia", "nandi", "thabo", "zuri", "kyle", "yourdancer"]
    public static let heightRange = 1.4...2.0
    public static let maxTriangles = 60_000   // iPhone runtime budget (ND-005)
    public static let requiredMeshes = ["Body", "Head", "Eyes", "Hair", "Outfit"]

    public static func validate(_ m: CharacterManifest) -> [String] {
        var issues: [String] = []
        if m.contract != contractName { issues.append("contract \(m.contract) != \(contractName)") }
        if Set(m.joints).count != m.joints.count { issues.append("duplicate joints") }
        let missing = Set(requiredJoints).subtracting(m.joints)
        if !missing.isEmpty { issues.append("missing joints: \(missing.sorted())") }
        if m.upAxis != "Y" { issues.append("upAxis must be Y") }
        if abs(m.metersPerUnit - 1.0) > 1e-9 { issues.append("metersPerUnit must be 1.0") }
        if !heightRange.contains(m.heightMeters) { issues.append("height out of range") }
        for r in requiredMeshes where !m.meshes.contains(r) { issues.append("missing mesh \(r)") }
        for c in proofClips where !m.clips.contains(c) { issues.append("missing clip \(c)") }
        if m.materials.isEmpty { issues.append("no materials") }
        if m.textures.isEmpty { issues.append("no textures") }
        if m.triangleCount <= 0 || m.triangleCount > maxTriangles { issues.append("triangle budget") }
        if m.maxSkinInfluences > 4 { issues.append("skin influences > 4") }
        if m.asset.isEmpty || m.blendSource.isEmpty { issues.append("missing asset/blend path") }
        return issues
    }
}

/// Retargets a normalized Pose onto the contract rig: per-joint world-direction targets from rest to posed.
public struct Quat: Equatable, Sendable {
    public var x, y, z, w: Double
    public static let identity = Quat(x: 0, y: 0, z: 0, w: 1)
    /// Shortest-arc rotation taking unit vector a to unit vector b.
    public static func rotation(from a: Vec3, to b: Vec3) -> Quat {
        let a = a.normalized, b = b.normalized
        let d = a.dot(b)
        if d > 0.999999 { return .identity }
        if d < -0.999999 {
            var axis = Vec3(1, 0, 0).cross(a); if axis.length < 1e-6 { axis = Vec3(0, 1, 0).cross(a) }
            axis = axis.normalized; return Quat(x: axis.x, y: axis.y, z: axis.z, w: 0)
        }
        let c = a.cross(b); let q = Quat(x: c.x, y: c.y, z: c.z, w: 1 + d)
        let n = (q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w).squareRoot()
        return Quat(x: q.x / n, y: q.y / n, z: q.z / n, w: q.w / n)
    }
    public func rotate(_ v: Vec3) -> Vec3 {
        let u = Vec3(x, y, z); let s = w
        return u * (2 * u.dot(v)) + v * (s * s - u.dot(u)) + u.cross(v) * (2 * s)
    }
}

public enum PoseRetargeter {
    /// World-space rotation per joint that carries the rest bone direction onto the posed bone direction.
    /// Leaves inherit their parent's rotation. Runtime converts world rotations to local using the rig hierarchy.
    public static func worldRotations(for pose: Pose) -> [SWAYJoint: Quat] {
        var out: [SWAYJoint: Quat] = [:]
        for j in SWAYJoint.allCases {
            if let c = Skeleton.primaryChild[j], let rj = Proportions.rest[j], let rc = Proportions.rest[c],
               let pj = pose.position(j), let pc = pose.position(c) {
                out[j] = Quat.rotation(from: rc - rj, to: pc - pj)
            } else if let p = Skeleton.parent[j], let q = out[p] { out[j] = q }
            else { out[j] = .identity }
        }
        return out
    }
}
