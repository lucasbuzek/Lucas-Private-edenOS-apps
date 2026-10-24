import XCTest
@testable import SWAYcoreKit

final class MatchingTests: XCTestCase {
    let wave = Stance(armL: Arm.side, armR: Arm.high, legL: Leg.wide, legR: Leg.wide)
    func testIdenticalPoseMatches() {
        let exp = PoseBuilder.build(wave)
        let r = Matcher.compare(expected: exp, observed: T.obs(wave, t: 1.0), now: 1.1)
        guard case .match(let e) = r else { return XCTFail("\(r)") }
        XCTAssertLessThan(e, 1)
    }
    func testWrongPoseIsNotMatchedNotUnknown() {
        let exp = PoseBuilder.build(wave)
        let wrong = Stance(armL: Arm.down, armR: Arm.down, legL: Leg.stand, legR: Leg.stand)
        guard case .notMatched = Matcher.compare(expected: exp, observed: T.obs(wrong, t: 1), now: 1.1) else { return XCTFail() }
    }
    func testMissingReferenceObservationAndStaleAreUnknown() {
        let exp = PoseBuilder.build(wave)
        XCTAssertEqual(Matcher.compare(expected: nil, observed: T.obs(wave, t: 1), now: 1), .unknown(.noReference))
        XCTAssertEqual(Matcher.compare(expected: exp, observed: nil, now: 1), .unknown(.noObservation))
        XCTAssertEqual(Matcher.compare(expected: exp, observed: T.obs(wave, t: 1), now: 2), .unknown(.stale))
    }
    func testLowConfidenceAndCoverageAreUnknown() {
        let exp = PoseBuilder.build(wave)
        let low = T.obs(wave, t: 1) { r in for k in r.keys { r[k]!.confidence = 0.1 } }
        XCTAssertEqual(Matcher.compare(expected: exp, observed: low, now: 1.1), .unknown(.lowConfidence))
        let partial = T.obs(wave, t: 1) { r in for j in [SWAYJoint.elbowL, .wristL, .elbowR, .wristR, .kneeL, .kneeR] { r[j]!.confidence = 0.1 } }
        XCTAssertEqual(Matcher.compare(expected: exp, observed: partial, now: 1.1), .unknown(.insufficientCoverage))
    }
    func testOutOfFrameIsUnknown() {
        let exp = PoseBuilder.build(wave)
        let o = T.obs(wave, t: 1) { r in r[.wristL]!.position.x = 2.0 }
        XCTAssertEqual(Matcher.compare(expected: exp, observed: o, now: 1.1), .unknown(.outOfFrame))
    }
    func testOnlyMatchEarnsCredit() {
        XCTAssertTrue(MatchResult.match(error: 1).earnsCredit)
        XCTAssertFalse(MatchResult.notMatched(error: 50).earnsCredit)
        XCTAssertFalse(MatchResult.unknown(.stale).earnsCredit)
    }
    func testScoreUnknownIsNeitherCreditNorPenalty() {
        var s = ScoreAccumulator()
        XCTAssertNil(s.accuracy); XCTAssertNil(s.stars)
        for _ in 0..<10 { s.record(.unknown(.stale)) }
        XCTAssertNil(s.accuracy); XCTAssertEqual(s.coverage, 0); XCTAssertNil(s.stars)
        for _ in 0..<9 { s.record(.match(error: 1)) }; s.record(.notMatched(error: 60))
        XCTAssertEqual(s.accuracy!, 0.9, accuracy: 1e-9); XCTAssertEqual(s.coverage, 0.5, accuracy: 1e-9); XCTAssertEqual(s.stars, 3)
    }
    func testMasteryNeverAdvancesWithoutEvidence() {
        XCTAssertEqual(MasteryRules.next(current: .learning, attempts: 9, accuracy: nil, coverage: 0), .learning)
        XCTAssertEqual(MasteryRules.next(current: .learning, attempts: 2, accuracy: 0.8, coverage: 0.9), .familiar)
        XCTAssertEqual(MasteryRules.next(current: .familiar, attempts: 4, accuracy: 0.95, coverage: 0.9), .mastered)
        XCTAssertEqual(MasteryRules.next(current: .learning, attempts: 9, accuracy: 0.99, coverage: 0.1), .learning)
    }
    func testTrackingLossFadeAndReacquisition() {
        var p = TrackingPresence()
        XCTAssertEqual(p.youConfidence(at: 0), 0); XCTAssertTrue(p.isLost(at: 0))
        p.observe(T.obs(.neutral, t: 1)); XCTAssertEqual(p.youConfidence(at: 1.2), 1); XCTAssertFalse(p.isLost(at: 1.2))
        XCTAssertTrue(p.isLost(at: 1.7)); let mid = p.youConfidence(at: 2.1)
        XCTAssertGreaterThan(mid, 0); XCTAssertLessThan(mid, 1)
        XCTAssertEqual(p.youConfidence(at: 5), 0)
        p.observe(T.obs(.neutral, t: 6)); XCTAssertEqual(p.youConfidence(at: 6.1), 1)   // reacquired
        p.observe(nil); p.observe(TrackingObservation(timestamp: 7, raw: [:])); XCTAssertEqual(p.lastGood, 6)  // junk never refreshes
    }
}

