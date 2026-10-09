import SwiftUI
import AppKit

/// BIFROST's real macOS status-bar menu.
///
/// Uses native NSMenu presentation through MenuBarExtra(.menu) instead of
/// custom dark popovers: legible at system text scaling, keyboard navigable,
/// visible status, and direct Headless controls without disclosure gates.
///
/// The menu is a view on BIFROST Headless; the GUI is not the service owner.
struct StatusMenu: View {
    @EnvironmentObject private var system: BifrostSystem
    @EnvironmentObject private var headless: HeadlessClient
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            Text("BIFROST · CONNECT · KEEP · RESOLVE")

            Text(headless.isRunning ? "Headless: Running" :
                 headless.isRegisteredWithLaunchd == true ?
                 "Headless: Registered · unreachable" : "Headless: Not connected")
            Text("RavenNest: " + ravenStatus)

            if headless.taskStatus == "observed" {
                Text("Active tasks: " + (headless.activeTasks.map(String.init) ?? "Unknown"))
            } else {
                Text("Active tasks: Not verified")
            }

            Divider()

            Button {
                openSection("Overview")
            } label: {
                Label("Open BIFROST", systemImage: "house")
            }
            Button {
                openSection("Devices")
            } label: {
                Label("Devices", systemImage: "desktopcomputer")
            }
            Button {
                openSection("Connections")
            } label: {
                Label("Connections", systemImage: "link")
            }
            Button {
                openSection("Capabilities")
            } label: {
                Label("Capabilities", systemImage: "square.grid.2x2")
            }

            Divider()

            Button {
                openSection("JANITOR")
            } label: {
                Label("JANITOR", systemImage: "paintbrush.pointed.fill")
            }
            Button {
                openSection("Settings")
            } label: {
                Label("Settings", systemImage: "gearshape")
            }

            Divider()

            if headless.isRunning {
                Button {
                    headless.openWeb()
                } label: {
                    Label("Open Headless Web", systemImage: "globe")
                }
            }

            if headless.isRunning || headless.isRegisteredWithLaunchd == true {
                Button(role: .destructive) {
                    confirmHeadlessShutdown(quitInterface: false)
                } label: {
                    Label("Stop Headless", systemImage: "stop.circle")
                }
            } else {
                Button {
                    headless.start()
                } label: {
                    Label("Start Headless", systemImage: "play.circle")
                }
            }

            Menu {
                Text(caffeinateStatus)

                if headless.caffeinateActive {
                    Button {
                        headless.stopCaffeinate()
                    } label: {
                        Label("Stop BIFROST Caffeinate", systemImage: "stop.circle")
                    }
                } else if headless.systemCaffeinateObserved == true {
                    Text("External Caffeinate — leave running")
                } else {
                    Button {
                        headless.startCaffeinate()
                    } label: {
                        Label("Start BIFROST Caffeinate", systemImage: "moon.zzz")
                    }
                    .disabled(!headless.isRunning)
                }

                Divider()

                Menu {
                    durationOption("30 minutes", minutes: 30)
                    durationOption("60 minutes", minutes: 60)
                    durationOption("120 minutes", minutes: 120)
                    durationOption("Until stopped", minutes: 0)
                } label: {
                    Label("Default duration", systemImage: "clock")
                }
            } label: {
                Label("Caffeinate & Sleep", systemImage: "moon.zzz")
            }

            Menu {
                Text("RavenNest: " + ravenStatus)
                Text("Mobile pairing: Unverified")
                Text("Remote Desktop: " + system.remote.state.rawValue)

                if system.remote.managedByBifrost {
                    Button("Stop BIFROST-owned Remote Desktop") {
                        system.remote.stop()
                        system.remote.refresh()
                    }
                } else if system.remote.state == .stopped {
                    Button("Start Remote Desktop") {
                        system.remote.start()
                        system.remote.refresh()
                    }
                }
            } label: {
                Label("Remote & Mobile", systemImage: "network")
            }

            Button {
                system.refresh()
            } label: {
                Label("Refresh Status", systemImage: "arrow.clockwise")
            }

            if !headless.feedback.isEmpty {
                Text("Last action: " + headless.feedback)
            }

            Divider()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit Interface · Keep Headless", systemImage: "xmark")
            }

            if headless.isRunning || headless.isRegisteredWithLaunchd == true {
                Button(role: .destructive) {
                    confirmHeadlessShutdown(quitInterface: true)
                } label: {
                    Label("Stop Headless & Quit Interface", systemImage: "power")
                }
            }
        }
        .onAppear {
            headless.refresh()
            system.remote.refresh()
        }
    }

    private var ravenStatus: String {
        switch headless.ravenBridge {
        case "running": return "Local agent running"
        case "offline": return "Local agent not running"
        default: return "Unknown"
        }
    }

    private var caffeinateStatus: String {
        if headless.caffeinateActive { return "BIFROST-owned Caffeinate active" }
        if headless.systemCaffeinateObserved == true {
            return "External Caffeinate active (not controlled)"
        }
        if headless.systemCaffeinateObserved == false { return "No process detected" }
        return "Caffeinate state unknown"
    }

    private func durationOption(_ title: String, minutes: Int) -> some View {
        Button {
            headless.setCaffeinateMinutes(minutes)
        } label: {
            if headless.preferences.caffeinateMinutes == minutes {
                Label(title, systemImage: "checkmark")
            } else {
                Text(title)
            }
        }
    }

    /// NSAlert works for system-native menus where SwiftUI confirmationDialog
    /// is not reliably presented when the menu closes after selection.
    private func confirmHeadlessShutdown(quitInterface: Bool) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = quitInterface ?
            "Stop BIFROST Headless and quit the interface?" :
            "Stop BIFROST Headless?"
        alert.informativeText = "BIFROST Headless will stop. RavenNest and external Caffeinate are independent and will not be stopped."
        alert.addButton(withTitle: quitInterface ? "Stop Headless & Quit" : "Stop Headless")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let stopped = headless.stop()
        if stopped && quitInterface {
            NSApplication.shared.terminate(nil)
        }
    }

    private func openSection(_ section: String) {
        system.selectedSection = section
        openWindow(id: "main")
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
