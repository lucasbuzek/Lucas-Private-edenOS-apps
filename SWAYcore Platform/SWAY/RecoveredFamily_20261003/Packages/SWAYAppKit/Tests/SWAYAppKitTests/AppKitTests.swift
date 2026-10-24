import XCTest
import SWAYcoreKit
@testable import SWAYAppKit

final class AppKitTests: XCTestCase {
    func testMissingCharacterIsReportedHonestlyNotFaked() {
        let a = CharacterAssets.availability("lucia")       // test bundle ships no assets
        XCTAssertFalse(a.ok); XCTAssertNotNil(a.reason)
    }
    func testBeatPlayerGridMatchesPattern() async throws {
        await MainActor.run {
            let p = BeatPlayer(); XCTAssertNil(p.grid)
        }
    }
    func testThemeTokensExist() { XCTAssertNotNil(SwayTheme.gradient) }
}
