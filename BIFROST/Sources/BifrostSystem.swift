import Foundation
import AppKit
import BifrostChatGPTApple

@MainActor final class BifrostSystem: ObservableObject {
    @Published var complexity: Complexity = .simple
    @Published var keepAwake = false
    @Published var lastMessage = "Ready"
    @Published var chatGPTClient: ChatGPTLocalProvider?
    let chatGPTThread = UUID().uuidString
    let discovery = DiscoveryService()
    let remote = RemoteDesktopProvider()
    let janitor = JanitorProvider()
    let capabilities = CapabilityRegistry()
    let apps = AppRegistry()
    private var awakeProcess: Process?

    init() { discovery.start(); refresh() }

    func refresh() {
        remote.refresh()
        janitor.refresh()
        capabilities.refresh(remote: remote)
        apps.refresh()
        keepAwake = hasBifrostSleepAssertion()
    }

    func setKeepAwake(_ enabled: Bool) {
        enabled ? startKeepAwake() : stopKeepAwake()
        refresh()
    }

    private func startKeepAwake() {
        guard awakeProcess?.isRunning != true else { return }
        let p = Process(); p.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        p.arguments = ["-dimsu"]
        do { try p.run(); awakeProcess = p; lastMessage = "Sleep prevention active" }
        catch { lastMessage = "Keep Awake failed: \(error.localizedDescription)" }
    }
    private func stopKeepAwake() {
        awakeProcess?.terminate(); awakeProcess = nil
        lastMessage = "Normal sleep restored"
    }

    private func hasBifrostSleepAssertion() -> Bool {
        guard let p = awakeProcess, p.isRunning else { return false }
        let probe = Process(); let pipe = Pipe()
        probe.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        probe.arguments = ["-g", "assertions"]
        probe.standardOutput = pipe
        do {
            try probe.run(); probe.waitUntilExit()
            let text = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            return text.contains("caffeinate") && p.isRunning
        } catch { return false }
    }
}
