import XCTest
@testable import SWAYcoreKit

final class AuthoringTests: XCTestCase {
    func draft() throws -> MoveDraft {
        var d = MoveDraft(id: "authored", name: "My Move", instruction: "Do it")
        try d.set(count: 1, stance: .neutral)
        try d.set(count: 3, stance: Stance(armL: Arm.high, armR: Arm.high, legL: Leg.wide, legR: Leg.wide))
        try d.set(count: 5, stance: Stance(armL: Arm.side, armR: Arm.side, legL: Leg.stand, legR: Leg.stand))
        d.setHold(count: 5, true); d.setCue(count: 3, "Reach!")
        return d
    }
    /// SWAYZ acceptance fixture: author -> save -> export -> import -> learner runtime sees identical counts/poses/timing.
    func testAuthorExportImportConsumeIdentical() throws {
        let m = try draft().build()
        XCTAssertEqual(m.keyframes.map(\.count), [1, 3, 5]); XCTAssertEqual(m.keyframes[1].cue, "Reach!"); XCTAssertTrue(m.keyframes[2].hold)
        var ch = ChoreographyDraft(id: "ch", name: "Routine"); ch.grid = MusicGrid(bpm: 100)
        ch.append("authored", repetitions: 2); ch.append("sway_march_v1", mirrored: true)
        var lib = MoveLibrary.byID; lib[m.id] = m
        let pack = try ch.pack(movements: lib, author: "Instructor")
        let imported = try SwayPack.import(try pack.export())
        let rt = Dictionary(uniqueKeysWithValues: imported.movements.map { ($0.id, $0) })
        let tl1 = ChoreographyTimeline(steps: ch.steps, movements: lib), tl2 = ChoreographyTimeline(steps: imported.combinations[0].steps, movements: rt)
        XCTAssertEqual(tl1.totalBeats, tl2.totalBeats); XCTAssertEqual(tl1.segments.map(\.movementID), tl2.segments.map(\.movementID))
        for beat in stride(from: 0.0, to: Double(tl1.totalBeats), by: 0.5) {
            let a = tl1.segment(atBeat: beat)!, b = tl2.segment(atBeat: beat)!
            XCTAssertEqual(lib[a.0.movementID]!.pose(atBeat: a.localBeat, mirrored: a.0.mirrored), rt[b.0.movementID]!.pose(atBeat: b.localBeat, mirrored: b.0.mirrored), "beat \(beat)")
        }
        XCTAssertEqual(imported.musicReferences.first?.grid, ch.grid)
    }
    func testDraftValidationAndEditing() throws {
        var d = MoveDraft(name: "x")
        XCTAssertThrowsError(try d.build())
        XCTAssertThrowsError(try d.set(count: 0, stance: .neutral)); XCTAssertThrowsError(try d.set(count: 9, stance: .neutral))
        XCTAssertThrowsError(try d.set(count: 1, capturedPose: Pose()))
        let built = try draft().build(); var e = MoveDraft(editing: built)
        XCTAssertEqual(e.revision, built.revision + 1); e.clear(count: 3)
        XCTAssertEqual(try e.build().keyframes.map(\.count), [1, 5])
        XCTAssertEqual(try MoveDraft(editing: built).build().keyframes, built.keyframes)
    }
    func testChoreographyReorderAndCues() throws {
        var ch = ChoreographyDraft(name: "c"); ch.append("a"); ch.append("b"); ch.append("c"); ch.move(from: 2, to: 0)
        XCTAssertEqual(ch.steps.map(\.movementID), ["c", "a", "b"]); ch.remove(at: 1); XCTAssertEqual(ch.steps.map(\.movementID), ["c", "b"])
        let m = try draft().build(); var c2 = ChoreographyDraft(name: "q"); c2.append(m.id, repetitions: 2)
        XCTAssertEqual(c2.cues(movements: [m.id: m]).map(\.beat), [2, 10])
    }
    func testCreateMoveFromCapturedPoses() throws {
        let a = PoseBuilder.build(.neutral), b = PoseBuilder.build(Stance(armL: Arm.high, armR: Arm.high, legL: Leg.stand, legR: Leg.stand))
        // simulate Vision-limited poses: drop structural joints
        func visionLike(_ p: Pose) -> Pose { var q = p; for j in [SWAYJoint.root, .spine, .chest, .headEnd, .handL, .handR, .toesL, .toesR] { q[j] = nil }; return q }
        let m = try PoseCapture.movement(id: "cap", name: "Captured", poses: [visionLike(a), visionLike(b)])
        try m.validate(); XCTAssertEqual(m.keyframes.count, 8)
        XCTAssertThrowsError(try PoseCapture.movement(id: "x", name: "x", poses: [a])) { XCTAssertEqual($0 as? PoseCapture.CaptureError, .tooFewPoses) }
        var broken = visionLike(a); broken[.kneeL] = nil; broken[.hips] = nil
        XCTAssertThrowsError(try PoseCapture.movement(id: "x", name: "x", poses: [broken, broken]))
    }
}

