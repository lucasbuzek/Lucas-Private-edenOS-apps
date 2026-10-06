import XCTest
@testable import SWAYcoreEngine

final class CalibrationMachineTests: XCTestCase {
    // Display coordinates: y grows downward. Standing: root .55, ankles .90, wrists .55.
    func frame(_ t: Double, ready: Bool = true, present: Bool = true, root: Double? = 0.55,
               lw: SwayPoint? = SwayPoint(x: 0.35, y: 0.55), rw: SwayPoint? = SwayPoint(x: 0.65, y: 0.55),
               la: SwayPoint? = SwayPoint(x: 0.45, y: 0.90), ra: SwayPoint? = SwayPoint(x: 0.55, y: 0.90)) -> SwayCalibrationFrame {
        SwayCalibrationFrame(timestamp: t, bodyPresent: present, scoringReady: ready, root: root.map { SwayPoint(x: 0.5, y: $0) },
                             leftWrist: lw, rightWrist: rw, leftAnkle: la, rightAnkle: ra)
    }
    func pump(_ m: inout SwayCalibrationMachine, _ n: Int, _ make: (Double, Int) -> SwayCalibrationFrame) -> [SwayCalibrationEvent] {
        var ev: [SwayCalibrationEvent] = []
        for i in 0..<n { ev += m.ingest(make(Double(i) / 30 + clock, i)) }
        clock += Double(n) / 30; return ev
    }
    var clock = 0.0
    func wave(_ x0: Double, _ i: Int) -> SwayPoint { SwayPoint(x: x0 + (i % 2 == 0 ? 0.03 : -0.03), y: 0.40) }   // 0.06 per frame

    func testStagesAreExactlyTheCanonicalSequenceAndTitles() {
        XCTAssertEqual(SwayCalibrationStage.allCases.map(\.title),
                       ["STEP INTO VIEW", "WAVE LEFT", "WAVE RIGHT", "LIFT LEFT FOOT", "LIFT RIGHT FOOT", "JUMP", "READY TO SWAY"])
    }

    func testHappyPathProgressesInOrderToReady() {
        var m = SwayCalibrationMachine(); var all: [SwayCalibrationEvent] = []
        all += pump(&m, 8) { t, _ in frame(t) }; XCTAssertEqual(m.stage, .waveLeft)
        all += pump(&m, 30) { t, i in frame(t, lw: wave(0.35, i)) }; XCTAssertEqual(m.stage, .waveRight)
        all += pump(&m, 30) { t, i in frame(t, rw: wave(0.65, i)) }; XCTAssertEqual(m.stage, .liftLeft)
        all += pump(&m, 6) { t, _ in frame(t, la: SwayPoint(x: 0.45, y: 0.80)) }; XCTAssertEqual(m.stage, .liftRight)
        all += pump(&m, 6) { t, _ in frame(t, ra: SwayPoint(x: 0.55, y: 0.80)) }; XCTAssertEqual(m.stage, .jump)
        all += pump(&m, 4) { t, _ in frame(t, root: 0.45) }
        XCTAssertTrue(m.isReady); XCTAssertEqual(m.status, "READY TO SWAY")
        XCTAssertEqual(m.completed, [.frame, .waveLeft, .waveRight, .liftLeft, .liftRight, .jump])
        XCTAssertEqual(all.filter { $0 == .ready }.count, 1)
    }

    func advanceTo(_ target: SwayCalibrationStage) -> SwayCalibrationMachine {
        var s = self; var m = SwayCalibrationMachine()
        _ = s.pump(&m, 8) { t, _ in frame(t) }
        if target == .waveLeft { return m }
        _ = s.pump(&m, 30) { t, i in frame(t, lw: wave(0.35, i)) }; if target == .waveRight { return m }
        _ = s.pump(&m, 30) { t, i in frame(t, rw: wave(0.65, i)) }; if target == .liftLeft { return m }
        _ = s.pump(&m, 6) { t, _ in frame(t, la: SwayPoint(x: 0.45, y: 0.80)) }; if target == .liftRight { return m }
        _ = s.pump(&m, 6) { t, _ in frame(t, ra: SwayPoint(x: 0.55, y: 0.80)) }
        return m
    }

