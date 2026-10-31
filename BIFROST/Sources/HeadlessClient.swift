import SwiftUI
import AppKit
import CryptoKit
import Foundation

/// Shared configuration written to ~/Library/Application Support/BIFROST/settings.json.
/// The Python headless service reads the same settings, independent of this GUI.
struct HeadlessPreferences: Codable, Equatable {
    var statusIndicators: [String] = ["headless"]
    var caffeinateMinutes: Int = 60
    var dashboardSections: [String] = ["headless", "caffeinate"]
}

/// A durable local observation receipt, not a remote job.
struct BifrostLocalReceipt: Decodable, Identifiable {
    let taskId: String
    let kind: String
    let state: String
    let createdAt: Int64
    let execution: String
    let remoteExecutionVerified: Bool

    var id: String { taskId }
}

private struct BifrostLocalReceiptList: Decodable {
    let tasks: [BifrostLocalReceipt]
}

/// Verified observation contract, not an execution or migration receipt.
private struct BifrostCoreRuntimeObservation: Decodable {
    struct Component: Decodable {
        let state: String
        let health: String
    }
    struct Legacy: Decodable {
        let state: String
        let health: String
        let registration: String
    }
    struct Ownership: Decodable {
        let unifiedDatabase: Bool
        let migrationPerformed: Bool
    }
    let schema: String
    let mode: String
    let headless: Component
    let legacyCore: Legacy
    let stateOwnership: Ownership
}

