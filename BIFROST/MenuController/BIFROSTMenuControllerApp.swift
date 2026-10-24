import SwiftUI
import AppKit

/// Independent status-item process. The full BIFROST window may be quit,
/// while this explicitly launched lightweight controller remains available.
/// Neither this process nor the full GUI is the parent of Headless.
@main
struct BIFROSTMenuControllerApp: App {
    @StateObject private var headless = HeadlessClient()
    @StateObject private var peers = BifrostObservedPeerRegistry()
    @AppStorage("bifrost.menu.level") private var menuLevel = "Simple"
    @AppStorage("bifrost.menu.peerSummary") private var showPeerSummary = true
    @AppStorage("bifrost.menu.animateBridge") private var animateBridge = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("bifrost.menu.showTitle") private var showTitle = true
    @AppStorage("bifrost.menu.showHeadlessState") private var showHeadlessState = true

    var body: some Scene {
        MenuBarExtra {
            BIFROSTMenuControllerView(headless: headless, peers: peers)
        } label: {
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
                "BIFROST Menu · Headless " +
                (headless.isRunning ? "running" :
                 headless.isRegisteredWithLaunchd == true ? "registered but unreachable" : "stopped") +
                (menuLevel != "Simple" && peers.hasFreshObservation
                    ? " · \(peers.observedRunningCount) other processes observed, health unverified" : "")
            )
        }
        .menuBarExtraStyle(.menu)
    }
}
