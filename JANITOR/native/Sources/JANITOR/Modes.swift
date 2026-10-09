import Foundation
import AppKit
import Photos
import Vision

/// All scan / inspection implementations. Pure functions: bounded, deadline-driven, error-tolerant.
enum Modes {
    static let home = FileManager.default.homeDirectoryForCurrentUser
    static func path(_ rel: String) -> URL { home.appendingPathComponent(rel) }
    static func abbrev(_ p: String) -> String { p.hasPrefix(home.path) ? "~" + String(p.dropFirst(home.path.count)) : p }
    static func exists(_ u: URL) -> Bool { FileManager.default.fileExists(atPath: u.path) }
    static func mtime(_ u: URL) -> Date? { (try? u.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate }
    static func sum(_ c: [Candidate]) -> Int64 { c.reduce(Int64(0)) { $0 + $1.bytes } }

    static func volumeLine() -> String {
        let rv = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])
        let total = Int64(rv?.volumeTotalCapacity ?? 0)
        let avail = rv?.volumeAvailableCapacityForImportantUsage ?? 0
        return "Startup volume: \(fmtBytes(total)) total · \(fmtBytes(avail)) available"
    }

    static func notTraversable(_ o: inout ScanOutput, _ root: URL, _ cls: StorageClass) {
        let st: ScanStatus = cls == .protected ? .protected : .deferred
        o.roots.append(RootStatus(path: root.path, storage: cls, status: st, bytes: 0, note: "Not traversed (\(cls.rawValue))"))
        o.lines.append("\(abbrev(root.path)) is \(cls.rawValue) — \(st.rawValue). Provider and Photos content is never crawled, hashed or moved.")
    }

    // MARK: STANDARD — Quick / Full

    struct Target { let url: URL; let category: String; let skip: Set<String>; let rule: (URL) -> (String, Bool)? }

    static func quick(full: Bool) -> ScanOutput {
        var o = ScanOutput(title: full ? "Full Scan" : "Quick Scan")
        let t = Prefs.timeout
        let global = Date().addingTimeInterval(t * (full ? 8 : 4))
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        let cacheRule: (URL) -> (String, Bool)? = { u in
            u.lastPathComponent.hasPrefix("com.apple.") ? ("Apple component cache — review first", false) : ("Regenerable app cache", true)
        }
        let logRule: (URL) -> (String, Bool)? = { _ in ("Log files", true) }
        let trashRule: (URL) -> (String, Bool)? = { _ in ("Already in Trash", true) }
        let tempRule: (URL) -> (String, Bool)? = { u in
            if let d = mtime(u), Date().timeIntervalSince(d) > 14 * 86400 { return ("Stale temp data (>14 days)", true) }
            return nil
        }
        let containerRule: (URL) -> (String, Bool)? = { u in
            let comps = u.pathComponents
            let owner = comps.firstIndex(of: "Containers").map { $0 + 1 < comps.count ? comps[$0 + 1] : "?" } ?? "?"
            return ("App container cache (\(owner))", true)
        }

        var targets: [Target] = [
            Target(url: path("Library/Caches"), category: "CACHE", skip: ["Homebrew", "com.janitor.native"], rule: cacheRule),
            Target(url: path("Library/Logs"), category: "LOG", skip: ["JANITOR"], rule: logRule),
            Target(url: path(".Trash"), category: "TRASH", skip: [], rule: trashRule),
            Target(url: tmp, category: "TEMP", skip: [], rule: tempRule)
        ]
        if full, let conts = Scan.listChildren(path("Library/Containers")) {
            for c in conts.prefix(80) {
                let caches = c.appendingPathComponent("Data/Library/Caches")
                if exists(caches) { targets.append(Target(url: caches, category: "CONTAINER CACHE", skip: [], rule: containerRule)) }
            }
        }

        for tg in targets {
            if Date() > global || Task.isCancelled {
                o.roots.append(RootStatus(path: tg.url.path, storage: .unknown, status: .skipped, bytes: 0, note: "Global time budget reached"))
                continue
            }
            guard exists(tg.url) else { continue }
            let r = Scan.candidates(in: tg.url, category: tg.category, skip: tg.skip, budget: full ? t : t / 2, rule: tg.rule)
            o.candidates += r.cands
            o.roots.append(r.root)
        }

        let pre = o.candidates.filter { $0.preselect }
        o.lines.append("Safe items preselected: \(pre.count) · \(fmtBytes(sum(pre)))")
        o.lines.append("Candidates listed: \(o.candidates.count) · \(fmtBytes(sum(o.candidates)))  (unknown ≠ junk: Apple caches and anything unclassified are left unselected)")
        let notComplete = o.roots.filter { $0.status != .complete }.count
        if notComplete > 0 { o.lines.append("\(notComplete) root(s) not COMPLETE — see Roots") }
        if exists(path("Library/Caches/Homebrew")) {
            o.lines.append("Homebrew cache present — not treated as junk. Use Maintenance → Homebrew cleanup (native `brew cleanup`).")
        }

        // Shallow top-level storage + quarantine (no recursion into Downloads)
        let dl = path("Downloads")
        if Storage.classify(dl).scannable, let kids = Scan.listChildren(dl) {
            var rows: [(Int64, String)] = []
            for k in kids {
                guard let rv = try? k.resourceValues(forKeys: [.isDirectoryKey, .totalFileAllocatedSizeKey]) else { continue }
                if rv.isDirectory == true { rows.append((0, "(folder)  \(k.lastPathComponent)")) }
                else { let b = Int64(rv.totalFileAllocatedSize ?? 0); rows.append((b, "\(fmtBytes(b))  \(k.lastPathComponent)")) }
            }
            rows.sort { $0.0 > $1.0 }
            o.sections.append(InfoSection(title: "Downloads — top level only (not scanned deeper)", rows: rows.prefix(12).map { $0.1 }))
        }
        let q = Prefs.quarantineRoot
        if exists(q) {
            let r = Scan.size(of: q, deadline: Date().addingTimeInterval(min(t, 3)))
            o.lines.append("Quarantine: \(Quarantine.present(q.path) ? fmtBytes(r.bytes) : "—") on disk [\(r.status.rawValue)]")
        }
        if full {
            let ov = overview()
            o.sections += ov.sections
            o.lines.append(ov.lines.first ?? "")
        }
        return o
    }

    static func overview() -> ScanOutput {
        var o = ScanOutput(title: "Storage Overview")
        o.lines.append(volumeLine())
        let t = Prefs.timeout
        let global = Date().addingTimeInterval(t * 4)
        var rows: [(Int64, String)] = []
        var notes: [String] = []
        for k in (Scan.listChildren(home) ?? []).sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let name = k.lastPathComponent
            if name == ".Trash" { continue }
            let cls = Storage.classify(k)
            if !cls.scannable || Storage.isBoundary(k) { notes.append("\(name): \(cls.rawValue) — not traversed (DEFERRED)"); continue }
            if Date() > global || Task.isCancelled { notes.append("\(name): SKIPPED — global time budget reached"); continue }
            let r = Scan.size(of: k, deadline: Date().addingTimeInterval(t / 2))
            rows.append((r.bytes, "\(fmtBytes(r.bytes))  \(name)  [\(r.status.rawValue)]"))
        }
        rows.sort { $0.0 > $1.0 }
        let largest = max(rows.first?.0 ?? 0, 1)
        o.sections.append(InfoSection(title: "Home folder — proportional storage bars (local only)", rows: rows.prefix(25).map { item in
            let count = item.0 > 0 ? max(1, Int(Double(item.0) / Double(largest) * 24.0)) : 0
            return String(repeating: "▰", count: count) + String(repeating: "▱", count: 24 - count) + "  " + item.1
        }))
        o.lines.append("Relative size bars are scaled to the largest measured folder; PARTIAL and DEFERRED results are not complete disk totals.")
        if !notes.isEmpty { o.sections.append(InfoSection(title: "Not traversed", rows: notes)) }
        return o
    }

    // Native macOS volume/folder treemap data. No provider-managed content is traversed.
    static func storageTreemap(root: URL?) -> ScanOutput {
        var o = ScanOutput(title: "Storage Treemap — Local Folders")
        let base = root ?? home
        let cls = Storage.classify(base)
        guard cls.scannable, !Storage.isBoundary(base), !Storage.isManagedTree(base) else {
            notTraversable(&o, base, cls); return o
        }
        let children = (Scan.listChildren(base) ?? []).prefix(60)
        let deadline = Date().addingTimeInterval(Prefs.timeout * 5)
        var items: [(Int64, URL, ScanStatus)] = []
        for u in children {
            if Date() > deadline || Task.isCancelled { break }
            let c = Storage.classify(u)
            guard c.scannable, !Storage.isBoundary(u), !Storage.isManagedTree(u) else { continue }
            let r = Scan.size(of: u, deadline: Date().addingTimeInterval(min(Prefs.timeout / 2, 2)))
            items.append((r.bytes, u, r.status))
        }
        items.sort { $0.0 > $1.0 }
        let total = max(items.reduce(Int64(0)) { $0 + max(0,$1.0) }, 1)
        o.sections.append(InfoSection(title: "Local folder map — proportional blocks", rows: items.prefix(30).map { v in
            let fraction = Double(max(0,v.0)) / Double(total)
            let width = max(1, min(30, Int(fraction * 30)))
            return String(repeating: "■", count: width) + "  " + fmtBytes(v.0) + "  " + v.1.lastPathComponent + " [" + v.2.rawValue + "]"
        }))
        o.lines.append("Read-only proportional map; size estimates are bounded and may be PARTIAL. Cloud and Photos roots excluded.")
        o.roots.append(RootStatus(path: base.path, storage: cls, status: Date() > deadline ? .partial : .review, bytes: total, note: "Measured children; not a full volume census"))
        return o
    }

    static func photoKitInventory() -> ScanOutput {
        var o = ScanOutput(title: "Photos — Native PhotoKit Inventory")
        let state = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch state {
        case .authorized, .limited:
            let images = PHAsset.fetchAssets(with: .image, options: nil)
            let videos = PHAsset.fetchAssets(with: .video, options: nil)
            o.lines.append("PhotoKit authorized: \(state == .limited ? "LIMITED" : "FULL")")
            o.sections.append(InfoSection(title: "PhotoKit asset counts", rows: ["Images: \(images.count)", "Videos: \(videos.count)"]))
            o.lines.append("Counts include cloud-backed assets. Local residency and reclaimable bytes UNKNOWN. No asset data requested or modified.")
        case .notDetermined: o.lines.append("Photos permission not requested. Grant access through macOS Settings if desired.")
        default: o.lines.append("Photos access restricted or denied. No library traversal attempted.")
        }
        return o
    }

    static func cloudItemMetadata(_ url: URL) -> ScanOutput {
        var o = ScanOutput(title: "Cloud Item — Native Metadata")
        let keys: Set<URLResourceKey> = [.isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey, .ubiquitousItemIsDownloadingKey, .ubiquitousItemIsUploadedKey, .ubiquitousItemHasUnresolvedConflictsKey]
        guard let values = try? url.resourceValues(forKeys: keys) else {
            o.lines.append("Metadata unavailable. Item not opened, hydrated or modified."); return o
        }
        o.sections.append(InfoSection(title: "Native URL metadata", rows: [
            "File: " + url.lastPathComponent,
            "Ubiquitous: " + String(describing: values.isUbiquitousItem),
            "Download status: " + (values.ubiquitousItemDownloadingStatus?.rawValue ?? "UNKNOWN"),
            "Downloading: " + String(describing: values.ubiquitousItemIsDownloading),
            "Uploaded: " + String(describing: values.ubiquitousItemIsUploaded),
            "Conflicts: " + String(describing: values.ubiquitousItemHasUnresolvedConflicts)
        ]))
        o.lines.append("Native URL resource properties only. Third-party FileProvider residency may be UNKNOWN. No hydration, eviction or deletion.")
        return o
    }

    static func cloudResidency() -> ScanOutput {
        var o = ScanOutput(title: "Cloud Storage — Provider Boundaries")
        let roots = [path("Library/CloudStorage"), path("Library/Mobile Documents"), path("Pictures")]
        for root in roots where exists(root) {
            let cls = Storage.classify(root)
            if cls == .fileProvider || root.lastPathComponent == "CloudStorage" {
                o.sections.append(InfoSection(title: abbrev(root.path), rows: (Scan.listChildren(root) ?? []).prefix(35).map { "PROVIDER MANAGED — " + $0.lastPathComponent }))
                o.roots.append(RootStatus(path: root.path, storage: .fileProvider, status: .deferred, bytes: 0, note: "Metadata-only listing; residency UNKNOWN"))
            } else if root.lastPathComponent == "Pictures" {
                o.sections.append(InfoSection(title: "Photos boundaries", rows: (Scan.listChildren(root) ?? []).filter { $0.pathExtension.lowercased() == "photoslibrary" }.map { "PROTECTED — " + $0.lastPathComponent }))
            }
        }
        o.lines.append("No downloads, evictions, hydration or Photos library modification. Native residency control remains unavailable.")
        return o
    }

    static func appUninstallReview() -> ScanOutput {
        var o = ScanOutput(title: "Application Uninstall — Ownership Review")
        let apps = installedApps()
        for a in apps.prefix(150) {
            let u = URL(fileURLWithPath: a.path)
            let cls = Storage.classify(u)
            let safe = a.path.hasPrefix(home.appendingPathComponent("Applications").path + "/")
            o.sections.append(InfoSection(title: a.name, rows: ["Bundle ID: " + a.bid, "Location: " + abbrev(a.path), "Storage: " + cls.rawValue, safe ? "User-installed app; use Finder or vendor uninstaller" : "Shared/system installation; use vendor or system installer"]))
        }
        o.lines.append("Read-only inventory. No removal or remnant deletion offered without ownership and recovery verification.")
        return o
    }

    static func chosen(_ url: URL) -> ScanOutput {
        var o = ScanOutput(title: "Scan \(url.lastPathComponent)")
        let cls = Storage.classify(url)
        guard cls.scannable, !Storage.isBoundary(url) else { notTraversable(&o, url, cls); return o }
        let r = Scan.candidates(in: url, category: "USER-SELECTED — UNKNOWN", budget: Prefs.timeout * 2, minBytes: 1) { _ in
            ("Unclassified — your decision", false)
        }
        o.candidates = Storage.isBroadRoot(url) ? [] : r.cands
        if Storage.isBroadRoot(url) { o.lines.append("Home folder (or above): listing only — no deletable candidates are offered.") }
        o.roots.append(r.root)
        o.lines.append("\(abbrev(url.path)): \(fmtBytes(r.root.bytes)) [\(r.root.status.rawValue)] — nothing is preselected")
        return o
    }

    // MARK: DEVELOPER

    static func defaultDevRoot() -> URL {
        for n in ["Developer", "Projects", "Code", "dev", "src", "Xcode"] where exists(path(n)) { return path(n) }
        return path("Downloads")
    }

    static func devQuick() -> ScanOutput {
        var o = ScanOutput(title: "Developer Quick")
        let t = Prefs.timeout
        let xcodeRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dt.Xcode").isEmpty
        func add(_ r: (cands: [Candidate], root: RootStatus)) { o.candidates += r.cands; o.roots.append(r.root) }
        func one(_ rel: String, _ cat: String, _ note: String, _ pre: Bool) {
            let u = path(rel)
            guard exists(u) else { return }
            let r = Scan.single(u, category: cat, note: note, pre: pre, budget: t)
            if let c = r.0 { o.candidates.append(c) }
            o.roots.append(r.1)
        }
        let dd = path("Library/Developer/Xcode/DerivedData")
        if exists(dd) {
            add(Scan.candidates(in: dd, category: "BUILD OUTPUT", budget: t, minBytes: 1) { u in
                if xcodeRunning { return ("DerivedData — Xcode is running; review before removing", false) }
                if let d = mtime(u), Date().timeIntervalSince(d) < 600 { return ("Built in the last 10 minutes — treated as active", false) }
                return ("DerivedData (regenerable by rebuilding)", true)
            })
        }
        let sim = path("Library/Developer/CoreSimulator/Caches")
        if exists(sim) { add(Scan.candidates(in: sim, category: "SAFE CACHE", budget: t) { _ in ("Simulator cache", true) }) }
        one("Library/Caches/org.swift.swiftpm", "SAFE CACHE", "SwiftPM cache (re-downloaded on demand)", true)
        one(".npm", "SAFE CACHE", "npm cache (re-downloaded; `npm cache clean --force` is the native cleaner)", true)
        one(".gradle/caches", "SAFE CACHE", "Gradle cache (re-downloaded on demand)", true)
        let ar = path("Library/Developer/Xcode/Archives")
        if exists(ar) { add(Scan.candidates(in: ar, category: "PROJECT DATA", budget: t, minBytes: 1) { _ in ("Xcode archives are project data — review only", false) }) }
        let ds = path("Library/Developer/Xcode/iOS DeviceSupport")
        if exists(ds) { add(Scan.candidates(in: ds, category: "UNKNOWN", budget: t) { _ in ("Device support — regenerated on next connect; review age first", false) }) }

        let devices = path("Library/Developer/CoreSimulator/Devices")
        if exists(devices) {
            let r = Scan.size(of: devices, deadline: Date().addingTimeInterval(t))
            o.sections.append(InfoSection(title: "Simulator data (not listed for deletion)", rows: [
                "\(fmtBytes(r.bytes)) [\(r.status.rawValue)] CoreSimulator/Devices — PROJECT DATA. Use Standard → Maintenance → “Remove unavailable simulators” (native simctl)."]))
        }
        let pre = o.candidates.filter { $0.preselect }
        o.lines.append("Safe items preselected: \(pre.count) · \(fmtBytes(sum(pre)))")
        o.lines.append("Candidates listed: \(o.candidates.count) · \(fmtBytes(sum(o.candidates)))")
        if xcodeRunning { o.lines.append("Xcode is running — DerivedData left unselected so active compilation products are never removed blindly.") }
        return o
    }

    static let suppress: Set<String> = ["node_modules", "vendor", "Pods", ".build", "Carthage", ".venv", "venv",
                                        "site-packages", "dist-packages", "DerivedData", "target", ".gradle", "__pycache__"]

    static func projects(root: URL) -> ScanOutput {
        var o = ScanOutput(title: "Project Identity & Versions")
        let cls = Storage.classify(root)
        guard cls.scannable, !Storage.isBoundary(root) else { notTraversable(&o, root, cls); return o }
        let t = Prefs.timeout * 3
        let maxDepth = Prefs.maxDepth
        let dl = Date().addingTimeInterval(t)
        let markerFiles: [String: String] = [".git": "Git", "Package.swift": "SwiftPM", "package.json": "Node", "pyproject.toml": "Python",
                                             "Cargo.toml": "Rust", "build.gradle": "Gradle", "build.gradle.kts": "Gradle", "pom.xml": "Maven", "go.mod": "Go"]
        let markerExts: [String: String] = ["xcodeproj": "Xcode", "xcworkspace": "Xcode"]
        var found: [String: Set<String>] = [:]
        var archives: [URL] = []
        var partial = false
        if let en = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
                                                   options: [], errorHandler: { _, _ in true }) {
            var n = 0
            while let obj = en.nextObject() {
                guard let url = obj as? URL else { continue }
                n += 1
                if n % 128 == 0, Date() > dl || Task.isCancelled { partial = true; break }
                let rv = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
                if rv?.isSymbolicLink == true { continue }
                let isDir = rv?.isDirectory == true
                let name = url.lastPathComponent
                let parent = url.deletingLastPathComponent().path
                if let k = markerFiles[name] { found[parent, default: []].insert(k) }
                if isDir, let k = markerExts[url.pathExtension] { found[parent, default: []].insert(k); en.skipDescendants(); continue }
                if isDir {
                    if Storage.isBoundary(url) || suppress.contains(name) || name == ".git" { en.skipDescendants(); continue }
                    if en.level >= maxDepth { en.skipDescendants() }
                } else if ["zip", "gz", "tgz", "xip", "tar"].contains(url.pathExtension.lowercased()) {
                    archives.append(url)
                }
            }
        }
        let entries = found.map { (path: $0.key, kinds: $0.value.sorted()) }.sorted { $0.path < $1.path }
        o.roots.append(RootStatus(path: root.path, storage: cls, status: partial ? .partial : .complete, bytes: 0,
                                  note: "depth ≤ \(maxDepth), time ≤ \(Int(t))s; dependencies/vendor/node_modules suppressed"))
        o.lines.append("\(entries.count) project(s) found under \(abbrev(root.path)) [\(partial ? "PARTIAL" : "COMPLETE")]")
        o.sections.append(InfoSection(title: "Projects", rows: entries.prefix(150).map { "\($0.kinds.joined(separator: "+"))  \(abbrev($0.path))" }))

        let groups = Dictionary(grouping: entries, by: { Names.family(URL(fileURLWithPath: $0.path).lastPathComponent) })
        let git = Shell.which("git")
        var gitCalls = 0
        var rows: [String] = []
        for (fam, members) in groups.sorted(by: { $0.key < $1.key }) where members.count > 1 {
            rows.append("Family “\(fam)” — \(members.count) locations")
            for m in members {
                var g = ""
                if m.kinds.contains("Git"), let gp = git, gitCalls < 25 {
                    gitCalls += 1
                    let r = Shell.run(gp, ["-C", m.path, "status", "--porcelain"], timeout: 3)
                    g = r.ok ? (r.out.isEmpty ? " · git: clean" : " · git: \(r.out.split(separator: "\n").count) change(s)") : " · git: unknown"
                } else if m.kinds.contains("Git") { g = " · git working copy" }
                rows.append("   working copy: \(abbrev(m.path)) [\(m.kinds.joined(separator: "+"))]\(g)")
            }
            for a in archives where Names.family(a.deletingPathExtension().lastPathComponent) == fam {
                rows.append("   archive: \(abbrev(a.path))")
            }
        }
        if rows.isEmpty { rows = ["No related copies/versions detected."] }
        o.sections.append(InfoSection(title: "Related copies / versions (review only — sources are never auto-merged)", rows: rows))
        return o
    }

    static func buildFamilies(root: URL) -> ScanOutput {
        var o = ScanOutput(title: "Build Families")
        let cls = Storage.classify(root)
        guard cls.scannable, !Storage.isBoundary(root) else { notTraversable(&o, root, cls); return o }
        if Storage.isBroadRoot(root) {
            o.lines.append("REFUSED: \(abbrev(root.path)) is the home folder (or above it). Choose the folder that holds your delivered builds.")
            return o
        }
        if exists(root.appendingPathComponent(".git")) {
            o.lines.append("\(abbrev(root.path)) is a Git working copy — excluded. Choose the folder that holds delivered builds.")
            return o
        }
        struct Item { let url: URL; let nums: [Int]; let bytes: Int64; let date: Date }
        let exts: Set<String> = ["zip", "dmg", "ipa", "pkg", "xip", "tgz", "gz", "apk", "aab", "msi", "deb", "app", "xcarchive"]
        let maxDepth = Prefs.maxDepth
        let dl = Date().addingTimeInterval(Prefs.timeout * 3)
        var fam: [String: [Item]] = [:]
        var partial = false
        func add(_ url: URL, _ bytes: Int64) {
            let stem = url.deletingPathExtension().lastPathComponent
            guard let p = Names.parse(stem) else { return }
            fam[p.base + "|" + url.pathExtension.lowercased(), default: []]
                .append(Item(url: url, nums: p.nums, bytes: bytes, date: mtime(url) ?? .distantPast))
        }
        if let en = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey, .totalFileAllocatedSizeKey],
                                                   options: [], errorHandler: { _, _ in true }) {
            var n = 0
            while let obj = en.nextObject() {
                guard let url = obj as? URL else { continue }
                n += 1
                if n % 128 == 0, Date() > dl || Task.isCancelled { partial = true; break }
                let rv = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .totalFileAllocatedSizeKey])
                if rv?.isSymbolicLink == true { continue }
                let ext = url.pathExtension.lowercased()
                if rv?.isDirectory == true {
                    let name = url.lastPathComponent
                    if Storage.isBoundary(url) || suppress.contains(name) || name == ".git" { en.skipDescendants(); continue }
                    if exists(url.appendingPathComponent(".git")) { en.skipDescendants(); continue }
                    if ext == "app" || ext == "xcarchive" {
                        en.skipDescendants()
                        add(url, Scan.size(of: url, deadline: Date().addingTimeInterval(2)).bytes)
                        continue
                    }
                    if en.level >= maxDepth { en.skipDescendants() }
                } else if exts.contains(ext) {
                    add(url, Int64(rv?.totalFileAllocatedSize ?? 0))
                }
            }
        }
        o.roots.append(RootStatus(path: root.path, storage: cls, status: partial ? .partial : .complete, bytes: 0,
                                  note: "depth ≤ \(maxDepth); Git working copies excluded"))
        var rows: [String] = []
        var interTotal = 0
        for (key, var items) in fam.sorted(by: { $0.key < $1.key }) where items.count >= 2 {
            items.sort { Names.less($0.nums, $1.nums) || ($0.nums == $1.nums && $0.date < $1.date) }
            let first = items[0], latest = items[items.count - 1]
            var inter: [Item] = items.count >= 3 ? Array(items[1..<(items.count - 1)]) : []
            let active = inter.filter { Date().timeIntervalSince($0.date) < 600 }.count
            inter = inter.filter { Date().timeIntervalSince($0.date) >= 600 }
            let size = inter.reduce(Int64(0)) { $0 + $1.bytes }
            let label = key.split(separator: "|").map(String.init)
            rows.append("\(label.first ?? key) (.\(label.last ?? "")) — \(items.count) builds · first \(first.url.lastPathComponent) · latest \(latest.url.lastPathComponent) · \(inter.count) intermediate(s) \(fmtBytes(size))\(active > 0 ? " · \(active) active, skipped" : "")")
            interTotal += inter.count
            for i in inter {
                o.candidates.append(Candidate(url: i.url, category: "BUILD FAMILY INTERMEDIATE", bytes: i.bytes,
                                              note: "family keeps first \(first.url.lastPathComponent) + latest \(latest.url.lastPathComponent)", preselect: false))
            }
        }
        o.lines.append("\(rows.count) build family(ies) · \(interTotal) intermediate candidate(s) · \(fmtBytes(sum(o.candidates)))")
        o.lines.append("First + latest are always preserved. Ordering uses version/build numbers only — verify before deleting. Nothing is preselected.")
        o.sections.append(InfoSection(title: "Families", rows: rows.isEmpty ? ["No multi-build families found."] : rows))
        return o
    }

    static func dependencies(root: URL) -> ScanOutput {
        var o = ScanOutput(title: "Build & Dependency Discovery")
        let cls = Storage.classify(root)
        guard cls.scannable, !Storage.isBoundary(root) else { notTraversable(&o, root, cls); return o }
        if Storage.isBroadRoot(root) {
            o.lines.append("REFUSED: \(abbrev(root.path)) is the home folder (or above it). Choose a projects folder.")
            return o
        }
        let eco: [String: (marker: [String], note: String, cat: String)] = [
            "node_modules": (["package.json"], "Node dependencies — restore with `npm install`", "DEPENDENCY"),
            ".build": (["Package.swift"], "SwiftPM build output — rebuilt by `swift build`", "BUILD OUTPUT"),
            "Pods": (["Podfile"], "CocoaPods dependencies — restore with `pod install`", "DEPENDENCY"),
            "target": (["Cargo.toml"], "Rust build output — `cargo clean` is the native cleaner", "BUILD OUTPUT"),
            "build": (["build.gradle", "build.gradle.kts"], "Gradle build output — `./gradlew clean`", "BUILD OUTPUT"),
            ".venv": (["pyproject.toml", "requirements.txt"], "Python virtualenv — recreate from requirements", "DEPENDENCY"),
            "venv": (["pyproject.toml", "requirements.txt"], "Python virtualenv — recreate from requirements", "DEPENDENCY"),
            "Carthage": (["Cartfile"], "Carthage checkouts — `carthage bootstrap`", "DEPENDENCY"),
            "bin": (["*.sln", "*.csproj", "*.fsproj"], ".NET binary output — prefer `dotnet clean`", "BUILD OUTPUT"),
            "obj": (["*.sln", "*.csproj", "*.fsproj"], ".NET intermediate output — prefer `dotnet clean`", "BUILD OUTPUT"),
            ".dart_tool": (["pubspec.yaml"], "Dart tool cache — regenerate with `dart pub get`", "BUILD OUTPUT"),
            ".gradle": (["settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts"], "Project Gradle state — review before removing", "DEPENDENCY"),
            "__pycache__": (["pyproject.toml", "requirements.txt", "setup.py"], "Python bytecode — regenerable", "BUILD OUTPUT"),
            "dist": (["pyproject.toml", "setup.py"], "Python package distributions — review before removing", "BUILD OUTPUT")
        ]
        let t = Prefs.timeout
        let global = Date().addingTimeInterval(t * 6)
        let maxDepth = Prefs.maxDepth
        var partial = false
        if let en = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
                                                   options: [], errorHandler: { _, _ in true }) {
            var n = 0
            while let obj = en.nextObject() {
                guard let url = obj as? URL else { continue }
                n += 1
                if n % 128 == 0, Date() > global || Task.isCancelled { partial = true; break }
                let rv = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
                guard rv?.isDirectory == true, rv?.isSymbolicLink != true else { continue }
                let name = url.lastPathComponent
                if Storage.isBoundary(url) || name == ".git" { en.skipDescendants(); continue }
                if let e = eco[name] {
                    en.skipDescendants()
                    let parent = url.deletingLastPathComponent()
                    guard e.marker.contains(where: { marker in
                        if marker.hasPrefix("*.") {
                            let ext = String(marker.dropFirst(2)).lowercased()
                            return ((try? FileManager.default.contentsOfDirectory(at: parent, includingPropertiesForKeys: nil)) ?? [])
                                .contains { $0.pathExtension.lowercased() == ext }
                        }
                        return exists(parent.appendingPathComponent(marker))
                    }) else { continue }
                    let s = Scan.size(of: url, deadline: Date().addingTimeInterval(t))
                    if s.bytes > 0 {
                        let active = mtime(url).map { Date().timeIntervalSince($0) < 600 } ?? false
                        o.candidates.append(Candidate(url: url, category: e.cat, bytes: s.bytes,
                                                      note: e.note + (active ? " · modified in last 10 min — treated as active" : ""), preselect: false))
                    }
                    continue
                }
                if en.level >= maxDepth { en.skipDescendants() }
            }
        }
        o.candidates.sort { $0.bytes > $1.bytes }
        o.roots.append(RootStatus(path: root.path, storage: cls, status: partial ? .partial : .complete, bytes: 0, note: "depth ≤ \(maxDepth)"))
        o.lines.append("\(o.candidates.count) regenerable item(s) · \(fmtBytes(sum(o.candidates))) — a marker file (package.json, Package.swift, …) must sit beside each one. Nothing is preselected; prefer the ecosystem's native cleaner.")
        return o
    }

    // MARK: MEDIA

    static let videoExt: Set<String> = ["mp4", "mov", "m4v", "mkv", "avi", "webm"]
    static let imageExt: Set<String> = ["jpg", "jpeg", "png", "heic", "gif", "tiff", "dng", "webp", "psd"]
    static let audioExt: Set<String> = ["mp3", "m4a", "wav", "aiff", "flac", "aac"]

    static func mediaRoots(_ root: URL?) -> [URL] {
        if let r = root { return [r] }
        return ["Movies", "Music", "Pictures", "Downloads"].map { path($0) }
    }

    /// Media/duplicate scans never run on a whole home folder (or above): fall back to the default media folders.
    static func resolveMediaRoots(_ root: URL?, _ o: inout ScanOutput) -> [URL] {
        if let r = root, Storage.isBroadRoot(r) {
            o.lines.append("REFUSED: \(abbrev(r.path)) is the home folder (or above it). This scan never runs on a whole home folder — using Movies, Music, Pictures and Downloads instead. Choose a narrower folder to override.")
            return mediaRoots(nil)
        }
        return mediaRoots(root)
    }

    static func media(root: URL?) -> ScanOutput {
        var o = ScanOutput(title: "Local Media Inventory")
        let t = Prefs.timeout
        var counts: [String: (Int, Int64)] = ["Video": (0, 0), "Image": (0, 0), "Audio": (0, 0)]
        var large: [(URL, Int64, String)] = []
        for r in resolveMediaRoots(root, &o) where exists(r) {
            let cls = Storage.classify(r)
            guard cls.scannable, !Storage.isBoundary(r) else { notTraversable(&o, r, cls); continue }
            var total: Int64 = 0
            let w = Scan.walkFiles(r, maxDepth: 6, deadline: Date().addingTimeInterval(t * 2), skipDir: Storage.isManagedTree) { u, size in
                let e = u.pathExtension.lowercased()
                let kind: String? = videoExt.contains(e) ? "Video" : (imageExt.contains(e) ? "Image" : (audioExt.contains(e) ? "Audio" : nil))
                guard let k = kind else { return }
                counts[k]!.0 += 1; counts[k]!.1 += size; total += size
                if size >= 50_000_000 { large.append((u, size, k)) }
            }
            o.roots.append(RootStatus(path: r.path, storage: cls, status: w.status, bytes: total,
                                      note: w.skipped.isEmpty ? "depth ≤ 6" : "Excluded: " + w.skipped.prefix(4).joined(separator: ", ") + " (PROTECTED/provider)"))
        }
        for k in ["Video", "Image", "Audio"] { o.lines.append("\(k): \(counts[k]!.0) files · \(fmtBytes(counts[k]!.1))") }
        large.sort { $0.1 > $1.1 }
        for l in large.prefix(25) {
            o.candidates.append(Candidate(url: l.0, category: "LARGE MEDIA", bytes: l.1, note: l.2 + " ≥ 50 MB — your call", preselect: false))
        }
        o.lines.append("Large Media: top \(min(25, large.count)) of \(large.count) files ≥ 50 MB listed below (nothing preselected).")
        return o
    }

    static func duplicates(root: URL?) -> ScanOutput {
        var o = ScanOutput(title: "Exact Duplicates")
        let t = Prefs.timeout
        var bySize: [Int64: [URL]] = [:]
        var walkPartial = false
        for r in resolveMediaRoots(root, &o) where exists(r) {
            let cls = Storage.classify(r)
            guard cls.scannable, !Storage.isBoundary(r) else { notTraversable(&o, r, cls); continue }
            if Storage.isManagedTree(r) {
                o.lines.append("\(abbrev(r.path)) looks like a managed tree (project, backup, hidden or review folder) — excluded from duplicate scans.")
                continue
            }
            let w = Scan.walkFiles(r, maxDepth: 6, deadline: Date().addingTimeInterval(t * 2), skipDir: Storage.isManagedTree) { u, size in
                if size >= 1_000_000 { bySize[size, default: []].append(u) }
            }
            if w.status == .partial { walkPartial = true }
            o.roots.append(RootStatus(path: r.path, storage: cls, status: w.status, bytes: 0, note: "files ≥ 1 MB; depth ≤ 6"))
        }
        let hashDeadline = Date().addingTimeInterval(t * 5)
        var hashPartial = false
        var groups: [(size: Int64, urls: [URL])] = []
        for (size, urls) in bySize where urls.count > 1 {
            var byPartial: [String: [URL]] = [:]
            for u in urls {
                guard let h = Scan.sha256(u, limit: 65_536, deadline: hashDeadline) else { hashPartial = true; continue }
                byPartial[h, default: []].append(u)
            }
            for (_, us) in byPartial where us.count > 1 {
                var byFull: [String: [URL]] = [:]
                for u in us {
                    guard let h = Scan.sha256(u, limit: nil, deadline: hashDeadline) else { hashPartial = true; continue }
                    byFull[h, default: []].append(u)
                }
                for (_, fs) in byFull where fs.count > 1 {
                    groups.append((size, fs.sorted { (mtime($0) ?? .distantFuture) < (mtime($1) ?? .distantFuture) }))
                }
            }
        }
        groups.sort { $0.size * Int64($0.urls.count - 1) > $1.size * Int64($1.urls.count - 1) }
        var wasted: Int64 = 0
        var rows: [InfoSection] = []
        for (gi, g) in groups.enumerated() {
            wasted += g.size * Int64(g.urls.count - 1)
            if gi < 30 {
                rows.append(InfoSection(title: "\(g.urls.count) × \(fmtBytes(g.size)) — \(g.urls[0].lastPathComponent)",
                                        rows: g.urls.enumerated().map { ($0.offset == 0 ? "KEEP (oldest)  " : "duplicate      ") + abbrev($0.element.path) }))
            }
            for u in g.urls.dropFirst() where o.candidates.count < 300 {
                o.candidates.append(Candidate(url: u, category: "EXACT DUPLICATE", bytes: g.size,
                                              note: "same content as \(abbrev(g.urls[0].path))", preselect: false, keeper: g.urls[0]))
            }
        }
        o.sections = rows
        o.lines.append("\(groups.count) duplicate group(s) · \(fmtBytes(wasted)) reclaimable in total [\((walkPartial || hashPartial) ? "PARTIAL — time budget reached" : "COMPLETE")]")
        o.lines.append("Provider roots and Photos libraries are excluded. Method: size → first-64 KB hash → full SHA-256 (CryptoKit). Never auto-deleted.")
        return o
    }

    /// Vision feature-print comparison is read-only, bounded and never proposes deletion.
    static func similarImages(root: URL?) -> ScanOutput {
        var o = ScanOutput(title: "Similar Images — Visual Review")
        let r = root ?? path("Pictures")
        let cls = Storage.classify(r)
        guard cls.scannable, !Storage.isBoundary(r), !Storage.isBroadRoot(r), !Storage.isManagedTree(r) else {
            notTraversable(&o, r, cls); return o
        }
        var images: [URL] = []
        let allowed: Set<String> = ["jpg", "jpeg", "png", "heic", "tif", "tiff"]
        let w = Scan.walkFiles(r, maxDepth: 4, deadline: Date().addingTimeInterval(Prefs.timeout * 3), skipDir: Storage.isManagedTree) { u, size in
            if images.count < 100, size > 0, size < 80_000_000, allowed.contains(u.pathExtension.lowercased()) { images.append(u) }
        }
        var features: [(URL, VNFeaturePrintObservation)] = []
        let deadline = Date().addingTimeInterval(Prefs.timeout * 5)
        for u in images {
            if Task.isCancelled || Date() > deadline { break }
            let request = VNGenerateImageFeaturePrintRequest()
            do {
                try VNImageRequestHandler(url: u, options: [:]).perform([request])
                if let f = request.results?.first { features.append((u, f)) }
            } catch { continue }
        }
        var matches = 0
        for i in features.indices {
            for j in features.indices where j > i {
                var distance: Float = 0
                if (try? features[i].1.computeDistance(&distance, to: features[j].1)) != nil && distance < 0.35 {
                    if matches < 60 { o.sections.append(InfoSection(title: "Visual match — distance \(String(format: "%.3f", distance))", rows: [abbrev(features[i].0.path), abbrev(features[j].0.path)])) }
                    matches += 1
                }
            }
        }
        o.roots.append(RootStatus(path: r.path, storage: cls, status: w.status, bytes: 0, note: "Vision feature print; first 100 supported local images; no modifications"))
        o.lines.append("\(matches) potential pair(s); \(features.count) images analyzed. Visual similarity is not proof of duplication. Review only; no removal candidates.")
        if images.count >= 100 || features.count < images.count { o.lines.append("PARTIAL — bounded sample or image processing budget; results are not exhaustive.") }
        return o
    }

    static func similarNames(root: URL?) -> ScanOutput {
        var o = ScanOutput(title: "Similar Names")
        let r = (root.map { Storage.isBroadRoot($0) } ?? false) ? path("Downloads") : (root ?? path("Downloads"))
        let cls = Storage.classify(r)
        guard cls.scannable, !Storage.isBoundary(r) else { notTraversable(&o, r, cls); return o }
        var fam: [String: [URL]] = [:]
        let w = Scan.walkFiles(r, maxDepth: 3, deadline: Date().addingTimeInterval(Prefs.timeout * 2), skipDir: Storage.isManagedTree) { u, _ in
            var stem = u.deletingPathExtension().lastPathComponent
            for pat in [#" \(\d+\)$"#, #" copy( \d+)?$"#] {
                stem = stem.replacingOccurrences(of: pat, with: "", options: .regularExpression)
            }
            fam[Names.family(stem) + "." + u.pathExtension.lowercased(), default: []].append(u)
        }
        o.roots.append(RootStatus(path: r.path, storage: cls, status: w.status, bytes: 0, note: "depth ≤ 3"))
        let multi = fam.filter { $0.value.count > 1 }.sorted { $0.value.count > $1.value.count }
        for (k, v) in multi.prefix(40) {
            o.sections.append(InfoSection(title: "\(k) — \(v.count) similar", rows: v.map { abbrev($0.path) }))
        }
        o.lines.append("\(multi.count) group(s) of similarly named files — likely repeated downloads or versions. Review only; similar names are not proof of duplication.")
        return o
    }

    static func photosFootprint() -> ScanOutput {
        var o = ScanOutput(title: "Photos Library Footprint")
        let t = Prefs.timeout
        let libs = (Scan.listChildren(path("Pictures")) ?? []).filter { $0.pathExtension == "photoslibrary" }
        if libs.isEmpty { o.lines.append("No .photoslibrary found in ~/Pictures (or Pictures is not readable)."); return o }
        for lib in libs {
            guard let kids = Scan.listChildren(lib) else {
                o.roots.append(RootStatus(path: lib.path, storage: .photos, status: .protected, bytes: 0, note: "Not readable — Photos data is protected; grant access in Privacy & Security if you want a footprint"))
                continue
            }
            let total = Scan.size(of: lib, deadline: Date().addingTimeInterval(t * 3), allowPhotos: true)
            o.roots.append(RootStatus(path: lib.path, storage: .photos, status: total.status, bytes: total.bytes, note: "PROTECTED — read-only"))
            var rows: [(Int64, String)] = []
            for k in kids {
                let r = Scan.size(of: k, deadline: Date().addingTimeInterval(t * 2), allowPhotos: true)
                rows.append((r.bytes, "\(fmtBytes(r.bytes))  \(k.lastPathComponent)  [\(r.status.rawValue)]"))
            }
            rows.sort { $0.0 > $1.0 }
            o.sections.append(InfoSection(title: "\(lib.lastPathComponent) — \(fmtBytes(total.bytes))", rows: rows.map { $0.1 }))
        }
        o.lines.append("Footprint on this Mac only. This is not authoritative about iCloud residency (PhotoKit support is DEFERRED). JANITOR never deletes originals or alters the Photos database.")
        return o
    }

    // MARK: FULL CREW

    static func classifyProc(_ p: String, _ cache: inout [String: String]) -> (String, String) {
        let apple = "APPLE/macOS SYSTEM", third = "INSTALLED APPLICATIONS / THIRD PARTY", dev = "USER / DEVELOPMENT", unk = "UNKNOWN / REVIEW"
        let exe = URL(fileURLWithPath: p).lastPathComponent
        for pre in ["/System/", "/usr/libexec", "/usr/sbin", "/usr/bin", "/sbin", "/bin", "/Library/Apple"] where p.hasPrefix(pre) { return (apple, exe) }
        if let r = p.range(of: ".app/") {
            let appPath = String(p[..<r.lowerBound]) + ".app"
            let name = URL(fileURLWithPath: appPath).deletingPathExtension().lastPathComponent
            let bid: String
            if let c = cache[appPath] { bid = c } else { bid = Bundle(path: appPath)?.bundleIdentifier ?? ""; cache[appPath] = bid }
            if bid.hasPrefix("com.apple.") { return (apple, name) }
            if p.hasPrefix("/Applications/") || p.hasPrefix(home.path + "/Applications/") { return (third, name) }
            return (unk, name)
        }
        if p.hasPrefix(home.path) || p.hasPrefix("/opt/homebrew") || p.hasPrefix("/usr/local") { return (dev, exe) }
        return (unk, exe)
    }

    static func processes() -> ScanOutput {
        var o = ScanOutput(title: "Running Processes")
        let r = Shell.run("/bin/ps", ["-axww", "-o", "pid=,pcpu=,rss=,etime=,comm="], timeout: 10)
        guard r.ok else { o.lines = ["REVIEW — could not read the process list"]; return o }
        struct P { var group: String; var name: String; var cpu: Double; var rss: Int64; var etime: String; var path: String; var count: Int }
        var apple = (n: 0, cpu: 0.0, rss: Int64(0))
        var agg: [String: P] = [:]
        var cache: [String: String] = [:]
        for line in r.out.split(separator: "\n") {
            let f = line.split(maxSplits: 4, omittingEmptySubsequences: true, whereSeparator: { $0 == " " || $0 == "\t" })
            guard f.count == 5, let cpu = Double(f[1]), let rss = Int64(f[2]) else { continue }
            let path = String(f[4]).trimmingCharacters(in: .whitespaces)
            let (group, name) = classifyProc(path, &cache)
            if group == "APPLE/macOS SYSTEM" { apple.n += 1; apple.cpu += cpu; apple.rss += rss; continue }
            let key = group + "|" + name
            if var p = agg[key] { p.cpu += cpu; p.rss += rss; p.count += 1; agg[key] = p }
            else { agg[key] = P(group: group, name: name, cpu: cpu, rss: rss, etime: String(f[3]), path: path, count: 1) }
        }
        o.lines.append("Read-only report. Quit/Force Quit and signing/origin attribution are DEFERRED.")
        o.sections.append(InfoSection(title: "APPLE/macOS SYSTEM (collapsed, protected)", rows: [
            "\(apple.n) processes · \(String(format: "%.1f", apple.cpu))% CPU · \(fmtBytes(apple.rss * 1024)) RAM"]))
        for g in ["INSTALLED APPLICATIONS / THIRD PARTY", "USER / DEVELOPMENT", "UNKNOWN / REVIEW"] {
            let items = agg.values.filter { $0.group == g }.sorted { $0.rss > $1.rss }
            let rows = items.prefix(15).map { p in
                "\(p.name)\(p.count > 1 ? " ×\(p.count)" : "") — \(String(format: "%.1f", p.cpu))% CPU · \(fmtBytes(p.rss * 1024)) · up \(p.etime) · \(abbrev(p.path))"
            }
            o.sections.append(InfoSection(title: "\(g) (\(items.count))", rows: rows.isEmpty ? ["none"] : Array(rows)))
        }
        return o
    }

    static func startup() -> ScanOutput {
        var o = ScanOutput(title: "Startup & Background Items")
        let dirs: [(URL, String)] = [(path("Library/LaunchAgents"), "user login agent"),
                                     (URL(fileURLWithPath: "/Library/LaunchAgents"), "all-user agent"),
                                     (URL(fileURLWithPath: "/Library/LaunchDaemons"), "system daemon")]
        var groups: [String: [String]] = [:]
        var apple = 0
        for (d, kind) in dirs {
            guard let files = Scan.listChildren(d) else { continue }
            for f in files where f.pathExtension == "plist" {
                guard let dict = NSDictionary(contentsOf: f) as? [String: Any] else { continue }
                let label = dict["Label"] as? String ?? f.deletingPathExtension().lastPathComponent
                if label.hasPrefix("com.apple.") { apple += 1; continue }
                let prog = dict["Program"] as? String ?? (dict["ProgramArguments"] as? [String])?.first ?? ""
                let missing = !prog.isEmpty && !Quarantine.present(prog)
                let group: String
                if missing { group = "Unknown / review (program missing)" }
                else if prog.contains(".app/") || prog.hasPrefix("/Applications/") { group = "Installed-app helpers" }
                else if prog.hasPrefix(home.path) || prog.hasPrefix("/opt/homebrew") || prog.hasPrefix("/usr/local") || label.hasPrefix("homebrew.") { group = "Developer / local services" }
                else { group = "Unknown / review" }
                groups[group, default: []].append("\(label) — \(kind) — \(prog.isEmpty ? "no program" : abbrev(prog))\(missing ? " — target not found (not proof of orphan)" : "")")
            }
        }
        o.lines.append("Inventory of launchd plists. Modern Login Items / Background Task Management (SMAppService) are not enumerated — DEFERRED.")
        o.sections.append(InfoSection(title: "Apple / macOS (collapsed)", rows: ["\(apple) item(s)"]))
        for g in ["Installed-app helpers", "Developer / local services", "Unknown / review", "Unknown / review (program missing)"] {
            let rows = (groups[g] ?? []).sorted()
            o.sections.append(InfoSection(title: "\(g) (\(rows.count))", rows: rows.isEmpty ? ["none"] : rows))
        }
        return o
    }

    struct App { let name: String; let bid: String; let version: String; let path: String }

    static func installedApps() -> [App] {
        var apps: [App] = []
        func scan(_ dir: URL, depth: Int) {
            guard let kids = Scan.listChildren(dir) else { return }
            for k in kids {
                if k.pathExtension == "app" {
                    let info = Bundle(url: k)?.infoDictionary ?? [:]
                    let name = (info["CFBundleDisplayName"] as? String) ?? (info["CFBundleName"] as? String) ?? k.deletingPathExtension().lastPathComponent
                    apps.append(App(name: name, bid: info["CFBundleIdentifier"] as? String ?? "?",
                                    version: info["CFBundleShortVersionString"] as? String ?? "?", path: k.path))
                } else if depth > 0, (try? k.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                    scan(k, depth: depth - 1)
                }
            }
        }
        scan(URL(fileURLWithPath: "/Applications"), depth: 1)
        scan(path("Applications"), depth: 1)
        return apps.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    static func appsInventory() -> ScanOutput {
        var o = ScanOutput(title: "Installed Apps")
        let apps = installedApps()
        o.lines.append("\(apps.count) application(s) in /Applications and ~/Applications")
        o.sections.append(InfoSection(title: "Applications", rows: apps.prefix(300).map { "\($0.name) — \($0.version) — \($0.bid)" }))
        return o
    }

    static func supportInventory() -> ScanOutput {
        var o = ScanOutput(title: "Support Inventory")
        let apps = installedApps()
        var known = Set<String>()
        for a in apps {
            known.insert(a.name.lowercased()); known.insert(a.bid.lowercased())
            if let last = a.bid.split(separator: ".").last { known.insert(String(last).lowercased()) }
        }
        let dir = path("Library/Application Support")
        let r = Scan.candidates(in: dir, category: "SUPPORT", budget: Prefs.timeout * 2, minBytes: 1_000_000, limit: 40) { _ in ("", false) }
        o.roots.append(r.root)
        o.sections.append(InfoSection(title: "~/Library/Application Support — largest 40", rows: r.cands.map { c in
            let key = c.url.lastPathComponent.lowercased()
            let match = known.contains(key) || known.contains(where: { key.contains($0) && $0.count > 4 })
            return "\(fmtBytes(c.bytes))  \(c.url.lastPathComponent)  —  \(match ? "matches an installed app" : "no installed app matched — REVIEW (not a remnant claim)")"
        }))
        o.lines.append("Support locations only. “Remnant” is never claimed without ownership evidence — robust attribution is DEFERRED.")
        o.sections.append(InfoSection(title: "Uninstall safety contract", rows: [
            "Use the application's own uninstaller or native package manager first.",
            "Only inspect exact bundle identifiers and signed package receipts for associated files.",
            "No orphan is automatically selected. Shared support directories are never presumed disposable.",
            "Quit checks, permission checks, quarantine, verification and recovery are required before any removal."
        ]))
        return o
    }

    static func broken(root: URL) -> ScanOutput {
        var o = ScanOutput(title: "Broken Items")
        let cls = Storage.classify(root)
        guard cls.scannable, !Storage.isBoundary(root) else { notTraversable(&o, root, cls); return o }
        let fm = FileManager.default
        let maxDepth = Prefs.maxDepth
        let dl = Date().addingTimeInterval(Prefs.timeout * 3)
        var partial = false
        var inaccessible = 0
        let skipNames: Set<String> = ["Library", ".Trash", "node_modules", ".git", ".build"]
        if let en = fm.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey], options: [], errorHandler: { _, _ in true }) {
            var n = 0
            while let obj = en.nextObject() {
                guard let url = obj as? URL else { continue }
                n += 1
                if n % 128 == 0, Date() > dl || Task.isCancelled { partial = true; break }
                let rv = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
                if rv?.isSymbolicLink == true {
                    guard let dest = try? fm.destinationOfSymbolicLink(atPath: url.path) else { inaccessible += 1; continue }
                    let target = dest.hasPrefix("/") ? URL(fileURLWithPath: dest) : url.deletingLastPathComponent().appendingPathComponent(dest)
                    let resolved = target.standardized
                    if Storage.isBoundary(resolved) || Storage.classify(resolved.deletingLastPathComponent()) == .fileProvider { continue }
                    if fm.fileExists(atPath: resolved.path) { continue }
                    let parent = resolved.deletingLastPathComponent().path
                    if fm.fileExists(atPath: parent), !fm.isReadableFile(atPath: parent) { inaccessible += 1; continue }
                    o.candidates.append(Candidate(url: url, category: "BROKEN LINK", bytes: 0, note: "target missing: \(dest)", preselect: false))
                } else if rv?.isDirectory == true {
                    if skipNames.contains(url.lastPathComponent) || Storage.isBoundary(url) { en.skipDescendants(); continue }
                    if en.level >= maxDepth { en.skipDescendants() }
                }
            }
        }
        o.roots.append(RootStatus(path: root.path, storage: cls, status: partial ? .partial : .complete, bytes: 0,
                                  note: "depth ≤ \(maxDepth); ~/Library skipped; inaccessible ≠ broken (\(inaccessible) not judged)"))
        o.lines.append("\(o.candidates.count) broken symlink(s) in \(abbrev(root.path)) [\(partial ? "PARTIAL" : "COMPLETE")]. Items we could not read were not judged.")
        return o
    }

    static func storageGrowth() -> ScanOutput {
        var o = ScanOutput(title: "Storage Diagnostics")
        o.lines.append(volumeLine())
        let t = Prefs.timeout
        let global = Date().addingTimeInterval(t * 8)
        let areas: [(String, String)] = [
            ("Library/Developer", "Developer (Xcode, simulators)"), ("Library/Developer/CoreSimulator", "Simulators"),
            ("Library/Developer/Xcode/DerivedData", "DerivedData"), ("Library/Developer/Xcode/Archives", "Xcode Archives"),
            ("Library/Developer/Xcode/iOS DeviceSupport", "Device support"), ("Library/Caches", "Caches"),
            ("Library/Application Support", "Application Support"), ("Library/Logs", "Logs"), ("Library/Containers", "App containers"),
            ("Downloads", "Downloads"), ("Movies", "Movies"), ("Music", "Music"), ("Pictures", "Pictures"),
            (".Trash", "Trash"), (".npm", "npm cache"), (".gradle", "Gradle"), (".cargo", "Cargo")
        ]
        var rows: [(Int64, String)] = []
        var notes: [String] = []
        for (rel, label) in areas {
            let u = path(rel)
            guard exists(u) else { continue }
            let cls = Storage.classify(u)
            if !cls.scannable { notes.append("\(label): \(cls.rawValue) — not traversed"); continue }
            if Date() > global || Task.isCancelled { notes.append("\(label): SKIPPED — global time budget reached"); continue }
            let r = Scan.size(of: u, deadline: Date().addingTimeInterval(t))
            rows.append((r.bytes, "\(fmtBytes(r.bytes))  \(label)  [\(r.status.rawValue)]"))
        }
        rows.sort { $0.0 > $1.0 }
        o.sections.append(InfoSection(title: "Growth areas, largest first", rows: rows.map { $0.1 }))
        if !notes.isEmpty { o.sections.append(InfoSection(title: "Not measured", rows: notes)) }
        if let tm = Shell.which("tmutil") {
            let r = Shell.run(tm, ["listlocalsnapshots", "/"], timeout: 10)
            let snaps = r.out.split(separator: "\n").filter { $0.contains("com.apple") }.map(String.init)
            o.sections.append(InfoSection(title: "Local APFS snapshots (\(snaps.count)) — via tmutil, read-only", rows: snaps.isEmpty ? ["none reported"] : snaps))
        }
        return o
    }

    // MARK: SETTINGS / DIAGNOSTICS

    static func diagnostics() -> ScanOutput {
        var o = ScanOutput(title: "Diagnostics")
        #if arch(arm64)
        let arch = "arm64 (Apple silicon)"
        #else
        let arch = "x86_64 (Intel)"
        #endif
        o.lines = ["JANITOR \(janitorVersion)", "macOS \(ProcessInfo.processInfo.operatingSystemVersionString) · \(arch)",
                   "Reports: \(abbrev(Report.dir.path))", "iCloud Drive present: \(Storage.iCloudActive ? "yes — Desktop/Documents treated as provider-managed" : "no")"]
        o.sections.append(InfoSection(title: "Tools (optional ones are never installed for you)", rows:
            ["brew", "git", "xcrun", "tmutil", "diskutil", "ps", "launchctl", "fdupes"].map { n in
                "\(n): \(Shell.which(n).map { abbrev($0) } ?? "not found (optional)")" }))
        let fm = FileManager.default
        func access(_ rel: String) -> String {
            let u = path(rel)
            guard exists(u) else { return "\(rel): not present" }
            return "\(rel): \((try? fm.contentsOfDirectory(atPath: u.path)) != nil ? "readable" : "needs permission (Privacy & Security)")"
        }
        o.sections.append(InfoSection(title: "Access", rows: [access(".Trash"), access("Library/Containers"), access("Downloads"), access("Pictures")]))
        let q = Prefs.quarantineRoot
        let qExists = exists(q)
        var qRows = ["Root: \(abbrev(q.path))", "Exists: \(qExists ? "yes" : "not yet (created on first quarantine)")"]
        if qExists {
            qRows.append("Class: \(Storage.classify(q).rawValue)")
            qRows.append("Writable: \(fm.isWritableFile(atPath: q.path) ? "yes" : "NO")")
            let ops = Quarantine.loadOps()
            qRows.append("Operations: \(ops.count) · items MOVED \(ops.flatMap { $0.manifest.items }.filter { $0.state == "MOVED" }.count) / MISSING \(ops.flatMap { $0.manifest.items }.filter { $0.state == "MISSING" }.count)")
        }
        o.sections.append(InfoSection(title: "Quarantine health", rows: qRows))
        return o
    }
}