    func testWrongGestureDoesNotAdvance() {
        var s = self
        var m = advanceTo(.waveLeft)                                       // expects LEFT wave
        _ = s.pump(&m, 40) { t, i in frame(t, rw: wave(0.65, i)) }         // waving the RIGHT hand
        XCTAssertEqual(m.stage, .waveLeft)
        _ = s.pump(&m, 20) { t, _ in frame(t, la: SwayPoint(x: 0.45, y: 0.80)) }   // lifting a foot
        XCTAssertEqual(m.stage, .waveLeft)
        var m2 = advanceTo(.liftLeft)
        _ = s.pump(&m2, 20) { t, _ in frame(t, ra: SwayPoint(x: 0.55, y: 0.80)) }  // lifts RIGHT foot at LIFT LEFT
        XCTAssertEqual(m2.stage, .liftLeft)
    }

    func testRepeatedGestureDoesNotSkipStages() {
        var s = self; var m = advanceTo(.waveLeft)
        _ = s.pump(&m, 120) { t, i in frame(t, lw: wave(0.35, i)) }        // keep waving LEFT long after completion
        XCTAssertEqual(m.stage, .waveRight)                                 // advanced exactly one stage
        XCTAssertEqual(m.completed, [.frame, .waveLeft])
    }

    func testSensorJitterNeverCountsAsAWave() {
        var s = self; var m = advanceTo(.waveLeft)
        _ = s.pump(&m, 900) { t, i in frame(t, lw: SwayPoint(x: 0.35 + (i % 2 == 0 ? 0.0015 : -0.0015), y: 0.55)) }   // 30 s of jitter
        XCTAssertEqual(m.stage, .waveLeft)
    }

    func testMissingLimbAndLowConfidenceBlockProgress() {
        var s = self; var m = advanceTo(.waveLeft)
        _ = s.pump(&m, 60) { t, i in frame(t, lw: nil) }                    // left wrist unobserved
        XCTAssertEqual(m.stage, .waveLeft); XCTAssertEqual(m.status, "SHOW YOUR LEFT HAND")
        var f = SwayCalibrationMachine()
        _ = s.pump(&f, 60) { t, _ in frame(t, ready: false) }               // body present but not scoring-ready (low confidence/cropped)
        XCTAssertEqual(f.stage, .frame); XCTAssertEqual(f.status, "STEP BACK — SHOW YOUR FEET")
        var l = advanceTo(.liftLeft)
        _ = s.pump(&l, 30) { t, _ in frame(t, la: nil) }
        XCTAssertEqual(l.stage, .liftLeft); XCTAssertEqual(l.status, "SHOW BOTH FEET")
    }

    func testTrackingLossDiscardsProgressAndRecoveryResumes() {
        var s = self; var m = advanceTo(.liftLeft)
        _ = s.pump(&m, 3) { t, _ in frame(t, la: SwayPoint(x: 0.45, y: 0.80)) }      // 3 of 4 stable frames
        let lost = s.pump(&m, 5) { t, _ in frame(t, present: false, root: nil, lw: nil, rw: nil, la: nil, ra: nil) }
        XCTAssertTrue(lost.contains(.trackingLost)); XCTAssertTrue(m.trackingLost); XCTAssertEqual(m.status, "STEP INTO VIEW")
        let rec = s.pump(&m, 1) { t, _ in frame(t, la: SwayPoint(x: 0.45, y: 0.80)) }
        XCTAssertTrue(rec.contains(.trackingRecovered)); XCTAssertEqual(m.stage, .liftLeft)   // 1 frame is not enough: progress was discarded
        _ = s.pump(&m, 3) { t, _ in frame(t, la: SwayPoint(x: 0.45, y: 0.80)) }
        XCTAssertEqual(m.stage, .liftRight)
        XCTAssertEqual(m.completed, [.frame, .waveLeft, .waveRight, .liftLeft])      // completed stages survive loss
    }

