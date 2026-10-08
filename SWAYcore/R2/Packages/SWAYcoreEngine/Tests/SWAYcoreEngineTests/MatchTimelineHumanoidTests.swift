import XCTest
@testable import SWAYcoreEngine

final class MusicalClockTests: XCTestCase {
    func testPauseResumeHasNoWallClockDrift() {
        var clock = SwayMusicalClock(musicalTime: 4.25, hostTime: 10)
        XCTAssertEqual(clock.sample(hostTime: 11.5), 5.75, accuracy: 0.000_001)
        clock.pause(hostTime: 12)
        let frozenBeat = clock.musicalTime
        XCTAssertEqual(clock.sample(hostTime: 3_612), frozenBeat, accuracy: 0.000_001)
        clock.resume(hostTime: 4_000)
        XCTAssertEqual(clock.sample(hostTime: 4_000.5), frozenBeat + 0.5, accuracy: 0.000_001)
    }
}

final class WorkoutTimelineTests: XCTestCase {
    func testCompletionRequiresTimelineDurationAndPhraseBoundary() {
        XCTAssertEqual(SwayWorkoutTimeline.activeSeconds(start: 120, current: 179.5), 59.5)
        XCTAssertFalse(SwayWorkoutTimeline.isComplete(start: 120, current: 181, duration: 60, completedPhrase: false))
        XCTAssertTrue(SwayWorkoutTimeline.isComplete(start: 120, current: 181, duration: 60, completedPhrase: true))
    }
}

final class CorruptSaveRecoveryTests: XCTestCase {
    private struct Fixture: Codable, Equatable { let name: String; let count: Int }

    func testTruncatedJSONIsBackedUpAndDefaultsCanContinue() {
        do { try runTruncatedJSONCase() } catch { XCTFail("unexpected error: \(error)") }
    }

    private func runTruncatedJSONCase() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("profile.json")
        let truncated = Data("{\"name\":\"dancer\",\"count\":".utf8)
        try truncated.write(to: url)

