import Foundation

@main
struct BifrostAccountStoreSmoke {
    @MainActor static func main() throws {
        let name = "eden.bifrost.tests.accounts." + UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let store = BifrostAccountStore(preferences: defaults)
        precondition(store.identities.isEmpty)
        let first = try store.add(provider: .rdc, purpose: .personal, label: "BifrostBridge1")
        let second = try store.add(provider: .rdc, purpose: .personal, label: "BifrostBridge2")
        precondition(first.id != second.id)
        do {
            _ = try store.add(provider: .rdc, purpose: .personal, label: "bifrostbridge1")
            fatalError("Duplicate accepted")
        } catch BifrostAccountStoreError.duplicate {}
        for bad in ["", "x\ny", String(repeating: "x", count: 65)] {
            do {
                _ = try store.add(provider: .chatgpt, purpose: .personal, label: bad)
                fatalError("Invalid label accepted")
            } catch BifrostAccountStoreError.invalidLabel {}
        }
        for provider in BifrostKnownAccountProvider.allCases {
            precondition(provider.allows(provider.homeURL))
            for bad in ["http://chatgpt.com", "https://chatgpt.com.attacker.invalid/", "file:///etc/passwd", "https://user:secret@chatgpt.com", "https://chatgpt.com:8443/"] {
                precondition(!provider.allows(URL(string: bad)!))
            }
        }
        try store.recordOpened(first.id)
        let restored = BifrostAccountStore(preferences: defaults)
        precondition(restored.identities.count == 2)
        precondition(restored.identities[0].id == first.id)
        precondition(restored.identities[1].id == second.id)
        precondition(restored.identities[0].lastOpenedAt != nil)
        precondition(restored.identities.allSatisfy { $0.connectionStatus == "Adapter connection not verified" })
        let stale = BifrostAccountStore(preferences: defaults)
        _ = try restored.add(provider: .claude, purpose: .personal, label: "Newer window")
        do {
            _ = try stale.add(provider: .gemini, purpose: .personal, label: "Stale window")
            fatalError("Stale metadata overwrote newer identities")
        } catch BifrostAccountStoreError.changedRecord {}
        precondition(BifrostAccountStore(preferences: defaults).identities.count == 3)
        let key = "eden.bifrost.account-identities.v1"
        let damaged = Data("invalid".utf8)
        defaults.set(damaged, forKey: key)
        let corrupt = BifrostAccountStore(preferences: defaults)
        precondition(corrupt.error != nil && corrupt.identities.isEmpty)
        do {
            _ = try corrupt.add(provider: .claude, purpose: .personal, label: "No overwrite")
            fatalError("Corrupt metadata overwritten")
        } catch BifrostAccountStoreError.unsafeRecord {}
        precondition(defaults.data(forKey: key) == damaged)
        print("PASS: two RDC identities; persistence; duplicate/invalid input rejection; provider URL boundaries; corruption preservation; no inferred authentication")
    }
}
