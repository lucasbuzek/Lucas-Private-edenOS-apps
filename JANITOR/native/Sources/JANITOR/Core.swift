import Foundation
import CryptoKit

let janitorVersion = "0.2.1"

func fmtBytes(_ b: Int64) -> String { ByteCountFormatter.string(fromByteCount: b, countStyle: .file) }
func fmtOrDash(_ b: Int64) -> String { b > 0 ? fmtBytes(b) : "—" }

enum StorageClass: String, Sendable {
    case local = "LOCAL", external = "EXTERNAL", network = "NETWORK"
    case fileProvider = "FILE_PROVIDER-CLOUD", photos = "PHOTOS_LIBRARY"
    case protected = "PROTECTED", unknown = "UNKNOWN"
    var scannable: Bool { self == .local || self == .external }
}

enum ScanStatus: String, Sendable {
    case complete = "COMPLETE", partial = "PARTIAL", review = "REVIEW"
    case skipped = "SKIPPED", protected = "PROTECTED", deferred = "DEFERRED"
}

struct RootStatus: Identifiable, Sendable {
    let id = UUID()
    var path: String
    var storage: StorageClass
    var status: ScanStatus
    var bytes: Int64
    var note: String
}

struct Candidate: Identifiable, Sendable, Hashable {
    let id = UUID()
    let url: URL
    let category: String
    let bytes: Int64
    let note: String
    var preselect: Bool
    /// For duplicate candidates: the copy that is being kept. Deleting/quarantining is refused if it is gone, changed or also selected.
    var keeper: URL? = nil
    var title: String { url.lastPathComponent }
}

struct InfoSection: Identifiable, Sendable {
    let id = UUID()
    var title: String
    var rows: [String]
}

struct ScanOutput: Sendable {
    var title: String
    var lines: [String] = []
    var roots: [RootStatus] = []
    var sections: [InfoSection] = []
    var candidates: [Candidate] = []
}

struct ActionResult: Identifiable, Sendable {
    let id = UUID()
    var state: String
    var name: String
    var detail: String
    var cid: UUID? = nil
}

// MARK: - Preferences

enum Prefs {
    static let ud = UserDefaults.standard
    static var timeout: TimeInterval { let v = ud.double(forKey: "timeout"); return v >= 2 ? v : 6 }
    static var maxDepth: Int { let v = ud.integer(forKey: "maxDepth"); return (2...6).contains(v) ? v : 4 }
    static var defaultQuarantineRoot: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads/#Review&Delete/JANITOR", isDirectory: true)
    }
    static var quarantineRoot: URL {
        if let s = ud.string(forKey: "quarantineRoot"), !s.isEmpty { return URL(fileURLWithPath: s, isDirectory: true) }
        return defaultQuarantineRoot
    }
}

// MARK: - Storage classification (conservative)

enum Storage {
    static let home = FileManager.default.homeDirectoryForCurrentUser
    static let desktop = home.appendingPathComponent("Desktop").path
    static let documents = home.appendingPathComponent("Documents").path
    static let iCloudActive = FileManager.default.fileExists(
        atPath: home.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs").path)

    /// Conventional paths are not proof of local storage: when iCloud Drive exists,
    /// Desktop and Documents are treated as provider-managed.
    static func classify(_ url: URL) -> StorageClass {
        let u = url.resolvingSymlinksInPath()
        let p = u.path
        if u.pathComponents.contains(where: { $0.hasSuffix(".photoslibrary") }) { return .photos }
        if p.contains("/Library/CloudStorage") || p.contains("/Library/Mobile Documents") { return .fileProvider }
        for pre in ["/System", "/usr", "/bin", "/sbin", "/private/var/db", "/Library/Apple"] where p == pre || p.hasPrefix(pre + "/") {
            return .protected
        }
        if iCloudActive {
            for d in [desktop, documents] where p == d || p.hasPrefix(d + "/") { return .fileProvider }
        }
        if let v = try? u.resourceValues(forKeys: [.isUbiquitousItemKey]), v.isUbiquitousItem == true { return .fileProvider }
        guard let vol = try? u.resourceValues(forKeys: [.volumeIsLocalKey, .volumeIsInternalKey]) else { return .unknown }
        if vol.volumeIsLocal == false { return .network }
        if vol.volumeIsInternal == false { return .external }
        return vol.volumeIsLocal == true ? .local : .unknown
    }

    /// A root that is the home folder, or contains it (e.g. "/" or "/Users"). Analysis that can produce
    /// deletable candidates must never run on these.
    static func isBroadRoot(_ url: URL) -> Bool {
        let p = url.resolvingSymlinksInPath().standardized.path
        let h = home.resolvingSymlinksInPath().standardized.path
        return p == "/" || p == h || h.hasPrefix(p + "/")
    }

    /// Trees whose contents are managed by something else (VCS, projects, backups, LKG snapshots,
    /// content-addressed stores, hidden/app data, review folders, our own quarantine).
    /// Duplicate/large-file analysis never looks inside them: identical files there are usually intentional.
    static func isManagedTree(_ dir: URL) -> Bool {
        let name = dir.lastPathComponent
        let l = name.lowercased()
        if name.hasPrefix(".") || name == "Library" || l.hasPrefix("#review") { return true }
        if l.contains("backup") || l.contains("lkg") { return true }
        if ["objects", "blobs", "node_modules", "vendor", "pods", "deriveddata", "snapshots"].contains(l) { return true }
        if dir.standardized.path == Prefs.quarantineRoot.standardized.path { return true }
        let fm = FileManager.default
        for m in [".git", "Package.swift", "package.json", "Cargo.toml", "pyproject.toml", "build.gradle", "build.gradle.kts", "pom.xml", "go.mod", "Podfile"]
        where fm.fileExists(atPath: dir.appendingPathComponent(m).path) { return true }
        return false
    }

    /// Cheap check used during traversal: never descend into these.
    static func isBoundary(_ url: URL, allowPhotos: Bool = false) -> Bool {
        let p = url.path
        if !allowPhotos && url.pathExtension == "photoslibrary" { return true }
        if p.contains("/Library/CloudStorage") || p.contains("/Library/Mobile Documents") { return true }
        if iCloudActive && (p == desktop || p == documents) { return true }
        return false
    }
}

// MARK: - Bounded process runner

enum Shell {
    static func which(_ name: String) -> String? {
        for d in ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin"] {
            let p = d + "/" + name
            if FileManager.default.isExecutableFile(atPath: p) { return p }
        }
        return nil
    }

