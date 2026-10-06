import XCTest
import SWAYcoreEngine
@testable import SWAY

/// Application-level smoke tests (host app). Simulator evidence at best; camera/Vision/MusicKit/HealthKit need a physical device.
@MainActor final class SWAYSmokeTests: XCTestCase {
    func testStoreBootsWithAuthoredLibrary() {
        let store = SwayStore()
        XCTAssertGreaterThanOrEqual(store.moves.count, 20)
        XCTAssertEqual(Set(store.moves.map(\.id)).count, store.moves.count, "move ids must be unique")
    }
    func testEveryAuthoredMoveHasACompleteCoachPose() {
        let store = SwayStore()
        let authored = store.moves.map(\.id).filter { SwayCoachPoseEngine.supports(moveID: $0) }
        XCTAssertGreaterThanOrEqual(authored.count, 20, "20 authored COACH moves are a protected capability")
        for id in authored {
            XCTAssertNotNil(SwayReferencePoseCatalog.referenceIfAvailable(moveID: id, musicalTime: 1.0, bpm: 100), id)
        }
    }
    func testTimelineEngineRunsPausesAndResumesWithoutDrift() async {
        let t = SwayTimelineEngine()
        t.start(bpm: 120)
        try? await Task.sleep(nanoseconds: 300_000_000)
        t.pause(); let frozen = t.elapsed
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(t.elapsed, frozen, accuracy: 0.001, "paused timeline must not advance")
        t.resume(); try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertGreaterThan(t.elapsed, frozen); t.stop(reset: true)
    }
    func testLearnTempoFloorIs20() {
        let a = SwayCoachPoseEngine.pose(moveID: "march", musicalTime: 0.5, bpm: 20)
        let b = SwayCoachPoseEngine.pose(moveID: "march", musicalTime: 0.5, bpm: 40)
        XCTAssertNotEqual(a.leftKnee.y, b.leftKnee.y, "20 BPM must not be clamped to 40 BPM (defect D-005)")
    }
    func testScoringEngineNeverCreditsMissingEvidence() {
        let s = SwayScoringEngine()
        let ref = SwayReferencePose(moveID: "march", count: 1, jointAngles: ["leftElbow": 90, "rightElbow": 90, "leftKnee": 160, "rightKnee": 160, "leftHip": 170, "rightHip": 170])
        s.ingest(reference: ref, observed: [:], timingError: 0, confidence: 0.9)
        XCTAssertEqual(s.latest?.state, .unknown); XCTAssertEqual(s.combo, 0)
        s.ingest(reference: ref, observed: ["leftElbow": 90], timingError: 0, confidence: 0.9)
        XCTAssertEqual(s.latest?.state, .unknown, "one joint of six is not enough evidence (D-002)")
    }
    func testSwayPackValidationRejectsMalformedPackages() {
        func pkg(format: String = "swaypack", version: Int = 2, moves: [DanceMove] = []) -> SwayPackage { SwayPackage(format: format, version: version, creator: "t", moves: moves, transitions: []) }
        XCTAssertThrowsError(try pkg(format: "other").validate())
        XCTAssertThrowsError(try pkg(version: 0).validate())
        XCTAssertThrowsError(try pkg(version: 3).validate())
        XCTAssertNoThrow(try pkg(version: 1).validate()); XCTAssertNoThrow(try pkg(version: 2).validate())
        let m = SwayStore().moves[0]
        XCTAssertThrowsError(try pkg(moves: [m, m]).validate(), "duplicate ids must be rejected")
        XCTAssertThrowsError(try JSONDecoder().decode(SwayPackage.self, from: Data("not json".utf8)))
    }
}
