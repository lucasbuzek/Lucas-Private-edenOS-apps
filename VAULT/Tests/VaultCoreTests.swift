import XCTest
@testable import VAULT

final class VaultCoreTests: XCTestCase {
    func testSeparatePINsAndData() throws {
        let real = VaultDocument(mode: .personal, accounts: [VaultAccount(name: "Private", balance: "100")])
        let sample = VaultDocument(mode: .sample, accounts: [VaultAccount(name: "Everyday", balance: "500")])
        let a = try VaultCipher.seal(real, pin: "correct-primary-password")
        let b = try VaultCipher.seal(sample, pin: "different-alternate-password")
        XCTAssertEqual(try VaultCipher.open(a, pin: "correct-primary-password"), real)
        XCTAssertEqual(try VaultCipher.open(b, pin: "different-alternate-password"), sample)
        XCTAssertThrowsError(try VaultCipher.open(a, pin: "different-alternate-password"))
        XCTAssertThrowsError(try VaultCipher.open(b, pin: "correct-primary-password"))
        XCTAssertNotEqual(a.salt, b.salt)
        XCTAssertNotEqual(a.payload, b.payload)
    }
    func testChangedRecordDoesNotModifyOtherRecord() throws {
        let first = try VaultCipher.seal(VaultDocument(mode: .personal, accounts: []), pin: "real-long-password")
        let second = try VaultCipher.seal(VaultDocument(mode: .sample, accounts: []), pin: "sample-long-password")
        let key = try VaultCipher.key(for: "real-long-password", salt: first.salt, iterations: first.iterations)
        let changed = try VaultCipher.reseal(VaultDocument(mode: .personal,
            accounts: [VaultAccount(name: "Added", balance: "23")]), with: key, existing: first)
        XCTAssertEqual(try VaultCipher.open(second, pin: "sample-long-password").accounts.count, 0)
        XCTAssertEqual(try VaultCipher.open(changed, pin: "real-long-password").accounts.count, 1)
    }
}