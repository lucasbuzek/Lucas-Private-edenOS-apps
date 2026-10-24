import SwiftUI
import AppKit

@MainActor final class BIFROSTNativeAppLauncher: ObservableObject {
    @Published private(set) var status = ""

    private let expectedBundleID = BIFROSTNativeAppLocation.nativeBundleID

    private func validated(_ url: URL) -> URL? {
        BIFROSTNativeAppLocation.validated(url)
    }

    private func findApp() -> URL? {
        if let chosen = BIFROSTNativeAppLocation.approved() {
            return chosen
        }
        // Flat Releases may contain many accepted historical candidates.
        // First prefer the exact release partner with our own dated suffix;
        // do not pick "newest", overwrite an earlier candidate, or launch a
        // random same-identifier app merely because it shares a directory.
        let parent = Bundle.main.bundleURL.deletingLastPathComponent()
        let menuName = Bundle.main.bundleURL.lastPathComponent
        if menuName.hasPrefix("BIFROST_Menu_") {
            // Preserve the original VersionZero companion route while also
            // pairing the current Orchestration / Automation named releases.
            // Exact bundle identity is verified before requesting a launch.
            let suffix = String(menuName.dropFirst("BIFROST_Menu_".count))
            for partnerName in ["BIFROST_" + suffix,
                                "BIFROST_VersionZero_" + suffix] {
                if let verified = validated(parent.appendingPathComponent(partnerName)) {
                    return verified
                }
            }
        }
        if let registered = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: expectedBundleID
        ), let verified = validated(registered) {
            return verified
        }
        let candidates = (try? FileManager.default.contentsOfDirectory(
            at: parent,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ))?.filter {
            $0.pathExtension.lowercased() == "app" &&
            $0.lastPathComponent.hasPrefix("BIFROST_")
        }.compactMap(validated) ?? []
        return candidates.count == 1 ? candidates[0] : nil
    }

    func open() {
        guard let nativeApp = findApp() else {
            status = "BIFROST not located. Select the authorized BIFROST app."
            return
        }
        NSWorkspace.shared.openApplication(
            at: nativeApp,
            configuration: NSWorkspace.OpenConfiguration()
        ) { _, error in
            Task { @MainActor in
                self.status = error.map { "Open failed: \($0.localizedDescription)" }
                    ?? "macOS accepted the BIFROST launch request."
            }
        }
    }

    func chooseApp() {
        let panel = NSOpenPanel()
        panel.title = "Select the existing BIFROST native application"
        panel.message = "Only the app with bundle identifier eden.private.bifrost is accepted."
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsOtherFileTypes = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let selection = panel.url else { return }
        do {
            let approved = try BIFROSTNativeAppLocation.approve(selection)
            status = "Approved BIFROST app: \(approved.lastPathComponent). Not launched."
        } catch {
            status = "Could not approve BIFROST app: \(error.localizedDescription)"
        }
    }
}

struct BIFROSTMenuControllerView: View {
    @ObservedObject var headless: HeadlessClient
    @ObservedObject var peers: BifrostObservedPeerRegistry
    @AppStorage("bifrost.menu.level") private var menuLevel = "Simple"
    @AppStorage("bifrost.menu.peerSummary") private var showPeerSummary = true
    @AppStorage("bifrost.menu.animateBridge") private var animateBridge = true
    @StateObject private var launcher = BIFROSTNativeAppLauncher()
    @AppStorage("bifrost.menu.showTitle") private var showTitle = true
    @AppStorage("bifrost.menu.showHeadlessState") private var showHeadlessState = true
    @AppStorage("bifrost.menu.showDashboard") private var showDashboard = true
    @AppStorage("bifrost.menu.showKeepAwake") private var showKeepAwake = true
    @AppStorage("bifrost.menu.showAppSelection") private var showAppSelection = true

