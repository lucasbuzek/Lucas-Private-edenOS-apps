import SwiftUI
import AppKit

@MainActor
final class Model: ObservableObject {
    enum Mode: String, CaseIterable, Identifiable, Hashable {
        case clean = "Clean"
        case organize = "Organize"
        case crew = "Full Crew"
        case recovery = "Recovery"
        case developer = "Developer"
        case tools = "Tools"
        var id: String { rawValue }
        /// Lowest disclosure level at which this section appears in the sidebar.
        var minLevel: Level {
            switch self {
            case .developer: return .advanced
            case .tools: return .advanced
            default: return .simple
            }
        }
    }

    enum Workspace: String {
        case system, results, recovery, settings
    }

    enum Appearance: String, CaseIterable, Identifiable {
        case automatic = "Automatic", light = "Light", dark = "Dark"
        var id: String { rawValue }
        var scheme: ColorScheme? {
            switch self {
            case .automatic: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }
    @Published var appearance: Appearance = Appearance(rawValue: UserDefaults.standard.string(forKey: "janitorAppearance") ?? "Automatic") ?? .automatic {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: "janitorAppearance") }
    }

    @Published var workspace: Workspace = .system
    @Published var workspaceTitle = "System Check"
    @Published var showInspector: Bool = UserDefaults.standard.object(forKey: "janitorInspectorOpen") as? Bool ?? true {
        didSet { UserDefaults.standard.set(showInspector, forKey: "janitorInspectorOpen") }
    }
    @Published var expandedSidebarGroups: [String] = UserDefaults.standard.stringArray(forKey: "janitorExpandedGroups") ?? ["Maintenance"] {
        didSet { UserDefaults.standard.set(expandedSidebarGroups, forKey: "janitorExpandedGroups") }
    }
    @Published var inspectedCandidateID: UUID?
    @Published var systemReport: SystemCheckReport?
    @Published var systemReportMessage = ""

    var inspectedCandidate: Candidate? {
        guard let id = inspectedCandidateID else { return nil }
        return out?.candidates.first(where: { $0.id == id })
    }

    func sidebarIsExpanded(_ group: String) -> Bool { expandedSidebarGroups.contains(group) }
    func setSidebarExpanded(_ group: String, expanded: Bool) {
        if expanded && !expandedSidebarGroups.contains(group) { expandedSidebarGroups.append(group) }
        if !expanded { expandedSidebarGroups.removeAll { $0 == group } }
    }

    func runSystemCheck() {
        guard !busy else { return }
        workspace = .system
        workspaceTitle = "System Check"
        inspectedCandidateID = nil
        busy = true
        busyTitle = "Checking system information…"
        systemReportMessage = ""
        task = Task.detached(priority: .userInitiated) { [weak self] in
            let report = SystemInspector.inspect()
            let interrupted = Task.isCancelled
            await self?.finishSystemCheck(report, cancelled: interrupted)
        }
    }

    private func finishSystemCheck(_ report: SystemCheckReport, cancelled: Bool) {
        busy = false
        systemReport = report
        if cancelled { systemReportMessage = "Check interrupted. Some findings may be incomplete; run it again for a current snapshot." }
        Report.write("System Check", lines: report.areas.map { "\($0.title): \($0.state.rawValue) — \($0.summary)" }
                     + report.recommendations.map { "Suggestion: \($0.title) — \($0.reason)" } + report.notes)
    }

    @Published var mode: Mode = .clean { didSet { if oldValue != mode { resetOutput() } } }
    @Published var showTreemap = false
    @Published var busy = false
    @Published var busyTitle = ""
    @Published var out: ScanOutput?
    @Published var selection = Set<UUID>()
    @Published var results: [ActionResult] = []
    @Published var message = ""
    @Published var ops: [QOp] = []
    @Published var openOp: String?
    @Published var opSelection = Set<String>()
    @Published var rootMap: [String: String] = (UserDefaults.standard.dictionary(forKey: "workRoots") as? [String: String]) ?? [:] {
        didSet { UserDefaults.standard.set(rootMap, forKey: "workRoots") }
    }

