import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Folder permissions are selected in native UI, not accepted as browser paths.
/// This rule is an explicit grant to an independently started Headless service.
/// A separately running service can still be denied by macOS TCC; never bypass it.
private struct BifrostApprovedFolderRule: Codable {
    let schema: String
    let enabled: Bool
    let folder: String
    let shortcut: String
}

struct BifrostFolderActionApproval: View {
    let shortcuts: [String]
    @State private var showingFolderPicker = false
    @State private var pendingConfirmation = false
    @State private var chosenFolder: URL?
    @State private var selectedShortcut = ""
    @State private var enabled = false
    @State private var feedback = "No folder action approved in this view."

    private var support: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/BIFROST", isDirectory: true)
    }
    private var ruleURL: URL { support.appendingPathComponent("orchestration-rule.json") }

    var body: some View {
        GroupBox("Folder Actions · Headless orchestration") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Approve one exact folder and saved Shortcut. No recursive scanning. Existing files are ignored when a watch starts. Native Automator Folder Actions remain available independently through macOS.")
                    .font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    Button("Open macOS Folder Actions") {
                        openSystemApp("/System/Library/CoreServices/Applications/Folder Actions Setup.app")
                    }
                    Button("Open Automator") {
                        openSystemApp("/System/Applications/Automator.app")
                    }
                }
                HStack(spacing: 10) {
                    Button("Choose Folder…") { showingFolderPicker = true }
                    Text(chosenFolder?.path ?? "No selected folder")
                        .font(.caption).lineLimit(2).textSelection(.enabled)
                }
                HStack {
                    Text("Action").font(.caption)
                    Picker("Saved Shortcut", selection: $selectedShortcut) {
                        Text("Choose Shortcut").tag("")
                        ForEach(shortcuts, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }.labelsHidden()
                }
                Toggle("Automatically run for new direct-child files while Headless is running",
                       isOn: $enabled)
                .disabled(chosenFolder == nil || !shortcuts.contains(selectedShortcut))
                HStack {
                    Button("Review and Save…") { pendingConfirmation = true }
                        .disabled(chosenFolder == nil || !shortcuts.contains(selectedShortcut))
                    Button("Disable existing Folder Action") { disableRule() }
                        .buttonStyle(.bordered)
                    Spacer()
                }
                Text(feedback).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                Text("Folder monitoring is OFF by default. Automatic actions may modify other files or invoke networks through the selected Shortcut. The daemon cannot start itself, nor override macOS Privacy permissions; physical test required.")
                    .font(.caption2).foregroundStyle(.secondary)
            }.padding(8)
        }
        .fileImporter(isPresented: $showingFolderPicker, allowedContentTypes: [.folder],
                      allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    try validateFolder(url)
                    chosenFolder = url.standardizedFileURL
                    enabled = false
                    feedback = "Folder selected. Choose a saved Shortcut; automatic actions remain disabled."
                } catch {
                    chosenFolder = nil
                    enabled = false
                    feedback = "Folder denied: \(error.localizedDescription)"
                }
            case .failure(let error):
                feedback = "Selection unavailable: \(error.localizedDescription)"
            }
        }
        .confirmationDialog("Approve folder-triggered automation?",
                            isPresented: $pendingConfirmation) {
            Button(enabled ? "Save and Enable Automatic Folder Action" : "Save Disabled Folder Rule") {
                saveRule(enabled: enabled)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("BIFROST Headless may run the selected saved Shortcut when new files arrive in the selected folder. Shortcut side effects are outside BIFROST's control. This grants no browser ability to select arbitrary paths.")
        }
        .onAppear(perform: loadExisting)
    }

    private func openSystemApp(_ path: String) {
        let app = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: app.path) else {
            feedback = "macOS application not found."
            return
        }
        NSWorkspace.shared.openApplication(at: app, configuration: NSWorkspace.OpenConfiguration()) {
            _, error in
            if let error {
                Task { @MainActor in
                    feedback = "macOS could not open the selected utility: " + error.localizedDescription
                }
            }
        }
    }

    private func validateFolder(_ folder: URL) throws {
        let home = FileManager.default.homeDirectoryForCurrentUser.resolvingSymlinksInPath()
        let candidate = folder.standardizedFileURL
        let actual = candidate.resolvingSymlinksInPath()
        let prefix = home.path + "/"
        let relative = actual.path.hasPrefix(prefix) ? String(actual.path.dropFirst(prefix.count)) : ""
        let pieces = relative.split(separator: "/")
        let properties = try candidate.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        guard properties.isDirectory == true, properties.isSymbolicLink == false,
              !relative.isEmpty, actual.path == candidate.path,
              !pieces.contains(where: { $0.hasPrefix(".") || $0 == "Library" }),
              !(pieces.count >= 2 && pieces[0] == "edenOS" && pieces[1] == "Projects") else {
            throw NSError(domain: "BIFROST", code: 17,
                          userInfo: [NSLocalizedDescriptionKey:
                                      "Choose a normal individual folder in your home, outside protected Projects, Library and hidden paths."])
        }
        let scope = candidate.startAccessingSecurityScopedResource()
        defer { if scope { candidate.stopAccessingSecurityScopedResource() } }
        guard FileManager.default.isReadableFile(atPath: candidate.path) else {
            throw NSError(domain: "BIFROST", code: 18,
                          userInfo: [NSLocalizedDescriptionKey: "Selected folder is not readable by this app."])
        }
    }

    private func saveRule(enabled newEnabled: Bool) {
        guard let folder = chosenFolder, shortcuts.contains(selectedShortcut) else {
            feedback = "Select a folder and current installed Shortcut first."
            return
        }
        do {
            try validateFolder(folder)
            let record = BifrostApprovedFolderRule(
                schema: "bifrost.orchestration.v1", enabled: newEnabled,
                folder: folder.path, shortcut: selectedShortcut)
            let fm = FileManager.default
            try fm.createDirectory(at: support, withIntermediateDirectories: true)
            try fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: support.path)
            let encoded = try JSONEncoder().encode(record)
            try encoded.write(to: ruleURL, options: .atomic)
            try fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: ruleURL.path)
            feedback = newEnabled
                ? "Saved enabled rule. Headless must be running; macOS folder permission still requires physical verification."
                : "Saved disabled rule. No folder watcher was enabled."
        } catch {
            feedback = "Approval failed; no new rule verified: \(error.localizedDescription)"
        }
    }

    private func disableRule() {
        guard let data = try? Data(contentsOf: ruleURL),
              let current = try? JSONDecoder().decode(BifrostApprovedFolderRule.self, from: data),
              current.schema == "bifrost.orchestration.v1" else {
            feedback = "No valid existing rule to disable."
            return
        }
        do {
            let disabled = BifrostApprovedFolderRule(
                schema: "bifrost.orchestration.v1", enabled: false,
                folder: current.folder, shortcut: current.shortcut)
            try JSONEncoder().encode(disabled).write(to: ruleURL, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: ruleURL.path)
            chosenFolder = URL(fileURLWithPath: current.folder)
            selectedShortcut = current.shortcut
            enabled = false
            feedback = "Existing Folder Action disabled."
        } catch {
            feedback = "Unable to disable rule: \(error.localizedDescription)"
        }
    }

    private func loadExisting() {
        guard let data = try? Data(contentsOf: ruleURL),
              let rule = try? JSONDecoder().decode(BifrostApprovedFolderRule.self, from: data),
              rule.schema == "bifrost.orchestration.v1" else { return }
        chosenFolder = URL(fileURLWithPath: rule.folder)
        selectedShortcut = rule.shortcut
        enabled = rule.enabled
        feedback = "Existing native approval loaded · " + (rule.enabled ? "enabled" : "disabled")
    }
}

