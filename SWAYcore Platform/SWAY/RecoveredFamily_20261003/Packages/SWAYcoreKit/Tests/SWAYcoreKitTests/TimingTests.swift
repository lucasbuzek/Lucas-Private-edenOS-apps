import XCTest
@testable import SWAYcoreKit

final class TimingTests: XCTestCase {
    func testGridBeatTimeInverse() {
        let g = MusicGrid(bpm: 120, phase: 0.25)
        XCTAssertEqual(g.beat(at: 0.25), 0, accuracy: 1e-9)
        XCTAssertEqual(g.beat(at: 1.25), 2, accuracy: 1e-9)
        XCTAssertEqual(g.time(ofBeat: g.beat(at: 3.7)), 3.7, accuracy: 1e-9)
    }
    func testHalfTimeKeepsPhaseAndHalvesRate() {
        let g = MusicGrid(bpm: 140, phase: 0.1, halfTime: true)
        XCTAssertEqual(g.beat(at: 0.1), 0, accuracy: 1e-9)
        XCTAssertEqual(g.effectiveBPM, 70)
        XCTAssertEqual(g.beat(at: 0.1 + 60.0 / 70.0), 1, accuracy: 1e-9)
    }
    func testBarAndPhrase() {
        let g = MusicGrid(bpm: 120, downbeatOffset: 1)
        XCTAssertEqual(g.bar(atBeat: 1), 0); XCTAssertEqual(g.bar(atBeat: 5), 1); XCTAssertEqual(g.phrase(atBeat: 9), 1)
    }
    func testCountPosition() {
        XCTAssertEqual(Counting.position(atBeat: 0).count, 1)
        XCTAssertEqual(Counting.position(atBeat: 7.5).count, 8)
        XCTAssertEqual(Counting.position(atBeat: 8.0).count, 1)
        XCTAssertEqual(Counting.position(atBeat: 8.0).cycleIndex, 1)
    }
    func testBeatAnalyzerRecoversTempoAndPhase() throws {
        let period = 60.0 / 120.0
        let onsets = (0..<64).map { 0.13 + Double($0) * period }
        let r = try XCTUnwrap(BeatAnalyzer.estimate(onsets: onsets))
        XCTAssertEqual(r.grid.bpm, 120, accuracy: 1.0)
        let ph = r.grid.phase.truncatingRemainder(dividingBy: period)
        XCTAssertEqual(ph, 0.13, accuracy: 0.02)
        XCTAssertGreaterThan(r.confidence, 0.9)
    }
    func testBeatAnalyzerRejectsInsufficientOrRandomOnsets() {
        XCTAssertNil(BeatAnalyzer.estimate(onsets: [0, 1, 2]))
        var s: UInt64 = 42; var t = 0.0; var o: [Double] = []
        for _ in 0..<40 { s = s &* 6364136223846793005 &+ 1442695040888963407; t += 0.2 + Double(s >> 40) / Double(1 << 24) * 0.7; o.append(t) }
        XCTAssertNil(BeatAnalyzer.estimate(onsets: o))
    }
    func testPracticeClockPauseFreezesAndResumeContinues() {
        var c = PracticeClock(bpm: 60)
        c.play(at: 10); XCTAssertEqual(c.beat(at: 12), 2, accuracy: 1e-9)
        c.pause(at: 12); XCTAssertEqual(c.beat(at: 50), 2, accuracy: 1e-9)
        c.play(at: 100); XCTAssertEqual(c.beat(at: 101), 3, accuracy: 1e-9)
    }
    func testTempoChangeIsContinuousAndUserControlledOnly() {
        var c = PracticeClock(bpm: 60); c.play(at: 0)
        c.setBPM(120, at: 4); XCTAssertEqual(c.beat(at: 4), 4, accuracy: 1e-9); XCTAssertEqual(c.beat(at: 5), 6, accuracy: 1e-9)
        XCTAssertEqual(c.beat(at: 1000) , 4 + 996 * 2, accuracy: 1e-6) // no hidden auto speed-up
    }
    func testSelectCountFreezesAtThatCount() {
        var c = PracticeClock(bpm: 90); c.play(at: 0); c.select(count: 5, at: 3)
        XCTAssertFalse(c.isPlaying); XCTAssertEqual(c.beat(at: 99), 4); XCTAssertEqual(Counting.position(atBeat: c.beat(at: 99)).count, 5)
    }
}
