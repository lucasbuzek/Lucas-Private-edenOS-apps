import Foundation
import CryptoKit

/// Bounded filesystem primitives. Every traversal has a deadline, never follows symlinks,
/// never crosses a volume boundary, never enters provider/Photos roots, and continues past errors.
enum Scan {
    static func listChildren(_ dir: URL) -> [URL]? {
        try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: [])
    }

    static func exists(_ u: URL) -> Bool { FileManager.default.fileExists(atPath: u.path) }

    static func size(of root: URL, maxDepth: Int = Int.max, deadline: Date, allowPhotos: Bool = false)
        -> (bytes: Int64, files: Int, status: ScanStatus, skipped: [String]) {
        if let r0 = try? root.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .totalFileAllocatedSizeKey]),
           r0.isDirectory != true {
            return (r0.isSymbolicLink == true ? 0 : Int64(r0.totalFileAllocatedSize ?? 0), 1, .complete, [])
        }
        var bytes: Int64 = 0, files = 0, skipped: [String] = []
        var status = ScanStatus.complete, depthHit = false
        let keys: [URLResourceKey] = [.isDirectoryKey, .isSymbolicLinkKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .volumeIdentifierKey]
        let rootVol = try? root.resourceValues(forKeys: [.volumeIdentifierKey]).volumeIdentifier
        guard let en = FileManager.default.enumerator(at: root, includingPropertiesForKeys: keys, options: [],
                                                      errorHandler: { _, _ in true }) else { return (0, 0, .skipped, []) }
        var n = 0
        while let obj = en.nextObject() {
            guard let url = obj as? URL else { continue }
            n += 1
            if n % 256 == 0, Date() > deadline || Task.isCancelled { status = .partial; break }
            guard let rv = try? url.resourceValues(forKeys: Set(keys)) else { continue }
            if rv.isSymbolicLink == true { continue }
            if rv.isDirectory == true {
                if Storage.isBoundary(url, allowPhotos: allowPhotos) { en.skipDescendants(); skipped.append(url.lastPathComponent); continue }
                if let a = rootVol, let b = rv.volumeIdentifier, !a.isEqual(b) { en.skipDescendants(); continue }
                if en.level >= maxDepth { en.skipDescendants(); depthHit = true }
            } else {
                bytes += Int64(rv.totalFileAllocatedSize ?? rv.fileAllocatedSize ?? 0)
                files += 1
            }
        }
        if depthHit && status == .complete { status = .partial }
        return (bytes, files, status, skipped)
    }

    /// Walk regular files (logical size) with depth + deadline bounds.
    static func walkFiles(_ root: URL, maxDepth: Int, deadline: Date, skipDir: ((URL) -> Bool)? = nil, visit: (URL, Int64) -> Void)
        -> (status: ScanStatus, skipped: [String]) {
        var status = ScanStatus.complete
        var skipped: [String] = []
        let keys: [URLResourceKey] = [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey, .volumeIdentifierKey]
        let rootVol = try? root.resourceValues(forKeys: [.volumeIdentifierKey]).volumeIdentifier
        guard let en = FileManager.default.enumerator(at: root, includingPropertiesForKeys: keys,
                                                      options: [.skipsPackageDescendants],
                                                      errorHandler: { _, _ in true }) else { return (.skipped, []) }
        var n = 0
        while let obj = en.nextObject() {
            guard let url = obj as? URL else { continue }
            n += 1
            if n % 128 == 0, Date() > deadline || Task.isCancelled { status = .partial; break }
            guard let rv = try? url.resourceValues(forKeys: Set(keys)) else { continue }
            if rv.isSymbolicLink == true { continue }
            if rv.isDirectory == true {
                if Storage.isBoundary(url) { en.skipDescendants(); skipped.append(url.lastPathComponent); continue }
                if let sk = skipDir, sk(url) { en.skipDescendants(); skipped.append(url.lastPathComponent + " (managed tree)"); continue }
                if let a = rootVol, let b = rv.volumeIdentifier, !a.isEqual(b) { en.skipDescendants(); continue }
                if en.level >= maxDepth { en.skipDescendants() }
            } else {
                visit(url, Int64(rv.fileSize ?? 0))
            }
        }
        return (status, skipped)
    }

    /// Measure each child of `dir` (one level), with a per-root time budget.
    static func candidates(in dir: URL, category: String, skip: Set<String> = [], budget: TimeInterval,
                           minBytes: Int64 = 100_000, limit: Int = 60,
                           rule: (URL) -> (String, Bool)?) -> (cands: [Candidate], root: RootStatus) {
        let cls = Storage.classify(dir)
        var root = RootStatus(path: dir.path, storage: cls, status: .complete, bytes: 0, note: "")
        guard cls.scannable else {
            root.status = cls == .protected ? .protected : .deferred
            root.note = "Not traversed: \(cls.rawValue)"
            return ([], root)
        }
        guard let kids = listChildren(dir) else {
            root.status = .skipped
            root.note = "Not readable — if this should be included, grant JANITOR Full Disk Access (System Settings → Privacy & Security)"
            return ([], root)
        }
        let dl = Date().addingTimeInterval(budget)
        var out: [Candidate] = []
        var total: Int64 = 0
        for k in kids {
            if skip.contains(k.lastPathComponent) || Storage.isBoundary(k) { continue }
            if Date() > dl || Task.isCancelled { root.status = .partial; root.note = "Time budget reached; remaining items not measured"; break }
            guard let (note, pre) = rule(k) else { continue }
            let r = size(of: k, deadline: dl)
            total += r.bytes
            if r.status == .partial { root.status = .partial; root.note = "Some items measured partially" }
            if r.bytes >= minBytes { out.append(Candidate(url: k, category: category, bytes: r.bytes, note: note, preselect: pre)) }
        }
        out.sort { $0.bytes > $1.bytes }
        if out.count > limit { out = Array(out.prefix(limit)) }
        root.bytes = total
        return (out, root)
    }

    /// One path measured as a single candidate.
    static func single(_ url: URL, category: String, note: String, pre: Bool, budget: TimeInterval) -> (Candidate?, RootStatus) {
        let cls = Storage.classify(url)
        var rs = RootStatus(path: url.path, storage: cls, status: .complete, bytes: 0, note: "")
        guard cls.scannable, !Storage.isBoundary(url) else {
            rs.status = cls == .protected ? .protected : .deferred; rs.note = "Not traversed: \(cls.rawValue)"; return (nil, rs)
        }
        let r = size(of: url, deadline: Date().addingTimeInterval(budget))
        rs.status = r.status; rs.bytes = r.bytes
        guard r.bytes > 0 else { return (nil, rs) }
        return (Candidate(url: url, category: category, bytes: r.bytes, note: note, preselect: pre), rs)
    }

    static func sha256(_ url: URL, limit: Int?, deadline: Date) -> String? {
        guard let h = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? h.close() }
        var hasher = SHA256()
        var read = 0
        while true {
            if Date() > deadline || Task.isCancelled { return nil }
            let want = limit.map { min(1 << 20, $0 - read) } ?? (1 << 20)
            if want <= 0 { break }
            guard let d = try? h.read(upToCount: want), !d.isEmpty else { break }
            hasher.update(data: d)
            read += d.count
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
