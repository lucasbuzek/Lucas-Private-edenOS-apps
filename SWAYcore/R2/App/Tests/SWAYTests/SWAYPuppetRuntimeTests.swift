import XCTest
import Vision
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
}
