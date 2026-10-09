import SwiftUI
import AppKit

// Finder-style native shell. Existing JANITOR scan and recovery engines are unchanged.
private struct SidebarCommand: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let minLevel: Level
    init(_ id: String, _ name: String, _ symbol: String, _ minLevel: Level = .advanced) {
        self.id = id; self.name = name; self.symbol = symbol; self.minLevel = minLevel
    }
}

private struct SidebarTools: View {
    @EnvironmentObject private var m: Model
    let name: String
    let symbol: String
    let entries: [SidebarCommand]
    let run: (String) -> Void

    var body: some View {
        DisclosureGroup(isExpanded: Binding(
            get: { m.sidebarIsExpanded(name) },
            set: { m.setSidebarExpanded(name, expanded: $0) }
        )) {
            ForEach(entries.filter { m.level >= $0.minLevel }) { entry in
                Button { run(entry.id) } label: {
                    Label(entry.name, systemImage: entry.symbol)
                        .font(.callout)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 3)
                .help(entry.name)
            }
        } label: {
            Label(name, systemImage: symbol)
                .font(.callout.weight(.medium))
        }
    }
}

struct FinderShellView: View {
    @EnvironmentObject private var m: Model
    @State private var confirmBrew = false
    @State private var confirmSim = false
    @State private var confirmOld = false

    private let maintenance: [SidebarCommand] = [
        .init("full", "Detailed system scan", "magnifyingglass"),
        .init("choose-scan", "Scan a selected folder", "folder"),
        .init("treemap", "Interactive storage map", "rectangle.split.3x3"),
        .init("storage-map", "Folder size report", "chart.bar.xaxis"),
        .init("brew-preview", "Preview Homebrew cleanup", "eye"),
        .init("brew-run", "Run Homebrew cleanup…", "shippingbox"),
        .init("sim-preview", "Review unavailable simulators", "iphone"),
        .init("sim-run", "Remove unavailable simulators…", "trash", .expert),
        .init("old-recovery", "Purge old Recovery items…", "clock.arrow.circlepath", .expert)
    ]
    private let developer: [SidebarCommand] = [
        .init("devquick", "Development leftovers", "hammer"),
        .init("projects", "Project discovery", "square.stack.3d.up"),
        .init("builds", "Build versions", "list.number", .expert),
        .init("dependencies", "Dependencies", "shippingbox", .expert),
        .init("dev-root", "Choose developer folder…", "folder.badge.gearshape")
    ]
    private let media: [SidebarCommand] = [
        .init("media", "Find large media files", "film"),
        .init("similar-images", "Similar images", "photo.stack"),
        .init("similar-names", "Similar filenames", "textformat"),
        .init("photos-footprint", "Photos library footprint", "photo.on.rectangle")
    ]
    private let fullCrew: [SidebarCommand] = [
        .init("processes", "Running processes", "cpu"),
        .init("startup", "Startup items", "power"),
        .init("apps", "Installed applications", "square.grid.2x2"),
        .init("uninstall-review", "Uninstall ownership review", "app.badge.checkmark"),
        .init("support", "App support inventory", "tray.full"),
        .init("broken", "Broken shortcuts", "link"),
        .init("growth", "Storage diagnostics", "chart.bar"),
        .init("app-quit", "Request app to quit…", "xmark.app", .expert),
        .init("agent-disable", "Disable user login agent…", "power.circle", .expert),
        .init("app-quarantine", "Quarantine user app…", "app.badge", .expert)
    ]
    private let cloud: [SidebarCommand] = [
        .init("cloud", "Provider storage boundaries", "icloud"),
        .init("photos", "PhotoKit inventory", "photo.on.rectangle.angled"),
        .init("cloud-item", "Inspect cloud-file metadata…", "icloud.and.arrow.down")
    ]

