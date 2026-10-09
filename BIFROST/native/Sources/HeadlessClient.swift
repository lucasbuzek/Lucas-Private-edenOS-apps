import SwiftUI
import AppKit
import Foundation

/// Shared configuration written to ~/Library/Application Support/BIFROST/settings.json.
/// The Python headless service reads the same settings, independent of this GUI.
struct HeadlessPreferences: Codable, Equatable {
    var statusIndicators: [String] = ["headless", "activeTasks"]
    var aiRouting: String = "auto"
    var caffeinateMinutes: Int = 60
    var dashboardSections: [String] = ["headless", "tasks", "caffeinate", "raven", "ai"]
}

@MainActor
final class HeadlessClient: ObservableObject {
    @Published private(set) var isRunning = false
    /// Whether our exact launchd service label is registered, independent
    /// of the HTTP health endpoint. A degraded service must remain stoppable.
    @Published private(set) var isRegisteredWithLaunchd: Bool? = nil
    @Published private(set) var stateMessage = "Checking Headless"
    @Published private(set) var activeTasks: Int? = nil
    @Published private(set) var taskStatus = "unknown"
    @Published private(set) var caffeinateActive = false
    /// Observation only. A separate Caffeinate process may belong to the user
    /// and MUST NOT be stopped by Headless's Caffeinate controls.
    @Published private(set) var systemCaffeinateObserved: Bool? = nil
    @Published private(set) var awakeUntil: Date? = nil
    @Published private(set) var ravenBridge = "unknown"
    @Published private(set) var preferences: HeadlessPreferences
    @Published private(set) var feedback = ""
    private var refreshTimer: Timer?
    private let baseURL = URL(string: "http://127.0.0.1:8798")!
    private let label = "eden.bifrost.headless"

