import Foundation
import Combine

/// BIFROST-owned approval for one named capability. It does not grant macOS TCC,
/// authenticate an external account, or authorize an individual high-risk action.
enum BifrostAccessScope: String, CaseIterable, Identifiable {
    case rdcProfileDiscovery
    case externalAccounts
    case localAutomation
    case fileOperations

    var id: String { rawValue }
    var isIntegrated: Bool {
        switch self {
        case .rdcProfileDiscovery, .localAutomation: true
        case .externalAccounts, .fileOperations: false
        }
    }
    var title: String {
        switch self {
        case .rdcProfileDiscovery: "RDC Manager · View profiles"
        case .externalAccounts: "External accounts and providers"
        case .localAutomation: "Local automation"
        case .fileOperations: "File operations"
        }
    }
    var explanation: String {
        switch self {
        case .rdcProfileDiscovery: "Read existing RDC profile names and selection only. Connection management and device operations require separate approval."
        case .externalAccounts: "Manage supported account connections. Sign-in remains with the official provider."
        case .localAutomation: "Access local automation workflows. Commands, writes and system permissions remain separately reviewed."
        case .fileOperations: "Request BIFROST file operations. Folder selection and macOS file permissions are still required."
        }
    }
}

enum BifrostAccessDecision: String, Codable {
    case ask
    case allowAll
    case deny
}

/// A one-time grant is deliberately NOT stored. Only an exact approved
/// capability can have a persistent allow-all/deny preference.
@MainActor
final class BifrostPermissionCenter: ObservableObject {
    @Published private(set) var revision = 0

    private let preferences: UserDefaults
    private let prefix = "eden.bifrost.permission.v1."

    init(preferences: UserDefaults = .standard) {
        self.preferences = preferences
    }

    func decision(for scope: BifrostAccessScope) -> BifrostAccessDecision {
        guard let value = preferences.string(forKey: prefix + scope.rawValue),
              let result = BifrostAccessDecision(rawValue: value) else {
            return .ask
        }
        return result
    }

    func save(_ decision: BifrostAccessDecision, for scope: BifrostAccessScope) {
        if decision == .ask {
            preferences.removeObject(forKey: prefix + scope.rawValue)
        } else {
            preferences.set(decision.rawValue, forKey: prefix + scope.rawValue)
        }
        revision += 1
    }

    func resetAll() {
        for scope in BifrostAccessScope.allCases {
            preferences.removeObject(forKey: prefix + scope.rawValue)
        }
        revision += 1
    }
}