@MainActor
final class HeadlessClient: ObservableObject {
    @Published private(set) var isRunning = false
    /// Whether our exact launchd service label is registered, independent
    /// of the HTTP health endpoint. A degraded service must remain stoppable.
    @Published private(set) var isRegisteredWithLaunchd: Bool? = nil
    @Published private(set) var stateMessage = "Checking Headless"
    @Published private(set) var caffeinateActive = false
    /// Observation only. A separate Caffeinate process may belong to the user
    /// and MUST NOT be stopped by Headless's Caffeinate controls.
    @Published private(set) var systemCaffeinateObserved: Bool? = nil
    @Published private(set) var awakeUntil: Date? = nil
    @Published private(set) var preferences: HeadlessPreferences
    @Published private(set) var feedback = ""
    @Published private(set) var localReceipts: [BifrostLocalReceipt] = []
    @Published private(set) var localLedgerFeedback = "No local check submitted"
    @Published private(set) var coreRuntimeFeedback = "Not inspected"
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
              var prefs = try? JSONDecoder().decode(HeadlessPreferences.self, from: data) else {
            return HeadlessPreferences()
        }
        // Respect older user preferences without reactivating any remote,
        // AI-provider or cloud-task settings saved by prior candidate builds.
        prefs.statusIndicators = prefs.statusIndicators.filter { $0 == "headless" }
        prefs.dashboardSections = prefs.dashboardSections.filter {
            ["headless", "caffeinate"].contains($0)
        }
        if ![0, 5, 10, 15, 30, 45, 60, 90, 120, 180, 240, 360, 480].contains(prefs.caffeinateMinutes) {
            prefs.caffeinateMinutes = 60
        }
        return prefs
    }

    var menuBarTitle: String {
        var parts: [String] = []
        if preferences.statusIndicators.contains("headless") {
            parts.append(isRunning ? "H●" : "H○")
        }
        return parts.joined(separator: " · ")
    }

    func setHeadlessIndicator(_ enabled: Bool) {
        update { prefs in
            prefs.statusIndicators.removeAll(where: { $0 == "headless" })
            if enabled { prefs.statusIndicators.insert("headless", at: 0) }
        }
    }

    func setCaffeinateMinutes(_ minutes: Int) {
        guard [0, 5, 10, 15, 30, 45, 60, 90, 120, 180, 240, 360, 480].contains(minutes) else { return }
        update { $0.caffeinateMinutes = minutes }
    }

    func setDashboardSection(_ section: String, enabled: Bool) {
        guard ["headless", "caffeinate"].contains(section) else { return }
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
        // Observe only local resources. External plugin services are managed
        // by their own projects, never polled or started by BIFROST Headless.
        Task.detached(priority: .utility) { [weak self] in
            let systemAwake = Self.observeCaffeinateProcess()
            let serviceRegistered = Self.observeHeadlessLaunchdRegistration()
            await MainActor.run {
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
                // A 200 response on loopback does not prove that this App's
                // installed Headless build owns the port. Validate product,
                // runtime location and on-disk source identity before trusting it.
                let runtimePath = runtimeURL.resolvingSymlinksInPath().path
                let expectedRuntimeId = String(SHA256.hash(data: Data(runtimePath.utf8))
                    .map { String(format: "%02x", $0) }.joined().prefix(16))
                guard let identity = headless["identity"] as? [String: Any],
                      identity["schema"] as? String == "bifrost.headless.identity.v1",
                      identity["productId"] as? String == "eden.bifrost.headless",
                      identity["runtimeId"] as? String == expectedRuntimeId,
                      let sourceData = try? Data(contentsOf: runtimeURL.appendingPathComponent("server.py")),
                      let runningSource = identity["sourceSha256"] as? String,
                      SHA256.hash(data: sourceData)
                        .map({ String(format: "%02x", $0) }).joined() == runningSource else {
                    isRunning = false
                    stateMessage = "Unverified Headless identity on localhost"
                    coreRuntimeFeedback = "Core observation stale · Headless identity unverified"
                    caffeinateActive = false
                    awakeUntil = nil
                    return
                }
                isRunning = true
                stateMessage = "Running"
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
                coreRuntimeFeedback = "Core observation stale · Headless disconnected"
                caffeinateActive = false
                awakeUntil = nil
                localReceipts = []
                localLedgerFeedback = "Headless disconnected; local receipts hidden"
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
        if isRunning {
            feedback = "Headless is already running; reusing the existing process"
            return
        }
        if stateMessage == "Unverified Headless identity on localhost" {
            feedback = "Refusing to replace an unknown process at the Headless port"
            return
        }
        // Do not overwrite an already-running independent Headless runtime.
        // A stale GUI health observation is not sufficient to decide ownership:
        // query the actual launchd job before copying any runtime files.
        if launchctl(["print", "gui/\(getuid())/\(label)"]).0 == 0 {
            feedback = "BIFROST Headless is already registered with launchd"
            refresh()
            return
        }
        let fm = FileManager.default
        let staged = supportURL.appendingPathComponent("runtime.staging." + UUID().uuidString)
        let previous = supportURL.appendingPathComponent("runtime.recovery." + UUID().uuidString)
        var hadPreviousRuntime = false
        var promotedRuntime = false
        do {
            guard let resource = Bundle.main.resourceURL?
                .appendingPathComponent("headless", isDirectory: true),
                fm.fileExists(atPath: resource.appendingPathComponent("server.py").path) else {
                throw NSError(domain: "BIFROST", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "Bundled Headless runtime unavailable"])
            }
            // The adapter needs the portable kernel alongside server.py.
            // The bundle stores it in Resources/core, separately from headless.
            guard let portableKernel = Bundle.main.resourceURL?
                .appendingPathComponent("core/portable_kernel.py"),
                fm.isReadableFile(atPath: portableKernel.path),
                fm.isReadableFile(atPath: resource.appendingPathComponent("kernel_adapter.py").path) else {
                throw NSError(domain: "BIFROST", code: 3,
                              userInfo: [NSLocalizedDescriptionKey: "Bundled portable kernel adapter missing"])
            }
            try fm.createDirectory(at: supportURL, withIntermediateDirectories: true)
            try fm.copyItem(at: resource, to: staged)
            do {
                try fm.copyItem(at: portableKernel,
                                to: staged.appendingPathComponent("portable_kernel.py"))
                // Promote only after every import dependency is present. Preserve
                // the former runtime as a recovery artifact, never delete it.
                if fm.fileExists(atPath: runtimeURL.path) {
                    try fm.moveItem(at: runtimeURL, to: previous)
                    hadPreviousRuntime = true
                }
                do {
                    try fm.moveItem(at: staged, to: runtimeURL)
                    promotedRuntime = true
                } catch {
                    if fm.fileExists(atPath: previous.path) {
                        try? fm.moveItem(at: previous, to: runtimeURL)
                    }
                    throw error
                }
            } catch {
                if fm.fileExists(atPath: staged.path) {
                    try? fm.removeItem(at: staged)
                }
                throw error
            }
            let candidates = ["/opt/homebrew/bin/python3", "/usr/local/bin/python3", "/usr/bin/python3"]
            guard let interpreter = candidates.first(where: { fm.isExecutableFile(atPath: $0) }) else {
                throw NSError(domain: "BIFROST", code: 2,
                              userInfo: [NSLocalizedDescriptionKey: "Python 3 is unavailable"])
            }
            let agent: [String: Any] = [
                "Label": label,
                "ProgramArguments": [interpreter, runtimeURL.appendingPathComponent("server.py").path],
                "WorkingDirectory": runtimeURL.path,
                "RunAtLoad": false,
                "KeepAlive": false,
                "ThrottleInterval": 10,
                "StandardOutPath": supportURL.appendingPathComponent("headless.stdout.log").path,
                "StandardErrorPath": supportURL.appendingPathComponent("headless.stderr.log").path
            ]
            let plist = try PropertyListSerialization.data(fromPropertyList: agent,
                                                           format: .xml, options: 0)
            try fm.createDirectory(at: launchAgentURL.deletingLastPathComponent(),
                                   withIntermediateDirectories: true)
            try plist.write(to: launchAgentURL, options: .atomic)
            let target = "gui/\(getuid())/\(label)"
            // RunAtLoad=false: only the visible user action activates Headless.
            // Keep the launchd label disabled across logins.
            let (enableCode, enableError) = launchctl(["enable", target])
            guard enableCode == 0 else {
                throw NSError(domain: "BIFROST", code: 4,
                              userInfo: [NSLocalizedDescriptionKey: "Could not enable manual Headless session: \(enableError)"])
            }
            let (code, message) = launchctl(["bootstrap", "gui/\(getuid())", launchAgentURL.path])
            guard code == 0 else {
                throw NSError(domain: "BIFROST", code: 5,
                              userInfo: [NSLocalizedDescriptionKey: "launchd bootstrap failed: \(message)"])
            }
            let (kickCode, kickError) = launchctl(["kickstart", target])
            guard kickCode == 0 else {
                throw NSError(domain: "BIFROST", code: 6,
                              userInfo: [NSLocalizedDescriptionKey: "Headless manual start failed: \(kickError)"])
            }
            let (disableCode, disableError) = launchctl(["disable", target])
            guard disableCode == 0 else {
                throw NSError(domain: "BIFROST", code: 7,
                              userInfo: [NSLocalizedDescriptionKey: "Could not restore disabled startup: \(disableError)"])
            }
            feedback = "Headless started by request · login startup disabled"
        } catch {
            // An unsuccessful launch may have left a partially registered job.
            // Return launchd to disabled, then clean only this Headless label.
            let target = "gui/\(getuid())/\(label)"
            _ = launchctl(["disable", target])
            if launchctl(["print", target]).0 == 0 {
                _ = launchctl(["bootout", target])
            }
            // An unsuccessful launch must not replace an existing runnable LKG.
            // Keep the failed candidate for diagnosis and restore the prior copy.
            if promotedRuntime && launchctl(["print", "gui/\(getuid())/\(label)"]).0 != 0,
               fm.fileExists(atPath: runtimeURL.path) {
                let failed = supportURL.appendingPathComponent("runtime.failed." + UUID().uuidString)
                try? fm.moveItem(at: runtimeURL, to: failed)
            }
            if hadPreviousRuntime && !fm.fileExists(atPath: runtimeURL.path),
               fm.fileExists(atPath: previous.path) {
                try? fm.moveItem(at: previous, to: runtimeURL)
            }
            if fm.fileExists(atPath: staged.path) {
                try? fm.removeItem(at: staged)
            }
            feedback = "Headless start failed: \(error.localizedDescription)"
        }
        refreshSoon()
    }

    /// Only the BIFROST Headless label is stopped; independent apps remain unchanged.
    @discardableResult
    func stop() -> Bool {
        // Only the dedicated BIFROST launchd label is affected. No
        // unrelated Caffeinate, app or plugin process is signaled.
        let target = "gui/\(getuid())/\(label)"
        let (disableCode, disableError) = launchctl(["disable", target])
        guard disableCode == 0 else {
            feedback = "Could not disable Headless login startup: \(disableError)"
            refreshSoon()
            return false
        }
        let (code, message) = launchctl(["bootout", target])
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
        feedback = "BIFROST Headless stopped; independent apps unchanged"
        isRegisteredWithLaunchd = false
        isRunning = false
        stateMessage = "Not connected"
        coreRuntimeFeedback = "Core observation stale · Headless stopped"
        caffeinateActive = false
        refreshSoon()
        return true
    }

    /// One on-demand BIFROSTcore observation, shared by App and Menu.
    /// Never triggers a legacy daemon start, provider login or state migration.
    func inspectCoreRuntime() {
        guard isRunning else {
            coreRuntimeFeedback = "Headless unavailable; no service started"
            return
        }
        coreRuntimeFeedback = "Inspecting verified local runtime…"
        Task { @MainActor in
            do {
                let token = try await localLedgerToken()
                var request = URLRequest(url: baseURL.appendingPathComponent("api/core/v1"))
                request.timeoutInterval = 4
                request.cachePolicy = .reloadIgnoringLocalCacheData
                request.setValue(token, forHTTPHeaderField: "X-Bifrost-Token")
                let (data, response) = try await URLSession.shared.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                let report = try JSONDecoder().decode(BifrostCoreRuntimeObservation.self, from: data)
                guard report.schema == "bifrost.core.runtime-state.v1",
                      report.mode == "read-only-federation",
                      report.headless.state == "identity-verified",
                      !report.stateOwnership.unifiedDatabase,
                      !report.stateOwnership.migrationPerformed else {
                    throw URLError(.cannotParseResponse)
                }
                coreRuntimeFeedback = "Observed at " +
                    Date().formatted(date: .omitted, time: .shortened) +
                    " · Headless identity verified · legacy Core " +
                    report.legacyCore.state + " (" + report.legacyCore.registration +
                    ") · databases separate"
            } catch {
                coreRuntimeFeedback = "Core status unavailable in current Headless; no service changed"
            }
        }
    }

    /// Display only LOCAL observation receipts from the owner-authenticated
    /// loopback API. The native UI never starts Headless during this read.
    func refreshLocalReceipts() {
        guard isRunning else {
            localReceipts = []
            localLedgerFeedback = "Start Headless manually to inspect local receipts"
            return
        }
        Task { @MainActor in
            do {
                let token = try await localLedgerToken()
                let listURL = baseURL.appendingPathComponent("api/tasks/v1")
                var components = URLComponents(url: listURL, resolvingAgainstBaseURL: false)!
                components.queryItems = [URLQueryItem(name: "limit", value: "8")]
                guard let url = components.url else { throw URLError(.badURL) }
                var request = URLRequest(url: url)
                request.timeoutInterval = 4
                request.cachePolicy = .reloadIgnoringLocalCacheData
                request.setValue(token, forHTTPHeaderField: "X-Bifrost-Token")
                let (data, response) = try await URLSession.shared.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    throw URLError(.userAuthenticationRequired)
                }
                let listing = try JSONDecoder().decode(BifrostLocalReceiptList.self, from: data)
                localReceipts = listing.tasks
                localLedgerFeedback = listing.tasks.isEmpty ?
                    "No local checks recorded" : "Recorded on this Mac only · not remote execution"
            } catch {
                localReceipts = []
                localLedgerFeedback = "Local receipts unavailable: \(error.localizedDescription)"
            }
        }
    }

    /// Called only from the user-visible Record local check button.
    func recordLocalObservation() {
        guard isRunning else {
            localLedgerFeedback = "Headless must be started manually first"
            return
        }
        Task { @MainActor in
            do {
                let token = try await localLedgerToken()
                var request = URLRequest(url: baseURL.appendingPathComponent("api/tasks/v1"))
                request.httpMethod = "POST"
                request.timeoutInterval = 4
                request.cachePolicy = .reloadIgnoringLocalCacheData
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(token, forHTTPHeaderField: "X-Bifrost-Token")
                let body: [String: String] = [
                    "kind": "local.status.snapshot",
                    "idempotencyKey": UUID().uuidString
                ]
                request.httpBody = try JSONEncoder().encode(body)
                let (data, response) = try await URLSession.shared.data(for: request)
                guard [200, 201].contains((response as? HTTPURLResponse)?.statusCode ?? 0),
                      let receipt = try? JSONDecoder().decode(BifrostLocalReceipt.self, from: data),
                      receipt.kind == "local.status.snapshot",
                      receipt.execution == "local-readonly-observation",
                      !receipt.remoteExecutionVerified else {
                    throw URLError(.badServerResponse)
                }
                localLedgerFeedback = "Recorded \(receipt.taskId) · no external task submitted"
                refreshLocalReceipts()
            } catch {
                localLedgerFeedback = "Could not record local check: \(error.localizedDescription)"
            }
        }
    }

    private func localLedgerToken() async throws -> String {
        var request = URLRequest(url: baseURL.appendingPathComponent("api/session"))
        request.timeoutInterval = 4
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              let values = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = values["token"] as? String, !token.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }
        return token
    }

    func openWeb() {
        guard isRunning else {
            feedback = "Start Headless to open the local dashboard"
            return
        }
        // Deliberate user invocation only; never hand this link to an
        // unrestricted default browser.
        guard let safari = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: "com.apple.Safari"
        ) else {
            feedback = "Safari unavailable. Use the BIFROST native local dashboard instead."
            return
        }
        NSWorkspace.shared.open(
            [baseURL], withApplicationAt: safari,
            configuration: NSWorkspace.OpenConfiguration(),
            completionHandler: nil
        )
    }

    func startCaffeinate() {
        control("caffeinate.start", duration: preferences.caffeinateMinutes)
    }

    /// Duration selection and activation are one user action.
    /// Refuse unverified Headless and external caffeinate ownership.
    func activateCaffeinate(minutes: Int) {
        guard [0, 5, 10, 15, 30, 45, 60, 90, 120, 180, 240, 360, 480].contains(minutes) else {
            feedback = "Unsupported Keep Awake duration"
            return
        }
        guard isRunning else {
            feedback = "Start BIFROST Headless before using Keep Awake"
            return
        }
        guard systemCaffeinateObserved != true || caffeinateActive else {
            feedback = "External Caffeinate is running; BIFROST will not take ownership"
            return
        }
        setCaffeinateMinutes(minutes)
        control("caffeinate.start", duration: minutes)
    }

    func stopCaffeinate() { control("caffeinate.stop") }

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