    /// The analysis root is remembered per mode, so a root chosen in one mode can never leak into another.
    var workRoot: URL? {
        get { rootMap[mode.rawValue].map { URL(fileURLWithPath: $0, isDirectory: true) } }
        set { rootMap[mode.rawValue] = newValue?.path }
    }

    /// Disclosure level (Simple / Advanced / Expert). Changes what is shown, never what is allowed to be unsafe.
    @Published var level: Level = Level(rawValue: UserDefaults.standard.integer(forKey: "level")) ?? .simple {
        didSet {
            UserDefaults.standard.set(level.rawValue, forKey: "level")
            // Interface complexity never invalidates or clears an already displayed result.
        }
    }
    /// Per-feature expansion ("More options"), keyed by Mode.rawValue.
    @Published var featureLevels: [String: Int] = (UserDefaults.standard.dictionary(forKey: "featureLevels") as? [String: Int]) ?? [:] {
        didSet { UserDefaults.standard.set(featureLevels, forKey: "featureLevels") }
    }
    func effective(_ feature: String? = nil) -> Level {
        let f = feature ?? mode.rawValue
        return max(level, Level(rawValue: featureLevels[f] ?? 0) ?? .simple)
    }
    func expand(_ feature: String) {
        if let n = Level(rawValue: effective(feature).rawValue + 1) { featureLevels[feature] = n.rawValue }
    }
    func collapse(_ feature: String) { featureLevels[feature] = nil }

    /// Pinned sections, shown at the top of the sidebar. Order = order pinned. Stored by Mode.rawValue.
    @Published var favorites: [String] = (UserDefaults.standard.stringArray(forKey: "favorites") ?? []) {
        didSet { UserDefaults.standard.set(favorites, forKey: "favorites") }
    }
    func isFavorite(_ mode: Mode) -> Bool { favorites.contains(mode.rawValue) }
    func toggleFavorite(_ mode: Mode) {
        if let i = favorites.firstIndex(of: mode.rawValue) { favorites.remove(at: i) } else { favorites.append(mode.rawValue) }
    }
    /// Favorites that are visible at the current level (a favorite never bypasses level gating).
    var visibleFavorites: [Mode] {
        favorites.compactMap { Mode(rawValue: $0) }.filter { $0.minLevel <= level }
    }

    private var task: Task<Void, Never>?

    init() {
        // v0.1.0 stored ONE shared root that leaked across modes (it made Exact Duplicates scan the whole home folder).
        UserDefaults.standard.removeObject(forKey: "workRoot")
    }

    var devRoot: URL { workRoot ?? Modes.defaultDevRoot() }

    func resetOutput() { out = nil; results = []; selection = []; message = ""; inspectedCandidateID = nil }

    // MARK: scans

    func run(_ title: String, work: @escaping @Sendable () -> ScanOutput) {
        guard !busy else { return }
        busy = true; busyTitle = title + "…"
        results = []; message = ""; selection = []; out = nil; inspectedCandidateID = nil
        task = Task.detached(priority: .userInitiated) { [weak self] in
            let o = work()
            let cancelled = Task.isCancelled
            await self?.finish(o, cancelled: cancelled)
        }
    }

    private func finish(_ o: ScanOutput, cancelled: Bool) {
        var o2 = o
        if cancelled { o2.lines.insert("Cancelled — results are PARTIAL", at: 0) }
        busy = false
        out = o2
        selection = Set(o2.candidates.filter { $0.preselect }.map { $0.id })
        Report.write(o2.title, lines: Report.scanLines(o2))
    }

    func cancel() { task?.cancel() }

    func chooseAndScan() {
        let p = NSOpenPanel()
        p.canChooseDirectories = true; p.canChooseFiles = false; p.allowsMultipleSelection = false
        p.message = "Choose a local folder to inspect"; p.prompt = "Inspect"
        if p.runModal() == .OK, let u = p.url { run("Scanning \(u.lastPathComponent)") { Modes.chosen(u) } }
    }

    func chooseWorkRoot() {
        let p = NSOpenPanel()
        p.canChooseDirectories = true; p.canChooseFiles = false; p.allowsMultipleSelection = false
        p.message = "Choose the folder to analyse"; p.prompt = "Choose"
        if p.runModal() == .OK, let u = p.url { workRoot = u }
    }

