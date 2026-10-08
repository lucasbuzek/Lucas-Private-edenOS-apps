import XCTest
@testable import SWAYcoreEngine

final class MusicalClockTests: XCTestCase {
    func testPauseResumeHasNoDriftAndCompletionUsesTimeline() {
        var clock = SwayMusicalClock(); clock.start(at: 100); clock.update(at: 105); clock.pause(at: 106)
        XCTAssertEqual(clock.musicalTime, 6); clock.update(at: 1006); XCTAssertEqual(clock.musicalTime, 6)
        clock.resume(at: 2000); clock.update(at: 2004); XCTAssertEqual(clock.musicalTime, 10)
        let plan = SwayTimelinePlan(bpm: 120, totalCounts: 20)
        XCTAssertFalse(plan.isComplete(at: 9.999)); XCTAssertTrue(plan.isComplete(at: clock.musicalTime))
        XCTAssertEqual(clock.position(bpm: 120).count, 5)
    }
}

final class WorkoutReducerTests: XCTestCase {
    func testTruthComboScoreCalibrationAndEndEarly() {
        var engine = SwayWorkoutEngine()
        engine.record(.init(count: 1, truth: .match, score: 100), calibrationReady: false)
        XCTAssertTrue(engine.results.isEmpty)
        engine.record(.init(count: 1, truth: .match, score: 90), calibrationReady: true)
        engine.record(.init(count: 2, truth: .unknown, score: 0), calibrationReady: true)
        XCTAssertEqual(engine.combo, 1); XCTAssertEqual(engine.score, 90)
        engine.record(.init(count: 3, truth: .notMatched, score: 10), calibrationReady: true)
        XCTAssertEqual(engine.combo, 0); XCTAssertEqual(engine.score, 50)
        engine.end(.endedEarly); XCTAssertEqual(engine.outcome, .endedEarly)
    }
    func testMasteryAndLifecycle() {
        XCTAssertEqual(SwayWorkoutEngine.mastery(successfulKnownCounts: 0), .discovered)
        XCTAssertEqual(SwayWorkoutEngine.mastery(successfulKnownCounts: 16), .familiar)
        XCTAssertEqual(SwayWorkoutEngine.mastery(successfulKnownCounts: 64), .mastered)
        var e = SwayWorkoutEngine(); e.pause(); e.nextMove(); XCTAssertEqual(e.moveIndex, 0); e.resume(); e.nextMove(); XCTAssertEqual(e.moveIndex, 1); e.restart(); XCTAssertEqual(e.moveIndex, 0)
    }
}

final class ContentPackPersistenceTests: XCTestCase {
    func testAuthoredContentAndDifficulty() {
        XCTAssertEqual(SwayAuthoredLibrary.moves.count, 26)
        XCTAssertEqual(Set(SwayAuthoredLibrary.moves.map(\.id)).count, 26)
        XCTAssertEqual(SwayAuthoredLibrary.workouts.map(\.name), ["Foundation Flow", "Latin Vibes", "Full Body Groove"])
        XCTAssertTrue(SwayAuthoredLibrary.moves(maxDifficulty: .beginner).allSatisfy { $0.difficulty == .beginner })
    }
    func testSwayPackRoundTripValidationAndEditing() throws {
        var pack = SwayPack(title: "Mine", moves: [SwayAuthoredLibrary.moves[0]], parameters: ["march": .init(bpm: 92, range: 0.8, armStyle: .pump, intensity: 0.7)])
        let decoded = try SwayPack.decode(pack.encoded()); XCTAssertEqual(decoded, pack)
        pack.title = "Edited"; XCTAssertEqual(try SwayPack.decode(pack.encoded()).title, "Edited")
        pack.format = "zip"; XCTAssertThrowsError(try pack.encoded())
    }
    func testMigrationCorruptionFallbackAndOfflineJourney() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = SwayLocalStore(url: folder.appendingPathComponent("state.json"))
        let legacy = Data("{\"learnedMoveIDs\":[\"march\"]}".utf8); try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true); try legacy.write(to: store.url)
        var migrated = store.load(); XCTAssertEqual(migrated.schema, SwayPersistedState.schemaVersion); XCTAssertEqual(migrated.selectedCoachID, "lucia")
        migrated.selectedCoachID = "zuri"; try store.save(migrated); migrated.selectedCoachID = "kyle"; try store.save(migrated)
        try Data("broken".utf8).write(to: store.url); XCTAssertEqual(store.load().selectedCoachID, "zuri")
        // Complete core journey uses only deterministic bundled data and local filesystem.
        let pack = SwayPack(title: "Offline", moves: [SwayAuthoredLibrary.moves[0]]); migrated.packs = [try SwayPack.decode(pack.encoded())]; try store.save(migrated)
        XCTAssertEqual(store.load().packs.first?.title, "Offline")
    }
}

final class BeatProgressRegistryTests: XCTestCase {
    func testGeneratedBeatAndRegistry() {
        let beats = SwayGeneratedBeatEngine.events(style: .tropical, bpm: 120, intensity: 0.5, count: 8)
        XCTAssertEqual(beats.count, 8); XCTAssertEqual(beats[4].time, 2); XCTAssertGreaterThan(beats[4].accent, beats[3].accent)
        XCTAssertEqual(Set(SwayCharacterRegistry.all.map(\.id)), Set(SwayCharacterIdentifier.allCases))
    }
    func testResultsHistoryWeeklyAndStreak() {
        let calendar = Calendar(identifier: .gregorian), now = Date(timeIntervalSince1970: 2_000_000)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let records = [SwaySessionRecord(date: now, activeSeconds: 600, moveCount: 5, activeCalories: 40, outcome: .completed), SwaySessionRecord(date: yesterday, activeSeconds: 300, moveCount: 3, activeCalories: 20, outcome: .endedEarly)]
        XCTAssertEqual(SwayProgressMath.completedCount(records), 1); XCTAssertEqual(SwayProgressMath.weeklySeconds(records, now: now, calendar: calendar), 900); XCTAssertEqual(SwayProgressMath.streak(records, now: now, calendar: calendar), 2)
    }
}
