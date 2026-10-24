import Foundation

/// Isolated native permission-store regression. Uses a temporary preferences
/// suite; never modifies BIFROST's real settings or macOS TCC.
@main
struct PermissionCenterSmoke {
    @MainActor
    static func main() {
        let suiteName = "eden.bifrost.permission.smoke.\(ProcessInfo.processInfo.processIdentifier)"
        guard let isolated = UserDefaults(suiteName: suiteName) else {
            fatalError("Unable to open isolated permission test suite")
        }
        isolated.removePersistentDomain(forName: suiteName)
        defer { isolated.removePersistentDomain(forName: suiteName) }

        let first = BifrostPermissionCenter(preferences: isolated)
        precondition(first.decision(for: .rdcProfileDiscovery) == .ask)
        precondition(first.decision(for: .fileOperations) == .ask)
        first.save(.allowAll, for: .rdcProfileDiscovery)
        precondition(first.decision(for: .rdcProfileDiscovery) == .allowAll)
        precondition(first.decision(for: .fileOperations) == .ask)

        guard let reloaded = UserDefaults(suiteName: suiteName) else {
            fatalError("Unable to reload isolated preferences")
        }
        let second = BifrostPermissionCenter(preferences: reloaded)
        precondition(second.decision(for: .rdcProfileDiscovery) == .allowAll)
        second.save(.deny, for: .rdcProfileDiscovery)
        precondition(first.decision(for: .rdcProfileDiscovery) == .deny)
        second.save(.ask, for: .rdcProfileDiscovery)
        precondition(second.decision(for: .rdcProfileDiscovery) == .ask)

        second.save(.deny, for: .externalAccounts)
        second.resetAll()
        precondition(BifrostAccessScope.allCases.allSatisfy {
            second.decision(for: $0) == .ask
        })
        print("PASS: scoped access, persistence, denial, reset, nonpersistent once")
    }
}