    func chooseQuarantineRoot() {
        let p = NSOpenPanel()
        p.canChooseDirectories = true; p.canChooseFiles = false; p.canCreateDirectories = true; p.allowsMultipleSelection = false
        p.message = "Choose a LOCAL folder for quarantine (not iCloud / cloud-provider storage)"; p.prompt = "Use"
        if p.runModal() == .OK, let u = p.url { UserDefaults.standard.set(u.path, forKey: "quarantineRoot") }
    }

    /// Explicit user-installed bundle quarantine. Only a direct child of ~/Applications may be moved.
    /// This is not an app-support/remnant uninstaller and never removes shared/system applications.
    func chooseAppForQuarantine() {
        guard !busy else { return }
        let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true)
        let panel = NSOpenPanel()
        panel.directoryURL = dir
        panel.allowedContentTypes = [.applicationBundle]
        panel.canChooseFiles = true; panel.canChooseDirectories = false; panel.allowsMultipleSelection = false
        panel.message = "Select a user-installed application directly inside ~/Applications. Its data and support files will remain untouched."
        panel.prompt = "Review app"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let canonical = url.standardizedFileURL
        guard canonical.deletingLastPathComponent().resolvingSymlinksInPath().path == dir.resolvingSymlinksInPath().path,
              canonical.pathExtension.lowercased() == "app",
              Storage.classify(canonical) == .local,
              (try? canonical.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink != true,
              !NSWorkspace.shared.runningApplications.contains(where: { $0.bundleURL?.standardizedFileURL == canonical }) else {
            message = "REFUSED: only non-running, local app bundles directly in ~/Applications can be quarantined"
            return
        }
        let alert = NSAlert()
        alert.messageText = "Quarantine \(canonical.lastPathComponent)?"
        alert.informativeText = "Moves this app bundle to JANITOR's local recovery area. It does not remove preferences, support files or login items. Restore it from Recovery."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Quarantine app")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        busy = true; busyTitle = "Quarantining application…"
        let candidate = Candidate(url: canonical, category: "USER APP", bytes: 0, note: "User-confirmed application bundle", preselect: false)
        Task.detached(priority: .userInitiated) { [weak self] in
            // Recheck before mutation; quarantine enforces same-volume moves and recovery manifest.
            guard Storage.classify(canonical) == .local,
                  canonical.deletingLastPathComponent().resolvingSymlinksInPath().path == dir.resolvingSymlinksInPath().path else {
                await self?.finishAction("App quarantine", [ActionResult(state: "SKIPPED", name: canonical.lastPathComponent, detail: "Ownership/path changed")], reclaimed: 0)
                return
            }
            guard !NSWorkspace.shared.runningApplications.contains(where: { $0.bundleURL?.standardizedFileURL == canonical }) else {
                await self?.finishAction("App quarantine", [ActionResult(state: "SKIPPED", name: canonical.lastPathComponent, detail: "App became active; close it first")], reclaimed: 0)
                return
            }
            let result = Quarantine.move([candidate], label: "User-Application")
            await self?.finishAction("App quarantine", result.results, reclaimed: 0)
        }
    }

