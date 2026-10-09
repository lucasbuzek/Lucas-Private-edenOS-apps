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
            case .developer, .tools: return .advanced
            default: return .simple
            }
        }
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

    @Published var mode: Mode = .clean { didSet { if oldValue != mode { resetOutput() } } }
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
            if mode.minLevel > level { mode = .clean }
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

    func resetOutput() { out = nil; results = []; selection = []; message = "" }

    // MARK: scans

    func run(_ title: String, work: @escaping @Sendable () -> ScanOutput) {
        guard !busy else { return }
        busy = true; busyTitle = title + "…"
        results = []; message = ""; selection = []
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