    func testUserLeavingFrameDuringFramingNeverCompletes() {
        var s = self; var m = SwayCalibrationMachine()
        _ = s.pump(&m, 5) { t, _ in frame(t) }
        _ = s.pump(&m, 40) { t, _ in frame(t, present: false, root: nil, lw: nil, rw: nil, la: nil, ra: nil) }
        _ = s.pump(&m, 5) { t, _ in frame(t) }
        XCTAssertEqual(m.stage, .frame)                                              // 5 + 5 frames never accumulate to 6
    }

    func testTimeoutIsReportedOnceAndContinuable() {
        var m = SwayCalibrationMachine(); var ev: [SwayCalibrationEvent] = []
        for i in 0..<(70 * 30) { ev += m.ingest(frame(Double(i) / 30, ready: false)) }
        XCTAssertEqual(ev.filter { $0 == .timedOut(.frame) }.count, 1); XCTAssertTrue(m.timedOut)
        m.continueAfterTimeout(); XCTAssertFalse(m.timedOut)
    }

    func testCancelIsTerminalAndSilent() {
        var s = self; var m = advanceTo(.waveRight)
        XCTAssertEqual(m.cancel(), [.cancelled]); XCTAssertTrue(m.cancelled)
        let ev = s.pump(&m, 40) { t, i in frame(t, rw: wave(0.65, i)) }
        XCTAssertTrue(ev.isEmpty); XCTAssertEqual(m.stage, .waveRight); XCTAssertEqual(m.cancel(), [])
    }

    func testOrientationChangeInvalidatesJumpBaseline() {
        var s = self; var m = advanceTo(.liftRight)
        _ = s.pump(&m, 6) { t, _ in frame(t, ra: SwayPoint(x: 0.55, y: 0.80)) }; XCTAssertEqual(m.stage, .jump)
        m.geometryChanged()
        _ = s.pump(&m, 6) { t, _ in frame(t, root: 0.30) }                           // geometry now different; no baseline yet
        XCTAssertEqual(m.stage, .jump)
        _ = s.pump(&m, 12) { t, _ in frame(t, root: 0.30) }                          // new calm baseline
        _ = s.pump(&m, 4) { t, _ in frame(t, root: 0.24) }                           // real jump relative to new baseline
        XCTAssertTrue(m.isReady)
    }

    func testStepBackwardsDriftIsNotAJump() {
        var s = self; var m = advanceTo(.liftRight)
        _ = s.pump(&m, 6) { t, _ in frame(t, ra: SwayPoint(x: 0.55, y: 0.80)) }; XCTAssertEqual(m.stage, .jump)
        _ = s.pump(&m, 200) { t, i in frame(t, root: 0.55 - Double(i) * 0.0005) }    // slow drift upward in image (user steps away), 0.1 total
        XCTAssertEqual(m.stage, .jump)
    }

    func testSkipJumpOnlyAtJumpStep() {
        var s = self; var m = advanceTo(.waveLeft)
        XCTAssertEqual(m.skipJump(), []); XCTAssertEqual(m.stage, .waveLeft)
        var j = advanceTo(.liftRight); _ = s.pump(&j, 6) { t, _ in frame(t, ra: SwayPoint(x: 0.55, y: 0.80)) }
        let ev = j.skipJump(); XCTAssertTrue(ev.contains(.ready)); XCTAssertTrue(j.lowImpact); XCTAssertTrue(j.isReady)
    }

    func testDeterministicReplay() {
        func run() -> [SwayCalibrationStage] {
            var s = self; var m = SwayCalibrationMachine()
            _ = s.pump(&m, 8) { t, _ in frame(t) }; _ = s.pump(&m, 30) { t, i in frame(t, lw: wave(0.35, i)) }
            return m.completed
        }
        XCTAssertEqual(run(), run())
    }
}