    /// Disable only a user-owned launch agent by moving its plist to recoverable quarantine.
    /// This does not claim the currently running job is stopped; a logout may be needed.
    func chooseUserLaunchAgent() {
        guard !busy else { return }
        let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents", isDirectory: true)
        let panel = NSOpenPanel()
        panel.directoryURL = dir
        panel.allowedContentTypes = [.propertyList]
        panel.canChooseFiles = true; panel.canChooseDirectories = false; panel.allowsMultipleSelection = false
        panel.message = "Select a user LaunchAgent plist to disable on subsequent login. Running processes are not terminated."
        guard panel.runModal() == .OK, let selected = panel.url else { return }
        let u = selected.standardizedFileURL
        guard u.deletingLastPathComponent().resolvingSymlinksInPath().path == dir.resolvingSymlinksInPath().path,
              u.pathExtension.lowercased() == "plist",
              (try? u.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink != true,
              Storage.classify(u) == .local else { message = "REFUSED: only local user LaunchAgents plists can be managed"; return }
        let alert = NSAlert()
        alert.messageText = "Disable user login agent?"
        alert.informativeText = "Move \(u.lastPathComponent) to recoverable quarantine. This changes future startup, not the currently running process. Restore through Recovery."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Quarantine startup entry"); alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        busy = true; busyTitle = "Disabling user startup entry…"
        Task.detached(priority: .userInitiated) { [weak self] in
            guard u.deletingLastPathComponent().resolvingSymlinksInPath().path == dir.resolvingSymlinksInPath().path,
                  Storage.classify(u) == .local else {
                await self?.finishAction("Startup quarantine", [ActionResult(state: "SKIPPED", name: u.lastPathComponent, detail: "Path changed")], reclaimed: 0); return
            }
            let c = Candidate(url: u, category: "USER LAUNCH AGENT", bytes: 0, note: "User-confirmed future login disable", preselect: false)
            let result = Quarantine.move([c], label: "User-LaunchAgent")
            await self?.finishAction("Startup quarantine", result.results, reclaimed: 0)
        }
    }

    /// Provider-safe native file metadata inspection. Never opens contents or starts downloads.
    func chooseCloudItemMetadata() {
        guard !busy else { return }
        let panel = NSOpenPanel()
        panel.canChooseFiles = true; panel.canChooseDirectories = false; panel.allowsMultipleSelection = false
        panel.message = "Choose a cloud-backed file to inspect native URL residency metadata. No download is requested."
        guard panel.runModal() == .OK, let url = panel.url else { return }
        run("Cloud item metadata") { Modes.cloudItemMetadata(url) }
    }

    /// User-visible, user-owned application termination. No kill -9 or arbitrary PID access.
    func chooseUserAppToQuit() {
        guard !busy else { return }
        let homeApps = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path + "/"
        let candidates = NSWorkspace.shared.runningApplications.filter { app in
            guard let u = app.bundleURL else { return false }
            return u.standardizedFileURL.path.hasPrefix(homeApps) && !app.isTerminated && app.processIdentifier != ProcessInfo.processInfo.processIdentifier
        }.sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
        guard !candidates.isEmpty else { message = "No running user-installed apps found in ~/Applications"; return }
        let alert = NSAlert()
        alert.messageText = "Request user app to quit"
        alert.informativeText = "Choose a running application installed under ~/Applications. A normal quit is requested; unsaved work may prevent quitting. No force kill is used."
        alert.addButton(withTitle: "Request Quit"); alert.addButton(withTitle: "Cancel")
        let selector = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 350, height: 28), pullsDown: false)
        for a in candidates { selector.addItem(withTitle: "\(a.localizedName ?? "Application") (PID \(a.processIdentifier))") }
        alert.accessoryView = selector
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let index = selector.indexOfSelectedItem
        guard candidates.indices.contains(index) else { return }
        let app = candidates[index]
        guard !app.isTerminated, app.bundleURL?.standardizedFileURL.path.hasPrefix(homeApps) == true else { message = "REFUSED: application changed"; return }
        let requested = app.terminate()
        message = requested ? "Normal quit requested for \(app.localizedName ?? "application"); completion not yet verified" : "Application refused the normal quit request"
    }

    // MARK: actions on candidates

    func selected() -> [Candidate] { (out?.candidates ?? []).filter { selection.contains($0.id) } }

    func quarantineSelected() {
        let items = selected()
        guard !items.isEmpty, !busy else { return }
        let label = (out?.title ?? "Cleanup").replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: "/", with: "-")
        busy = true; busyTitle = "Moving \(items.count) item(s) to quarantine…"
        Task.detached(priority: .userInitiated) { [weak self] in
            let g = Model.splitKeepers(items)
            let r = Quarantine.move(g.ok, label: label)
            await self?.finishAction("Quarantine", g.blocked + r.results, reclaimed: 0)
        }
    }

    func deleteSelected() {
        let items = selected()
        guard !items.isEmpty, !busy else { return }
        busy = true; busyTitle = "Deleting \(items.count) item(s)…"
        let freeBefore = Maint.free()
        Task.detached(priority: .userInitiated) { [weak self] in
            let g = Model.splitKeepers(items)
            let r = Quarantine.deleteCandidates(g.ok)
            await self?.finishAction("Delete", g.blocked + r.results, reclaimed: r.reclaimed, freeBefore: freeBefore)
        }
    }

    /// Duplicate candidates are only actionable while their kept copy still exists, is unchanged in size,
    /// and is not itself part of the selection. Anything else is SKIPPED (never the last copy).
    nonisolated static func splitKeepers(_ items: [Candidate]) -> (ok: [Candidate], blocked: [ActionResult]) {
        let paths = Set(items.map { $0.url.path })
        var ok: [Candidate] = []
        var blocked: [ActionResult] = []
        for c in items {
            if let k = c.keeper {
                let ks = (try? k.resourceValues(forKeys: [.fileSizeKey]))?.fileSize
                let cs = (try? c.url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize
                if !FileManager.default.fileExists(atPath: k.path) || paths.contains(k.path) || ks == nil || (cs != nil && ks != cs) {
                    blocked.append(ActionResult(state: "SKIPPED", name: c.title,
                                                detail: "Kept copy missing, changed or also selected — refusing to remove the last copy"))
                    continue
                }
            }
            ok.append(c)
        }
        return (ok, blocked)
    }

    private func finishAction(_ title: String, _ res: [ActionResult], reclaimed: Int64, freeBefore: Int64? = nil) {
        busy = false
        results = res
        let handled = Set(res.filter { ["MOVED", "DELETED", "MISSING"].contains($0.state) }.compactMap { $0.cid })
        out?.candidates.removeAll { handled.contains($0.id) }
        selection.subtract(handled)
        let counts = Dictionary(grouping: res, by: { $0.state }).mapValues { $0.count }
        var msg = counts.sorted { $0.key < $1.key }.map { "\($0.value) \($0.key)" }.joined(separator: " · ")
        if reclaimed > 0 {
            msg += " · removed \(fmtBytes(reclaimed)) (size from scan; removal verified per item)"
            if let fb = freeBefore {
                let d = Maint.free() - fb
                msg += " · free space \(d >= 0 ? "up" : "down") \(fmtBytes(abs(d))) (approximate)"
            }
        }
        if (counts["MOVED"] ?? 0) > 0 { msg += " · space is freed when the quarantine is deleted" }
        message = msg
        var lines = ["Summary: \(msg)", ""]
        lines += res.map { "[\($0.state)] \($0.name) — \($0.detail)" }
        Report.write(title, lines: lines)
        refreshOps()
    }

    // MARK: quarantine manager

    func refreshOps() {
        Task.detached { [weak self] in
            let o = Quarantine.loadOps()
            await self?.setOps(o)
        }
    }

    private func setOps(_ o: [QOp]) { ops = o }

    func restore(_ op: QOp, ids: Set<String>?) {
        guard !busy else { return }
        busy = true; busyTitle = "Restoring…"
        Task.detached { [weak self] in
            let r = Quarantine.restore(op, ids: ids)
            await self?.finishRestore(r)
        }
    }

    private func finishRestore(_ r: [ActionResult]) {
        busy = false
        results = r
        message = Dictionary(grouping: r, by: { $0.state }).map { "\($0.value.count) \($0.key)" }.sorted().joined(separator: " · ")
        opSelection = []
        Report.write("Restore", lines: r.map { "[\($0.state)] \($0.name) — \($0.detail)" })
        refreshOps()
    }

    func deleteOps(_ list: [QOp]) {
        guard !busy, !list.isEmpty else { return }
        busy = true; busyTitle = "Deleting quarantine…"
        Task.detached { [weak self] in
            var res: [ActionResult] = []
            var bytes: Int64 = 0
            for op in list { let d = Quarantine.delete(op); res.append(d.0); bytes += d.1 }
            await self?.finishAction("Quarantine delete", res, reclaimed: bytes)
        }
    }

    func oldOps(days: Int) -> [QOp] {
        let cutoff = Date().addingTimeInterval(-Double(days) * 86400)
        return ops.filter { (ISO8601DateFormatter().date(from: $0.manifest.created) ?? .distantFuture) < cutoff }
    }
}
