import SwiftUI
import AppKit

struct BIFROSTMenuControllerView: View {
    @ObservedObject var headless: HeadlessClient
    @ObservedObject var peers: BifrostObservedPeerRegistry
    @AppStorage("bifrost.menu.level") private var menuLevel = "Simple"
    @AppStorage("bifrost.menu.peerSummary") private var showPeerSummary = true
    @AppStorage("bifrost.menu.animateBridge") private var animateBridge = true
    @Environment(\.openWindow) private var openWindow
    @AppStorage("bifrost.menu.showTitle") private var showTitle = true
    @AppStorage("bifrost.menu.showHeadlessState") private var showHeadlessState = true
    @AppStorage("bifrost.menu.showDashboard") private var showDashboard = true
    @AppStorage("bifrost.menu.showKeepAwake") private var showKeepAwake = true

    var body: some View {
        Group {
            Text("BIFROST · CONNECT · KEEP · RESOLVE")
            Text(headless.isRunning ? "Headless · Running" :
                 headless.isRegisteredWithLaunchd == true ?
                 "Headless · Registered but unreachable" :
                 "Headless · Stopped")
            Divider()
            Button {
                openWindow(id: "main")
                NSApplication.shared.activate(ignoringOtherApps: true)
            } label: {
                Label("Open BIFROST App", systemImage: "macwindow")
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
                    if headless.caffeinateActive {
                        Text("BIFROST Keep Awake · Active")
                        if let until = headless.awakeUntil {
                            Text("Ends at \(until.formatted(date: .omitted, time: .shortened))")
                            Text(until, style: .timer)
                        } else {
                            Text("Active until stopped")
                        }
                        Button("Stop BIFROST Keep Awake") { headless.stopCaffeinate() }
                    } else if headless.systemCaffeinateObserved == true {
                        Text("External Caffeinate · Not controlled")
                    } else {
                        Text("BIFROST Keep Awake · Inactive")
                    }
                    Divider()
                    ForEach([30, 60, 120, 0], id: \.self) { minutes in
                        Button(durationName(minutes)) {
                            headless.activateCaffeinate(minutes: minutes)
                        }
                        .disabled(!canStartKeepAwake)
                    }
                    Menu {
                        ForEach([5, 10, 15, 45, 90, 180, 240, 360, 480], id: \.self) { minutes in
                            Button(durationName(minutes)) {
                                headless.activateCaffeinate(minutes: minutes)
                            }
                            .disabled(!canStartKeepAwake)
                        }
                    } label: {
                        Text("More durations")
                    }
                    if !headless.isRunning {
                        Text("Choosing a duration starts BIFROST Headless on this Mac")
                    }
                } label: {
                    Label(headless.caffeinateActive ? "Keep Awake · Active" : "Keep Awake",
                          systemImage: headless.caffeinateActive ? "sun.max.fill" : "sun.max")
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
            } label: {
                Label("Customize Menu Bar", systemImage: "slider.horizontal.3")
            }
            Button {
                headless.refresh()
                if menuLevel != "Simple" { peers.refresh() }
            } label: {
                Label("Refresh Headless Status", systemImage: "arrow.clockwise")
            }
            if !headless.feedback.isEmpty {
                Text(headless.feedback)
            }
            Divider()
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit BIFROST App · Keep Headless", systemImage: "xmark")
            }
        }
        .onAppear {
            headless.refresh()
            if menuLevel != "Simple" { peers.refresh() }
        }
    }

    private var canStartKeepAwake: Bool {
        headless.systemCaffeinateObserved != true || headless.caffeinateActive
    }

    private func durationName(_ minutes: Int) -> String {
        if minutes == 0 { return "Until stopped" }
        if minutes < 60 { return "\(minutes) minutes" }
        if minutes.isMultiple(of: 60) {
            let hours = minutes / 60
            return "\(hours) hour" + (hours == 1 ? "" : "s")
        }
        return "\(minutes / 60) h \(minutes % 60) min"
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
