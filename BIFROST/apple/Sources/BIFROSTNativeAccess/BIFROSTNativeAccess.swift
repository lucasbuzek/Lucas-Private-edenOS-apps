import AppKit
import Foundation
import LocalAuthentication
import SwiftUI

/// Native owner surface for the same Python Core. No assistant/provider credentials.
@MainActor
final class AccessModel: ObservableObject {
    @Published var status = "Computer access is off"
    @Published var error: String?
    @Published var deviceID: String?
    @Published var allowWrite = false
    @Published var busy = false
    @Published var devices: [[String: Any]] = []
    @Published var grantID: String?

    private var controlURL: URL {
        Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/native-control/native-control")
    }
    var hostURL: URL {
        Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/native-host/native-host")
    }

    func request(_ payload: [String: Any]) async throws -> [String: Any] {
        let url = controlURL
        let input = try JSONSerialization.data(withJSONObject: payload)
        return try await Task.detached {
            guard FileManager.default.isExecutableFile(atPath: url.path) else {
                throw NSError(domain: "BIFROST", code: 1, userInfo: [NSLocalizedDescriptionKey:
                    "The Native Host runtime is missing. Install the verified BIFROST package."])
            }
            let process = Process()
            process.executableURL = url
            let stdin = Pipe(), stdout = Pipe(), stderr = Pipe()
            process.standardInput = stdin
            process.standardOutput = stdout
            process.standardError = stderr
            try process.run()
            try stdin.fileHandleForWriting.write(contentsOf: input)
            try stdin.fileHandleForWriting.close()
            // Control results are bounded metadata, never process-output or secret dumps.
            let output = stdout.fileHandleForReading.readDataToEndOfFile()
            _ = stderr.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard let result = try JSONSerialization.jsonObject(with: output) as? [String: Any] else {
                throw NSError(domain: "BIFROST", code: 2, userInfo: [NSLocalizedDescriptionKey:
                    "Native Host returned an invalid result. Check package integrity."])
            }
            guard result["ok"] as? Bool == true, let body = result["result"] as? [String: Any] else {
                let message = (result["error"] as? [String: Any])?["message"] as? String ?? "Computer access was not authorized."
                throw NSError(domain: "BIFROST", code: 3, userInfo: [NSLocalizedDescriptionKey: message])
            }
            return body
        }.value
    }

    func refresh() async {
        busy = true
        defer { busy = false }
        do {
            let body = try await request(["action": "devices"])
            devices = body["devices"] as? [[String: Any]] ?? []
            if let saved = UserDefaults.standard.string(forKey: "nativeDeviceID"),
               devices.contains(where: { $0["id"] as? String == saved && $0["revoked"] as? Int == 0 }) {
                let result = try await request(["action": "status", "device_id": saved])
                deviceID = saved
                let grants = result["grants"] as? [[String: Any]] ?? []
                grantID = grants.first?["id"] as? String
                status = grants.isEmpty ? "Choose a folder to enable access" : "Authorized locally"
            } else {
                deviceID = nil
                status = "Computer access is off"
            }
            error = nil
        } catch { self.error = error.localizedDescription }
    }

