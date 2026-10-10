import Foundation
import AppKit

@MainActor final class JanitorProvider: ObservableObject {
    @Published private(set) var available = false
    @Published private(set) var version = "Not found"
    @Published private(set) var detail = "JANITOR unavailable"
    @Published private(set) var lastReport: URL?

    private let roots = [
        URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Downloads/JANITOR"),
        URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Downloads/JANITOR-v0.9.0-mode-separation-cloud-photos-candidate")
    ]

    var launcher: URL? { roots.map { $0.appendingPathComponent("JANITOR.command") }.first { FileManager.default.fileExists(atPath: $0.path) } }

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
        guard let launcher else { return }
        let script = "tell application \"Terminal\" to do script \"" + launcher.path.replacingOccurrences(of: "\"", with: "\\\"") + " " + argument + "\""
        let p = Process(); p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript"); p.arguments = ["-e", script]
        do { try p.run(); detail = "JANITOR \(argument) started" } catch { detail = "JANITOR failed: \(error.localizedDescription)" }
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