final class CalibrationTests: XCTestCase {
    static let n = Stance.neutral
    func feed(_ e: inout CalibrationEngine, frames: Int, t0: inout Double, _ make: (Int, Double) -> TrackingObservation?) {
        for i in 0..<frames { e.ingest(make(i, t0)); t0 += 1 / 30 }
    }
    func stand(_ t: Double) -> TrackingObservation { T.obs(Self.n, t: t) }

    func testStepsAreExactlyTheSixActionsThenReady() {
        XCTAssertEqual(CalibrationStep.allCases.map(\.prompt), ["STEP INTO VIEW", "WAVE LEFT", "WAVE RIGHT", "LIFT LEFT FOOT", "LIFT RIGHT FOOT", "JUMP", "READY TO SWAY"])
    }
    func testFullHappyPathReachesReady() {
        var e = CalibrationEngine(); var t = 0.0
        feed(&e, frames: 10, t0: &t) { _, tt in self.stand(tt) }
        XCTAssertEqual(e.state.step, .waveLeft)
        let offs: [Double] = [-0.08, -0.04, 0, 0.04, 0.08, 0.04, 0, -0.04]
        feed(&e, frames: 40, t0: &t) { i, tt in T.obs(Stance(armL: Arm.high, armR: Arm.down, legL: Leg.stand, legR: Leg.stand), t: tt) { r in r[.wristL]!.position.x += offs[i % 8] * 0.18 } }
        XCTAssertEqual(e.state.step, .waveRight)
        feed(&e, frames: 40, t0: &t) { i, tt in T.obs(Stance(armL: Arm.down, armR: Arm.high, legL: Leg.stand, legR: Leg.stand), t: tt) { r in r[.wristR]!.position.x += offs[i % 8] * 0.18 } }
        XCTAssertEqual(e.state.step, .liftLeftFoot)
        feed(&e, frames: 6, t0: &t) { _, tt in T.obs(Self.n, t: tt) { r in r[.ankleL]!.position.y += 0.25 * 0.18 } }
        XCTAssertEqual(e.state.step, .liftRightFoot)
        feed(&e, frames: 6, t0: &t) { _, tt in T.obs(Self.n, t: tt) { r in r[.ankleR]!.position.y += 0.25 * 0.18 } }
        XCTAssertEqual(e.state.step, .jump)
        feed(&e, frames: 4, t0: &t) { _, tt in T.obs(Self.n, t: tt) { r in for k in r.keys { r[k]!.position.y += 0.2 * 0.18 } } }
        XCTAssertFalse(e.state.isReady)           // peak alone is not a jump; must land
        feed(&e, frames: 3, t0: &t) { _, tt in self.stand(tt) }
        XCTAssertTrue(e.state.isReady); XCTAssertEqual(e.state.completed.count, 6)
    }
    func testOutOfFrameNeverAdvancesAndNilIsSafe() {
        var e = CalibrationEngine(); var t = 0.0
        feed(&e, frames: 30, t0: &t) { _, tt in T.obs(Self.n, t: tt) { r in r[.ankleL]!.confidence = 0.0 } }
        XCTAssertEqual(e.state.step, .stepIntoView); XCTAssertFalse(e.state.inView)
        feed(&e, frames: 30, t0: &t) { _, _ in nil }
        XCTAssertEqual(e.state.step, .stepIntoView)
    }
    func testStaticArmRaiseWithoutWavingDoesNotCountAsWave() {
        var e = CalibrationEngine(); var t = 0.0
        feed(&e, frames: 10, t0: &t) { _, tt in self.stand(tt) }
        feed(&e, frames: 80, t0: &t) { _, tt in T.obs(Stance(armL: Arm.high, armR: Arm.down, legL: Leg.stand, legR: Leg.stand), t: tt) }
        XCTAssertEqual(e.state.step, .waveLeft)
    }
    func testWrongFootDoesNotAdvance() {
        var e = CalibrationEngine(); var t = 0.0
        feed(&e, frames: 10, t0: &t) { _, tt in self.stand(tt) }
        e.reset(); feed(&e, frames: 10, t0: &t) { _, tt in self.stand(tt) }
        // jump straight to lift stage is impossible; verify lifting right foot early does nothing
        feed(&e, frames: 10, t0: &t) { _, tt in T.obs(Self.n, t: tt) { r in r[.ankleR]!.position.y += 0.25 * 0.18 } }
        XCTAssertEqual(e.state.step, .waveLeft)
    }
    func testTrackingLossKeepsCompletedStepsButDropsProgress() {
        var e = CalibrationEngine(); var t = 0.0
        feed(&e, frames: 10, t0: &t) { _, tt in self.stand(tt) }
        XCTAssertEqual(e.state.completed, [.stepIntoView])
        e.ingest(nil)
        XCTAssertEqual(e.state.completed, [.stepIntoView]); XCTAssertEqual(e.state.step, .waveLeft)
    }
}

