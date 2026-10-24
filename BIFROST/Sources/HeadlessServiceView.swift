import AppKit
import SwiftUI

/// Native control surface for the independently managed BIFROST Headless.
/// Neither opening this screen nor refreshing its status starts any service.
struct HeadlessServiceView: View {
    @EnvironmentObject private var headless: HeadlessClient
    @State private var confirmStop = false
    @State private var lastRefresh: Date?

    private var sessionState: String {
        if headless.isRunning { return "Running" }
        if headless.isRegisteredWithLaunchd == true { return "Registered · not responding" }
        if headless.isRegisteredWithLaunchd == false { return "Stopped" }
        return "Checking"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    BifrostColorIcon("Headless", symbol: "server.rack", accent: BifrostUI.bridge)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Headless").font(.title2.weight(.bold))
                        Text("Independent local service · controlled from BIFROST")
                            .font(.caption).foregroundStyle(BifrostUI.muted)
                    }
                    Spacer()
                    BifrostStatusDot(status: headless.isRunning ? "running" : "offline")
                    Text(sessionState)
                        .font(.subheadline.weight(.semibold))
                    Button("Refresh") {
                        lastRefresh = Date()
                        headless.refresh()
                        headless.refreshLocalReceipts()
                    }
                }

                BifrostPanel(title: "Service control", symbol: "server.rack",
                             accent: BifrostUI.bridge) {
                    HStack(spacing: 13) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("On demand · no login startup")
                                .font(.subheadline.weight(.semibold))
                            Text("RunAtLoad off · automatic crash restart off. The browser dashboard and native App both connect to this same local service.")
                                .font(.caption).foregroundStyle(BifrostUI.muted)
                        }
                        Spacer()
                        if headless.isRunning || headless.isRegisteredWithLaunchd == true {
                            Button("Stop Headless", role: .destructive) {
                                confirmStop = true
                            }
                        } else {
                            Button("Start Headless") { headless.start() }
                                .buttonStyle(.borderedProminent)
                        }
                        Button("Open Web") { headless.openWeb() }
                            .disabled(!headless.isRunning)
                    }
                    .padding(.vertical, 5)
                    HStack {
                        Label("Loopback only · 127.0.0.1", systemImage: "lock.shield")
                        Spacer()
                        Text("Installed service remains independent of this window")
                    }
                    .font(.caption2).foregroundStyle(BifrostUI.muted)
                }

                BifrostPanel(title: "Keep Awake", symbol: "moon.zzz.fill",
                             accent: BifrostUI.backup) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(headless.caffeinateActive ? "BIFROST Caffeinate active" : "BIFROST Caffeinate off")
                                .font(.subheadline.weight(.medium))
                            Text(headless.systemCaffeinateObserved == true && !headless.caffeinateActive ?
                                 "External Caffeinate detected · not managed by BIFROST" :
                                 "Headless manages only its own power assertion")
                                .font(.caption2).foregroundStyle(BifrostUI.muted)
                        }
                        Spacer()
                        Menu {
                            ForEach([30, 60, 120, 0], id: \.self) { duration in
                                Button(duration == 0 ? "Until stopped" : "\(duration) minutes") {
                                    headless.setCaffeinateMinutes(duration)
                                }
                            }
                        } label: {
                            Text(headless.preferences.caffeinateMinutes == 0 ?
                                 "Until stopped" : "\(headless.preferences.caffeinateMinutes)m")
                        }
                        Button(headless.caffeinateActive ? "Stop" : "Start") {
                            if headless.caffeinateActive {
                                headless.stopCaffeinate()
                            } else {
                                headless.startCaffeinate()
                            }
                        }
                        .disabled(!headless.isRunning)
                    }
                }

                BifrostPanel(title: "Local activity", symbol: "list.bullet.rectangle",
                             accent: BifrostUI.tasks) {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Observation receipts").font(.subheadline.weight(.medium))
                            Text("Persist across independent Headless restarts · no provider execution")
                                .font(.caption2).foregroundStyle(BifrostUI.muted)
                        }
                        Spacer()
                        Button("Record check") { headless.recordLocalObservation() }
                            .disabled(!headless.isRunning)
                        Button("Refresh") { headless.refreshLocalReceipts() }
                            .disabled(!headless.isRunning)
                    }
                    if headless.localReceipts.isEmpty {
                        Text("No local receipts available")
                            .font(.caption).foregroundStyle(BifrostUI.muted)
                    } else {
                        ForEach(headless.localReceipts.prefix(8)) { receipt in
                            Divider().overlay(BifrostUI.line)
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(BifrostUI.healthy)
                                Text("Local status observation").font(.caption)
                                Spacer()
                                Text(Date(timeIntervalSince1970:
                                    TimeInterval(receipt.createdAt) / 1000)
                                    .formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2).foregroundStyle(BifrostUI.muted)
                                Text(String(receipt.taskId.suffix(8)))
                                    .font(.caption2.monospaced()).foregroundStyle(BifrostUI.muted)
                            }
                        }
                    }
                    Text(headless.localLedgerFeedback)
                        .font(.caption2).foregroundStyle(BifrostUI.muted)
                }

                if !headless.feedback.isEmpty {
                    Label(headless.feedback, systemImage: "info.circle")
                        .font(.caption).foregroundStyle(BifrostUI.muted)
                }
            }
            .frame(maxWidth: 1060, alignment: .leading)
            .padding(.bottom, 18)
        }
        .onAppear {
            headless.refresh()
            headless.refreshLocalReceipts()
        }
        .onChange(of: headless.isRunning) { _, _ in
            headless.refreshLocalReceipts()
        }
        .confirmationDialog("Stop the independent BIFROST Headless service?",
                            isPresented: $confirmStop, titleVisibility: .visible) {
            Button("Stop Headless", role: .destructive) {
                _ = headless.stop()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This stops the local Headless service and any Caffeinate assertion it owns. It will not stop independent applications or other power assertions.")
        }
    }
}
