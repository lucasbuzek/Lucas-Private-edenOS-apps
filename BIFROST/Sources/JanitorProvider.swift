import Foundation
import AppKit

@MainActor final class JanitorProvider: ObservableObject {
    @Published private(set) var available = false
    @Published private(set) var version = "Not found"
    @Published private(set) var detail = "JANITOR unavailable"
    @Published private(set) var lastReport: URL?

    // JANITOR is a separate App and owns its own working core. BIFROST must
    // never launch an obsolete Download or arbitrarily select a legacy release.
    private var launcher: URL? {
        let canonical = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("edenOS/Software Development/JANITOR/JANITOR.command")
        return FileManager.default.isExecutableFile(atPath: canonical.path) ? canonical : nil
    }

    func refresh() {
        guard let launcher else { available = false; version = "Not found"; detail = "Install or locate JANITOR"; return }
        available = true
        version = runCapture(launcher.path, ["--version"]).trimmingCharacters(in: .whitespacesAndNewlines)
        detail = "Standalone JANITOR ready"
        refreshLatestReport()
    }

    func open() {
        guard let launcher else { return }
        NSWorkspace.shared.open(launcher)
    }
    func runQuickScan() { runInTerminal("quick") }
    func runDeveloperQuick() { runInTerminal("dev-quick") }
    func runFullScan() { runInTerminal("full") }
    func showReports() {
        let url = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Logs/JANITOR")
        NSWorkspace.shared.open(url)
    }

    private func runInTerminal(_ argument: String) {
        guard ["quick", "dev-quick", "full"].contains(argument), let launcher else {
            detail = "JANITOR command unavailable"
            return
        }
        // Pass arguments separately to AppleScript and let AppleScript perform
        // shell quoting. The canonical folder contains spaces; unquoted direct
        // script string interpolation would run the wrong command.
        let script = """
        on run args
            set commandPath to item 1 of args
            set scanMode to item 2 of args
            tell application "Terminal"
                do script ((quoted form of commandPath) & " " & (quoted form of scanMode))
                activate
            end tell
        end run
        """
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script, launcher.path, argument]
        do {
            try task.run()
            detail = "JANITOR \(argument) requested in Terminal; completion not yet verified"
        } catch {
            detail = "JANITOR launch failed: \(error.localizedDescription)"
        }
    }

    private func refreshLatestReport() {
        let dir = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Logs/JANITOR")
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        lastReport = files.filter { $0.pathExtension == "txt" }.max { a,b in
            ((try? a.resourceValues(forKeys:[.contentModificationDateKey]).contentModificationDate) ?? .distantPast) < ((try? b.resourceValues(forKeys:[.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
        }
    }

    private func runCapture(_ executable: String, _ arguments: [String]) -> String {
        let p = Process(); let pipe = Pipe(); p.executableURL = URL(fileURLWithPath: executable); p.arguments = arguments; p.standardOutput = pipe
        do { try p.run(); p.waitUntilExit(); return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "" } catch { return "" }
    }
}
