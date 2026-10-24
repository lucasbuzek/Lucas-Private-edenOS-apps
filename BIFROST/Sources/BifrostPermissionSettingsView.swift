import SwiftUI
import AppKit

/// These are BIFROST's own approval preferences, not macOS TCC grants.
struct BifrostPermissionSettingsView: View {
    @EnvironmentObject private var permissions: BifrostPermissionCenter
    @State private var confirmReset = false
    @State private var systemSettingsFeedback = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(BifrostAccessScope.allCases) { scope in
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(scope.title).font(.subheadline.weight(.medium))
                        Text(scope.explanation)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if !scope.isIntegrated {
                            Text("Pending integration · no access can be granted here yet")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 12)
                    Picker(scope.title, selection: Binding(
                        get: { permissions.decision(for: scope) },
                        set: { permissions.save($0, for: scope) }
                    )) {
                        Text("Ask").tag(BifrostAccessDecision.ask)
                        Text("Allow All").tag(BifrostAccessDecision.allowAll)
                        Text("Deny").tag(BifrostAccessDecision.deny)
                    }
                    .labelsHidden()
                    .frame(width: 135)
                    .disabled(!scope.isIntegrated)
                    .accessibilityLabel("BIFROST access to \(scope.title)")
                }
                Divider()
            }
            HStack {
                Text("Allow Once is offered when an action is requested and expires after that action. Allow All applies only to the named BIFROST capability, not every device, account or action.")
                    .font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Button("Reset All…") { confirmReset = true }
                    .buttonStyle(.bordered)
            }
            Text("macOS Privacy & Security, provider sign-in, individual device grants and destructive-action confirmations remain independent. This page cannot override them.")
                .font(.caption2).foregroundStyle(.secondary)
            Button("Open macOS System Settings…") { openSystemSettings() }
                .buttonStyle(.bordered)
            if !systemSettingsFeedback.isEmpty {
                Text(systemSettingsFeedback).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .confirmationDialog("Reset BIFROST app access decisions?",
                            isPresented: $confirmReset) {
            Button("Reset All", role: .destructive) { permissions.resetAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Future BIFROST capability requests will ask again. This does not revoke macOS or provider grants.")
        }
    }

    private func openSystemSettings() {
        guard let app = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: "com.apple.systempreferences") else {
            systemSettingsFeedback = "macOS System Settings is unavailable."
            return
        }
        NSWorkspace.shared.openApplication(
            at: app, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            Task { @MainActor in
                systemSettingsFeedback = error.map {
                    "macOS System Settings could not open: \($0.localizedDescription)"
                } ?? "System Settings launch was accepted. Choose Privacy & Security to review OS grants."
            }
        }
    }
}
