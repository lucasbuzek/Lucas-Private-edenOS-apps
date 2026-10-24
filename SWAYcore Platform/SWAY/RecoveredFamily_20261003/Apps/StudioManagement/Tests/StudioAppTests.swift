import XCTest
import SWAYStudioKit
@testable import SWAYcoreStudioManagement

@MainActor final class StudioAppTests: XCTestCase {
    func testModelBootsAndReportsFriendlyErrors() {
        let m = StudioModel(); XCTAssertNotNil(m.store)
        XCTAssertEqual(StudioModel.describe(StudioError.classFull), "This class is full.")
        XCTAssertEqual(money(12345), "$123.45")
    }
}
