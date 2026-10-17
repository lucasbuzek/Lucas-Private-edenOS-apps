import Foundation
import CryptoKit
import CommonCrypto
import Security

// Candidate proof of concept. These offline encrypted records are NOT bank accounts.
enum VaultMode: String, Codable { case personal, sample }
struct VaultAccount: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var balance: String
    var currency: String = "ZAR"
}
struct VaultDocument: Codable, Equatable {
    var mode: VaultMode
    var accounts: [VaultAccount]
}
struct SealedRecord: Codable {
    var salt: Data
    var payload: Data
    var iterations: UInt32
}
enum VaultFailure: Error { case invalidPIN, encryptionFailed, invalidArchive }

enum VaultCipher {
    static let rounds: UInt32 = 310_000
    static func key(for pin: String, salt: Data, iterations: UInt32) throws -> SymmetricKey {
        guard (100_000...2_000_000).contains(iterations), salt.count == 16 else {
            throw VaultFailure.invalidArchive
        }
        var keyBytes = [UInt8](repeating: 0, count: 32)
        let status = pin.withCString { chars in
            salt.withUnsafeBytes { raw in
                CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), chars,
                                    pin.utf8.count,
                                    raw.bindMemory(to: UInt8.self).baseAddress,
                                    salt.count,
                                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                                    iterations, &keyBytes, keyBytes.count)
            }
        }
        guard status == kCCSuccess else { throw VaultFailure.encryptionFailed }
        return SymmetricKey(data: Data(keyBytes))
    }
    static func seal(_ document: VaultDocument, pin: String) throws -> SealedRecord {
        var bytes = [UInt8](repeating: 0, count: 16)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
            throw VaultFailure.encryptionFailed
        }
        let salt = Data(bytes)
        let key = try key(for: pin, salt: salt, iterations: rounds)
        let sealed = try AES.GCM.seal(JSONEncoder().encode(document), using: key)
        guard let combined = sealed.combined else { throw VaultFailure.encryptionFailed }
        return SealedRecord(salt: salt, payload: combined, iterations: rounds)
    }
    static func open(_ record: SealedRecord, pin: String) throws -> VaultDocument {
        let key = try key(for: pin, salt: record.salt, iterations: record.iterations)
        let box = try AES.GCM.SealedBox(combined: record.payload)
        return try JSONDecoder().decode(VaultDocument.self, from: AES.GCM.open(box, using: key))
    }
    static func reseal(_ document: VaultDocument, with key: SymmetricKey, existing: SealedRecord) throws -> SealedRecord {
        let box = try AES.GCM.seal(JSONEncoder().encode(document), using: key)
        guard let combined = box.combined else { throw VaultFailure.encryptionFailed }
        return SealedRecord(salt: existing.salt, payload: combined, iterations: existing.iterations)
    }
}

@MainActor
final class VaultStore: ObservableObject {
    @Published private(set) var configured = false
    @Published private(set) var unlocked = false
    @Published private(set) var accounts: [VaultAccount] = []
    @Published var message: String?
    private(set) var records: [SealedRecord] = []
    private var sessionKey: SymmetricKey?
    private var sessionRecordIndex: Int?
    private var currentDocument: VaultDocument?
    private let location: URL

    init(location: URL? = nil) {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.location = location ?? base.appendingPathComponent("vault-state.enc")
        if let data = try? Data(contentsOf: self.location),
           let recovered = try? JSONDecoder().decode([SealedRecord].self, from: data),
           !recovered.isEmpty {
            records = recovered
            configured = true
        }
    }
    func initialize(personalPIN: String, samplePIN: String) {
        guard personalPIN.count >= 8, (samplePIN.isEmpty || samplePIN.count >= 8),
              samplePIN.isEmpty || samplePIN != personalPIN else {
            message = "Choose different PINs of at least 8 characters."
            return
        }
        guard !configured else { message = "Vault already exists."; return }
        do {
            var output = [try VaultCipher.seal(VaultDocument(mode: .personal, accounts: []), pin: personalPIN)]
            if !samplePIN.isEmpty {
                let sample = VaultDocument(mode: .sample, accounts: [
                    VaultAccount(name: "Everyday", balance: "3,450.00"),
                    VaultAccount(name: "Savings", balance: "18,100.00")
                ])
                output.append(try VaultCipher.seal(sample, pin: samplePIN))
            }
            output.shuffle()
            try persist(output)
            records = output
            configured = true
            message = nil
        } catch { message = "Could not initialize encrypted storage." }
    }
    func unlock(pin: String) {
        guard configured else { return }
        for (index, record) in records.enumerated() {
            guard let document = try? VaultCipher.open(record, pin: pin),
                  let key = try? VaultCipher.key(for: pin, salt: record.salt, iterations: record.iterations) else { continue }
            sessionKey = key
            sessionRecordIndex = index
            currentDocument = document
            accounts = document.accounts
            unlocked = true
            message = nil
            return
        }
        message = "Unable to unlock."
    }
    func addAccount(name: String, balance: String) {
        guard unlocked, !name.trimmingCharacters(in: .whitespaces).isEmpty,
              var document = currentDocument, let index = sessionRecordIndex,
              let key = sessionKey else { return }
        document.accounts.append(VaultAccount(name: name, balance: balance))
        do {
            var next = records
            next[index] = try VaultCipher.reseal(document, with: key, existing: records[index])
            try persist(next)
            records = next
            currentDocument = document
            accounts = document.accounts
            message = nil
        } catch { message = "Could not save changes." }
    }
    func lock() {
        sessionKey = nil
        sessionRecordIndex = nil
        currentDocument = nil
        accounts = []
        unlocked = false
        message = nil
    }
    private func persist(_ value: [SealedRecord]) throws {
        let parent = location.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        try JSONEncoder().encode(value).write(to: location, options: .atomic)
        #if os(iOS)
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete],
                                              ofItemAtPath: location.path)
        #endif
    }
}