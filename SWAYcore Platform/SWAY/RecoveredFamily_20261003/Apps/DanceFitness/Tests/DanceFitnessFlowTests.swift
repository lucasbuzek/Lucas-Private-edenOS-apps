import XCTest
import SWAYcoreKit
import SWAYAppKit
@testable import SWAYcoreDanceFitness

@MainActor final class DanceFitnessFlowTests: XCTestCase {
    func testSixProductionCharactersAreBundledAndMeetRigContract() {
        for id in ["lucia", "nandi", "thabo", "zuri", "kyle", "yourdancer"] {
            let availability = CharacterAssets.availability(id)
            XCTAssertTrue(availability.ok, "\(id): \(availability.reason ?? "")")
            XCTAssertEqual(CharacterAssets.manifest(id)?.visualQuality, "UNREVIEWED")
        }
    }
    func testAppLaunchModelBootsWithBundledLibrary() {
        let m = AppModel(); XCTAssertGreaterThanOrEqual(m.library.count, 26)
        XCTAssertEqual(m.lookup.count, m.library.count)
    }
    func testQuickPlanUsesRealMovesAndBuildsTimeline() {
        let m = AppModel(); let p = WorkoutPlan.quick(model: m)
        XCTAssertFalse(p.steps.isEmpty)
        let tl = ChoreographyTimeline(steps: p.steps, movements: m.lookup); XCTAssertGreaterThan(tl.totalBeats, 0)
    }
    func testCustomMoveSurvivesExportImportThroughApp() throws {
        let m = AppModel(); var d = MoveDraft(id: "app-test", name: "T"); try d.set(count: 1, stance: .neutral); try d.set(count: 4, stance: Stance(armL: Arm.high, armR: Arm.high, legL: Leg.wide, legR: Leg.wide))
        let built = try d.build(); m.save(move: built)
        let url = try m.exportPack(title: "T-\(UUID().uuidString)", ids: [built.id])
        let m2 = AppModel(); m2.state.custom.removeAll(); m2.importPack(from: url)
        XCTAssertEqual(m2.state.custom.first(where: { $0.id == "app-test" })?.keyframes, built.keyframes); XCTAssertNil(m2.importError)
        try? FileManager.default.removeItem(at: url)
    }
    func testMalformedImportReportsError() throws {
        let m = AppModel(); let u = FileManager.default.temporaryDirectory.appendingPathComponent("bad.swaypack"); try Data("nope".utf8).write(to: u)
        m.importPack(from: u); XCTAssertNotNil(m.importError)
    }
    func testFollowAlongRunnerNeverScores() {
        let m = AppModel(); let r = WorkoutRunner(plan: .quick(model: m), model: m, tracking: false)
        XCTAssertNil(r.finished); XCTAssertEqual(r.phase, .idle); XCTAssertFalse(r.trackingRequested)
    }
}