    private var supportURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/BIFROST", isDirectory: true)
    }
    private var preferencesURL: URL { supportURL.appendingPathComponent("settings.json") }
    private var runtimeURL: URL { supportURL.appendingPathComponent("runtime", isDirectory: true) }
    private var launchAgentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    init() {
        preferences = Self.loadPreferences()
        refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
    }

    private static func loadPreferences() -> HeadlessPreferences {
        let path = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/BIFROST/settings.json")
        guard let data = try? Data(contentsOf: path),
              let prefs = try? JSONDecoder().decode(HeadlessPreferences.self, from: data) else {
            return HeadlessPreferences()
        }
        return prefs
    }

    var menuBarTitle: String {
        var parts: [String] = []
        if preferences.statusIndicators.contains("headless") {
            parts.append(isRunning ? "H●" : "H○")
        }
        if preferences.statusIndicators.contains("activeTasks") {
            parts.append("T\(activeTasks.map(String.init) ?? "?")")
        }
        // RavenNest is independent of Headless: always show its local agent
        // status, including when the Headless API is unavailable.
        parts.append(ravenBridge == "running" ? "R●" :
                     ravenBridge == "offline" ? "R○" : "R?")
        return parts.joined(separator: " · ")
    }

    func setHeadlessIndicator(_ enabled: Bool) {
        update { prefs in
            prefs.statusIndicators.removeAll(where: { $0 == "headless" })
            if enabled { prefs.statusIndicators.insert("headless", at: 0) }
        }
    }

    func setTasksIndicator(_ enabled: Bool) {
        update { prefs in
            prefs.statusIndicators.removeAll(where: { $0 == "activeTasks" })
            if enabled { prefs.statusIndicators.append("activeTasks") }
        }
    }

    func setAIMode(_ mode: String) {
        guard ["auto", "manual", "local"].contains(mode) else { return }
        update { $0.aiRouting = mode }
    }

    func setCaffeinateMinutes(_ minutes: Int) {
        guard [0, 30, 60, 120].contains(minutes) else { return }
        update { $0.caffeinateMinutes = minutes }
    }

    func setDashboardSection(_ section: String, enabled: Bool) {
        guard ["headless", "tasks", "caffeinate", "raven", "ai"].contains(section) else { return }
        update { p in
            p.dashboardSections.removeAll(where: { $0 == section })
            if enabled { p.dashboardSections.append(section) }
        }
    }

    private func update(_ change: (inout HeadlessPreferences) -> Void) {
        var next = preferences
        change(&next)
        do {
            try FileManager.default.createDirectory(at: supportURL,
                                                    withIntermediateDirectories: true)
            try FileManager.default.setAttributes([.posixPermissions: 0o700],
                                                  ofItemAtPath: supportURL.path)
            let data = try JSONEncoder().encode(next)
            try data.write(to: preferencesURL, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600],
                                                  ofItemAtPath: preferencesURL.path)
            preferences = next
            feedback = "Settings saved for Headless, Web and macOS"
        } catch {
            feedback = "Could not save preferences: \(error.localizedDescription)"
        }
    }

    func refresh() {
        // Read the Raven launch agent independently of the Headless HTTP API.
        // This is observation only: it never starts/stops the Raven service
        // and never represents a running local agent as remote authentication.
        Task.detached(priority: .utility) { [weak self] in
            let observation = Self.observeRavenAgent()
            let systemAwake = Self.observeCaffeinateProcess()
            let serviceRegistered = Self.observeHeadlessLaunchdRegistration()
            await MainActor.run {
                self?.ravenBridge = observation
                self?.systemCaffeinateObserved = systemAwake
                self?.isRegisteredWithLaunchd = serviceRegistered
            }
        }
        Task { @MainActor in
            do {
                let (data, response) = try await URLSession.shared.data(
                    from: baseURL.appendingPathComponent("api/state"))
                guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                      let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let headless = json["headless"] as? [String: Any],
                      headless["status"] as? String == "running" else {
                    throw URLError(.badServerResponse)
                }
                isRunning = true
                stateMessage = "Running"
                if let task = json["tasks"] as? [String: Any] {
                    taskStatus = task["status"] as? String ?? "unknown"
                    activeTasks = taskStatus == "observed" ? task["active"] as? Int : nil
                }
                if let caffeinate = json["caffeinate"] as? [String: Any] {
                    caffeinateActive = caffeinate["active"] as? Bool ?? false
                    awakeUntil = (caffeinate["expiresAt"] as? Double).map { Date(timeIntervalSince1970: $0) }
                }
                if let config = json["preferences"] as? [String: Any],
                   let configData = try? JSONSerialization.data(withJSONObject: config),
                   let decoded = try? JSONDecoder().decode(HeadlessPreferences.self, from: configData) {
                    preferences = decoded
                }
            } catch {
                isRunning = false
                stateMessage = "Not connected"
                taskStatus = "unknown"
                activeTasks = nil
                caffeinateActive = false
                awakeUntil = nil
                // Leave independent Raven agent observation intact.
                preferences = Self.loadPreferences()
            }
        }
    }

    nonisolated private static func observeHeadlessLaunchdRegistration() -> Bool? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["print", "gui/\(getuid())/eden.bifrost.headless"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return nil
        }
    }

    nonisolated private static func observeCaffeinateProcess() -> Bool? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-x", "caffeinate"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 { return true }
            if process.terminationStatus == 1 { return false }
            return nil
        } catch {
            return nil
        }
    }

    nonisolated private static func observeRavenAgent() -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["list", "eden.bifrost.raven-bridge"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return "offline" }
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(),
                                encoding: .utf8) ?? ""
            for row in output.split(separator: "\n") where row.contains("\"PID\"") {
                let fragments = row.split(separator: "=", maxSplits: 1)
                if fragments.count == 2,
                   let pid = Int(fragments[1].trimmingCharacters(in: .whitespacesAndNewlines)
                                            .trimmingCharacters(in: CharacterSet(charactersIn: "; "))),
                   pid > 0 {
                    return "running"
                }
            }
            return "offline"
        } catch {
            return "unknown"
        }
    }

    private func launchctl(_ arguments: [String]) -> (Int32, String) {
        let process = Process()
        let stderr = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        process.standardOutput = Pipe()
        process.standardError = stderr
        do {
            try process.run()
            process.waitUntilExit()
            let message = String(data: stderr.fileHandleForReading.readDataToEndOfFile(),
                                 encoding: .utf8) ?? ""
            return (process.terminationStatus, message.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch {
            return (1, error.localizedDescription)
        }
    }

    /// Start from the installed bundle, but copy runtime to a stable location.
    /// Closing or quitting the GUI therefore cannot remove the headless code.
    func start() {
        // Do not overwrite an already-running independent Headless runtime.
        // A stale GUI health observation is not sufficient to decide ownership:
        // query the actual launchd job before copying any runtime files.
        if launchctl(["print", "gui/\(getuid())/\(label)"]).0 == 0 {
            feedback = "BIFROST Headless is already registered with launchd"
            refresh()
            return
        }
        let fm = FileManager.default
        do {
            guard let resource = Bundle.main.resourceURL?
                .appendingPathComponent("headless", isDirectory: true),
                fm.fileExists(atPath: resource.appendingPathComponent("server.py").path) else {
                throw NSError(domain: "BIFROST", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "Bundled Headless runtime unavailable"])
            }
            try fm.createDirectory(at: supportURL, withIntermediateDirectories: true)
            if fm.fileExists(atPath: runtimeURL.path) {
                try fm.removeItem(at: runtimeURL)
            }
            try fm.copyItem(at: resource, to: runtimeURL)
            let candidates = ["/opt/homebrew/bin/python3", "/usr/local/bin/python3", "/usr/bin/python3"]
            guard let interpreter = candidates.first(where: { fm.isExecutableFile(atPath: $0) }) else {
                throw NSError(domain: "BIFROST", code: 2,
                              userInfo: [NSLocalizedDescriptionKey: "Python 3 is unavailable"])
            }
            let agent: [String: Any] = [
                "Label": label,
                "ProgramArguments": [interpreter, runtimeURL.appendingPathComponent("server.py").path],
                "WorkingDirectory": runtimeURL.path,
                "RunAtLoad": true,
                "KeepAlive": true,
                "ThrottleInterval": 10,
                "StandardOutPath": supportURL.appendingPathComponent("headless.stdout.log").path,
                "StandardErrorPath": supportURL.appendingPathComponent("headless.stderr.log").path
            ]
            let plist = try PropertyListSerialization.data(fromPropertyList: agent,
                                                           format: .xml, options: 0)
            try fm.createDirectory(at: launchAgentURL.deletingLastPathComponent(),
                                   withIntermediateDirectories: true)
            try plist.write(to: launchAgentURL, options: .atomic)
            let (code, message) = launchctl(["bootstrap", "gui/\(getuid())", launchAgentURL.path])
            feedback = code == 0 ? "Headless launch requested · verifying status" : "Headless start failed: \(message)"
        } catch {
            feedback = "Headless start failed: \(error.localizedDescription)"
        }
        refreshSoon()
    }

    /// Only the BIFROST launch agent is stopped; RavenNest and other Apps remain running.
    @discardableResult
    func stop() -> Bool {
        // Only the dedicated BIFROST launchd label is affected. No
        // unrelated caffeinate, RavenNest or provider process is signaled.
        let (code, message) = launchctl(["bootout", "gui/\(getuid())/\(label)"])
        guard code == 0 else {
            feedback = "Could not stop Headless: \(message)"
            refreshSoon()
            return false
        }
        // A stop-and-quit operation is permitted only after launchd confirms
        // that the old BIFROST service label is no longer registered.
        if launchctl(["print", "gui/\(getuid())/\(label)"]).0 == 0 {
            feedback = "Headless shutdown still pending; interface remains open"
            refreshSoon()
            return false
        }
        try? FileManager.default.removeItem(at: launchAgentURL)
        feedback = "BIFROST Headless stopped; RavenNest unchanged"
        isRegisteredWithLaunchd = false
        isRunning = false
        stateMessage = "Not connected"
        taskStatus = "unknown"
        activeTasks = nil
        caffeinateActive = false
        refreshSoon()
        return true
    }

    func openWeb() {
        guard isRunning else {
            feedback = "Start Headless to open the local dashboard"
            return
        }
        NSWorkspace.shared.open(baseURL)
    }

    func startCaffeinate() {
        control("caffeinate.start", duration: preferences.caffeinateMinutes)
    }

    func stopCaffeinate() { control("caffeinate.stop") }

    func refreshTasks() { control("tasks.refresh") }

    private func control(_ action: String, duration: Int? = nil) {
        Task { @MainActor in
            do {
                let (sessionData, _) = try await URLSession.shared.data(
                    from: baseURL.appendingPathComponent("api/session"))
                guard let session = try JSONSerialization.jsonObject(with: sessionData) as? [String: Any],
                      let token = session["token"] as? String else {
                    throw URLError(.userAuthenticationRequired)
                }
                var command: [String: Any] = ["action": action]
                if let duration { command["minutes"] = duration }
                var request = URLRequest(url: baseURL.appendingPathComponent("api/control"))
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(token, forHTTPHeaderField: "X-Bifrost-Token")
                request.httpBody = try JSONSerialization.data(withJSONObject: command)
                let (data, response) = try await URLSession.shared.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    let payload = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
                    throw NSError(domain: "BIFROST", code: 3,
                                  userInfo: [NSLocalizedDescriptionKey: payload?["error"] as? String ?? "Action rejected"])
                }
                feedback = "Headless accepted: \(action)"
                refresh()
            } catch {
                feedback = "Headless action failed: \(error.localizedDescription)"
                refresh()
            }
        }
    }

    private func refreshSoon() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))
            refresh()
        }
    }
}