final class SessionTests: XCTestCase {
    func readyState() -> CalibrationState { var s = CalibrationState(); s.step = .ready; return s }
    func testNothingRunsBeforeReady() {
        var s = SessionController(mode: .tracking)
        s.begin(); XCTAssertEqual(s.phase, .requestingPermission)
        s.tick(now: 100); XCTAssertEqual(s.workoutTime(now: 100), 0); XCTAssertNil(s.countdownRemaining(now: 100))
        s.record(.match(error: 0)); XCTAssertEqual(s.score.matched, 0)
        s.permissionResolved(granted: true, now: 1); s.bodyAcquired(); XCTAssertEqual(s.phase, .calibrating)
        s.startCountdown(now: 2); XCTAssertEqual(s.phase, .calibrating)           // cannot skip calibration
        s.calibrationFinished(CalibrationState()); XCTAssertEqual(s.phase, .calibrating)
    }
    func testLifecycleCountdownRunPauseResume() {
        var s = SessionController(mode: .tracking, countdownSeconds: 3)
        s.begin(); s.permissionResolved(granted: true, now: 0); s.bodyAcquired(); s.calibrationFinished(readyState())
        XCTAssertEqual(s.phase, .ready)
        s.startCountdown(now: 10); XCTAssertEqual(s.countdownRemaining(now: 11)!, 2, accuracy: 1e-9)
        s.tick(now: 12.9); XCTAssertEqual(s.phase, .countdown); XCTAssertEqual(s.workoutTime(now: 12.9), 0)
        s.tick(now: 13); XCTAssertEqual(s.phase, .running)
        XCTAssertEqual(s.workoutTime(now: 15), 2, accuracy: 1e-9)
        s.pause(now: 15); XCTAssertEqual(s.workoutTime(now: 99), 2, accuracy: 1e-9)
        s.record(.match(error: 0)); XCTAssertEqual(s.score.matched, 0)                 // no credit while paused
        s.resume(now: 100); XCTAssertEqual(s.workoutTime(now: 101), 3, accuracy: 1e-9)
        s.record(.match(error: 0)); XCTAssertEqual(s.score.matched, 1)
        s.end(now: 102); XCTAssertEqual(s.phase, .ended); XCTAssertEqual(s.workoutTime(now: 500), 4, accuracy: 1e-9)
    }
    func testPermissionDeniedReturnsToIdleWithoutRunning() {
        var s = SessionController(mode: .tracking); s.begin(); s.permissionResolved(granted: false, now: 0)
        XCTAssertEqual(s.phase, .idle)
    }
    func testFollowAlongSkipsCalibrationButNeverScores() {
        var s = SessionController(mode: .followAlong, countdownSeconds: 1)
        s.begin(); XCTAssertEqual(s.phase, .ready); s.startCountdown(now: 5); s.tick(now: 6)
        XCTAssertEqual(s.phase, .running); s.record(.match(error: 0)); XCTAssertEqual(s.score.judged, 0)
        XCTAssertFalse(s.scoringEnabled)
    }
}
