import SwiftUI
import AppKit

struct ConnectionsView: View {
    @EnvironmentObject private var system: BifrostSystem
    @EnvironmentObject private var headless: HeadlessClient
    @EnvironmentObject private var permissions: BifrostPermissionCenter
    @State private var showLocalMiniBrowser = false
    @State private var showRDCConsent = false
    @State private var showRDCReadOnly = false
    @State private var showAccountJourney = false
    @State private var rdcFeedback = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            BifrostHeader(title: "Local Connections",
                          subtitle: "Observe and manage connections on this device. No online service is required.")
            GroupBox("BIFROST Headless") {
                HStack(spacing: 12) {
                    Image(systemName: "server.rack")
                        .foregroundStyle(BifrostUI.bridge)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(headless.stateMessage).font(.headline)
                        Text("Local-only loopback service · independent of this window")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if headless.isRunning {
                        Button("Open Local Dashboard") { showLocalMiniBrowser = true }
                        Button("Stop") { headless.stop() }
                    } else {
                        Button("Start…") { headless.start() }
                    }
                    Button("Refresh") { headless.refresh() }
                }.padding(10)
            }
            GroupBox("BIFROSTcore · Runtime identity") {
                HStack(spacing: 12) {
                    Image(systemName: "server.rack")
                        .foregroundStyle(BifrostUI.bridge)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(headless.coreRuntimeFeedback)
                            .font(.subheadline)
                        Text("Read-only · legacy Core remains independent · no database migration")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Inspect Runtime") { headless.inspectCoreRuntime() }
                        .disabled(!headless.isRunning)
                }.padding(10)
            }
            GroupBox("Nearby devices & services") {
                HStack(spacing: 12) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .foregroundStyle(BifrostUI.devices)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(system.discovery.services.count) services observed")
                            .font(.headline)
                        Text("Bonjour discovery does not imply trust, pairing or device control.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Show Devices") { system.selectedSection = "Devices" }
                    Button("Refresh") { system.refresh() }
                }.padding(10)
            }
            GroupBox("RDC Manager · Optional plugin") {
                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("BIFROST owns remote-connection management")
                                .font(.subheadline.weight(.medium))
                            Text("Read existing RDC profile labels; no account sign-in or device operation starts.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("View RDC Manager…") { requestRDCAccess() }
                    }
                    if !rdcFeedback.isEmpty {
                        Text(rdcFeedback).font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(8)
            }
            GroupBox("Accounts & Access · Guided setup") {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .foregroundStyle(BifrostUI.bridge)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Add an account through its official provider")
                            .font(.subheadline.weight(.medium))
                        Text("Save separate provider identities and open their isolated WebKit sessions. Connector authorization remains independently verified.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Account Setup…") { showAccountJourney = true }
                }.padding(8)
            }
            Text("Online access and cloud providers are independent plugins, not bundled BIFROST functions.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: 960, alignment: .leading)
        .confirmationDialog("Allow BIFROST to access RDC Manager?",
                            isPresented: $showRDCConsent,
                            titleVisibility: .visible) {
            Button("Allow Once") { showRDCReadOnly = true }
            Button("Allow All") {
                permissions.save(.allowAll, for: .rdcProfileDiscovery)
                showRDCReadOnly = true
            }
            Button("Deny", role: .destructive) {
                permissions.save(.deny, for: .rdcProfileDiscovery)
                rdcFeedback = "RDC Manager denied. Change this in Settings → BIFROST Access."
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Allow access to local RDC profile labels only. This does not grant macOS permissions, authenticate accounts, start agents or authorize remote device operations.")
        }
        .sheet(isPresented: $showRDCReadOnly) {
            BifrostRDCManagerReadOnlyView()
        }
        .sheet(isPresented: $showAccountJourney) {
            BifrostAccountJourneyView()
        }
        .sheet(isPresented: $showLocalMiniBrowser) {
            VStack(spacing: 0) {
                HStack {
                    Text("BIFROST Local Dashboard").font(.headline)
                    Spacer()
                    Text("127.0.0.1 only · no external navigation")
                        .font(.caption).foregroundStyle(.secondary)
                    Button("Close") { showLocalMiniBrowser = false }
                }.padding(12)
                Divider()
                BifrostLocalDashboardWebView()
            }
            .frame(minWidth: 760, minHeight: 520)
        }
    }

    private func requestRDCAccess() {
        switch permissions.decision(for: .rdcProfileDiscovery) {
        case .ask:
            showRDCConsent = true
        case .allowAll:
            rdcFeedback = "Viewing optional RDC Manager metadata."
            showRDCReadOnly = true
        case .deny:
            rdcFeedback = "Access denied by BIFROST. Review Settings → BIFROST Access."
        }
    }
}

