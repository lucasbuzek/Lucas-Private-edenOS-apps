import Foundation
import Combine

// Local Apple workflow adapter. Intentionally does not install, edit, schedule,
// discover credentials for, or automatically invoke any workflow.
struct BifrostNativeWorkflow: Identifiable, Sendable {
    let name: String
    let path: String
    var id: String { path }
}

enum BifrostNativeWorkflowCatalog {
    static func automatorWorkflows(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> [BifrostNativeWorkflow] {
        let fm = FileManager.default
        let allowed = [
            home.appendingPathComponent("Library/Services", isDirectory: true),
            home.appendingPathComponent("Library/Workflows/Applications/Finder", isDirectory: true)
        ]
        var entries: [BifrostNativeWorkflow] = []
        for directory in allowed {
            guard let contents = try? fm.contentsOfDirectory(
                at: directory, includingPropertiesForKeys: [.isSymbolicLinkKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }
            for url in contents.sorted(by: { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }) {
                if entries.count >= 100 { break }
                guard url.pathExtension.lowercased() == "workflow",
                      let values = try? url.resourceValues(forKeys: [.isSymbolicLinkKey, .isDirectoryKey]),
                      values.isSymbolicLink == false, values.isDirectory == true else { continue }
                entries.append(.init(name: url.deletingPathExtension().lastPathComponent, path: url.path))
            }
        }
        return entries
    }

    static func canRunShortcut(_ name: String, known: [String]) -> Bool {
        guard !name.isEmpty, name.utf8.count <= 160,
              !name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) })
        else { return false }
        return known.contains(name)
    }

    static func canRunAutomator(_ workflow: BifrostNativeWorkflow,
                                discovered: [BifrostNativeWorkflow],
                                home: URL = FileManager.default.homeDirectoryForCurrentUser) -> Bool {
        guard discovered.contains(where: { $0.path == workflow.path && $0.name == workflow.name }),
              workflow.name.utf8.count <= 160 else { return false }
        let file = URL(fileURLWithPath: workflow.path).standardizedFileURL
        let roots = [
            home.appendingPathComponent("Library/Services").standardizedFileURL,
            home.appendingPathComponent("Library/Workflows/Applications/Finder").standardizedFileURL
        ]
        guard roots.contains(where: { $0.path == file.deletingLastPathComponent().path }),
              file.pathExtension.lowercased() == "workflow",
              let values = try? file.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey]),
              values.isDirectory == true, values.isSymbolicLink == false else { return false }
        return true
    }

    static func runAutomator(_ workflow: BifrostNativeWorkflow,
                             discovered: [BifrostNativeWorkflow]) -> String {
        guard canRunAutomator(workflow, discovered: discovered) else {
            return "Refused: Automator workflow is not an approved saved workflow."
        }
        let process = Process()
        let finished = DispatchSemaphore(value: 0)
        process.executableURL = URL(fileURLWithPath: "/usr/bin/automator")
        process.arguments = [workflow.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        process.terminationHandler = { _ in finished.signal() }
        do { try process.run() }
        catch { return "Automator could not start. No workflow result verified." }
        guard finished.wait(timeout: .now() + .seconds(60)) == .success else {
            if process.isRunning { process.terminate() }
            return "Automator command timed out. Any external changes must be checked separately."
        }
        return process.terminationStatus == 0
            ? "Automator reported completion. Workflow effects have not been independently verified."
            : "Automator failed (exit \(process.terminationStatus)). No workflow result verified."
    }

    // One exact user-confirmed action, no shell interpolation, no captured
    // shortcut results/secrets, and bounded waiting. Exit 0 is provider
    // completion only, not independent workflow postcondition verification.
    static func runShortcut(_ name: String, known: [String]) -> String {
        guard canRunShortcut(name, known: known) else {
            return "Refused: shortcut was not in the discovered catalog."
        }
        let process = Process()
        let finished = DispatchSemaphore(value: 0)
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["run", name]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        process.terminationHandler = { _ in finished.signal() }
        do { try process.run() }
        catch { return "Shortcut could not start. No result verified." }
        guard finished.wait(timeout: .now() + .seconds(60)) == .success else {
            if process.isRunning { process.terminate() }
            return "Shortcut command timed out. Any actions already started inside Shortcuts must be checked separately."
        }
        return process.terminationStatus == 0
            ? "Shortcuts reported successful completion. Workflow effects have not been independently verified."
            : "Shortcuts command failed (exit \(process.terminationStatus)). No workflow result verified."
    }
}

@MainActor final class BifrostNativeWorkflowRunner: ObservableObject {
    @Published private(set) var running = false
    @Published private(set) var status = "No workflow started."
    @Published private(set) var automatorItems: [BifrostNativeWorkflow] = []

    func refreshAutomator() {
        automatorItems = BifrostNativeWorkflowCatalog.automatorWorkflows()
    }

    func runConfirmedAutomator(_ workflow: BifrostNativeWorkflow) {
        guard !running else { return }
        let items = automatorItems
        guard BifrostNativeWorkflowCatalog.canRunAutomator(workflow, discovered: items) else {
            status = "Automator workflow changed or is no longer approved. Inspect again."
            return
        }
        running = true
        status = "Running selected Automator workflow…"
        Task {
            let result = await Task.detached(priority: .userInitiated) {
                BifrostNativeWorkflowCatalog.runAutomator(workflow, discovered: items)
            }.value
            running = false
            status = result
        }
    }

    func runConfirmedShortcut(_ name: String, discovered: [String]) {
        guard !running else { return }
        guard BifrostNativeWorkflowCatalog.canRunShortcut(name, known: discovered) else {
            status = "Shortcut is no longer in the current catalog; refresh and select again."
            return
        }
        running = true
        status = "Running selected Shortcut…"
        Task {
            let result = await Task.detached(priority: .userInitiated) {
                BifrostNativeWorkflowCatalog.runShortcut(name, known: discovered)
            }.value
            running = false
            status = result
        }
    }
}
