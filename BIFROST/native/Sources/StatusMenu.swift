import SwiftUI
import AppKit

struct StatusMenu: View {
    @EnvironmentObject private var system: BifrostSystem
    @EnvironmentObject private var headless: HeadlessClient
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @State private var showEDENControls = false

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 10) {
                BifrostMark(size: 37)
                VStack(alignment: .leading, spacing: 2) {
                    Text("BIFROST").font(.headline)
                    Text("CONNECT · KEEP · RESOLVE")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(BifrostUI.muted)
                }
                Spacer()
                BifrostStatusDot(status: headless.isRunning ? "running" : "offline")
                Text(headless.isRunning ? "Running" : "Offline")
                    .font(.caption.weight(.medium))
            }
            BifrostSpectrum()
            VStack(spacing: 8) {
                if headless.preferences.statusIndicators.contains("headless") {
                    statusRow(title: "Headless", symbol: "server.rack",
                              accent: BifrostUI.bridge,
                              value: headless.stateMessage,
                              state: headless.isRunning ? "running" : "offline")
                }
                if headless.preferences.statusIndicators.contains("activeTasks") {
                    statusRow(title: "Active tasks", symbol: "checklist",
                              accent: BifrostUI.tasks,
                              value: headless.activeTasks.map(String.init) ?? "Unknown",
                              state: headless.taskStatus == "observed" ? "observed" : "unknown")
                }
                statusRow(title: "RavenNest", symbol: "network",
                          accent: BifrostUI.raven,
                          value: headless.ravenBridge == "running" ? "Agent running" : headless.ravenBridge.capitalized,
                          state: headless.ravenBridge)
            }
            .padding(10)
            .background(BifrostUI.panel, in: RoundedRectangle(cornerRadius: 10))
            HStack(spacing: 8) {
                if headless.isRunning {
                    controlButton("Stop Headless", symbol: "stop.circle",
                                  accent: BifrostUI.problem) { headless.stop() }
                    controlButton("Open Web", symbol: "globe",
                                  accent: BifrostUI.bridge) { headless.openWeb() }
                } else {
                    controlButton("Start Headless", symbol: "play.circle",
                                  accent: BifrostUI.healthy) { headless.start() }
                }
                Button {
                    system.refresh()
                } label: { Image(systemName: "arrow.clockwise") }
                    .buttonStyle(.bordered)
                    .help("Refresh BIFROST status")
            }
            Divider().overlay(BifrostUI.line)
            HStack(spacing: 9) {
                Image(systemName: "moon.zzz.fill").foregroundStyle(BifrostUI.backup)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Caffeinate").font(.subheadline.weight(.medium))
                    Text(headless.caffeinateActive ? "Preventing Mac sleep" : "Not active")
                        .font(.caption2).foregroundStyle(BifrostUI.muted)
                }
                Spacer()
                Button(headless.caffeinateActive ? "Stop" : "Start") {
                    headless.caffeinateActive ? headless.stopCaffeinate() : headless.startCaffeinate()
                }
                .disabled(!headless.isRunning)
                .buttonStyle(.bordered)
            }
            HStack {
                Text("Default duration")
                    .font(.caption).foregroundStyle(BifrostUI.muted)
                Spacer()
                Picker("Caffeinate duration", selection: Binding(
                    get: { headless.preferences.caffeinateMinutes },
                    set: { headless.setCaffeinateMinutes($0) }
                )) {
                    Text("30 min").tag(30)
                    Text("60 min").tag(60)
                    Text("120 min").tag(120)
                    Text("Until stopped").tag(0)
                }
                .labelsHidden().frame(width: 155)
            }
            Divider().overlay(BifrostUI.line)
            DisclosureGroup(isExpanded: $showEDENControls) {
                VStack(alignment: .leading, spacing: 8) {
                    statusRow(title: "Remote access", symbol: "macbook.and.iphone",
                              accent: BifrostUI.devices, value: system.remote.state.rawValue,
                              state: "unknown")
                    statusRow(title: "Nearby services", symbol: "dot.radiowaves.left.and.right",
                              accent: BifrostUI.bridge, value: "\(system.discovery.services.count) observed",
                              state: "unknown")
                    HStack {
                        Button("Start Remote") { system.remote.start(); system.refresh() }
                        Button("Stop Remote") { system.remote.stop(); system.refresh() }
                    }.buttonStyle(.bordered)
                }.padding(.top, 6)
            } label: {
                Label("Other EDEN controls", systemImage: "square.grid.2x2.fill")
                    .foregroundStyle(BifrostUI.apps)
                    .font(.subheadline.weight(.medium))
            }
            HStack(spacing: 9) {
                controlButton("Open BIFROST App", symbol: "app.window",
                              accent: BifrostUI.apps) { openWindow(id: "main") }
                controlButton("Preferences", symbol: "gearshape",
                              accent: BifrostUI.bridge) { openSettings() }
            }
            if !headless.feedback.isEmpty {
                Text(headless.feedback)
                    .font(.caption2).foregroundStyle(BifrostUI.muted)
                    .lineLimit(3)
            }
            Divider().overlay(BifrostUI.line)
            Button("Quit Menu Bar / App Only") {
                NSApplication.shared.terminate(nil)
            }
            .font(.caption)
            .help("Leaves BIFROST Headless and RavenNest running")
        }
        .padding(13)
        .frame(width: 350)
        .background(BifrostUI.sidebar)
        .tint(BifrostUI.apps)
        .onAppear { headless.refresh() }
    }

    private func statusRow(title: String, symbol: String,
                           accent: Color, value: String, state: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).foregroundStyle(accent).frame(width: 20)
            Text(title).font(.subheadline)
            Spacer()
            BifrostStatusDot(status: state)
            Text(value).font(.caption).foregroundStyle(BifrostUI.muted)
                .lineLimit(1)
        }
    }

    private func controlButton(_ name: String, symbol: String,
                               accent: Color, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            Label {
                Text(name).font(.caption.weight(.medium))
            } icon: {
                Image(systemName: symbol).foregroundStyle(accent)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }
}