struct CapabilitiesView: View {
    @EnvironmentObject var system: BifrostSystem
    @EnvironmentObject private var permissions: BifrostPermissionCenter
    @ObservedObject var capabilities: CapabilityRegistry
    @StateObject private var localIntelligence = BifrostLocalIntelligence()
    @StateObject private var workflowRunner = BifrostNativeWorkflowRunner()
    @State private var requestedShortcut: String?
    @State private var confirmShortcut = false
    @State private var requestedAutomator: BifrostNativeWorkflow?
    @State private var confirmAutomator = false
    @State private var showAutomationConsent = false
    @State private var continueAutomationReviewAfterConsent = false
    @State private var accessFeedback = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            BifrostHeader(title: "Capabilities", subtitle: "Real capabilities and providers visible to this Mac.")
            HStack {
                Text("\(capabilities.items.filter { $0.available }.count) available")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Refresh") { system.refresh() }
            }
            List(capabilities.items) { capability in
                HStack {
                    BifrostFeatureIcon(symbol: capability.available ? "checkmark.circle.fill" : "circle.dashed", feature: .capabilities, size: 15)
                    VStack(alignment: .leading) {
                        Text(capability.name).font(.headline)
                        Text("\(capability.provider) · \(capability.kind.rawValue) · \(capability.detail)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(capability.available ? "Available" : "Unavailable")
                        .foregroundStyle(.secondary)
                }
            }
            GroupBox("Work on this Mac · capability routing") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("BIFROST resolves existing capabilities. The appropriate native app or specialist executes each approved task.")
                        .font(.caption).foregroundStyle(.secondary)
                    ForEach(capabilities.workItems) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: item.detected ? "checkmark.circle" : "circle.dashed")
                                .foregroundStyle(item.detected ? .green : .secondary)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name).font(.subheadline.weight(.medium))
                                Text(item.provider).font(.caption2).foregroundStyle(.secondary)
                                Text(item.boundary).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 8)
                            Text(item.detected ? "Detected" : "External")
                                .font(.caption2).foregroundStyle(.secondary)
                        }.accessibilityElement(children: .combine)
                    }
                    Button("View installed apps") { system.selectedSection = "App Management" }
                        .buttonStyle(.bordered)
                    Text("Discovery launches no apps, commands, services, media jobs or remote tasks.")
                        .font(.caption2).foregroundStyle(.secondary)
                }.padding(8)
            }
            GroupBox("Shortcuts") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(capabilities.shortcutsStatus)
                        .font(.caption).foregroundStyle(.secondary)
                    if !capabilities.shortcuts.isEmpty {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], alignment: .leading) {
                                ForEach(capabilities.shortcuts, id: \.self) { shortcut in
                                    HStack {
                                        Label(shortcut, systemImage: "command")
                                            .lineLimit(1)
                                        Spacer()
                                        Button("Run…") {
                                            requestedShortcut = shortcut
                                            requestedAutomator = nil
                                            requestAutomationAccess()
                                        }
                                        .disabled(workflowRunner.running)
                                        .accessibilityLabel("Review running \(shortcut)")
                                    }
                                }
                            }
                        }
                    }
                }.padding(8)
                if workflowRunner.running { ProgressView("Running chosen Shortcut…") }
                Text(workflowRunner.status)
                    .font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                if !accessFeedback.isEmpty {
                    Text(accessFeedback).font(.caption).foregroundStyle(.secondary)
                }
                Text("Running a Shortcut may change files, use network services or request permissions. Each action requires your confirmation; no scheduled or automatic execution is enabled.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            GroupBox("Automator Quick Actions · Discovery only") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(workflowRunner.automatorItems.count) saved workflows discovered")
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Button("Inspect") { workflowRunner.refreshAutomator() }
                    }
                    ForEach(workflowRunner.automatorItems) { workflow in
                        HStack {
                            Text(workflow.name).font(.caption).textSelection(.enabled)
                            Spacer()
                            Button("Run…") {
                                requestedAutomator = workflow
                                requestedShortcut = nil
                                requestAutomationAccess()
                            }
                            .disabled(workflowRunner.running)
                        }
                    }
                    Text("Only saved, inspected workflows can run after explicit confirmation. Automator may perform file/network operations or request macOS permissions; no unattended runs.")
                        .font(.caption2).foregroundStyle(.secondary)
                }.padding(8)
            }
            BifrostFolderActionApproval(shortcuts: capabilities.shortcuts)
            GroupBox("Apple on-device intelligence · Optional") {
                VStack(alignment: .leading, spacing: 9) {
                    Text(localIntelligence.availabilityMessage)
                        .font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Button("Explain observed capabilities") {
                            localIntelligence.explain(
                                capabilities: capabilities.items,
                                services: system.discovery.services.count,
                                shortcutStatus: capabilities.shortcutsStatus
                            )
                        }
                        .disabled(!localIntelligence.available || localIntelligence.isRunning)
                        if localIntelligence.isRunning {
                            ProgressView().controlSize(.small)
                            Button("Cancel") { localIntelligence.cancel() }
                        }
                        Spacer()
                        Button("Check availability") { localIntelligence.refreshAvailability() }
                    }
                    if !localIntelligence.explanation.isEmpty {
                        Text(localIntelligence.explanation)
                            .font(.callout)
                            .textSelection(.enabled)
                            .accessibilityLabel("On-device explanation")
                    }
                    Text("Explicit opt-in. Only capability names and counts are provided to Apple's local model. No commands execute, and the app works without AI.")
                        .font(.caption2).foregroundStyle(.secondary)
                }.padding(8)
            }
        }
        .frame(maxWidth: 960, alignment: .leading)
        .sheet(isPresented: $showAutomationConsent, onDismiss: {
            if continueAutomationReviewAfterConsent {
                continueAutomationReviewAfterConsent = false
                showAutomationActionReview()
            }
        }) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Allow BIFROST to access local automation?")
                    .font(.title3.weight(.semibold))
                Text("Allow Once applies to this request. Allow All remembers this BIFROST capability permission. Every Shortcut or Automator run still requires separate review, and macOS permission prompts still apply.")
                    .font(.callout).foregroundStyle(.secondary)
                HStack {
                    Button("Deny", role: .destructive) {
                        permissions.save(.deny, for: .localAutomation)
                        accessFeedback = "Local automation denied. Change this in Settings → BIFROST Access."
                        showAutomationConsent = false
                    }
                    Spacer()
                    Button("Allow Once") {
                        continueAutomationReviewAfterConsent = true
                        showAutomationConsent = false
                    }
                    Button("Allow All") {
                        permissions.save(.allowAll, for: .localAutomation)
                        continueAutomationReviewAfterConsent = true
                        showAutomationConsent = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(22)
            .frame(minWidth: 520, minHeight: 210)
        }
        .confirmationDialog("Run installed Shortcut?", isPresented: $confirmShortcut) {
            if let shortcut = requestedShortcut {
                Button("Run \(shortcut)") {
                    workflowRunner.runConfirmedShortcut(shortcut, discovered: capabilities.shortcuts)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This may perform actions defined in your existing Shortcut. BIFROST does not modify it, and requires explicit confirmation for each run.")
        }
        .confirmationDialog("Run saved Automator workflow?", isPresented: $confirmAutomator) {
            if let workflow = requestedAutomator {
                Button("Run \(workflow.name)") {
                    workflowRunner.runConfirmedAutomator(workflow)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This workflow may perform actions outside BIFROST. Review the original workflow before running. No workflow is executed until you confirm.")
        }
        .onAppear { workflowRunner.refreshAutomator() }
    }

    private func requestAutomationAccess() {
        guard !workflowRunner.running else { return }
        switch permissions.decision(for: .localAutomation) {
        case .ask:
            showAutomationConsent = true
        case .allowAll:
            showAutomationActionReview()
        case .deny:
            accessFeedback = "Local automation denied by BIFROST. Review Settings → BIFROST Access."
        }
    }

    private func showAutomationActionReview() {
        accessFeedback = ""
        if requestedShortcut != nil {
            confirmShortcut = true
        } else if requestedAutomator != nil {
            confirmAutomator = true
        }
    }
}

struct RepresentationsView: View {
    @EnvironmentObject var system: BifrostSystem

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            BifrostHeader(title: "Representations", subtitle: "Observed endpoints are evidence, not automatically trusted identities.")
            HStack {
                Text(system.discovery.status)
                    .font(.caption).foregroundStyle(.secondary)
                    .lineLimit(2)
                Spacer()
                Button("Refresh Bonjour") { system.discovery.refresh() }
            }
            if system.discovery.services.isEmpty {
                ContentUnavailableView(
                    "No local representations observed",
                    systemImage: "rectangle.on.rectangle.angled",
                    description: Text("Discovery is passive. No pairing or provider access is started automatically.")
                )
            }
            ForEach(Dictionary(grouping: system.discovery.services, by: { $0.name }).keys.sorted(), id: \.self) { name in
                let services = system.discovery.services.filter { $0.name == name }
                GroupBox { nameRow(name, services) }
            }
        }.frame(maxWidth: 960, alignment: .leading)
    }

    private func nameRow(_ name: String, _ services: [NearbyService]) -> some View {
        HStack {
            BifrostFeatureIcon(symbol: "network", feature: .representation, size: 18)
            VStack(alignment: .leading) {
                Text(name).font(.headline)
                Text(services.map { $0.type }.joined(separator: " · "))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("Observed").foregroundStyle(.secondary)
        }.padding(6)
    }
}

struct ManagementView: View {
    let title: String
    @EnvironmentObject var system: BifrostSystem
    @State private var workspaceFeedback = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            BifrostHeader(
                title: title,
                subtitle: title == "App Management"
                    ? "Installed EDEN apps remain independent capability owners."
                    : "Build and release governance is supporting BIFROST functionality."
            )
            if title == "App Management" {
                HStack {
                    Text("Registered applications").font(.headline)
                    Spacer()
                    Button("Refresh") { system.refresh() }
                }
                List(system.apps.apps) { app in
                    HStack {
                        BifrostFeatureIcon(symbol: app.installed ? "square.grid.2x2.fill" : "square.dashed", feature: .apps, size: 15)
                        VStack(alignment: .leading) {
                            Text(app.name).font(.headline)
                            Text(app.path ?? "Not registered on this Mac")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if app.installed { Button("Open") { system.apps.open(app) } }
                    }
                }
                if !system.apps.lastOpenMessage.isEmpty {
                    Text(system.apps.lastOpenMessage)
                        .font(.caption).foregroundStyle(.secondary)
                }
            } else {
                GroupBox("Current project") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("BIFROST", systemImage: "hammer")
                        Text("Canonical workspace: ~/edenOS/Software Development/BIFROST")
                            .font(.caption).foregroundStyle(.secondary)
                        Text("Release actions appear only when backed by actual build evidence.")
                            .font(.caption)
                        HStack(spacing: 12) {
                            Button("Show Working Project") {
                                showFolder("edenOS/Software Development/BIFROST")
                            }
                            Button("Show Test Releases") {
                                showFolder("edenOS/Releases")
                            }
                        }
                        if !workspaceFeedback.isEmpty {
                            Text(workspaceFeedback)
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }.frame(maxWidth: 960, alignment: .leading)
    }

    private func showFolder(_ relativePath: String) {
        let target = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(relativePath, isDirectory: true)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: target.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            workspaceFeedback = "Folder unavailable: \(target.lastPathComponent)"
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([target])
        workspaceFeedback = "Requested Finder access to \(target.lastPathComponent)."
    }
}

struct SettingsView: View {
    @EnvironmentObject private var system: BifrostSystem
    @EnvironmentObject private var headless: HeadlessClient
    @State private var menuControllerFeedback = ""

    var body: some View {
        Form {
            Section("Interface") {
                Picker("Interface complexity", selection: $system.complexity) {
                    ForEach(Complexity.allCases) { Text($0.rawValue).tag($0) }
                }
            }
            Section("Menu Bar · Independent Controller") {
                Button("Open BIFROST Menu Controller") { openMenuController() }
                Button("Approve This BIFROST App for Headless Open") {
                    approveThisNativeApp()
                }
                Text("The independent menu controller can remain active after the full app quits. It never starts Headless automatically.")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("Headless status indicator", isOn: Binding(
                    get: { headless.preferences.statusIndicators.contains("headless") },
                    set: { headless.setHeadlessIndicator($0) }
                ))
                Text("Other menu visibility options are controlled directly from BIFROST Menu → Customize Menu Bar.")
                    .font(.caption).foregroundStyle(.secondary)
                if !menuControllerFeedback.isEmpty {
                    Text(menuControllerFeedback).font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Headless · This Mac") {
                LabeledContent("Service", value: headless.stateMessage)
                HStack {
                    if headless.isRunning {
                        Button("Stop Headless") { headless.stop() }
                        Button("Open Local Dashboard") { headless.openWeb() }
                    } else {
                        Button("Start Headless…") { headless.start() }
                    }
                    Button("Refresh") { headless.refresh() }
                }
                Text("Headless listens only on 127.0.0.1. It does not start with BIFROST, and closing the interface does not stop it.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Keep Awake") {
                Picker("Default duration", selection: Binding(
                    get: { headless.preferences.caffeinateMinutes },
                    set: { headless.setCaffeinateMinutes($0) }
                )) {
                    Text("30 minutes").tag(30)
                    Text("60 minutes").tag(60)
                    Text("120 minutes").tag(120)
                    Text("Until stopped").tag(0)
                }
                Toggle("Prevent Mac sleep", isOn: Binding(
                    get: { headless.caffeinateActive },
                    set: { $0 ? headless.startCaffeinate() : headless.stopCaffeinate() }
                )).disabled(!headless.isRunning)
            }
            Section("BIFROST Access · First Use & Permissions") {
                BifrostPermissionSettingsView()
            }
            Section("Local capabilities") {
                LabeledContent("Discovered services",
                               value: "\(system.discovery.services.count)")
                LabeledContent("Available capabilities",
                               value: "\(system.capabilities.items.filter { $0.available }.count)")
                Text("Online integrations have their own plugin lifecycle and permissions.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if !headless.feedback.isEmpty {
                Text(headless.feedback).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(minWidth: 550, minHeight: 520)
    }

    private func approveThisNativeApp() {
        do {
            let approved = try BIFROSTNativeAppLocation.approve(Bundle.main.bundleURL)
            menuControllerFeedback = "Approved \(approved.lastPathComponent) for user-initiated Headless launch."
        } catch {
            menuControllerFeedback = "App approval failed: \(error.localizedDescription)"
        }
    }

    private func openMenuController() {
        let expected = "eden.private.bifrost.menu"
        let folder = Bundle.main.bundleURL.deletingLastPathComponent()
        let embedded = Bundle.main.bundleURL.appendingPathComponent(
            "Contents/Library/LoginItems/BIFROSTMenu.app"
        )
        let appName = Bundle.main.bundleURL.lastPathComponent
        let exactPartner = folder.appendingPathComponent(appName.replacingOccurrences(
            of: "BIFROST_VersionZero_", with: "BIFROST_Menu_"
        ))
        let sibling = (try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ))?.filter { $0.pathExtension.lowercased() == "app"
                      && $0.lastPathComponent.hasPrefix("BIFROST_Menu_") } ?? []

        // Prefer this release's exact partner over older LaunchServices
        // registrations or unrelated historical test candidate bundles.
        let candidates = [embedded, exactPartner] +
            (NSWorkspace.shared.urlForApplication(withBundleIdentifier: expected).map { [$0] } ?? []) +
            (sibling.count == 1 ? sibling : [])
        guard let menuApp = candidates.first(where: {
            Bundle(url: $0)?.bundleIdentifier == expected
        }) else {
            menuControllerFeedback = "Menu controller not installed. Use the separate BIFROST Menu test app."
            return
        }
        NSWorkspace.shared.openApplication(
            at: menuApp,
            configuration: NSWorkspace.OpenConfiguration()
        ) { _, error in
            Task { @MainActor in
                menuControllerFeedback = error.map {
                    "Menu launch failed: \($0.localizedDescription)"
                } ?? "macOS accepted the independent menu controller launch."
            }
        }
    }
}

