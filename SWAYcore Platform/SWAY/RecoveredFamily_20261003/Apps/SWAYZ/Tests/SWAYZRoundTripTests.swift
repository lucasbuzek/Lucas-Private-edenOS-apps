import XCTest
import SWAYcoreKit
@testable import SWAYcoreSWAYZ

@MainActor final class SWAYZRoundTripTests: XCTestCase {
    /// Author -> save -> export -> import -> consumer runtime: identical counts/poses/timing.
    func testAuthorExportImportConsume() throws {
        let a = AuthoringModel()
        a.draft = MoveDraft(id: "swayz-test", name: "Instructor Move")
        try a.draft.set(count: 1, stance: .neutral); try a.draft.set(count: 5, stance: Stance(armL: Arm.high, armR: Arm.side, legL: Leg.wide, legR: Leg.wide))
        a.commitDraft(); a.doc.steps = [ContentStep(movementID: "swayz-test", repetitions: 2), ContentStep(movementID: "sway_march_v1", mirrored: true)]; a.doc.title = "RT-\(UUID().uuidString)"
        let url = try a.exportURL()
        let pack = try SwayPack.import(try Data(contentsOf: url))
        let rt = Dictionary(uniqueKeysWithValues: pack.movements.map { ($0.id, $0) })
        let tl1 = ChoreographyTimeline(steps: a.doc.steps, movements: a.library), tl2 = ChoreographyTimeline(steps: pack.combinations[0].steps, movements: rt)
        XCTAssertEqual(tl1.totalBeats, tl2.totalBeats)
        for beat in stride(from: 0.0, to: Double(tl1.totalBeats), by: 1) {
            let x = tl1.segment(atBeat: beat)!, y = tl2.segment(atBeat: beat)!
            XCTAssertEqual(a.library[x.0.movementID]!.pose(atBeat: x.localBeat, mirrored: x.0.mirrored), rt[y.0.movementID]!.pose(atBeat: y.localBeat, mirrored: y.0.mirrored))
        }
        try? FileManager.default.removeItem(at: url)
    }
    func testSWAYZUsesCoreSchemaNotItsOwn() {
        XCTAssertEqual(SwayPack.currentVersion, 2)   // single schema owned by Core
    }
}
