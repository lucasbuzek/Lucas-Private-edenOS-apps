import XCTest
@testable import DropboxLiteCore

final class AccountNicknamePolicyTests: XCTestCase {
    func testRemoteKeysAreSourceScopedAndStable() throws {
        XCTAssertEqual(try AccountNicknamePolicy.key(source: "managed", remote: "dropboxlite"), "managed|dropboxlite")
        XCTAssertEqual(try AccountNicknamePolicy.key(source: "system", remote: "dropboxlite"), "system|dropboxlite")
        XCTAssertNotEqual(try AccountNicknamePolicy.key(source: "managed", remote: "dropboxlite"),
                          try AccountNicknamePolicy.key(source: "system", remote: "dropboxlite"))
    }
    func testInvalidRemoteOrTenantCannotCreateKey() {
        for remote in ["", "../else", "foo:bar", "a|b", "foo bar", "a\\b", "a\nsecret"] {
            XCTAssertThrowsError(try AccountNicknamePolicy.key(source: "managed", remote: remote))
        }
        for source in ["", "owner", "family", "system|manager"] {
            XCTAssertThrowsError(try AccountNicknamePolicy.key(source: source, remote: "dropboxlite"))
        }
    }
    func testNicknameIsDisplayOnlyAndTrimmed() throws {
        XCTAssertEqual(try AccountNicknamePolicy.normalized("  My personal Dropbox  "), "My personal Dropbox")
        XCTAssertNil(try AccountNicknamePolicy.normalized(" \n "))
        XCTAssertEqual(try AccountNicknamePolicy.normalized(String(repeating: "a", count: 48))?.count, 48)
    }
    func testUnsafeOrMisleadingUnicodeNotStored() {
        for value in [String(repeating: "a", count: 49), "Nickname\nRoot", "a\u{0000}b", "a\u{202E}b", "a\u{2067}b"] {
            XCTAssertThrowsError(try AccountNicknamePolicy.normalized(value))
        }
    }
}