        guard case let .corrupt(backupURL) = SwayCorruptSaveRecovery.load(Fixture.self, from: url) else {
            return XCTFail("truncated fixture was not classified as corrupt")
        }
        XCTAssertEqual(try Data(contentsOf: backupURL), truncated)
        XCTAssertTrue(backupURL.lastPathComponent.hasPrefix("profile.json.corrupt"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        let defaults = Fixture(name: "default", count: 0)
        XCTAssertEqual(defaults, Fixture(name: "default", count: 0))
    }
}

final class MatchTruthTests: XCTestCase {
    let ref: [String: Double] = ["leftElbow": 90, "rightElbow": 90, "leftKnee": 160, "rightKnee": 160]
    func s(_ obs: [String: Double], timing: Double = 0, conf: Double = 0.9, prev: Double? = nil, age: TimeInterval? = nil) -> SwayMatchResult {
        SwayMatchTruth.score(referenceAngles: ref, observedAngles: obs, timingError: timing, detectorConfidence: conf, previousTotal: prev, observationAge: age)
    }
    /// D-001: as received, zero overlapping joints scored PARTIAL.
    func testZeroOverlapIsUnknownNotPartial() { XCTAssertEqual(s(["other": 1]).outcome, .unknown(.insufficientJointCoverage)) }
    /// D-002: as received, one joint of four scored GOOD.
    func testSingleJointIsNotEnough() { XCTAssertEqual(s(["leftElbow": 90]).outcome, .unknown(.insufficientJointCoverage)) }
    func testPerfectIsGoodAndEarnsCredit() { let r = s(ref); XCTAssertEqual(r.outcome, .good); XCTAssertTrue(r.outcome.earnsCredit); XCTAssertEqual(r.comparableJoints, 4) }
    func testPoorWithEvidenceIsNotMatchedAndEarnsNothing() {
        let r = s(["leftElbow": 10, "rightElbow": 170, "leftKnee": 20, "rightKnee": 30], timing: 0.3)
        XCTAssertEqual(r.outcome, .notMatched); XCTAssertFalse(r.outcome.earnsCredit); XCTAssertFalse(r.outcome.isUnknown)
    }
    func testUnknownReasons() {
        XCTAssertEqual(s(ref, age: 0.5).outcome, .unknown(.staleObservation))
        XCTAssertEqual(s(ref, age: -0.1).outcome, .unknown(.staleObservation))
        XCTAssertEqual(s(ref, conf: 0.1).outcome, .unknown(.lowDetectorConfidence))
        XCTAssertEqual(s(ref, conf: .nan).outcome, .unknown(.lowDetectorConfidence))
        XCTAssertEqual(SwayMatchTruth.score(referenceAngles: [:], observedAngles: ref, timingError: 0, detectorConfidence: 0.9, previousTotal: nil).outcome, .unknown(.noReference))
        XCTAssertEqual(s([:]).outcome, .unknown(.noObservation))
        XCTAssertFalse(s(ref, conf: 0.1).outcome.earnsCredit)
    }
    func testDeterministic() { let o = ["leftElbow": 80.0, "rightElbow": 95, "leftKnee": 150, "rightKnee": 170]; XCTAssertEqual(s(o, timing: 0.05, conf: 0.8, prev: 0.6), s(o, timing: 0.05, conf: 0.8, prev: 0.6)) }
    func testLegacyWeightsPreserved() {
        let r = s(ref, conf: 1.0)       // shape 1, timing 1, continuity 1 → total 1.0
        XCTAssertEqual(r.total, 1.0, accuracy: 1e-12)
        let half = s(["leftElbow": 135, "rightElbow": 135, "leftKnee": 115, "rightKnee": 115], conf: 1.0)    // mean error 45° → shape 0.5
        XCTAssertEqual(half.total, 0.35 + 0.35 * 0.5 + 0.30 * 1.0, accuracy: 1e-12)
    }
}

final class TimelineMathTests: XCTestCase {
    func testTwentyBPMFloorHonoured() {
        let p = SwayTimelineMath.position(time: 3.0, bpm: 20); XCTAssertEqual(p.beat, 1); XCTAssertEqual(p.count, 2)   // 3 s/beat
        XCTAssertEqual(SwayTimelineMath.position(time: 3.0, bpm: 10).beat, 1)                                           // clamp to 20, not 40 (D-005)
        XCTAssertEqual(SwayTimelineMath.secondsPerBeat(bpm: 20), 3.0, accuracy: 1e-12)
    }
    func testCountBarPhrase() {
        let p = SwayTimelineMath.position(time: 60.0 / 120.0 * 40, bpm: 120)
        XCTAssertEqual([p.beat, p.count, p.bar, p.phrase], [40, 1, 10, 1])
        XCTAssertEqual(SwayTimelineMath.position(time: 0, bpm: 100).count, 1)
        XCTAssertEqual(SwayTimelineMath.position(time: 60.0 / 100.0 * 7, bpm: 100).count, 8)
    }
    func testGridMapping() {
        let g: [TimeInterval] = [0, 0.5, 1.0, 1.6, 2.2]
        XCTAssertEqual(SwayTimelineMath.position(time: 1.2, bpm: 120, gridBeats: g, gridBPM: 100).beat, 2)
        XCTAssertEqual(SwayTimelineMath.position(time: -1, bpm: 120, gridBeats: g).beat, 0)
        let late = SwayTimelineMath.position(time: 5.0, bpm: 120, gridBeats: g, gridBPM: 100)
        XCTAssertEqual(late.beat, 4); XCTAssertLessThan(late.beatPhase, 1.0)
    }
    func testMonotonicAndDeterministic() {
        var last = -1
        for i in 0..<2000 { let b = SwayTimelineMath.position(time: Double(i) * 0.01, bpm: 97).beat; XCTAssertGreaterThanOrEqual(b, last); last = b }
        XCTAssertEqual(SwayTimelineMath.position(time: 12.34, bpm: 97), SwayTimelineMath.position(time: 12.34, bpm: 97))
    }
    func testPauseResumeIsTimeDerivedNotAccumulated() {
        // Same musical time always yields the same position regardless of how it was reached.
        XCTAssertEqual(SwayTimelineMath.position(time: 4.0, bpm: 90), SwayTimelineMath.position(time: 4.0, bpm: 90))
    }
}

final class HumanoidContractTests: XCTestCase {
    func testContractHas23UniqueJointsAndValidHierarchy() {
        XCTAssertEqual(SwayHumanoidV1.joints.count, 23); XCTAssertEqual(Set(SwayHumanoidV1.joints).count, 23)
        XCTAssertTrue(SwayHumanoidV1.isValidHierarchy()); XCTAssertEqual(SwayHumanoidV1.requiredAnimations.count, 10)
    }
    func testValidation() {
        XCTAssertEqual(SwayHumanoidV1.validate(joints: SwayHumanoidV1.joints, clips: SwayHumanoidV1.requiredAnimations), [])
        XCTAssertFalse(SwayHumanoidV1.validate(joints: Array(SwayHumanoidV1.joints.dropLast()), clips: SwayHumanoidV1.requiredAnimations).isEmpty)
        XCTAssertFalse(SwayHumanoidV1.validate(joints: SwayHumanoidV1.joints + ["Hips"], clips: SwayHumanoidV1.requiredAnimations).isEmpty)
        XCTAssertFalse(SwayHumanoidV1.validate(joints: SwayHumanoidV1.joints + ["Tail"], clips: SwayHumanoidV1.requiredAnimations).isEmpty)
        XCTAssertFalse(SwayHumanoidV1.validate(joints: SwayHumanoidV1.joints, clips: ["sway_idle_v1"]).isEmpty)
    }
    func visionPose() -> [String: (point: SwayPoint, confidence: Double)] {
        func p(_ x: Double, _ y: Double, _ c: Double = 0.9) -> (point: SwayPoint, confidence: Double) { (SwayPoint(x: x, y: y), c) }
        return ["root": p(0.5, 0.55), "neck": p(0.5, 0.25), "nose": p(0.5, 0.15),
                "leftShoulder": p(0.4, 0.28), "rightShoulder": p(0.6, 0.28), "leftElbow": p(0.35, 0.42), "rightElbow": p(0.65, 0.42),
                "leftWrist": p(0.33, 0.55), "rightWrist": p(0.67, 0.55), "leftHip": p(0.45, 0.55), "rightHip": p(0.55, 0.55),
                "leftKnee": p(0.44, 0.72), "rightKnee": p(0.56, 0.72), "leftAnkle": p(0.43, 0.90), "rightAnkle": p(0.57, 0.90)]
    }
    func testMappingProducesOnlyContractJointsAndOmitsToes() {
        let m = SwayPoseMapper.map(visionPose())
        XCTAssertTrue(Set(m.keys).isSubset(of: Set(SwayHumanoidV1.joints)))
        XCTAssertNil(m["LeftToe"]); XCTAssertNil(m["RightToe"])                       // never invented
        XCTAssertEqual(m.count, 21)                                                   // 23 minus the two unobservable toes
        XCTAssertEqual(m["LeftHand"]?.point, SwayPoint(x: 0.33, y: 0.55)); XCTAssertEqual(m["LeftHand"]?.derived, false)
        XCTAssertEqual(m["Chest"]?.derived, true); XCTAssertEqual(m["Head"]?.derived, true)
    }
    func testLowConfidenceJointsAreDroppedAndDerivedJointsNeedBothParents() {
        var v = visionPose(); v["leftWrist"] = (SwayPoint(x: 0.33, y: 0.55), 0.1); v["neck"] = (SwayPoint(x: 0.5, y: 0.25), 0.1)
        let m = SwayPoseMapper.map(v)
        XCTAssertNil(m["LeftHand"]); XCTAssertNil(m["Neck"]); XCTAssertNil(m["Spine"]); XCTAssertNil(m["LeftShoulder"])
        XCTAssertNotNil(m["Hips"]); XCTAssertNotNil(m["LeftLowerArm"])
    }
    func testLeftIsSubjectLeftAndMappingIsDeterministic() {
        let m = SwayPoseMapper.map(visionPose()); XCTAssertEqual(m["LeftUpperArm"]?.point.x, 0.4); XCTAssertEqual(m["RightUpperArm"]?.point.x, 0.6)
        XCTAssertEqual(SwayPoseMapper.map(visionPose()), m)
    }
}
