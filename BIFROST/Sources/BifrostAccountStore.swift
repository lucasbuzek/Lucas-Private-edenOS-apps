import Foundation
import Combine

enum BifrostKnownAccountProvider: String, CaseIterable, Codable, Identifiable {
    case chatgpt, claude, gemini, rdc, github, google, microsoft
    var id: String { rawValue }
    var title: String {
        switch self {
        case .chatgpt: "ChatGPT"
        case .claude: "Claude"
        case .gemini: "Gemini"
        case .rdc: "Remote Desktop Commander"
        case .github: "GitHub"
        case .google: "Google"
        case .microsoft: "Microsoft"
        }
    }
    var homeURL: URL {
        let address: String
        switch self {
        case .chatgpt: address = "https://chatgpt.com/"
        case .claude: address = "https://claude.ai/"
        case .gemini: address = "https://gemini.google.com/"
        case .rdc: address = "https://mcp.desktopcommander.app/"
        case .github: address = "https://github.com/"
        case .google: address = "https://accounts.google.com/"
        case .microsoft: address = "https://account.microsoft.com/"
        }
        return URL(string: address)!
    }
    // Top-level navigation only. Resources remain managed by WebKit and TLS.
    // Unknown redirect hosts fail closed instead of opening a different browser.
    func allows(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https", url.user == nil,
              url.password == nil, url.port == nil || url.port == 443,
              let host = url.host?.lowercased() else { return false }
        let roots: [String]
        let identity = ["accounts.google.com", "appleid.apple.com", "account.apple.com",
                        "login.microsoftonline.com", "login.live.com"]
        switch self {
        case .chatgpt: roots = ["chatgpt.com", "openai.com", "auth0.openai.com"] + identity
        case .claude: roots = ["claude.ai", "anthropic.com"] + identity
        case .gemini: roots = ["gemini.google.com", "accounts.google.com"]
        case .rdc: roots = ["desktopcommander.app"] + identity
        case .github: roots = ["github.com"] + identity
        case .google: roots = ["accounts.google.com", "myaccount.google.com"]
        case .microsoft: roots = ["account.microsoft.com"] + identity
        }
        return roots.contains { host == $0 || host.hasSuffix("." + $0) }
    }
}

enum BifrostAccountPurpose: String, CaseIterable, Codable, Identifiable {
    case personal = "Personal"
    case business = "Business"
    var id: String { rawValue }
}

struct BifrostAccountIdentity: Codable, Identifiable, Equatable {
    let id: UUID
    let provider: BifrostKnownAccountProvider
    let purpose: BifrostAccountPurpose
    let label: String
    let createdAt: Date
    var lastOpenedAt: Date?
    // Website navigation is deliberately not an authentication receipt.
    var connectionStatus: String { "Adapter connection not verified" }
}

enum BifrostAccountStoreError: LocalizedError {
    case invalidLabel, duplicate, unsafeRecord, full, changedRecord
    var errorDescription: String? {
        switch self {
        case .invalidLabel: "Use a label of 1–64 characters without control characters."
        case .duplicate: "This provider, context and label already exist. Select the saved identity."
        case .unsafeRecord: "Saved account metadata is invalid. It has been preserved; no changes were saved."
        case .full: "Account metadata limit reached. No changes were saved."
        case .changedRecord: "Account identities changed in another window. Reopen this page before saving; existing data was preserved."
        }
    }
}

/// Non-secret local identity metadata only. WebKit owns each separate session;
/// passwords, cookies and OAuth tokens never enter this model or UserDefaults.
@MainActor
final class BifrostAccountStore: ObservableObject {
    private struct Record: Codable {
        let schema: Int
        let identities: [BifrostAccountIdentity]
    }
    @Published private(set) var identities: [BifrostAccountIdentity] = []
    @Published private(set) var error: String?
    private let preferences: UserDefaults
    private let key = "eden.bifrost.account-identities.v1"
    private var writable = true
    private var observedData: Data?

    init(preferences: UserDefaults = .standard) {
        self.preferences = preferences
        guard let data = preferences.data(forKey: key) else {
            if preferences.object(forKey: key) != nil { refuseRecord() }
            return
        }
        guard data.count <= 65536,
              let record = try? JSONDecoder().decode(Record.self, from: data),
              record.schema == 1, record.identities.count <= 100,
              Set(record.identities.map(\.id)).count == record.identities.count,
              record.identities.allSatisfy({ Self.validLabel($0.label) }),
              Set(record.identities.map { Self.uniqueKey($0) }).count == record.identities.count else {
            refuseRecord(); return
        }
        identities = record.identities
        observedData = data
    }
    private func refuseRecord() {
        writable = false
        error = BifrostAccountStoreError.unsafeRecord.localizedDescription
    }
    static func validLabel(_ label: String) -> Bool {
        !label.isEmpty && label.count <= 64 &&
        label == label.trimmingCharacters(in: .whitespacesAndNewlines) &&
        label.unicodeScalars.allSatisfy { !CharacterSet.controlCharacters.contains($0) }
    }
    private static func uniqueKey(_ entry: BifrostAccountIdentity) -> String {
        entry.provider.rawValue + "/" + entry.purpose.rawValue + "/" + entry.label.lowercased()
    }
    private func commit(_ proposed: [BifrostAccountIdentity]) throws {
        guard writable else { throw BifrostAccountStoreError.unsafeRecord }
        let current = preferences.object(forKey: key)
        guard (current == nil || current is Data), preferences.data(forKey: key) == observedData else {
            throw BifrostAccountStoreError.changedRecord
        }
        guard proposed.count <= 100 else { throw BifrostAccountStoreError.full }
        let encoded = try JSONEncoder().encode(Record(schema: 1, identities: proposed))
        guard encoded.count <= 65536 else { throw BifrostAccountStoreError.full }
        preferences.set(encoded, forKey: key)
        observedData = encoded
        identities = proposed
        error = nil
    }
    @discardableResult
    func add(provider: BifrostKnownAccountProvider, purpose: BifrostAccountPurpose,
             label: String) throws -> BifrostAccountIdentity {
        let clean = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.validLabel(clean) else { throw BifrostAccountStoreError.invalidLabel }
        let entry = BifrostAccountIdentity(id: UUID(), provider: provider, purpose: purpose,
                                         label: clean, createdAt: Date())
        guard !identities.contains(where: { Self.uniqueKey($0) == Self.uniqueKey(entry) }) else {
            throw BifrostAccountStoreError.duplicate
        }
        try commit(identities + [entry])
        return entry
    }
    func recordOpened(_ id: UUID) throws {
        guard let index = identities.firstIndex(where: { $0.id == id }) else {
            throw BifrostAccountStoreError.unsafeRecord
        }
        var proposed = identities
        proposed[index].lastOpenedAt = Date()
        try commit(proposed)
    }
}
