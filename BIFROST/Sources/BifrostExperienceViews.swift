import SwiftUI
import AppKit

/// Simple is a task-led home, not the Advanced inventory with fewer rows.
/// All actions delegate to the existing BIFROST owners and remain explicit.
struct BifrostSimpleHomeView: View {
    @EnvironmentObject private var system: BifrostSystem
    @EnvironmentObject private var headless: HeadlessClient
    let navigate: (String) -> Void

    private var serviceStatus: String {
        if headless.isRunning { return "Local bridge running" }
        if headless.isRegisteredWithLaunchd == true { return "Local bridge needs attention" }
        if headless.isRegisteredWithLaunchd == false { return "Local bridge stopped" }
        return "Checking local bridge"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .center, spacing: 19) {
                    BifrostBridgeSymbol(width: 88, height: 70)
                        .frame(width: 94, height: 80)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("BIFROST").font(.system(size: 30, weight: .bold, design: .rounded))
                        Text("CONNECT · KEEP · RESOLVE")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(BifrostUI.muted)
                        Text("Your Mac, at a glance.")
                            .font(.headline).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                BifrostSpectrum()

                GroupBox {
                    HStack(spacing: 13) {
                        BifrostStatusDot(status: headless.isRunning ? "running" : "offline")
                        VStack(alignment: .leading, spacing: 4) {
                            Text(serviceStatus).font(.headline)
                            Text("Runs independently of this window. Never starts automatically.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        Button("Manage Bridge…") { navigate("Headless") }
                            .buttonStyle(.borderedProminent)
                            .accessibilityHint("Opens service controls; does not start Headless")
                    }
                    .padding(10)
                }
                .accessibilityElement(children: .contain)

                Text("What would you like to do?")
                    .font(.title2.weight(.semibold))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 235), spacing: 14)], spacing: 14) {
                    simpleAction("Find devices",
                                 subtitle: "\(system.discovery.services.count) nearby services observed",
                                 symbol: "macbook.and.iphone", accent: BifrostUI.devices) {
                        navigate("Devices")
                    }
                    simpleAction("Accounts & Access",
                                 subtitle: "Separate identities for AI providers and RDC",
                                 symbol: "person.crop.circle.badge.checkmark", accent: BifrostUI.bridge) {
                        navigate("Accounts & Access")
                    }
                    simpleAction("Setup packages",
                                 subtitle: "Import and review local installation packages",
                                 symbol: "shippingbox.fill", accent: BifrostUI.apps) {
                        navigate("Install & Setup")
                    }
                    simpleAction("My apps",
                                 subtitle: "\(system.apps.apps.filter { $0.installed }.count) registered on this Mac",
                                 symbol: "square.grid.3x3.fill", accent: BifrostUI.apps) {
                        navigate("App Management")
                    }
                    simpleAction("Find a file",
                                 subtitle: "Search your approved local index",
                                 symbol: "magnifyingglass", accent: BifrostUI.bridge) {
                        navigate("Index & Identity")
                    }
                    simpleAction("Automations",
                                 subtitle: "Choose Advanced in Settings to configure",
                                 symbol: "bolt.badge.clock", accent: BifrostUI.tasks) {
                        // Navigation must not silently change the owner's UI preference.
                        navigate("Settings")
                    }
                }

                HStack(spacing: 9) {
                    Image(systemName: "lock.shield").foregroundStyle(BifrostUI.bridge)
                    Text("Private and local by default. Connected online services are separate opt-in plugins.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if !headless.feedback.isEmpty {
                    Text(headless.feedback).font(.caption)
                        .foregroundStyle(.secondary).textSelection(.enabled)
                }
            }
            .frame(maxWidth: 870, alignment: .leading)
            .padding(.bottom, 20)
        }
        .onAppear { headless.refresh() }
    }

    private func simpleAction(_ title: String, subtitle: String,
                              symbol: String, accent: Color,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                BifrostColorIcon(title, symbol: symbol, accent: accent)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.headline).foregroundStyle(.primary)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(15).frame(maxWidth: .infinity, minHeight: 94)
            .background(BifrostUI.panel, in: RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title + ". " + subtitle)
    }
}

/// Expert is an evidence-oriented live local diagnostic workspace, not
/// a longer list of menu entries or an unrestricted remote-control console.
/// No token, credentials, file contents, remote APIs or commands are read.
struct BifrostExpertDiagnosticsView: View {
    @EnvironmentObject private var headless: HeadlessClient
    @State private var observedIdentity = "Not checked"
    @State private var observedSource = "Not checked"
    @State private var localRule = "Not checked"
    @State private var latestCheck: Date?
    @State private var checking = false

