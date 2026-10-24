import Foundation
import AppKit

struct BifrostCapability: Identifiable, Hashable {
    enum Kind: String {
        case native = "Native", automation = "Automation", eden = "EDEN", bridge = "Bridge"
    }
    let id: String
    let name: String
    let provider: String
    let kind: Kind
    let available: Bool
    let detail: String
}

private struct ShortcutSnapshot: Sendable {
    let names: [String]
    let status: String
}

@MainActor final class CapabilityRegistry: ObservableObject {
    @Published private(set) var items: [BifrostCapability] = []
    @Published private(set) var workItems: [BifrostWorkCapability] = []
    @Published private(set) var shortcuts: [String] = []
    @Published private(set) var shortcutsStatus = "Not checked"
    private var queryGeneration = 0

    func refresh() {
        var found: [BifrostCapability] = []
        func add(_ id: String, _ name: String, _ provider: String,
                 _ kind: BifrostCapability.Kind, _ ok: Bool, _ detail: String) {
            found.append(.init(id: id, name: name, provider: provider,
                               kind: kind, available: ok, detail: detail))
        }
        add("native.keepawake", "Keep Awake", "macOS", .native,
            FileManager.default.isExecutableFile(atPath: "/usr/bin/caffeinate"),
            "System power assertions managed by local Headless")
        add("native.automation", "AppleScript / Automator", "macOS", .automation,
            FileManager.default.isExecutableFile(atPath: "/usr/bin/osascript"),
            "Native automation · consent and TCC apply")
        add("native.shortcuts", "Shortcuts", "macOS", .automation,
            FileManager.default.isExecutableFile(atPath: "/usr/bin/shortcuts"),
            "App Intents and installed Shortcuts")
        for (id, name) in [("janitor", "JANITOR"), ("lingua", "LINGUA"), ("lector", "LECTOR")] {
            let url = NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: "eden.private.\(id)")
            add("eden.\(id)", name, name, .eden, url != nil,
                url == nil ? "Not registered on this Mac" : "Registered with macOS")
        }
        items = found
        workItems = BifrostWorkCapabilityProbe.discover()
        refreshShortcuts()
    }

    private func refreshShortcuts() {
        queryGeneration += 1
        let generation = queryGeneration
        guard FileManager.default.isExecutableFile(atPath: "/usr/bin/shortcuts") else {
            shortcuts = []
            shortcutsStatus = "Shortcuts command unavailable"
            return
        }
        shortcutsStatus = "Checking installed Shortcuts…"
        // Query on a utility thread. A stalled Shortcuts service must NEVER
        // block the native dashboard, menu bar, or refresh interaction.
        Task {
            let result = await Task.detached(priority: .utility) {
                Self.listShortcuts()
            }.value
            guard generation == self.queryGeneration else { return }
            shortcuts = result.names
            shortcutsStatus = result.status
        }
    }

    nonisolated private static func listShortcuts() -> ShortcutSnapshot {
        let process = Process()
        let output = Pipe()
        let errors = Pipe()
        let finished = DispatchSemaphore(value: 0)
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["list"]
        process.standardOutput = output
        process.standardError = errors
        process.terminationHandler = { _ in finished.signal() }
        do {
            try process.run()
        } catch {
            return .init(names: [], status: "Query failed · \(error.localizedDescription)")
        }

        guard finished.wait(timeout: .now() + .seconds(8)) == .success else {
            if process.isRunning { process.terminate() }
            return .init(names: [], status: "Shortcuts query timed out · retry Refresh")
        }
        let text = String(
            data: output.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        let err = String(
            data: errors.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if process.terminationStatus == 0 {
            let names = text.split(separator: "\n").map(String.init)
            return .init(names: names, status: "Query succeeded · \(names.count) shortcuts")
        }
        return .init(names: [], status: err.isEmpty
                     ? "Query failed · exit \(process.terminationStatus)"
                     : "Query failed · \(err)")
    }
}