// MARK: - Maintenance actions (native tools only)

enum Maint {
    static func free() -> Int64 {
        (try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]))?
            .volumeAvailableCapacityForImportantUsage ?? 0
    }
    static func tail(_ s: String, _ n: Int) -> [String] {
        s.split(separator: "\n", omittingEmptySubsequences: true).suffix(n).map(String.init)
    }

    static func brew(dryRun: Bool) -> ScanOutput {
        var o = ScanOutput(title: dryRun ? "Homebrew cleanup preview" : "Homebrew cleanup")
        guard let b = Shell.which("brew") else { o.lines = ["Homebrew is not installed (optional). Nothing to do."]; return o }
        let before = free()
        let r = Shell.run(b, dryRun ? ["cleanup", "-n"] : ["cleanup"], timeout: dryRun ? 60 : 300)
        o.lines = [r.timedOut ? "PARTIAL — timed out" : (r.ok ? "COMPLETE" : "REVIEW — brew reported an error"),
                   dryRun ? "Dry run — nothing was removed." : "Reclaimed (approximate free-space delta): \(fmtBytes(max(0, free() - before)))"]
        o.sections = [InfoSection(title: "brew output (last lines)", rows: tail(r.out, 40))]
        return o
    }

    static func simulators(dryRun: Bool) -> ScanOutput {
        var o = ScanOutput(title: dryRun ? "Unavailable simulators preview" : "Remove unavailable simulators")
        guard let x = Shell.which("xcrun") else { o.lines = ["xcrun not found."]; return o }
        let before = free()
        let r = Shell.run(x, dryRun ? ["simctl", "list", "devices", "unavailable"] : ["simctl", "delete", "unavailable"], timeout: 120)
        o.lines = [r.timedOut ? "PARTIAL — timed out" : (r.ok ? "COMPLETE" : "REVIEW — simctl reported an error"),
                   dryRun ? "Listing only — nothing was removed." : "Reclaimed (approximate free-space delta): \(fmtBytes(max(0, free() - before)))"]
        o.sections = [InfoSection(title: "simctl output (last lines)", rows: tail(r.out, 40))]
        return o
    }
}