    static func run(_ path: String, _ args: [String], timeout: TimeInterval = 15) -> (ok: Bool, out: String, timedOut: Bool) {
        let fm = FileManager.default
        guard fm.isExecutableFile(atPath: path) else { return (false, "", false) }
        let tmp = fm.temporaryDirectory.appendingPathComponent("janitor-\(UUID().uuidString).out")
        fm.createFile(atPath: tmp.path, contents: nil)
        guard let fh = try? FileHandle(forWritingTo: tmp) else { return (false, "", false) }
        defer { try? fh.close(); try? fm.removeItem(at: tmp) }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        p.standardOutput = fh
        p.standardError = fh
        p.standardInput = FileHandle.nullDevice
        do { try p.run() } catch { return (false, error.localizedDescription, false) }
        let end = Date().addingTimeInterval(timeout)
        var timedOut = false
        while p.isRunning {
            if Date() > end { timedOut = true; p.terminate(); break }
            if Task.isCancelled { p.terminate(); break }
            usleep(50_000)
        }
        p.waitUntilExit()
        let data = (try? Data(contentsOf: tmp)) ?? Data()
        return (p.terminationStatus == 0 && !timedOut, String(decoding: data, as: UTF8.self), timedOut)
    }
}

// MARK: - Name families (build numbers / versions / repeated downloads)

enum Names {
    static let verRegex = try! NSRegularExpression(
        pattern: #"(?:[\s._-]+(?:v|ver|version|build|b|rc|r))?[\s._-]*\d+"#, options: [.caseInsensitive])
    static let digitRegex = try! NSRegularExpression(pattern: #"\d+"#)

    static func parse(_ stem: String) -> (base: String, nums: [Int])? {
        let ns = stem as NSString
        let full = NSRange(location: 0, length: ns.length)
        let nums = digitRegex.matches(in: stem, range: full).compactMap { Int(String(ns.substring(with: $0.range).prefix(9))) }
        if nums.isEmpty { return nil }
        let stripped = verRegex.stringByReplacingMatches(in: stem, range: full, withTemplate: "")
        let base = stripped.trimmingCharacters(in: CharacterSet(charactersIn: " ._-")).lowercased()
        return (base.isEmpty ? stem.lowercased() : base, nums)
    }

    static func family(_ name: String) -> String { parse(name)?.base ?? name.lowercased() }

    static func less(_ a: [Int], _ b: [Int]) -> Bool {
        for (x, y) in zip(a, b) where x != y { return x < y }
        return a.count < b.count
    }
}

// MARK: - Reports

enum Report {
    static var dir: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/JANITOR", isDirectory: true)
    }

    static func write(_ title: String, lines: [String]) {
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let f = DateFormatter(); f.dateFormat = "yyyyMMdd-HHmmss"
        let safe = title.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "/", with: "-")
        var body = ["JANITOR native \(janitorVersion) — \(title)",
                    "Time: \(Quarantine.iso())",
                    "Host: macOS \(ProcessInfo.processInfo.operatingSystemVersionString)", ""]
        body += lines
        try? body.joined(separator: "\n").write(
            to: dir.appendingPathComponent("\(f.string(from: Date()))-\(safe).txt"), atomically: true, encoding: .utf8)
    }

    static func scanLines(_ o: ScanOutput) -> [String] {
        var l = o.lines
        l.append("")
        l.append("Roots / exclusions:")
        for r in o.roots { l.append("  [\(r.status.rawValue)] \(r.storage.rawValue) \(r.path) \(fmtOrDash(r.bytes)) \(r.note)") }
        for s in o.sections { l.append(""); l.append("\(s.title):"); l += s.rows.prefix(200).map { "  " + $0 } }
        l.append("")
        l.append("Candidates: \(o.candidates.count)")
        for c in o.candidates.prefix(200) { l.append("  \(c.category) \(fmtBytes(c.bytes)) \(c.url.path) — \(c.note)") }
        return l
    }
}
