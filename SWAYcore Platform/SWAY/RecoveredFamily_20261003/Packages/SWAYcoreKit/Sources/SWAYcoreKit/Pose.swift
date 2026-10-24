import Foundation

/// Stable joint contract. New implementation decision ND-001: 23 joints, superset-compatible with the
/// recovered SWAYHumanoid-v1 count. Bone names in Blender/USD equal `rawValue`.
public enum SWAYJoint: String, CaseIterable, Codable, Sendable {
    case root, hips, spine, chest, neck, head, headEnd
    case shoulderL, elbowL, wristL, handL, hipL, kneeL, ankleL, toesL
    case shoulderR, elbowR, wristR, handR, hipR, kneeR, ankleR, toesR

    public var mirrored: SWAYJoint {
        let n = rawValue
        if n.hasSuffix("L") { return SWAYJoint(rawValue: String(n.dropLast()) + "R")! }
        if n.hasSuffix("R") { return SWAYJoint(rawValue: String(n.dropLast()) + "L")! }
        return self
    }
}

public struct Vec3: Codable, Equatable, Sendable {
    public var x, y, z: Double
    public init(_ x: Double, _ y: Double, _ z: Double = 0) { self.x = x; self.y = y; self.z = z }
    public static func + (a: Vec3, b: Vec3) -> Vec3 { Vec3(a.x + b.x, a.y + b.y, a.z + b.z) }
    public static func - (a: Vec3, b: Vec3) -> Vec3 { Vec3(a.x - b.x, a.y - b.y, a.z - b.z) }
    public static func * (a: Vec3, s: Double) -> Vec3 { Vec3(a.x * s, a.y * s, a.z * s) }
    public var length: Double { (x * x + y * y + z * z).squareRoot() }
    public var normalized: Vec3 { let l = length; return l > 1e-12 ? self * (1 / l) : Vec3(0, 0, 0) }
    public func dot(_ o: Vec3) -> Double { x * o.x + y * o.y + z * o.z }
    public func cross(_ o: Vec3) -> Vec3 { Vec3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x) }
    public static func lerp(_ a: Vec3, _ b: Vec3, _ t: Double) -> Vec3 { a + (b - a) * t }
}

public struct JointSample: Codable, Equatable, Sendable {
    public var position: Vec3
    public var confidence: Double
    public init(_ position: Vec3, confidence: Double = 1) { self.position = position; self.confidence = confidence }
}

/// Coordinate convention (ND-002): +x = subject's LEFT (image-right for a camera facing the subject),
/// +y up, +z forward (toward camera). Units: normalized torso length (hips -> neck == 1.0). Origin: hips.
public struct Pose: Codable, Equatable, Sendable {
    /// Stored by joint raw name so JSON is keyed (enum-keyed dictionaries encode as arrays).
    public var samples: [String: JointSample]
    public init(samples: [String: JointSample] = [:]) { self.samples = samples }
    public subscript(_ j: SWAYJoint) -> JointSample? {
        get { samples[j.rawValue] }
        set { samples[j.rawValue] = newValue }
    }
    public func position(_ j: SWAYJoint) -> Vec3? { self[j]?.position }

    public func mirroredPose() -> Pose {
        var out = Pose()
        for (k, v) in samples {
            guard let j = SWAYJoint(rawValue: k) else { continue }
            var p = v.position; p.x = -p.x
            out[j.mirrored] = JointSample(p, confidence: v.confidence)
        }
        return out
    }

    public static func lerp(_ a: Pose, _ b: Pose, _ t: Double) -> Pose {
        var out = Pose()
        for j in SWAYJoint.allCases {
            if let pa = a[j], let pb = b[j] {
                out[j] = JointSample(Vec3.lerp(pa.position, pb.position, t), confidence: min(pa.confidence, pb.confidence))
            }
        }
        return out
    }
}

/// Parent hierarchy for the rig contract.
public enum Skeleton {
    public static let parent: [SWAYJoint: SWAYJoint] = {
        var p: [SWAYJoint: SWAYJoint] = [
            .hips: .root, .spine: .hips, .chest: .spine, .neck: .chest, .head: .neck, .headEnd: .head
        ]
        for s in ["L", "R"] {
            func J(_ n: String) -> SWAYJoint { SWAYJoint(rawValue: n + s)! }
            p[J("shoulder")] = .chest; p[J("elbow")] = J("shoulder"); p[J("wrist")] = J("elbow"); p[J("hand")] = J("wrist")
            p[J("hip")] = .hips; p[J("knee")] = J("hip"); p[J("ankle")] = J("knee"); p[J("toes")] = J("ankle")
        }
        return p
    }()

    /// Primary child used to define a bone's direction (nil for leaves).
    public static let primaryChild: [SWAYJoint: SWAYJoint] = {
        var c: [SWAYJoint: SWAYJoint] = [:]
        for s in ["L", "R"] {
            func J(_ n: String) -> SWAYJoint { SWAYJoint(rawValue: n + s)! }
            c[.chest] = .neck
            c[J("shoulder")] = J("elbow"); c[J("elbow")] = J("wrist"); c[J("wrist")] = J("hand")
            c[J("hip")] = J("knee"); c[J("knee")] = J("ankle"); c[J("ankle")] = J("toes")
        }
        c[.root] = .hips; c[.hips] = .spine; c[.spine] = .chest; c[.neck] = .head; c[.head] = .headEnd
        return c
    }()

    /// Segments compared by the matcher and used for retargeting direction.
    public static let matchSegments: [(SWAYJoint, SWAYJoint)] = [
        (.hips, .neck),
        (.shoulderL, .elbowL), (.elbowL, .wristL), (.shoulderR, .elbowR), (.elbowR, .wristR),
        (.hipL, .kneeL), (.kneeL, .ankleL), (.hipR, .kneeR), (.kneeR, .ankleR)
    ]
}

/// Raw camera-space observation (e.g. from Vision), y-up, image-normalized 0...1.
public struct TrackingObservation: Sendable {
    public var timestamp: TimeInterval
    public var raw: [SWAYJoint: JointSample]
    public init(timestamp: TimeInterval, raw: [SWAYJoint: JointSample]) { self.timestamp = timestamp; self.raw = raw }
}

public enum PoseNormalizer {
    public static let minConfidence = 0.3

    public static func torsoLength(_ raw: [SWAYJoint: JointSample]) -> Double? {
        guard let n = raw[.neck], let h = hipCenter(raw), n.confidence >= minConfidence else { return nil }
        let l = (n.position - h).length
        return l > 1e-6 ? l : nil
    }

    public static func hipCenter(_ raw: [SWAYJoint: JointSample]) -> Vec3? {
        if let h = raw[.hips], h.confidence >= minConfidence { return h.position }
        if let l = raw[.hipL], let r = raw[.hipR], l.confidence >= minConfidence, r.confidence >= minConfidence {
            return Vec3.lerp(l.position, r.position, 0.5)
        }
        return nil
    }

    /// Hip-centered, torso-length-scaled pose. Joints below minConfidence are dropped (never invented).
    public static func normalize(_ raw: [SWAYJoint: JointSample], aspect: Double = 1) -> Pose? {
        guard let c = hipCenter(raw), let torso = torsoLength(raw) else { return nil }
        var out = Pose()
        for (j, s) in raw where s.confidence >= minConfidence {
            let d = s.position - c
            out[j] = JointSample(Vec3(d.x * aspect / torso, d.y / torso, d.z / torso), confidence: s.confidence)
        }
        out[.hips] = JointSample(Vec3(0, 0, 0), confidence: raw[.hips]?.confidence ?? 1)
        return out
    }
}