    private var support: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/BIFROST", isDirectory: true)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                BifrostHeader(title: "Expert · Local diagnostics",
                              subtitle: "Read-only evidence and permission review. No services or workflows are started.")
                GroupBox("Headless · independent runtime") {
                    VStack(alignment: .leading, spacing: 11) {
                        diagnosticRow("Verified native state", headless.stateMessage)
                        diagnosticRow("launchd service registration",
                                      headless.isRegisteredWithLaunchd == nil ? "Unknown" :
                                      headless.isRegisteredWithLaunchd == true ? "Registered" : "Not registered")
                        diagnosticRow("Loopback listener", "127.0.0.1:8798 · local only")
                        diagnosticRow("Observed runtime identity", observedIdentity)
                        diagnosticRow("Observed source fingerprint", observedSource)
                        diagnosticRow("Caffeinate owner",
                                      headless.caffeinateActive ? "BIFROST-owned · active" :
                                      headless.systemCaffeinateObserved == true ?
                                      "External process observed · not controlled" : "BIFROST inactive")
                    }
                    .padding(8)
                }
                GroupBox("Folder Automation · permission boundary") {
                    VStack(alignment: .leading, spacing: 9) {
                        diagnosticRow("Local approval record", localRule)
                        Text("A saved rule is an authorization record, not proof of independent Headless filesystem access. macOS TCC, folder-triggered effects, external workflow outcomes and user acceptance remain unverified until tested.")
                            .font(.caption).foregroundStyle(.secondary)
                        Text("No workflow execution, permission modification, file indexing or installation is available from this diagnostic screen.")
                            .font(.caption2).foregroundStyle(.secondary)
                    }.padding(8)
                }

                HStack {
                    Button(checking ? "Inspecting…" : "Inspect Local State") {
                        Task { await refreshEvidence() }
                    }
                    .disabled(checking)
                    .buttonStyle(.borderedProminent)
                    if checking { ProgressView().controlSize(.small) }
                    Spacer()
                    if let latestCheck {
                        Text("Observed " + latestCheck.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: 1000, alignment: .leading)
            .padding(.bottom, 20)
        }
        .onAppear {
            guard latestCheck == nil else { return }
            Task { await refreshEvidence() }
        }
    }

    private func diagnosticRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 15) {
            Text(title).font(.caption.weight(.medium))
            Spacer(minLength: 10)
            Text(value).font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }

    @MainActor
    private func refreshEvidence() async {
        checking = true
        defer { checking = false; latestCheck = Date() }
        headless.refresh()
        let file = support.appendingPathComponent("orchestration-rule.json")
        do {
            let values = try FileManager.default.attributesOfItem(atPath: file.path)
            let mode = (values[.posixPermissions] as? NSNumber)?.uint16Value ?? 0xffff
            if mode & 0o077 != 0 {
                localRule = "Present · unsafe file permissions; refused"
            } else if let contents = try? Data(contentsOf: file),
                      let item = try? JSONSerialization.jsonObject(with: contents) as? [String: Any],
                      item["schema"] as? String == "bifrost.orchestration.v1",
                      let enabled = item["enabled"] as? Bool {
                localRule = enabled ? "User-approved rule present · daemon access unknown"
                                    : "User-approved rule disabled"
            } else {
                localRule = "Present · invalid or unreadable record"
            }
        } catch {
            localRule = FileManager.default.fileExists(atPath: file.path)
                ? "Approval record unavailable" : "No rule approved"
        }

        var req = URLRequest(url: URL(string: "http://127.0.0.1:8798/api/health")!)
        req.timeoutInterval = 2
        req.cachePolicy = .reloadIgnoringLocalCacheData
        guard let (data, response) = try? await URLSession.shared.data(for: req),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let identity = json["identity"] as? [String: Any],
              identity["schema"] as? String == "bifrost.headless.identity.v1",
              identity["productId"] as? String == "eden.bifrost.headless" else {
            observedIdentity = "No matching BIFROST listener observed"
            observedSource = "Unavailable"
            return
        }
        let runtime = identity["runtimeId"] as? String ?? "missing"
        observedIdentity = "Matched product identity · " + runtime
        observedSource = identity["sourceSha256"] as? String ?? "Missing fingerprint"
    }
}