    var body: some View {
        Group {
            Text("BIFROST · CONNECT · KEEP · RESOLVE")
            Text(headless.isRunning ? "Headless · Running" :
                 headless.isRegisteredWithLaunchd == true ?
                 "Headless · Registered but unreachable" :
                 "Headless · Stopped")
            Divider()
            Button {
                launcher.open()
            } label: {
                Label("Open BIFROST App", systemImage: "macwindow")
            }
            if showAppSelection {
                Button("Locate Existing BIFROST App…") {
                    launcher.chooseApp()
                }
            }
            Divider()

            if headless.isRunning || headless.isRegisteredWithLaunchd == true {
                Button(role: .destructive) {
                    confirmStop()
                } label: {
                    Label("Stop Headless…", systemImage: "stop.circle")
                }
            } else {
                Button {
                    headless.start()
                } label: {
                    Label("Start Headless", systemImage: "play.circle")
                }
            }
            if showDashboard && headless.isRunning {
                Button {
                    headless.openWeb()
                } label: {
                    Label("Open Local Dashboard", systemImage: "rectangle.on.rectangle")
                }
            }
            if showKeepAwake {
                Menu {
                    Text(headless.caffeinateActive ? "BIFROST Caffeinate · Running" :
                         headless.systemCaffeinateObserved == true ?
                         "External Caffeinate · Not controlled" :
                         "BIFROST Caffeinate · Stopped")
                    if headless.caffeinateActive {
                        Button("Stop BIFROST Keep Awake") { headless.stopCaffeinate() }
                    } else if headless.systemCaffeinateObserved != true {
                        Button("Start BIFROST Keep Awake") { headless.startCaffeinate() }
                            .disabled(!headless.isRunning)
                    }
                    Divider()
                    ForEach([30, 60, 120, 0], id: \.self) { minutes in
                        Button {
                            headless.setCaffeinateMinutes(minutes)
                        } label: {
                            if headless.preferences.caffeinateMinutes == minutes {
                                Label(durationName(minutes), systemImage: "checkmark")
                            } else {
                                Text(durationName(minutes))
                            }
                        }
                    }
                } label: {
                    Label("Keep Awake", systemImage: "moon.zzz")
                }
            }

            Divider()
            Menu {
                ForEach(["Simple", "Advanced", "Expert"], id: \.self) { level in
                    Button {
                        menuLevel = level
                        if level != "Simple" { peers.refresh() }
                    } label: {
                        if menuLevel == level {
                            Label(level, systemImage: "checkmark")
                        } else {
                            Text(level)
                        }
                    }
                }
            } label: {
                Label("Menu experience · " + menuLevel, systemImage: "rectangle.split.3x1")
            }
            if menuLevel != "Simple" {
                BifrostPeerMenu(peers: peers, expert: menuLevel == "Expert")
                Button {
                    headless.inspectCoreRuntime()
                } label: {
                    Label("Inspect BIFROSTcore…", systemImage: "server.rack")
                }
                .disabled(!headless.isRunning)
                if headless.coreRuntimeFeedback != "Not inspected" {
                    Text(headless.coreRuntimeFeedback)
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Menu {
                Toggle("Show BIFROST title", isOn: $showTitle)
                Toggle("Show observed peer count", isOn: $showPeerSummary)
                Toggle("Subtle active bridge pulse", isOn: $animateBridge)
                Toggle("Show Headless indicator", isOn: $showHeadlessState)
                Toggle("Show Local Dashboard action", isOn: $showDashboard)
                Toggle("Show Keep Awake", isOn: $showKeepAwake)
                Toggle("Show app-location selector", isOn: $showAppSelection)
            } label: {
                Label("Customize Menu Bar", systemImage: "slider.horizontal.3")
            }
            Button {
                headless.refresh()
                if menuLevel != "Simple" { peers.refresh() }
            } label: {
                Label("Refresh Headless Status", systemImage: "arrow.clockwise")
            }
            if !launcher.status.isEmpty {
                Text(launcher.status)
            }
            if !headless.feedback.isEmpty {
                Text(headless.feedback)
            }
            Divider()
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit Menu Controller · Keep Headless", systemImage: "xmark")
            }
        }
        .onAppear {
            headless.refresh()
            if menuLevel != "Simple" { peers.refresh() }
        }
    }

    private func durationName(_ minutes: Int) -> String {
        minutes == 0 ? "Until stopped" : "\(minutes) minutes"
    }

    private func confirmStop() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Stop local BIFROST Headless?"
        alert.informativeText = "Only the verified eden.bifrost.headless launchd service will be stopped. The full BIFROST application, other EDEN apps and external Caffeinate processes are unaffected."
        alert.addButton(withTitle: "Stop Headless")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            _ = headless.stop()
        }
    }
}
