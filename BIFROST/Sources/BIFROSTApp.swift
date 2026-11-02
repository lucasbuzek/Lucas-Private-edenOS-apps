import SwiftUI
import AppKit

/// One user-facing BIFROST application owns both the main workspace and
/// the rainbow status item. Only its opt-in Headless service runs separately.
@main
struct BIFROSTApp: App {
    @StateObject private var system = BifrostSystem()
    @StateObject private var permissions = BifrostPermissionCenter()
    @StateObject private var peers = BifrostObservedPeerRegistry()

    var body: some Scene {
        WindowGroup("BIFROST", id: "main") {
            RootView()
                .preferredColorScheme(.dark)
                .environmentObject(system)
                .environmentObject(system.headless)
                .environmentObject(permissions)
        }
        .defaultSize(width: 1180, height: 760)

        MenuBarExtra {
            BIFROSTMenuControllerView(headless: system.headless, peers: peers)
        } label: {
            BIFROSTStatusLabel(headless: system.headless, peers: peers)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .preferredColorScheme(.dark)
                .environmentObject(system)
                .environmentObject(system.headless)
                .environmentObject(permissions)
        }
    }
}

/// The menu label reflects the exact same HeadlessClient as the full window.
/// Rainbow bridge is a native multi-color SwiftUI shape, not a template SF icon.
private struct BIFROSTStatusLabel: View {
    @ObservedObject var headless: HeadlessClient
    @ObservedObject var peers: BifrostObservedPeerRegistry
    @AppStorage("bifrost.menu.level") private var menuLevel = "Simple"
    @AppStorage("bifrost.menu.peerSummary") private var showPeerSummary = true
    @AppStorage("bifrost.menu.animateBridge") private var animateBridge = true
    @AppStorage("bifrost.menu.showTitle") private var showTitle = true
    @AppStorage("bifrost.menu.showHeadlessState") private var showHeadlessState = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            if animateBridge && headless.isRunning && !reduceMotion &&
                !ProcessInfo.processInfo.isLowPowerModeEnabled {
                TimelineView(.periodic(from: .now, by: 3)) { tick in
                    BifrostBridgeSymbol(width: 24, height: 18)
                        .opacity(Int(tick.date.timeIntervalSince1970 / 3) % 2 == 0 ? 1.0 : 0.75)
                }
            } else {
                BifrostBridgeSymbol(width: 24, height: 18)
            }
            if showTitle {
                Text("BIFROST").font(.system(size: 12, weight: .semibold))
            }
            if menuLevel != "Simple" && showPeerSummary && peers.hasFreshObservation {
                Text("·\(peers.observedRunningCount)")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            if headless.caffeinateActive {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.orange)
                    .accessibilityLabel("BIFROST Keep Awake active")
            }
            if showHeadlessState {
                Image(systemName:
                    headless.isRunning ? "circle.fill" :
                    headless.isRegisteredWithLaunchd == true
                        ? "exclamationmark.circle.fill" : "circle")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(
                        headless.isRunning ? .green :
                        headless.isRegisteredWithLaunchd == true ? .orange : .secondary
                    )
            }
        }
        .accessibilityLabel(
            "BIFROST · Keep Awake " +
            (headless.caffeinateActive ? "active" : "inactive") + " · Headless " +
            (headless.isRunning ? "running" :
             headless.isRegisteredWithLaunchd == true ? "registered but unreachable" : "stopped") +
            (menuLevel != "Simple" && peers.hasFreshObservation
                ? " · \(peers.observedRunningCount) other processes observed, health unverified" : "")
        )
    }
}

enum Complexity: String, CaseIterable, Identifiable {
    case simple = "Simple", advanced = "Advanced", expert = "Expert"
    var id: String { rawValue }
}