final class PoseCompleterTests: XCTestCase {
    func testCompletionAndFallbackOnlyForDisplay() {
        var v = PoseBuilder.build(.neutral); for j in [SWAYJoint.spine, .chest, .root, .headEnd, .handL, .toesR] { v[j] = nil }
        let c = PoseCompleter.complete(v); XCTAssertTrue(SWAYJoint.allCases.allSatisfy { c[$0] != nil })
        var partial = v; partial[.kneeL] = nil
        XCTAssertNil(PoseCompleter.complete(partial)[.kneeL])
        XCTAssertNotNil(PoseCompleter.complete(partial, fallback: PoseBuilder.build(.neutral))[.kneeL])
        let sm = PoseCompleter.smooth(PoseBuilder.build(Stance(armL: Arm.high, armR: Arm.down, legL: Leg.stand, legR: Leg.stand)), previous: PoseBuilder.build(.neutral), alpha: 0.5)
        let a = PoseBuilder.build(.neutral).position(.wristL)!.y, b = PoseBuilder.build(Stance(armL: Arm.high, armR: Arm.down, legL: Leg.stand, legR: Leg.stand)).position(.wristL)!.y
        XCTAssertEqual(sm.position(.wristL)!.y, (a + b) / 2, accuracy: 1e-9)
    }
}

final class BeatsAndKidsTests: XCTestCase {
    func testTapTempo() {
        var t = TapTempo(); XCTAssertNil(t.bpm)
        for i in 0..<6 { t.tap(at: Double(i) * 0.5) }
        XCTAssertEqual(t.bpm!, 120, accuracy: 0.01); XCTAssertNotNil(t.grid)
        t.tap(at: 100); XCTAssertNil(t.bpm)       // long pause restarts
    }
    func testBeatPatternsCoverRecoveredStylesAndAreValid() {
        XCTAssertEqual(BeatPattern.all.map(\.name), ["Simple", "Pop", "House", "Hip-Hop", "Disco", "Latin", "Afro", "Percussion", "Rock", "Minimal"])
        XCTAssertTrue(BeatPattern.all.allSatisfy { $0.isValid() })
        XCTAssertEqual(BeatPattern.all[0].grid(start: 2).beat(at: 2 + 60 / 100.0), 1, accuracy: 1e-9)
    }
    func testPlaylistOrdering() {
        let ids = ["a", "b", "c", "d", "e"]
        XCTAssertEqual(Playlist.order(ids, mode: .inOrder), ids)
        XCTAssertEqual(Playlist.order(ids, mode: .shuffle, seed: 7), Playlist.order(ids, mode: .shuffle, seed: 7))
        XCTAssertEqual(Set(Playlist.order(ids, mode: .shuffle, seed: 7)), Set(ids))
        XCTAssertEqual(Array(Playlist.order(ids, mode: .automatic, currentTempo: ["a": 120, "b": 90, "c": 100]).prefix(3)), ["d", "e", "b"])
    }
    func testKidsPolicy() {
        XCTAssertFalse(KidsPolicy.collectsPersonalData); XCTAssertFalse(KidsSettings().cameraMatchingEnabled); XCTAssertFalse(KidsSettings().recordingEnabled)
        XCTAssertFalse(KidsPolicy.library().isEmpty)
        XCTAssertTrue(KidsPolicy.library().allSatisfy { $0.complexity.rawValue <= 1 && $0.intensity != .high })
        XCTAssertFalse(KidsPolicy.library().contains { $0.id == "sway_running_man_v1" })
        let g = KidsPolicy.adultGate(seed: 3); XCTAssertGreaterThan(g.answer, 50)
        XCTAssertEqual(KidsPolicy.adultGate(seed: 3).answer, g.answer)
    }
    func testKidsFeedbackNeverClaimsCameraEvidenceItLacks() {
        XCTAssertFalse(KidsPolicy.feedback(score: ScoreAccumulator(), cameraEnabled: false).lowercased().contains("camera"))
        XCTAssertTrue(KidsPolicy.feedback(score: ScoreAccumulator(), cameraEnabled: true).contains("camera"))   // no evidence -> asks to be visible, no praise
        var s = ScoreAccumulator(); for _ in 0..<10 { s.record(.match(error: 1)) }
        XCTAssertEqual(KidsPolicy.feedback(score: s, cameraEnabled: true), "Amazing moves!")
        XCTAssertEqual(KidsPolicy.feedback(score: s, cameraEnabled: false), "You danced along! Great job moving.")
    }
}
