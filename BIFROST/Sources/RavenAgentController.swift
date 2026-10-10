import AppKit
import Foundation
import SwiftUI

/// The RavenNest cloud Worker is independent. This class controls ONLY the
/// optional, user-requested Mac bridge. It does not manage cloud deployments,
/// credentials, other apps, RDC, Headless or external Caffeinate processes.
///
/// Default state: launchd DISABLED, RunAtLoad=false, KeepAlive=false.
/// The bridge is started only after explicit confirmation in the native UI.
@MainActor
final class RavenAgentController: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var autoStartDisabled: Bool? = nil
    @Published private(set) var isBusy = false
    @Published private(set) var status = "Checking local bridge"
    @Published private(set) var feedback = ""

    private nonisolated static let label = "eden.bifrost.raven-bridge"
    private nonisolated static let controlLock = NSLock()
    private nonisolated static let domain = "gui/\(getuid())"
    private var timer: Timer?
    private var terminateObserver: NSObjectProtocol?

    private nonisolated static var projectURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("edenOS/Software Development/Online Plugins & Connectors/RavenNest")
    }

    private nonisolated static var agentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    init() {
        // A Mac bridge session must not survive a normal BIFROST App quit.
        // The observer stops/disabled only this Raven label, synchronously.
        terminateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil, queue: nil) { _ in
                _ = Self.manualStop()
            }
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
    }

    var localSummary: String {
        if isRunning {
            return autoStartDisabled == true ?
                "Running · manual session" : "Running · automatic startup needs review"
        }
        if autoStartDisabled == true { return "Stopped · automatic startup disabled" }
        if autoStartDisabled == false { return "Stopped · automatic startup enabled (unsafe)" }
        return status
    }

    func refresh() {
        // Observation never starts or restarts any process.
        Task.detached(priority: .utility) {
            let result = Self.observe()
            await MainActor.run {
                self.isRunning = result.running
                self.autoStartDisabled = result.disabled
                self.status = result.description
            }
        }
    }

    /// The only normal activation path. Never invoked by init(), refresh(),
    /// an incoming Raven request, Headless startup, or a timer.
    func requestStart() {
        guard !isBusy else { return }
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Start RavenNest bridge on this Mac?"
        alert.informativeText = """
        This starts the optional local RavenNest connection using your existing \
        credentials. Automatic startup and crash-restart stay disabled.

        Cloudflare RavenNest can continue operating without this Mac bridge. \
        You can stop the local connection from BIFROST at any time.
        """
        alert.addButton(withTitle: "Start This Mac Bridge")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        perform(starting: true)
    }

    func stop() {
        guard !isBusy else { return }
        perform(starting: false)
    }

    private func perform(starting: Bool) {
        isBusy = true
        feedback = starting ? "Starting by explicit request…" : "Stopping local RavenNest…"
        Task.detached(priority: .userInitiated) {
            let result = starting ? Self.manualStart() : Self.manualStop()
            let observation = Self.observe()
            await MainActor.run {
                self.isRunning = observation.running
                self.autoStartDisabled = observation.disabled
                self.status = observation.description
                self.feedback = result.message
                self.isBusy = false
            }
        }
    }

    private nonisolated static func launchctl(_ args: [String]) -> (Int32, String) {
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        task.arguments = args
        task.standardOutput = pipe
        task.standardError = pipe
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            let output = String(data: data, encoding: .utf8) ?? ""
            return (task.terminationStatus, String(output.prefix(1800)))
        } catch {
            return (1, error.localizedDescription)
        }
    }

    private nonisolated static func observe() -> (running: Bool, disabled: Bool?, description: String) {
        let listed = launchctl(["list", label])
        let running = listed.0 == 0 &&
            listed.1.range(of: #""PID"\s*=\s*[1-9][0-9]*"#, options: .regularExpression) != nil
        let settings = launchctl(["print-disabled", domain])
        let escaped = NSRegularExpression.escapedPattern(for: label)
        let disabledPattern = #"""# + escaped + #""\s*=>\s*disabled"#
        let enabledPattern = #"""# + escaped + #""\s*=>\s*enabled"#
        let disabled: Bool?
        if settings.0 != 0 {
            disabled = nil
        } else if settings.1.range(of: disabledPattern, options: .regularExpression) != nil {
            disabled = true
        } else if settings.1.range(of: enabledPattern, options: .regularExpression) != nil {
            disabled = false
        } else {
            disabled = nil
        }
        let state = running ? "Running on this Mac" : "Not running on this Mac"
        return (running, disabled, state)
    }

    private nonisolated static func validateLaunchAgent() -> String? {
        let fm = FileManager.default
        let project = projectURL.standardizedFileURL
        let target = agentURL
        guard !fm.isSymbolicLink(atPath: target.path),
              fm.isReadableFile(atPath: target.path),
              fm.isReadableFile(atPath: project.appendingPathComponent("bifrostctl.py").path),
              fm.isReadableFile(atPath: project.appendingPathComponent("bifrost/raven_bridge.py").path),
              let data = try? Data(contentsOf: target),
              let plist = try? PropertyListSerialization.propertyList(
                from: data, options: [], format: nil) as? [String: Any] else {
            return "Installed RavenNest launch agent or canonical source missing"
        }
        let requiredCommand = ["/opt/homebrew/bin/python3",
                               project.appendingPathComponent("bifrostctl.py").path,
                               "raven-bridge"]
        guard plist["Label"] as? String == label,
              plist["ProgramArguments"] as? [String] == requiredCommand,
              plist["WorkingDirectory"] as? String == project.path,
              plist["RunAtLoad"] as? Bool == false,
              plist["KeepAlive"] as? Bool == false,
              let environment = plist["EnvironmentVariables"] as? [String: String],
              environment["BIFROST_RAVEN_MANUAL_SESSION"] == "1" else {
            return "RavenNest launch agent does not match the safe manual-only configuration"
        }
        return nil
    }

    private nonisolated static func manualStart() -> (ok: Bool, message: String) {
        controlLock.lock()
        defer { controlLock.unlock() }
        if let issue = validateLaunchAgent() { return (false, issue) }
        if observe().running {
            return (true, "RavenNest was already running; no duplicate was started")
        }

        let target = "\(domain)/\(label)"
        let pre = launchctl(["print", target])
        if pre.0 == 0 {
            // A registered but unobserved process is ambiguous: do not kick
            // another process into life without first reconciling its state.
            return (false, "RavenNest is already registered but not running; review its state")
        }

        // Temporarily enable ONLY this label to register and explicitly
        // kickstart one on-demand session. Disable again before returning.
        let enabled = launchctl(["enable", target])
        guard enabled.0 == 0 else {
            return (false, "Could not authorize one-time RavenNest activation: \(enabled.1)")
        }

        var registered = false
        var failure: String?
        let installed = launchctl(["bootstrap", domain, agentURL.path])
        if installed.0 != 0 {
            failure = "RavenNest bootstrap failed: \(installed.1)"
        } else {
            registered = true
            let kicked = launchctl(["kickstart", target])
            if kicked.0 != 0 {
                failure = "RavenNest manual start failed: \(kicked.1)"
            }
        }

        // Critical guarantee: no login-time activation after this explicit
        // session and no automatic retry if the process exits.
        let disabled = launchctl(["disable", target])
        if disabled.0 != 0 {
            failure = "Could not restore disabled startup: \(disabled.1)"
        }

        if failure != nil, registered {
            _ = launchctl(["bootout", target])
        }
        if let failure { return (false, failure) }

        let result = observe()
        guard result.running, result.disabled == true else {
            if registered { _ = launchctl(["bootout", target]) }
            _ = launchctl(["disable", target])
            return (false, "Mac bridge did not confirm running with autostart disabled")
        }
        return (true, "RavenNest running by request; auto-start and auto-restart disabled")
    }

    private nonisolated static func manualStop() -> (ok: Bool, message: String) {
        controlLock.lock()
        defer { controlLock.unlock() }
        let target = "\(domain)/\(label)"
        // Persistently disable BEFORE attempting to stop. Even if bootout fails
        // the service must not relaunch automatically on next login.
        let disabled = launchctl(["disable", target])
        if disabled.0 != 0 {
            return (false, "Could not disable RavenNest auto-start: \(disabled.1)")
        }
        if launchctl(["print", target]).0 == 0 {
            let stopped = launchctl(["bootout", target])
            if stopped.0 != 0 {
                return (false, "Could not stop RavenNest: \(stopped.1)")
            }
        }
        let checked = observe()
        guard !checked.running, checked.disabled == true else {
            return (false, "Stop not confirmed; inspect RavenNest manually")
        }
        return (true, "RavenNest stopped; automatic startup remains disabled")
    }
}

private extension FileManager {
    nonisolated func isSymbolicLink(atPath path: String) -> Bool {
        ((try? attributesOfItem(atPath: path))?[.type] as? FileAttributeType) == .typeSymbolicLink
    }
}
