import SwiftUI

/// Compact feature-colored dashboard. Every count and status comes from the
/// existing BIFROST system, Headless runtime or capability registry.
struct BifrostDashboardView: View {
    @EnvironmentObject private var system: BifrostSystem
    @EnvironmentObject private var headless: HeadlessClient
    @State private var showLegacyControls = false
    let onNavigate: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                header
                BifrostSpectrum()

                if system.complexity == .expert {
                    BifrostPanel(title: "Expert · Operations workbench",
                                 symbol: "waveform.path.ecg.rectangle",
                                 accent: BifrostUI.bridge) {
                        HStack(alignment: .top, spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Independent service and evidence")
                                    .font(.subheadline.weight(.semibold))
                                Text(headless.stateMessage + " · launchd " +
                                     (headless.isRegisteredWithLaunchd == nil ? "unknown" :
                                      headless.isRegisteredWithLaunchd == true ? "registered" : "not registered"))
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                Text("Workflow outcomes and macOS permissions need physical verification. No external connector is controlled here.")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 8)
                            Button("Inspect Diagnostics") {
                                onNavigate("Diagnostics")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 6)
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 175), spacing: 10)], spacing: 10) {
                    tile(title: "Headless",
                         value: headless.isRunning ? "Running" : "Offline",
                         secondary: "Local service", icon: "server.rack",
                         feature: BifrostUI.bridge,
                         state: headless.isRunning ? "running" : "offline")
                    tile(title: "Devices",
                         value: "\(system.discovery.services.count) observed",
                         secondary: "Bonjour · not automatically trusted",
                         icon: "macbook.and.iphone",
                         feature: BifrostUI.devices, state: "unknown")
                    tile(title: "Installed Apps",
                         value: String(system.apps.apps.filter { $0.installed }.count),
                         secondary: "Local registered applications", icon: "square.grid.3x3.fill",
                         feature: BifrostUI.apps, state: "unknown")
                    tile(title: "Index & Identity",
                         value: "Local", secondary: "User-selected folders only",
                         icon: "point.3.connected.trianglepath.dotted",
                         feature: BifrostUI.bridge, state: "unknown")
                }

                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 12) {
                        BifrostPanel(title: "Environment", symbol: "server.rack", accent: BifrostUI.bridge) {
                            statusRow(title: "BIFROST Headless", detail: "Local service",
                                      value: headless.stateMessage, symbol: "server.rack",
                                      feature: BifrostUI.bridge,
                                      state: headless.isRunning ? "running" : "offline")
                            Divider().overlay(BifrostUI.line)
                            statusRow(title: "Nearby services",
                                      detail: "Native Bonjour · discovered, not trusted",
                                      value: String(system.discovery.services.count) + " observed",
                                      symbol: "dot.radiowaves.left.and.right",
                                      feature: BifrostUI.devices, state: "unknown")
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
                            action("Install & Setup", symbol: "shippingbox.fill",
                                   accent: BifrostUI.apps) { onNavigate("Install & Setup") }
                            action("Devices", symbol: "macbook.and.iphone", accent: BifrostUI.devices) {
                                onNavigate("Devices")
                            }
                            action("Manage Capabilities", symbol: "square.stack.3d.up.fill",
                                   accent: BifrostUI.apps) { onNavigate("Capabilities") }
                            action("Open JANITOR", symbol: "paintbrush.pointed.fill",
                                   accent: BifrostUI.janitor) { system.janitor.open() }
                            action("Open Web Dashboard", symbol: "globe",
                                   accent: BifrostUI.bridge) { headless.openWeb() }
                            action("Headless Controls", symbol: "server.rack",
                                   accent: BifrostUI.bridge) { onNavigate("Headless") }
                        }

                        BifrostPanel(title: "Local Power Control",
                                     symbol: "moon.zzz.fill", accent: BifrostUI.backup) {
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

                BifrostPanel(title: "Local activity", symbol: "list.bullet.rectangle",
                             accent: BifrostUI.tasks) {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Recorded local checks").font(.subheadline.weight(.semibold))
                            Text("Durable Headless receipts · no cloud work or background automation")
                                .font(.caption2).foregroundStyle(BifrostUI.muted)
                        }
                        Spacer()
                        Button("Record check") { headless.recordLocalObservation() }
                            .disabled(!headless.isRunning)
                        Button("Refresh") { headless.refreshLocalReceipts() }
                            .disabled(!headless.isRunning)
                    }
                    if headless.localReceipts.isEmpty {
                        Text("No local receipts available.")
                            .font(.caption).foregroundStyle(BifrostUI.muted)
                    } else {
                        ForEach(headless.localReceipts.prefix(5)) { receipt in
                            HStack(spacing: 8) {
                                BifrostStatusDot(status: "observed")
                                Text("Local status check")
                                    .font(.caption)
                                Spacer()
                                Text(Date(timeIntervalSince1970:
                                    TimeInterval(receipt.createdAt) / 1000)
                                    .formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2).foregroundStyle(BifrostUI.muted)
                                Text(String(receipt.taskId.suffix(8)))
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(BifrostUI.muted)
                            }
                        }
                    }
                    if !headless.localLedgerFeedback.isEmpty {
                        Text(headless.localLedgerFeedback)
                            .font(.caption2).foregroundStyle(BifrostUI.muted)
                    }
                }

                if !headless.feedback.isEmpty {
                    Label(headless.feedback, systemImage: "info.circle")
                        .font(.caption).foregroundStyle(BifrostUI.muted)
                }
                DisclosureGroup("Additional local controls", isExpanded: $showLegacyControls) {
                    OverviewView().padding(.top, 10)
                }
                .font(.caption).foregroundStyle(BifrostUI.muted)
            }
            .frame(maxWidth: 1060, alignment: .leading)
            .padding(.bottom, 14)
        }
        .onAppear { headless.refresh() }
        .onChange(of: headless.isRunning) { _, _ in
            // Disconnects must remove stale observed receipts from the UI.
            headless.refreshLocalReceipts()
        }
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
