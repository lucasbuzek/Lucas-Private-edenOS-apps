import XCTest
import AVFoundation
import SWAYcoreEngine
@testable import SWAY

/// Application-level smoke tests (host app). Simulator evidence at best; camera/Vision/MusicKit/HealthKit need a physical device.
@MainActor final class SWAYSmokeTests: XCTestCase {
    func testRemixRetainsExecutableFoundationThroughShareAndReload() throws {
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at:folder) }
        let store=SwayStore(saveURL:folder.appendingPathComponent("source.json"))
        store.addMove(name:"My Step",style:"My Style",difficulty:2,basedOn:"step-touch")
        let created=try XCTUnwrap(store.moves.last)
        store.duplicate(created)
        let remix=try XCTUnwrap(store.moves.last)
        XCTAssertTrue(SwayCoachPoseEngine.supports(moveID:remix.id),"Remix must retain executable movement")
        XCTAssertEqual(SwayCoachPoseEngine.canonicalMoveID(remix.id),"step-touch")
        let url=try store.exportPackage()
        let imported=SwayStore(saveURL:folder.appendingPathComponent("imported.json"))
        try imported.importPackage(from:url)
        let reloaded=SwayStore(saveURL:folder.appendingPathComponent("imported.json"))
        let restored=try XCTUnwrap(reloaded.moves.first{$0.id==remix.id})
        XCTAssertEqual(restored.name,remix.name)
        XCTAssertTrue(SwayCoachPoseEngine.supports(moveID:restored.id))
        let reshared=try JSONDecoder().decode(SwayPackage.self,from:Data(contentsOf:reloaded.exportPackage()))
        XCTAssertTrue(reshared.moves.contains{$0.id==remix.id})
    }

    func testLocalAudioNativeClockRunsAndPauses() async throws {
        let url=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("caf")
        defer {try? FileManager.default.removeItem(at:url)}
        let format=try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate:44100,channels:1))
        let buffer=try XCTUnwrap(AVAudioPCMBuffer(pcmFormat:format,frameCapacity:132300))
        buffer.frameLength=132300
        if let channel=buffer.floatChannelData?[0] {for i in 0..<132300 {channel[i]=0}}
        do {let file=try AVAudioFile(forWriting:url,settings:format.settings);try file.write(from:buffer)}
        let local=SwayLocalAudioPlayer();defer {local.stop()}
        try local.load(url);try local.play()
        let start=local.currentTime
        try? await Task.sleep(nanoseconds:200_000_000)
        XCTAssertGreaterThan(local.currentTime,start+0.04,"local transport must supply native playback time to musical clock")
        local.pause();let frozen=local.currentTime
        try? await Task.sleep(nanoseconds:100_000_000)
        XCTAssertEqual(local.currentTime,frozen,accuracy:0.001,"paused local transport cannot advance movement")
    }

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
    func testPhraseRestartAnchorFollowsUniformAndAnalyzedAudio() {
        let timeline=SwayTimelineEngine()
        let grid=SwayBeatGrid(bpm:100,beats:[0,0.5,1.0,1.6,2.2],downbeats:[0],phraseStarts:[0],confidence:0.9)
        timeline.start(bpm:100,beatGrid:grid,timeSource:{1.3})
        XCTAssertEqual(timeline.currentMovePhraseStartTransportTime,0,accuracy:0.000001)
        timeline.start(bpm:100,beatGrid:grid,timeSource:{5})
        XCTAssertEqual(timeline.currentMovePhraseStartTransportTime,4.6,accuracy:0.000001)
        timeline.start(bpm:120,timeSource:{5.375})
        XCTAssertEqual(timeline.currentMovePhraseStartTransportTime,4,accuracy:0.000001)
        timeline.stop(reset:true)
    }

    func testAnalyzedBeatPhaseOwnsCoachMovementTime() async {
        let grid=SwayBeatGrid(bpm:100,beats:[0,0.5,1.0,1.6,2.2],downbeats:[0],phraseStarts:[0],confidence:0.9)
        let timeline=SwayTimelineEngine()
        timeline.start(bpm:100,beatGrid:grid,timeSource:{1.3})
        try? await Task.sleep(nanoseconds:20_000_000)
        XCTAssertEqual(timeline.beatPhase,0.5,accuracy:0.000001)
        XCTAssertEqual(timeline.movementTime,1.5,accuracy:0.000001)
        XCTAssertEqual(timeline.movementTime(forTransportTime:1.3),timeline.movementTime,accuracy:0.000001)
        let position=SwayTimelineMath.position(time:timeline.movementTime,bpm:100)
        XCTAssertEqual(position.count,timeline.count)
        XCTAssertEqual(position.beatPhase,timeline.beatPhase,accuracy:0.000001)
        timeline.stop(reset:true)
    }

    func testGeneratedBeatNativeClockPauseAndTempoRebuild() async throws {
        let music=SwayMusicEngine()
        defer {music.stop()}
        music.useOfflineBeat();music.setOfflineTempo(120);music.play()
        guard music.isPlaying else {throw XCTSkip("Native Generated Beat transport unavailable; audio gate UNKNOWN")}
        let start=music.authoritativePlaybackPosition
        try? await Task.sleep(nanoseconds:150_000_000)
        XCTAssertGreaterThan(music.authoritativePlaybackPosition,start+0.04)
        music.pause()
        music.seek(to:3.25)
        XCTAssertEqual(music.authoritativePlaybackPosition,3.25,accuracy:0.000001,"native seek and authoritative movement clock must agree")
        let frozen=music.authoritativePlaybackPosition
        try? await Task.sleep(nanoseconds:100_000_000)
        XCTAssertEqual(music.authoritativePlaybackPosition,frozen,accuracy:0.000001)
        music.setOfflineTempo(60)
        XCTAssertEqual(music.authoritativePlaybackPosition,frozen*2,accuracy:0.000001,"tempo change preserves beat phase")
        music.play()
        try? await Task.sleep(nanoseconds:100_000_000)
        XCTAssertGreaterThan(music.authoritativePlaybackPosition,frozen*2)
        let before=music.authoritativePlaybackPosition
        music.refreshOfflineBeatIfPlaying()
        XCTAssertEqual(music.authoritativePlaybackPosition,before,accuracy:0.05,"feel rebuild retains musical phase")
    }

    func testAudioMasterTimeDoesNotAdvanceFromWallTime() async {
        var audioTime:TimeInterval=5.375
        let timeline=SwayTimelineEngine()
        timeline.start(bpm:120,timeSource:{audioTime})
        try? await Task.sleep(nanoseconds:150_000_000)
        XCTAssertEqual(timeline.elapsed,5.375,accuracy:0.000001,"stalled audio must hold movement/counts")
        audioTime=6.625
        try? await Task.sleep(nanoseconds:50_000_000)
        XCTAssertEqual(timeline.elapsed,6.625,accuracy:0.000001)
        XCTAssertEqual(timeline.count,6)
        timeline.pause();audioTime=20
        try? await Task.sleep(nanoseconds:50_000_000)
        XCTAssertEqual(timeline.elapsed,6.625,accuracy:0.000001)
        timeline.stop(reset:true)
    }

    func testPausedTimelineSeekPreservesExactPoseAndResumePhase() async {
        let timeline=SwayTimelineEngine()
        timeline.updateTempo(60)
        timeline.seek(to:2.375)
        XCTAssertFalse(timeline.running)
        XCTAssertEqual(timeline.elapsed,2.375,accuracy:0.000001)
        XCTAssertEqual(timeline.beatPhase,0.375,accuracy:0.000001)
        let pose=SwayCoachPoseEngine.pose(moveID:"march",musicalTime:timeline.elapsed,bpm:60)
        try? await Task.sleep(nanoseconds:100_000_000)
        XCTAssertEqual(SwayCoachPoseEngine.pose(moveID:"march",musicalTime:timeline.elapsed,bpm:60).leftKnee.y,pose.leftKnee.y,accuracy:0.000001)
        timeline.resume()
        try? await Task.sleep(nanoseconds:100_000_000)
        timeline.pause()
        XCTAssertGreaterThan(timeline.elapsed,2.375)
        XCTAssertLessThan(timeline.elapsed,2.65,"resume must retain the seek phase")
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