    @ViewBuilder
    private func quick(_ name: String, icon: String, key: String) -> some View {
        Button { perform(key) } label: {
            Label(name, systemImage: icon)
                .font(.callout.weight(m.workspaceTitle == name ? .semibold : .regular))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
        .listRowBackground(m.workspaceTitle == name ? Color.accentColor.opacity(0.15) : Color.clear)
    }

    private var sidebar: some View {
        List {
            Section("QUICK ACTIONS") {
                quick("System Check", icon: "checkmark.shield", key: "system")
                quick("Quick Scan", icon: "bolt", key: "quick")
                quick("Storage", icon: "internaldrive", key: "storage")
                quick("Duplicates", icon: "doc.on.doc", key: "duplicates")
                quick("Recovery", icon: "arrow.uturn.backward", key: "recovery")
            }
            if m.level >= .advanced {
                Section("MORE TOOLS") {
                    SidebarTools(name: "Maintenance", symbol: "wrench", entries: maintenance, run: perform)
                    SidebarTools(name: "Developer", symbol: "hammer", entries: developer, run: perform)
                    SidebarTools(name: "Media", symbol: "photo", entries: media, run: perform)
                    SidebarTools(name: "Full Crew", symbol: "slider.horizontal.3", entries: fullCrew, run: perform)
                    SidebarTools(name: "Cloud & Photos", symbol: "icloud", entries: cloud, run: perform)
                }
            }
            Section {
                quick("Settings", icon: "gearshape", key: "settings")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("JANITOR")
        .navigationSplitViewColumnWidth(min: 205, ideal: 235, max: 285)
        .disabled(m.busy)
    }

    private var mainPane: some View {
        Group {
            switch m.workspace {
            case .system:
                SystemCheckWorkspace(run: perform)
            case .recovery:
                QuarantineView()
            case .settings:
                SettingsView()
            case .results:
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(m.workspaceTitle).font(.title2.bold())
                        Spacer()
                        if m.workspaceTitle == "Storage" {
                            Button("Storage map") { perform("treemap") }
                        }
                        if m.mode == .organize || m.mode == .developer {
                            Button("Choose folder…") { m.chooseWorkRoot() }
                        }
                    }
                    Divider()
                    ResultsView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            HSplitView {
                mainPane.frame(minWidth: 450)
                if m.showInspector {
                    SystemInspectorPanel(run: perform)
                        .frame(minWidth: 260, idealWidth: 300, maxWidth: 360)
                        .background(Color(nsColor: .controlBackgroundColor))
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Picker("Interface", selection: $m.level) {
                        ForEach(Level.allCases) { level in
                            Text(level.label).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 112)
                    .help("Interface complexity: Standard, Advanced or Expert")
                    Button {
                        m.showInspector.toggle()
                    } label: {
                        Image(systemName: "sidebar.right")
                    }
                    .help(m.showInspector ? "Hide Inspector" : "Show Inspector")
                    Button { perform("settings") } label: {
                        Image(systemName: "gearshape")
                    }
                    .help("Settings")
                }
            }
        }
        .sheet(isPresented: $m.showTreemap) {
            TreemapWindow(root: m.workRoot ?? Storage.home)
        }
        .confirmationDialog("Run Homebrew cleanup?", isPresented: $confirmBrew) {
            Button("Run cleanup") {
                m.run("Homebrew cleanup") { Maint.brew(dryRun: false) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Homebrew manages its own files. Preview the result before running cleanup.")
        }
        .confirmationDialog("Remove simulators that Xcode marks unavailable?", isPresented: $confirmSim) {
            Button("Remove unavailable simulators", role: .destructive) {
                m.run("Remove unavailable simulators") { Maint.simulators(dryRun: false) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Uses Xcode's native simctl delete unavailable. Active simulators are not selected.")
        }
        .confirmationDialog("Permanently remove Recovery operations older than 30 days?", isPresented: $confirmOld) {
            Button("Permanently delete", role: .destructive) { m.deleteOps(m.oldOps(days: 30)) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Permanently deleted Recovery items cannot be restored.")
        }
    }

    /// Every navigation action calls an existing JANITOR capability; none bypasses its safety contract.
    private func perform(_ key: String) {
        guard !m.busy else { return }

        switch key {
        case "system":
            m.runSystemCheck()
            return
        case "recovery":
            m.mode = .recovery
            m.workspaceTitle = "Recovery"
            m.workspace = .recovery
            m.refreshOps()
            return
        case "settings":
            m.workspaceTitle = "Settings"
            m.workspace = .settings
            return
        default: break
        }

        let group: Model.Mode
        let title: String
        switch key {
        case "quick": group = .clean; title = "Quick Scan"
        case "storage", "treemap", "storage-map", "full", "choose-scan", "brew-preview",
             "brew-run", "sim-preview", "sim-run", "old-recovery": group = .clean; title = "Storage"
        case "duplicates", "media", "similar-images", "similar-names", "photos-footprint": group = .organize; title = "Media"
        case "devquick", "projects", "builds", "dependencies", "dev-root": group = .developer; title = "Developer"
        default: group = .crew; title = "Full Crew"
        }
        m.mode = group
        m.workspace = .results
        m.workspaceTitle = key == "duplicates" ? "Duplicates" : title

        switch key {
        case "quick": m.run("Quick Scan") { Modes.quick(full: false) }
        case "storage": m.run("Storage Overview") { Modes.overview() }
        case "duplicates":
            let root = m.workRoot
            m.run("Exact duplicates") { Modes.duplicates(root: root) }
        case "treemap": m.showTreemap = true
        case "storage-map":
            let root = m.workRoot
            m.run("Storage folder report") { Modes.storageTreemap(root: root) }
        case "full": m.run("Full Scan") { Modes.quick(full: true) }
        case "choose-scan": m.chooseAndScan()
        case "brew-preview": m.run("Homebrew preview") { Maint.brew(dryRun: true) }
        case "brew-run": confirmBrew = true
        case "sim-preview": m.run("Simulator preview") { Maint.simulators(dryRun: true) }
        case "sim-run": confirmSim = true
        case "old-recovery": m.refreshOps(); confirmOld = true
        case "devquick": m.run("Development cleanup review") { Modes.devQuick() }
        case "projects":
            let root = m.devRoot
            m.run("Project discovery") { Modes.projects(root: root) }
        case "builds":
            let root = m.devRoot
            m.run("Build families") { Modes.buildFamilies(root: root) }
        case "dependencies":
            let root = m.devRoot
            m.run("Dependency discovery") { Modes.dependencies(root: root) }
        case "dev-root": m.chooseWorkRoot()
        case "media":
            let root = m.workRoot
            m.run("Media inventory") { Modes.media(root: root) }
        case "similar-images":
            let root = m.workRoot
            m.run("Similar images") { Modes.similarImages(root: root) }
        case "similar-names":
            let root = m.workRoot
            m.run("Similar filenames") { Modes.similarNames(root: root) }
        case "photos-footprint": m.run("Photos library footprint") { Modes.photosFootprint() }
        case "processes": m.run("Running processes") { Modes.processes() }
        case "startup": m.run("Startup items") { Modes.startup() }
        case "apps": m.run("Installed apps") { Modes.appsInventory() }
        case "uninstall-review": m.run("App ownership review") { Modes.appUninstallReview() }
        case "support": m.run("App support inventory") { Modes.supportInventory() }
        case "broken":
            let root = m.workRoot ?? Storage.home
            m.run("Broken shortcuts") { Modes.broken(root: root) }
        case "growth": m.run("Storage diagnostics") { Modes.storageGrowth() }
        case "app-quit": m.chooseUserAppToQuit()
        case "agent-disable": m.chooseUserLaunchAgent()
        case "app-quarantine": m.chooseAppForQuarantine()
        case "cloud": m.run("Cloud boundaries") { Modes.cloudResidency() }
        case "photos": m.run("Photos inventory") { Modes.photoKitInventory() }
        case "cloud-item": m.chooseCloudItemMetadata()
        default: break
        }
    }
}

// Central, on-demand summary. No fake health scores and no implied completed checks.
private struct SystemCheckWorkspace: View {
    @EnvironmentObject private var m: Model
    let run: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("System Check").font(.title2.bold())
                        Text("A quick, read-only look at maintenance opportunities.")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        run("system")
                    } label: {
                        Label(m.systemReport == nil ? "Run system check" : "Check again", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(m.busy)
                }
                if m.busy {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text(m.busyTitle)
                        Spacer()
                        Button("Cancel") { m.cancel() }
                    }.font(.callout)
                }
                if let report = m.systemReport {
                    Text("Last checked \(report.finishedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                    if !m.systemReportMessage.isEmpty {
                        Label(m.systemReportMessage, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                    HStack(spacing: 12) {
                        StatCard(label: "Suggested for review", value: "\(report.suggestedCount) items",
                                 detail: fmtBytes(report.suggestedBytes))
                        StatCard(label: "Need individual review", value: "\(report.manualCount) items",
                                 detail: "No automatic decisions")
                    }
                    Text("Recommended next actions").font(.headline)
                    if report.recommendations.isEmpty {
                        Text("No further actions recommended by these limited checks.")
                            .font(.callout).foregroundStyle(.secondary)
                    } else {
                        ForEach(report.recommendations) { advice in
                            Button { run(advice.action) } label: {
                                HStack(alignment: .center, spacing: 12) {
                                    Image(systemName: advice.priority == .attention ? "exclamationmark.triangle" : "arrow.forward.circle")
                                        .foregroundStyle(advice.priority == .attention ? Color.orange : Color.accentColor)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(advice.title).font(.subheadline.bold()).foregroundStyle(.primary)
                                        Text(advice.reason).font(.caption).foregroundStyle(.secondary)
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(.secondary)
                                }
                                .padding(10)
                                .background(Color(nsColor: .controlBackgroundColor),
                                            in: RoundedRectangle(cornerRadius: 9))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Text("What was checked").font(.headline)
                    ForEach(report.areas) { area in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(area.title).font(.subheadline.bold())
                                Spacer()
                                SystemCheckStatus(state: area.state)
                            }
                            Text(area.summary).font(.callout)
                            Text(area.detail).font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                        Divider().opacity(0.5)
                    }
                    DisclosureGroup("Scope and limitations") {
                        ForEach(report.notes, id: \.self) { note in
                            Text(note).font(.caption).foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                } else if !m.busy {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("No system check has been run in this session.", systemImage: "checkmark.shield")
                            .font(.headline)
                        Text("JANITOR will check available storage, temporary-file candidates, user startup entries and cloud/Photos access boundaries. More expensive scans run only if you select them.")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .controlBackgroundColor),
                                in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct StatCard: View {
    let label: String
    let value: String
    let detail: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline)
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor),
                    in: RoundedRectangle(cornerRadius: 9))
    }
}

private struct SystemCheckStatus: View {
    let state: SystemCheckReport.State
    var body: some View {
        let color: Color = state == .attention ? .orange : state == .normal ? .green : .secondary
        Text(state.rawValue).font(.caption2).foregroundStyle(color)
    }
}

// Optional detail column: context-sensitive item details or last System Check.
private struct SystemInspectorPanel: View {
    @EnvironmentObject private var m: Model
    let run: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    Image(systemName: "sidebar.right").foregroundStyle(.secondary)
                    Text("Inspector").font(.headline)
                    Spacer()
                    Button { m.showInspector = false } label: {
                        Image(systemName: "xmark").font(.caption)
                    }.buttonStyle(.borderless).help("Hide Inspector")
                }
                Divider()
                if let candidate = m.inspectedCandidate, m.workspace == .results {
                    Text("Selected item").font(.caption).foregroundStyle(.secondary)
                    Text(candidate.title).font(.headline).textSelection(.enabled)
                    DetailEntry(label: "Size", value: candidate.bytes > 0 ? fmtBytes(candidate.bytes) : "Not measured")
                    DetailEntry(label: "Type", value: friendlyCategory(candidate.category))
                    DetailEntry(label: "Why JANITOR listed it", value: friendlyReason(candidate))
                    DetailEntry(label: "Location", value: Modes.abbrev(candidate.url.path))
                    if let keeper = candidate.keeper {
                        DetailEntry(label: "Copy to keep", value: Modes.abbrev(keeper.path))
                    }
                    Button("Reveal in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([candidate.url])
                    }
                    Text("Inspecting an item does not select it for removal. To act, use the central results list and confirmation.")
                        .font(.caption).foregroundStyle(.secondary)
                } else if let report = m.systemReport {
                    Text("Last System Check").font(.subheadline.bold())
                    Text(report.finishedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption).foregroundStyle(.secondary)
                    ForEach(report.areas) { area in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(area.title).font(.callout.bold())
                                Spacer()
                                SystemCheckStatus(state: area.state)
                            }
                            Text(area.summary).font(.caption).foregroundStyle(.secondary)
                        }
                        Divider().opacity(0.4)
                    }
                    if !report.recommendations.isEmpty {
                        Text("Suggested next steps").font(.subheadline.bold())
                        ForEach(report.recommendations.prefix(4)) { advice in
                            Button(advice.title) { run(advice.action) }
                                .buttonStyle(.link)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    Button("Run system check again") { run("system") }
                        .disabled(m.busy)
                } else {
                    Text("System Inspector").font(.subheadline.bold())
                    Text("Run a quick system check to see evidence-based recommendations. Select a result and choose Details to inspect a file.")
                        .font(.callout).foregroundStyle(.secondary)
                    Button("Run system check") { run("system") }
                        .disabled(m.busy)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct DetailEntry: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption.bold()).foregroundStyle(.secondary)
            Text(value).font(.callout).textSelection(.enabled)
        }
    }
}
