import Foundation
@testable import SWAYcoreKit

enum T {
    /// Converts an authored pose to a camera observation (image-normalized, y-up) at the given torso scale.
    static func raw(_ pose: Pose, scale: Double = 0.18, origin: Vec3 = Vec3(0.5, 0.55, 0), confidence: Double = 1) -> [SWAYJoint: JointSample] {
        var r: [SWAYJoint: JointSample] = [:]
        for j in SWAYJoint.allCases {
            if let p = pose.position(j) { r[j] = JointSample(Vec3(origin.x + p.x * scale, origin.y + p.y * scale, 0), confidence: confidence) }
        }
        return r
    }
    static func obs(_ stance: Stance, t: TimeInterval, tweak: ((inout [SWAYJoint: JointSample]) -> Void)? = nil) -> TrackingObservation {
        var r = raw(PoseBuilder.build(stance)); tweak?(&r)
        return TrackingObservation(timestamp: t, raw: r)
    }
}
