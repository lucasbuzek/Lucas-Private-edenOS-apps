import SwiftUI
import Foundation

/// Optional RDC5 metadata adapter. Never opens credential files, launches
/// providers, changes profile selection or queries remote devices.
struct BifrostRDCManagerSnapshot {
    struct Profile: Identifiable {
        let id: String
        let selected: Bool
    }

    let status: String
    let profiles: [Profile]
    let available: Bool

    static func read(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> Self {
        let provider = home.appendingPathComponent(
            "edenOS/Software Development/Online Plugins & Connectors/RDC5/rdc5.py")
        guard FileManager.default.fileExists(atPath: provider.path) else {
            return .init(status: "RDC Manager backend not installed at its known location.",
                         profiles: [], available: false)
        }
        let index = home.appendingPathComponent(".config/rdc5/identities.json")
        do {
            let attributes = try index.resourceValues(
                forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey])
            guard attributes.isRegularFile == true,
                  attributes.isSymbolicLink == false,
                  let size = attributes.fileSize, size <= 65536 else {
                return .init(status: "RDC profile metadata is unavailable.",
                             profiles: [], available: true)
            }
            let data = try Data(contentsOf: index)
            guard data.count <= 65536,
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let schema = json["schema"] as? Int, schema == 2,
                  let entries = json["profiles"] as? [String: Any],
                  let active = json["active"] as? String else {
                return .init(status: "Unrecognized RDC metadata; no accounts changed.",
                             profiles: [], available: true)
            }
            let ids = entries.keys.filter { key in
                key.range(of: "^[A-Za-z][A-Za-z0-9_-]{0,39}$",
                          options: .regularExpression) != nil
            }.sorted()
            let profiles = ids.map { Profile(id: $0, selected: $0 == active) }
            return .init(status: "Local profile labels only. Authentication, remote device health and quota are unknown.",
                         profiles: profiles, available: true)
        } catch {
            return .init(status: "RDC metadata cannot be read. No session was started.",
                         profiles: [], available: true)
        }
    }
}

struct BifrostRDCManagerReadOnlyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var snapshot = BifrostRDCManagerSnapshot(
        status: "Not yet requested.", profiles: [], available: false)

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("BIFROST · RDC Manager").font(.title3.bold())
                Spacer()
                Button("Refresh") { snapshot = .read() }
                Button("Close") { dismiss() }
            }
            Label(snapshot.available ? "Backend detected" : "Backend unavailable",
                  systemImage: snapshot.available ? "checkmark.circle" : "circle.dashed")
                .foregroundStyle(.secondary)
            Text(snapshot.status).font(.caption).foregroundStyle(.secondary)
            if snapshot.profiles.isEmpty {
                ContentUnavailableView("No verified profiles",
                    systemImage: "person.crop.circle.badge.questionmark",
                    description: Text("Connection setup and profile editing require the separate BIFROST RDC Manager action and provider authorization."))
            } else {
                List(snapshot.profiles) { profile in
                    HStack {
                        Text(profile.id)
                        Spacer()
                        Text(profile.selected ? "Selected in local manager" : "Configured profile")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(minHeight: 180)
            }
            Text("Read-only view: credentials are never opened. No login, account selection, remote call or service activation occurs.")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(minWidth: 560, minHeight: 360)
        .onAppear { snapshot = .read() }
    }
}
