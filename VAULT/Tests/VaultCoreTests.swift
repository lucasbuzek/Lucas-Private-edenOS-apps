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

    func testCiphertextTamperingIsDetected() throws {
        let original = try VaultCipher.seal(VaultDocument(mode: .personal, accounts: []),
                                            pin: "test-protected-password")
        var modified = original
        modified.payload[modified.payload.startIndex] ^= 0x01
        XCTAssertThrowsError(try VaultCipher.open(modified, pin: "test-protected-password"))
    }

    @MainActor
    func testStorePersistsAcrossRestartAndDoesNotOverwriteCorruption() throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("VAULT-\(UUID().uuidString).enc")
        defer { try? FileManager.default.removeItem(at: file) }

        let first = VaultStore(location: file)
        first.initialize(personalPIN: "long-primary-password", samplePIN: "long-alternate-password")
        XCTAssertTrue(first.configured)
        first.unlock(pin: "long-primary-password")
        XCTAssertTrue(first.unlocked)
        first.addAccount(name: "Test account", balance: "100")
        XCTAssertEqual(first.accounts.count, 1)
        first.lock()

        let reopened = VaultStore(location: file)
        reopened.unlock(pin: "long-primary-password")
        XCTAssertEqual(reopened.accounts.count, 1)
        reopened.lock()
        reopened.unlock(pin: "long-alternate-password")
        XCTAssertEqual(reopened.accounts.count, 2)

        let corrupt = Data("unreadable ciphertext".utf8)
        try corrupt.write(to: file, options: .atomic)
        let damaged = VaultStore(location: file)
        XCTAssertTrue(damaged.configured)
        XCTAssertTrue(damaged.records.isEmpty)
        damaged.initialize(personalPIN: "replacement-password", samplePIN: "")
        XCTAssertEqual(try Data(contentsOf: file), corrupt)
    }
}