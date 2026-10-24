import XCTest
@testable import SWAYcoreKit

final class PoseAndMovementTests: XCTestCase {
    func testJointContractHas23UniqueJoints() {
        XCTAssertEqual(SWAYJoint.allCases.count, 23)
        XCTAssertEqual(Set(SWAYJoint.allCases.map(\.rawValue)).count, 23)
    }
    func testMirrorIsInvolution() {
        let p = PoseBuilder.build(Stance(armL: Arm.high, armR: Arm.down, legL: Leg.lift, legR: Leg.stand))
        XCTAssertEqual(p.mirroredPose().mirroredPose(), p)
        XCTAssertEqual(SWAYJoint.wristL.mirrored, .wristR)
        XCTAssertEqual(SWAYJoint.head.mirrored, .head)
    }
    func testNeutralPoseTorsoIsUnitLength() {
        let p = PoseBuilder.build(.neutral)
        XCTAssertEqual((p.position(.neck)! - p.position(.hips)!).length, 1.0, accuracy: 1e-9)
    }
    func testNormalizationRecoversAuthoredPoseRegardlessOfScaleAndOffset() {
        let src = PoseBuilder.build(Stance(armL: Arm.side, armR: Arm.high, legL: Leg.wide, legR: Leg.stand))
        for (scale, origin) in [(0.18, Vec3(0.5, 0.55, 0)), (0.12, Vec3(0.3, 0.45, 0))] {
            let n = PoseNormalizer.normalize(T.raw(src, scale: scale, origin: origin))!
            for j in [SWAYJoint.wristL, .wristR, .kneeL, .ankleR] {
                XCTAssertEqual(n.position(j)!.x, src.position(j)!.x, accuracy: 1e-6)
                XCTAssertEqual(n.position(j)!.y, src.position(j)!.y, accuracy: 1e-6)
            }
        }
    }
    func testNormalizationDropsLowConfidenceJointsInsteadOfInventingThem() {
        var r = T.raw(PoseBuilder.build(.neutral)); r[.wristL]!.confidence = 0.1
        let n = PoseNormalizer.normalize(r)!
        XCTAssertNil(n[.wristL])
        XCTAssertNil(PoseNormalizer.normalize([:]))
    }
    func testLibraryHas26ValidUniqueMoves() throws {
        XCTAssertGreaterThanOrEqual(MoveLibrary.all.count, 26)
        XCTAssertEqual(Set(MoveLibrary.all.map(\.id)).count, MoveLibrary.all.count)
        for m in MoveLibrary.all { try m.validate(); XCTAssertEqual(m.keyframes.count, 8) }
        for c in RigContract.proofClips { XCTAssertNotNil(MoveLibrary.byID[c], c) }
    }
    func testSelectedCountDeterministicallyDisplaysThatState() {
        let m = MoveLibrary.byID["sway_jumping_jack_v1"]!
        for c in 1...8 {
            XCTAssertEqual(m.pose(atCount: c), m.pose(atCount: c))
            XCTAssertEqual(m.pose(atCount: c), m.keyframes.first { $0.count == c }!.pose)
        }
        XCTAssertNotEqual(m.pose(atCount: 1), m.pose(atCount: 3))
        XCTAssertEqual(m.pose(atCount: 9), m.pose(atCount: 1))
    }
    func testInterpolationIsCyclicAndMidpointIsBetween() {
        let m = MoveLibrary.byID["sway_reach_up_v1"]!
        XCTAssertEqual(m.pose(atBeat: 8.0), m.pose(atBeat: 0.0))
        let a = m.pose(atBeat: 0).position(.wristL)!.y, b = m.pose(atBeat: 2).position(.wristL)!.y, mid = m.pose(atBeat: 1.0).position(.wristL)!.y
        XCTAssertEqual(mid, (a + b) / 2, accuracy: 1e-6)
        // between last keyframe (count 8) and wrap to count 1
        _ = m.pose(atBeat: 7.5)
    }
    func testHoldKeyframeDwells() {
        let a = PoseBuilder.build(.neutral), b = PoseBuilder.build(Stance(armL: Arm.high, armR: Arm.high, legL: Leg.stand, legR: Leg.stand))
        let m = MovementDefinition(id: "h", name: "h", keyframes: [CountKeyframe(count: 1, pose: a, hold: true), CountKeyframe(count: 3, pose: b)])
        XCTAssertEqual(m.pose(atBeat: 1.5), a)
    }
    func testMirroredMovementSwapsSides() {
        let m = MoveLibrary.byID["sway_knee_lift_v1"]!
        XCTAssertEqual(m.pose(atCount: 1, mirrored: true), m.pose(atCount: 1).mirroredPose())
    }
    func testValidationRejectsBadMovements() {
        XCTAssertThrowsError(try MovementDefinition(id: "x", name: "x", keyframes: []).validate())
        let p = PoseBuilder.build(.neutral)
        XCTAssertThrowsError(try MovementDefinition(id: "x", name: "x", keyframes: [CountKeyframe(count: 9, pose: p)]).validate())
        XCTAssertThrowsError(try MovementDefinition(id: "x", name: "x", keyframes: [CountKeyframe(count: 1, pose: p), CountKeyframe(count: 1, pose: p)]).validate())
        XCTAssertThrowsError(try MovementDefinition(id: "x", name: "x", keyframes: [CountKeyframe(count: 1, pose: Pose())]).validate())
    }
    func testChoreographyTimelineIsDeterministic() {
        let lib = MoveLibrary.byID
        let tl = ChoreographyTimeline(steps: [ContentStep(movementID: "sway_march_v1", repetitions: 2), ContentStep(movementID: "sway_squat_v1", mirrored: true)], movements: lib)
        XCTAssertEqual(tl.totalBeats, 24)
        XCTAssertEqual(tl.segment(atBeat: 17)?.0.movementID, "sway_squat_v1")
        XCTAssertEqual(tl.segment(atBeat: 17)?.localBeat, 1)
        XCTAssertEqual(tl.next(afterBeat: 3)?.movementID, "sway_squat_v1")
        XCTAssertNil(tl.segment(atBeat: 24)); XCTAssertNil(tl.segment(atBeat: -1))
    }
    func testSkeletonHierarchyCoversEveryJointOnce() {
        for j in SWAYJoint.allCases where j != .root { XCTAssertNotNil(Skeleton.parent[j], j.rawValue) }
    }
}
