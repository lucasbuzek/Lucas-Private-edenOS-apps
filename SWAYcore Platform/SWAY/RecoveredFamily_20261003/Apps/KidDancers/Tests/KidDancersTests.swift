import XCTest
import SWAYcoreKit
@testable import SWAYcoreKidDancers

@MainActor final class KidDancersTests: XCTestCase {
    func testKidsLibraryIsFilteredFromCoreNotForked() {
        let k = KidsModel(); XCTAssertFalse(k.moves.isEmpty)
        XCTAssertTrue(k.moves.allSatisfy { MoveLibrary.byID[$0.id] != nil })   // same movement truth, no separate content engine
        XCTAssertTrue(k.moves.allSatisfy(KidsPolicy.suitable))
    }
    func testDefaultsAreMostPrivate() {
        let s = KidsModel.Saved().settings; XCTAssertFalse(s.cameraMatchingEnabled); XCTAssertFalse(s.recordingEnabled)
        XCTAssertFalse(KidsPolicy.collectsPersonalData)
    }
}
