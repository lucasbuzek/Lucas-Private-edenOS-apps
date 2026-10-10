import SwiftUI

/// Compact feature-colored dashboard. Every count and status comes from the
/// existing BIFROST system, Headless runtime or capability registry.
struct BifrostDashboardView: View {
    @EnvironmentObject private var system: BifrostSystem
    @EnvironmentObject private var headless: HeadlessClient
    @EnvironmentObject private var raven: RavenAgentController
    @State private var showLegacyControls = false
    let onNavigate: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                header
                BifrostSpectrum()

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 175), spacing: 10)], spacing: 10) {
                    tile(title: "Headless",
                         value: headless.isRunning ? "Running" : "Offline",
                         secondary: "Local service", icon: "server.rack",
                         feature: BifrostUI.bridge,
                         state: headless.isRunning ? "running" : "offline")
                    tile(title: "Active tasks",
                         value: headless.activeTasks.map(String.init) ?? "Unknown",
                         secondary: "Codex Cloud · recent list", icon: "checklist",
                         feature: BifrostUI.tasks,
                         state: headless.taskStatus == "observed" ? "observed" : "unknown")
                    tile(title: "Devices",
                         value: "\(system.discovery.services.count) observed",
                         secondary: "Bonjour · not automatically trusted",
                         icon: "macbook.and.iphone",
                         feature: BifrostUI.devices, state: "unknown")
                    tile(title: "RavenNest · Mac",
                         value: raven.isRunning ? "Running" : "Stopped",
                         secondary: "Manual only · Cloudflare independent", icon: "network",
                         feature: BifrostUI.raven,
                         state: raven.isRunning ? "running" : "unknown")
                }

                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 12) {
                        BifrostPanel(title: "Environment", symbol: "server.rack", accent: BifrostUI.bridge) {
                            statusRow(title: "BIFROST Headless", detail: "Local service",
                                      value: headless.stateMessage, symbol: "server.rack",
                                      feature: BifrostUI.bridge,
                                      state: headless.isRunning ? "running" : "offline")
                            Divider().overlay(BifrostUI.line)
                            statusRow(title: "RavenNest Mac bridge", detail: "Manual connection · no automatic startup",
                                      value: raven.isRunning ? "Running" : "Stopped", symbol: "network",
                                      feature: BifrostUI.raven,
                                      state: raven.isRunning ? "running" : "unknown")
                            Divider().overlay(BifrostUI.line)
                            statusRow(title: "AI routing", detail: "Preference; no provider connected",
                                      value: headless.preferences.aiRouting.capitalized,
                                      symbol: "brain.head.profile", feature: BifrostUI.ai, state: "unknown")
                            Divider().overlay(BifrostUI.line)
                            statusRow(title: "Keep Awake", detail: "Headless-owned Caffeinate",
                                      value: headless.caffeinateActive ? "Active" : "Off",
                                      symbol: "moon.zzz.fill", feature: BifrostUI.backup,
                                      state: headless.caffeinateActive ? "running" : "unknown")
                        }

                        BifrostPanel(title: "EDEN Apps", symbol: "square.grid.3x3.fill", accent: BifrostUI.apps) {
                            Text("Installed status from macOS app registration")
                                .font(.caption2).foregroundStyle(BifrostUI.muted)
                            ForEach(system.apps.apps, id: \.id) { app in
                                HStack(spacing: 9) {
                                    Image(systemName: app.name == "JANITOR" ?
                                          "paintbrush.pointed.fill" : "app.fill")
                                        .foregroundStyle(app.name == "JANITOR" ? BifrostUI.janitor : BifrostUI.apps)
                                        .frame(width: 20)
                                    Text(app.name).font(.subheadline)
                                    Spacer()
                                    Text(app.installed ? "Installed" : "Not detected")
                                        .font(.caption2).foregroundStyle(BifrostUI.muted)
                                    if app.installed {
                                        Button("Open") { system.apps.open(app) }
                                            .buttonStyle(.borderless).font(.caption)
                                    }
                                }
                                .padding(.vertical, 3)
                            }
                        }
                    }

                    VStack(spacing: 12) {
                        BifrostPanel(title: "Quick Actions", symbol: "bolt.fill", accent: BifrostUI.tasks) {
                            action("Index & Identity", symbol: "point.3.connected.trianglepath.dotted",
                                   accent: BifrostUI.bridge) { onNavigate("Index & Identity") }
                            action("Devices", symbol: "macbook.and.iphone", accent: BifrostUI.devices) {
                                onNavigate("Devices")
                            }
                            action("Manage Capabilities", symbol: "square.stack.3d.up.fill",
                                   accent: BifrostUI.apps) { onNavigate("Capabilities") }
                            action("Open JANITOR", symbol: "paintbrush.pointed.fill",
                                   accent: BifrostUI.janitor) { system.janitor.open() }
                            action("Open Web Dashboard", symbol: "globe",
                                   accent: BifrostUI.bridge) { headless.openWeb() }
                            if headless.isRunning {
                                action("Stop Headless", symbol: "stop.circle",
                                       accent: BifrostUI.problem) { headless.stop() }
                            } else {
                                action("Start Headless", symbol: "play.circle.fill",
                                       accent: BifrostUI.healthy) { headless.start() }
                            }
                        }

                        BifrostPanel(title: "Task & Power Control", symbol: "checklist", accent: BifrostUI.tasks) {
                            HStack(spacing: 10) {
                                Image(systemName: "checklist").foregroundStyle(BifrostUI.tasks)
                                Text("Codex Cloud").font(.subheadline)
                                Spacer()
                                Text(headless.activeTasks.map { "\($0) active" } ?? "Unknown")
                                    .font(.caption).foregroundStyle(BifrostUI.muted)
                                Button("Check") { headless.refreshTasks() }
                                    .font(.caption).disabled(!headless.isRunning)
                            }
                            Divider().overlay(BifrostUI.line)
                            HStack(spacing: 10) {
                                Image(systemName: "moon.zzz.fill").foregroundStyle(BifrostUI.backup)
                                Text("Caffeinate").font(.subheadline)
                                Spacer()
                                Text(headless.caffeinateActive ? "Active" : "Off")
                                    .font(.caption).foregroundStyle(BifrostUI.muted)
                                Button(headless.caffeinateActive ? "Stop" : "Start \(headless.preferences.caffeinateMinutes)m") {
                                    headless.caffeinateActive ? headless.stopCaffeinate() : headless.startCaffeinate()
                                }
                                .font(.caption).disabled(!headless.isRunning)
                            }
                        }
                    }
                }

                if !headless.feedback.isEmpty {
                    Label(headless.feedback, systemImage: "info.circle")
                        .font(.caption).foregroundStyle(BifrostUI.muted)
                }
                DisclosureGroup("Existing native bridge controls", isExpanded: $showLegacyControls) {
                    OverviewView().padding(.top, 10)
                }
                .font(.caption).foregroundStyle(BifrostUI.muted)
            }
            .frame(maxWidth: 1060, alignment: .leading)
            .padding(.bottom, 14)
        }
        .onAppear { headless.refresh() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            BifrostMark(size: 49)
            VStack(alignment: .leading, spacing: 3) {
                Text("Garden of EDEN")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("BIFROST · CONNECT · KEEP · RESOLVE")
                    .font(.caption).foregroundStyle(BifrostUI.muted)
            }
            Spacer()
            Button { system.refresh() } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
    }

    private func tile(title: String, value: String, secondary: String,
                      icon: String, feature: Color, state: String) -> some View {
        HStack(alignment: .center, spacing: 10) {
            BifrostColorIcon(title, symbol: icon, accent: feature)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.caption).foregroundStyle(BifrostUI.muted)
                HStack(spacing: 6) {
                    BifrostStatusDot(status: state)
                    Text(value).font(.subheadline.weight(.semibold)).lineLimit(1)
                }
                Text(secondary).font(.system(size: 10))
                    .foregroundStyle(BifrostUI.muted).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(12).frame(maxWidth: .infinity, minHeight: 75, alignment: .leading)
        .background(BifrostUI.panel, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(feature.opacity(0.24)))
        .accessibilityElement(children: .combine)
    }

    private func statusRow(title: String, detail: String, value: String,
                           symbol: String, feature: Color, state: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).foregroundStyle(feature).frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline)
                Text(detail).font(.caption2).foregroundStyle(BifrostUI.muted)
            }
            Spacer(minLength: 8)
            BifrostStatusDot(status: state)
            Text(value).font(.caption).foregroundStyle(BifrostUI.muted).lineLimit(1)
        }.padding(.vertical, 4)
    }

    private func action(_ name: String, symbol: String, accent: Color,
                        perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            HStack(spacing: 10) {
                Image(systemName: symbol).foregroundStyle(accent)
                    .frame(width: 21)
                Text(name).font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2).foregroundStyle(BifrostUI.muted)
            }
            .padding(.horizontal, 11).padding(.vertical, 10)
            .background(BifrostUI.elevated, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
