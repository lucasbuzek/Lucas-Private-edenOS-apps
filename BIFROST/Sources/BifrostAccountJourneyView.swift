import AppKit
import SwiftUI

/// Existing BIFROST account surface: durable identity selection followed by an
/// explicitly opened, separate provider session. No automatic login or pairing.
struct BifrostAccountJourneyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var permissions: BifrostPermissionCenter
    @StateObject private var connector = BifrostAccountConnectorProbe()
    @State private var confirmConnectorCheck = false
    @StateObject private var accounts: BifrostAccountStore
    @State private var provider: BifrostKnownAccountProvider = .chatgpt
    @State private var purpose: BifrostAccountPurpose = .personal
    @State private var localLabel = ""
    @State private var selected: BifrostAccountIdentity?
    @State private var browser: BifrostAccountIdentity?
    @State private var confirmOpening = false
    @State private var feedback = ""
    private let onClose: (() -> Void)?

    init(accounts: BifrostAccountStore = BifrostAccountStore(), onClose: (() -> Void)? = nil) {
        _accounts = StateObject(wrappedValue: accounts)
        self.onClose = onClose
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                BifrostMark(size: 34)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Accounts & Access").font(.title2.bold())
                    Text("Choose an identity. Open its provider. Verify its connection.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Close") {
                    if let onClose { onClose() } else { dismiss() }
                }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GroupBox("Add an identity") {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Picker("Provider", selection: $provider) {
                                    ForEach(BifrostKnownAccountProvider.allCases) { Text($0.title).tag($0) }
                                }
                                Picker("Context", selection: $purpose) {
                                    ForEach(BifrostAccountPurpose.allCases) { Text($0.rawValue).tag($0) }
                                }
                            }
                            HStack {
                                TextField("Identity label, e.g. Lucas Personal or BifrostBridge1", text: $localLabel)
                                    .textFieldStyle(.roundedBorder).onSubmit { saveIdentity() }
                                Button("Save identity") { saveIdentity() }
                                    .disabled(!BifrostAccountStore.validLabel(localLabel.trimmingCharacters(in: .whitespacesAndNewlines)) || accounts.error != nil)
                            }
                            Text("Saves a local label and a separate session identity. It does not create a provider account or start a connection.")
                                .font(.caption).foregroundStyle(.secondary)
                        }.padding(8)
                    }
                    GroupBox("Your identities") {
                        VStack(alignment: .leading, spacing: 10) {
                            if accounts.identities.isEmpty {
                                Text("Save your first identity above. Use a separate RDC identity for each of the two intended connections.")
                                    .font(.callout).foregroundStyle(.secondary).padding(8)
                            }
                            ForEach(accounts.identities) { entry in
                                HStack(spacing: 12) {
                                    Image(systemName: entry.provider == .rdc ? "point.3.connected.trianglepath.dotted" : "person.crop.circle")
                                        .foregroundStyle(BifrostUI.bridge)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(entry.label).font(.headline)
                                        Text(entry.provider.title + " · " + entry.purpose.rawValue)
                                            .font(.caption).foregroundStyle(.secondary)
                                        Text(entry.connectionStatus).font(.caption2).foregroundStyle(BifrostUI.warning)
                                        if entry.provider == .rdc, let observation = connector.observation {
                                            Text(observation.rdcProfileIDs.contains(entry.label)
                                                 ? "Matching local RDC profile found · online access not checked"
                                                 : "No exact matching local RDC profile found")
                                                .font(.caption2).foregroundStyle(.secondary)
                                        }
                                        if let date = entry.lastOpenedAt {
                                            Text("Last open requested " + date.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption2).foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Button("Open provider…") { selected = entry; confirmOpening = true }
                                }.padding(8)
                                Divider()
                            }
                        }
                    }
                    GroupBox("Check existing connections") {
                        VStack(alignment: .leading, spacing: 9) {
                            HStack {
                                Text("Use the existing BIFROST Bridge connector on this Mac.")
                                    .font(.callout)
                                Spacer()
                                Button(connector.running ? "Checking…" : "Check local connector") {
                                    requestConnectorCheck()
                                }.disabled(connector.running)
                            }
                            if let observation = connector.observation {
                                Label(observation.runtimeVerified ? "BIFROST runtime identity verified" : "BIFROST runtime unavailable or unverified",
                                      systemImage: observation.runtimeVerified ? "checkmark.circle" : "questionmark.circle")
                                Text("Local RDC profiles: \(observation.rdcProfileIDs.count). Provider sign-in and remote access require separate verification.")
                                Text("Checked " + observation.observedAt.formatted(date: .abbreviated, time: .shortened))
                                if observation.taskDispatch == "NOT_IMPLEMENTED_BY_THIS_TOOL" {
                                    Text("This connector currently supports read-only checks. Authenticated task dispatch is not implemented by it.")
                                }
                            }
                            if !connector.feedback.isEmpty { Text(connector.feedback) }
                        }.font(.caption).foregroundStyle(.secondary).padding(8)
                    }
                    GroupBox("Connection verification") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Each identity keeps its own provider session across launches. Complete the provider's sign-in, MFA and account checks there.")
                            Text("MCP enrollment, device authorization and two active RDC connections require their existing adapters. This page does not infer them from website sign-in or a saved label.")
                            Button("Open Apple Passwords") { openPasswords() }
                        }.font(.caption).foregroundStyle(.secondary).padding(8)
                    }
                    if let error = accounts.error { Text(error).foregroundStyle(BifrostUI.warning) }
                    if !feedback.isEmpty { Text(feedback).font(.caption).foregroundStyle(.secondary) }
                }
            }
        }
        .padding(20).frame(minWidth: 720, minHeight: 540)
        .confirmationDialog("Open this identity's provider session?", isPresented: $confirmOpening,
                            titleVisibility: .visible) {
            Button("Open private session") {
                guard let entry = selected else { return }
                do { try accounts.recordOpened(entry.id); browser = entry }
                catch { feedback = error.localizedDescription }
            }
            Button("Cancel", role: .cancel) { selected = nil }
        } message: {
            if let entry = selected {
                Text(entry.label + " · " + entry.provider.homeURL.absoluteString + ". Provider-managed browsing begins only after opening. No other identity's session is imported.")
            }
        }
        .confirmationDialog("Allow this local connector check?", isPresented: $confirmConnectorCheck,
                            titleVisibility: .visible) {
            Button("Allow Once") { connector.inspect() }
            Button("Allow All") {
                permissions.save(.allowAll, for: .rdcProfileDiscovery)
                connector.inspect()
            }
            Button("Deny", role: .destructive) {
                permissions.save(.deny, for: .rdcProfileDiscovery)
                feedback = "Local profile discovery denied. Review BIFROST Access in Settings."
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Read local RDC profile labels and check BIFROST runtime identity through its existing connector. No provider is signed in, no agent starts and no credential is read.")
        }
        .sheet(item: $browser) { entry in BifrostPrivateAccountBrowser(identity: entry).id(entry.id) }
    }
    private func requestConnectorCheck() {
        switch permissions.decision(for: .rdcProfileDiscovery) {
        case .ask: confirmConnectorCheck = true
        case .allowAll: connector.inspect()
        case .deny: feedback = "Local profile discovery denied. Review BIFROST Access in Settings."
        }
    }
    private func saveIdentity() {
        do {
            let entry = try accounts.add(provider: provider, purpose: purpose, label: localLabel)
            localLabel = ""
            feedback = "Saved \(entry.label). No provider account or adapter connection was created."
        } catch { feedback = error.localizedDescription }
    }
    private func openPasswords() {
        guard let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Passwords") else {
            feedback = "Apple Passwords is unavailable on this Mac."; return
        }
        NSWorkspace.shared.openApplication(at: app, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            Task { @MainActor in
                feedback = error == nil ? "Apple Passwords opened. BIFROST has not read any credentials." : "Apple Passwords could not open."
            }
        }
    }
}
