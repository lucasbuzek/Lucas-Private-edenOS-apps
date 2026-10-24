import XCTest
import SWAYStudioKit
@testable import SWAYcoreStudioManagement

@MainActor final class StudioAppTests: XCTestCase {
    func testCorruptDatabaseFailsClosedWithoutOverwritingUserData() throws {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("studio-app-\(UUID().uuidString).json")
        let raw = Data("unreadable business data".utf8)
        try raw.write(to: path)
        let m = StudioModel(storageURL: path)
        XCTAssertNotNil(m.storageError)
        m.run { try m.store.add(Person(name: "Should not save", role: .member)) }
        XCTAssertTrue(m.store.data.people.isEmpty)
        XCTAssertEqual(try Data(contentsOf: path), raw)
    }
    func testModelBootsAndReportsFriendlyErrors() {
        let m = StudioModel(); XCTAssertNotNil(m.store)
        XCTAssertEqual(StudioModel.describe(StudioError.classFull), "This class is full.")
        XCTAssertEqual(money(12345), "$123.45")
    }
}
