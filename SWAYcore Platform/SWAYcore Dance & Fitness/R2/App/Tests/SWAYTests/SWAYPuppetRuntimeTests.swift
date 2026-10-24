import XCTest
import Vision
import SWAYcoreEngine
@testable import SWAY

final class SWAYPuppetRuntimeTests: XCTestCase {
    func testYawSweepVisitsEightDirectionsInOrder() {
        var selector=SWAYPuppetAngleSelector()
        let actual=stride(from:0.0,through:315.0,by:45.0).map { selector.select(yawRadians:$0 * .pi / 180) }
        XCTAssertEqual(actual,SWAYPuppetAngle.allCases)
    }

    func testAngleHysteresisRejectsTenDegreeBoundaryNoise() {
        var selector=SWAYPuppetAngleSelector()
        XCTAssertEqual(selector.select(yawRadians:32 * .pi / 180),.front)
        XCTAssertEqual(selector.select(yawRadians:33 * .pi / 180),.frontRight)
        XCTAssertEqual(selector.select(yawRadians:23 * .pi / 180),.frontRight)
        XCTAssertEqual(selector.select(yawRadians:12 * .pi / 180),.front)
    }

    func testDroppedVisionJointHoldsLastGoodPosition() {
        var mapper=SWAYVisionPuppetMapper()
        let elbow=PoseJoint(name:.leftElbow,point:CGPoint(x:0.2,y:0.3),confidence:0.9)
        let first=SwayBodyPose(timestamp:0,sequence:1,joints:[.leftElbow:elbow],averageConfidence:0.9)
        XCTAssertEqual(mapper.map(first)["LeftLowerArm"]?.point,SwayPoint(x:0.2,y:0.3))
        XCTAssertEqual(mapper.map(.empty)["LeftLowerArm"]?.point,SwayPoint(x:0.2,y:0.3))
    }

    func testCoachPuppetUsesContractJointNames() {
        let joints=SwayCoachPose.neutral.puppetJoints
        for name in ["Root","Hips","Chest","Neck","Head","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperLeg","RightLowerLeg","RightFoot"] {
            XCTAssertNotNil(joints[name],name)
        }
    }

    func testSwiftPlacementMatchesReferenceCompositorFixtureWithinHalfPixel() throws {
        let fixture: PlacementFixture = try decodeFixture("puppet_pivot_parity")
        let placement = SWAYPuppetMath.limbPlacement(
            proximal: CGPoint(x: fixture.proximal[0], y: fixture.proximal[1]),
            distal: CGPoint(x: fixture.distal[0], y: fixture.distal[1]),
            canvasSize: CGSize(width: fixture.canvas[0], height: fixture.canvas[1]),
            widthFraction: fixture.widthFraction
        )
        XCTAssertEqual(placement.center.x, fixture.expectedCenter[0], accuracy: 0.5)
        XCTAssertEqual(placement.center.y, fixture.expectedCenter[1], accuracy: 0.5)
        XCTAssertEqual(placement.size.width, fixture.expectedSize[0], accuracy: 0.5)
        XCTAssertEqual(placement.size.height, fixture.expectedSize[1], accuracy: 0.5)
        XCTAssertEqual(placement.rotationRadians, fixture.expectedRotationRadians, accuracy: 0.000_001)

        let pivoted = SWAYPuppetMath.pivotedPlacement(
            joint: CGPoint(x: fixture.proximal[0], y: fixture.proximal[1]),
            canvasSize: CGSize(width: fixture.canvas[0], height: fixture.canvas[1]),
            assetSize: CGSize(width: fixture.assetSize[0], height: fixture.assetSize[1]),
            assetPivot: CGPoint(x: fixture.assetPivot[0], y: fixture.assetPivot[1])
        )
        XCTAssertEqual(pivoted.center.x, fixture.expectedPivotedCenter[0], accuracy: 0.5)
        XCTAssertEqual(pivoted.center.y, fixture.expectedPivotedCenter[1], accuracy: 0.5)
    }

    func testRecordedSyntheticVisionFixturesDriveYouPuppetAndRetainDroppedJoint() throws {
        let fixture: VisionFixture = try decodeFixture("synthetic_vision_pose_sequence")
        XCTAssertEqual(fixture.provenance, "synthetic-hand-authored-from-coach-pose-atlas")
        var mapper = SWAYVisionPuppetMapper()
        var priorElbow: SwayPoint?

        for frame in fixture.frames {
            let joints = Dictionary(uniqueKeysWithValues: frame.joints.compactMap { name, sample in
                visionName(name).map { jointName in
                    (jointName, PoseJoint(
                        name: jointName,
                        point: CGPoint(x: sample.x, y: sample.y),
                        confidence: sample.confidence
                    ))
                }
            })
            let pose = SwayBodyPose(
                timestamp: frame.timestamp,
                sequence: frame.sequence,
                joints: joints,
                averageConfidence: 0.9
            )
            let mapped = mapper.map(pose)
            XCTAssertNotNil(mapped["Hips"], "fixture frame \(frame.sequence) must drive the YOU puppet")
            if frame.dropped.contains("leftElbow") {
                XCTAssertEqual(mapped["LeftLowerArm"]?.point, priorElbow)
            } else {
                priorElbow = mapped["LeftLowerArm"]?.point
            }
        }
    }

    private func decodeFixture<T: Decodable>(_ name: String) throws -> T {
        let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let url = testsDirectory.appendingPathComponent("Fixtures/\(name).json")
        return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
    }

    private func visionName(_ name: String) -> VNHumanBodyPoseObservation.JointName? {
        switch name {
        case "root": return .root
        case "neck": return .neck
        case "nose": return .nose
        case "leftShoulder": return .leftShoulder
        case "leftElbow": return .leftElbow
        case "leftWrist": return .leftWrist
        case "rightShoulder": return .rightShoulder
        case "rightElbow": return .rightElbow
        case "rightWrist": return .rightWrist
        case "leftHip": return .leftHip
        case "leftKnee": return .leftKnee
        case "leftAnkle": return .leftAnkle
        case "rightHip": return .rightHip
        case "rightKnee": return .rightKnee
        case "rightAnkle": return .rightAnkle
        default: return nil
        }
    }
}

private struct PlacementFixture: Decodable {
    let canvas: [CGFloat]
    let proximal: [CGFloat]
    let distal: [CGFloat]
    let widthFraction: CGFloat
    let expectedCenter: [CGFloat]
    let expectedSize: [CGFloat]
    let expectedRotationRadians: Double
    let assetSize: [CGFloat]
    let assetPivot: [CGFloat]
    let expectedPivotedCenter: [CGFloat]
}

private struct VisionFixture: Decodable {
    struct Sample: Decodable { let x: CGFloat; let y: CGFloat; let confidence: Float }
    struct Frame: Decodable {
        let timestamp: TimeInterval
        let sequence: UInt64
        let joints: [String: Sample]
        let dropped: [String]
    }
    let provenance: String
    let frames: [Frame]
}