    func ownerConfirmation(_ reason: String) async -> Bool {
        let context = LAContext()
        var failure: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &failure) {
            do { return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) }
            catch { self.error = error.localizedDescription; return false }
        }
        // OS identity confirmation is unavailable: do not silently substitute/bypass it.
        error = "macOS owner authentication is unavailable. Configure your Mac login and try again."
        return false
    }

    func enable() async {
        error = nil
        guard FileManager.default.isExecutableFile(atPath: hostURL.path) else {
            error = "Install the verified package containing the Native Host runtime."
            return
        }
        let panel = NSOpenPanel()
        panel.title = "Choose the folder BIFROST may access"
        panel.message = "Only this folder will be shared. Remote access stays off."
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let folder = panel.url else { return }
        let confirmation = NSAlert()
        confirmation.messageText = "Enable computer access?"
        confirmation.informativeText = "BIFROST may read and search “\(folder.lastPathComponent)”" +
            (allowWrite ? ", and create or replace files after digest confirmation." : ".") +
            "\nCommands require separate approval. macOS may ask for folder or Keychain access."
        confirmation.addButton(withTitle: "Enable Access")
        confirmation.addButton(withTitle: "Cancel")
        guard confirmation.runModal() == .alertFirstButtonReturn else { return }
        guard await ownerConfirmation("Enable BIFROST access to the selected folder") else { return }
        busy = true
        defer { busy = false }
        do {
            let scope = folder.startAccessingSecurityScopedResource()
            defer { if scope { folder.stopAccessingSecurityScopedResource() } }
            let result = try await request(["action": "enable", "approved": true, "folder": folder.path,
                                           "permissions": allowWrite ? ["read", "search", "write"] : ["read", "search"]])
            deviceID = result["device_id"] as? String
            grantID = result["grant_id"] as? String
            UserDefaults.standard.set(deviceID, forKey: "nativeDeviceID")
            status = result["state"] as? String == "local-ready" ? "Ready for this folder" : "Access needs attention"
            // The client launches the standard stdio provider on demand; no hidden daemon.
        } catch { self.error = error.localizedDescription; status = "Access needs attention" }
    }

    func revoke(_ id: String) async {
        let confirmation = NSAlert()
        confirmation.messageText = "Revoke this device's computer access?"
        confirmation.informativeText = "Its folder and command grants will be revoked, and its managed commands stopped."
        confirmation.addButton(withTitle: "Revoke")
        confirmation.addButton(withTitle: "Cancel")
        guard confirmation.runModal() == .alertFirstButtonReturn,
              await ownerConfirmation("Revoke BIFROST computer access") else { return }
        do {
            _ = try await request(["action": "revoke", "device_id": id, "approved": true])
            if id == deviceID {
                UserDefaults.standard.removeObject(forKey: "nativeDeviceID")
                deviceID = nil
                grantID = nil
                status = "Computer access is off"
            }
            await refresh()
        } catch { self.error = error.localizedDescription }
    }

    func approveCommand() async {
        guard let deviceID, let grantID else {
            error = "Enable access to a working folder first."
            return
        }
        let chooser = NSOpenPanel()
        chooser.title = "Choose the executable to authorize"
        chooser.canChooseDirectories = false
        guard chooser.runModal() == .OK, let executable = chooser.url else { return }
        let arguments = NSTextField(string: "[]")
        arguments.frame = NSRect(x: 0, y: 0, width: 440, height: 28)
        let prompt = NSAlert()
        prompt.messageText = "Approve this exact command?"
        prompt.informativeText = executable.path +
            "\nThis program runs with your Mac account privileges and may access files outside the chosen folder. Enter its exact argument array (Advanced)."
        prompt.accessoryView = arguments
        prompt.addButton(withTitle: "Approve Command")
        prompt.addButton(withTitle: "Cancel")
        guard prompt.runModal() == .alertFirstButtonReturn else { return }
        do {
            guard let data = arguments.stringValue.data(using: .utf8),
                  let argv = try JSONSerialization.jsonObject(with: data) as? [String] else {
                error = "Arguments must be a JSON array of strings."
                return
            }
            guard await ownerConfirmation("Authorize this exact BIFROST command with your Mac privileges") else { return }
            let result = try await request(["action": "approve_command", "approved": true, "device_id": deviceID,
                                           "grant_id": grantID, "argv": [executable.path] + argv])
            status = result["id"] != nil ? "Command authorized" : "Command needs attention"
        } catch { self.error = error.localizedDescription }
    }
}

struct AccessView: View {
    @StateObject private var model = AccessModel()
    @State private var advanced = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("BIFROST").font(.largeTitle.bold())
            Text("CONNECT · KEEP · RESOLVE").foregroundStyle(.secondary)
            Text("Computer Access").font(.title2)
            Text("Give BIFROST access to a folder on this Mac. You stay in control of each device and command.")
            Text(model.status).font(.headline).accessibilityLabel("Computer access status: " + model.status)
            if let error = model.error {
                Text(error).foregroundStyle(.red).textSelection(.enabled)
            }
            Toggle("Allow creating and replacing files in the selected folder", isOn: $model.allowWrite)
            HStack {
                Button("Enable Computer Access") { Task { await model.enable() } }
                    .buttonStyle(.borderedProminent)
                if let id = model.deviceID {
                    Button("Disable Access") { Task { await model.revoke(id) } }
                }
            }.disabled(model.busy)
            DisclosureGroup("Advanced", isExpanded: $advanced) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Native Host uses a local MCP connection. No remote listener or cloud service is started.")
                    Button("Authorize a Command…") { Task { await model.approveCommand() } }
                        .disabled(model.deviceID == nil || model.busy)
                    ForEach(model.devices.compactMap { device -> String? in
                        device["revoked"] as? Int == 0 ? device["id"] as? String : nil
                    }, id: \.self) { id in
                        HStack {
                            Text(model.devices.first(where: { $0["id"] as? String == id })?["name"] as? String ?? "Device")
                            Button("Revoke") { Task { await model.revoke(id) } }
                        }
                    }
                    Button("Refresh Status") { Task { await model.refresh() } }
                }.padding(.top, 10)
            }
        }
        .padding(32)
        .frame(minWidth: 560, minHeight: 470)
        .task { await model.refresh() }
    }
}

@main
struct BIFROSTNativeAccess: App {
    var body: some Scene {
        WindowGroup("BIFROST Computer Access") { AccessView() }
    }
}
