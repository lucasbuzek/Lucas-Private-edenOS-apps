import Foundation

struct QItem: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var original: String
    var destination: String
    var reason: String
    var timestamp: String
    var state: String      // MOVED / RESTORED / MISSING
    var bytes: Int64
}

struct QManifest: Codable, Sendable {
    var operation: String
    var created: String
    var version: String
    var items: [QItem]
}

struct QOp: Identifiable, Sendable {
    var folder: URL
    var manifest: QManifest
    var id: String { folder.lastPathComponent }
}

enum Quarantine {
    static func stamp() -> String { let f = DateFormatter(); f.dateFormat = "yyyyMMdd-HHmmss"; return f.string(from: Date()) }
    static func iso() -> String { ISO8601DateFormatter().string(from: Date()) }
    static func manifestURL(_ op: URL) -> URL { op.appendingPathComponent("manifest.json") }

    static func present(_ p: String) -> Bool {
        FileManager.default.fileExists(atPath: p) || (try? FileManager.default.destinationOfSymbolicLink(atPath: p)) != nil
    }

    static func save(_ m: QManifest, to folder: URL) {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let d = try? enc.encode(m) { try? d.write(to: manifestURL(folder), options: .atomic) }
    }

    static func sameVolume(_ a: URL, _ b: URL) -> Bool {
        guard let x = try? a.resourceValues(forKeys: [.volumeIdentifierKey]).volumeIdentifier,
              let y = try? b.resourceValues(forKeys: [.volumeIdentifierKey]).volumeIdentifier else { return false }
        return x.isEqual(y)
    }

    // MARK: move into quarantine (verified, per item)

    static func move(_ cands: [Candidate], label: String) -> (op: String, results: [ActionResult]) {
        let fm = FileManager.default
        let root = Prefs.quarantineRoot
        func all(_ state: String, _ detail: String) -> [ActionResult] {
            cands.map { ActionResult(state: state, name: $0.title, detail: detail, cid: $0.id) }
        }
        // Validate BEFORE creating any directory. Creating a root in File Provider storage
        // is itself a cloud mutation, even if all subsequent moves are refused.
        let resolvedRoot = root.resolvingSymlinksInPath().standardizedFileURL
        var existingAncestor = resolvedRoot
        while !fm.fileExists(atPath: existingAncestor.path) {
            let parent = existingAncestor.deletingLastPathComponent()
            if parent.path == existingAncestor.path { break }
            existingAncestor = parent
        }
        let ancestorClass = Storage.classify(existingAncestor)
        let proposedClass = Storage.classify(resolvedRoot)
        guard ancestorClass.scannable, !Storage.isBroadRoot(resolvedRoot),
              proposedClass != .fileProvider, proposedClass != .photos,
              proposedClass != .network, proposedClass != .protected,
              !Storage.isBoundary(resolvedRoot) else {
            return ("", all("SKIPPED", "Quarantine destination not proven local/external; no directory created"))
        }
        do { try fm.createDirectory(at: root, withIntermediateDirectories: true) }
        catch { return ("", all("FAILED", "Cannot create quarantine root: \(error.localizedDescription)")) }
        let rc = Storage.classify(root)
        guard rc.scannable else {
            return ("", all("SKIPPED", "Quarantine root is \(rc.rawValue); provider-safe quarantine is deferred"))
        }
        let opName = stamp() + "-" + label
        let opDir = root.appendingPathComponent(opName, isDirectory: true)
        let itemsDir = opDir.appendingPathComponent("items", isDirectory: true)
        do { try fm.createDirectory(at: itemsDir, withIntermediateDirectories: true) }
        catch { return ("", all("FAILED", "Cannot create operation folder: \(error.localizedDescription)")) }

        var manifest = QManifest(operation: label, created: iso(), version: janitorVersion, items: [])
        var results: [ActionResult] = []
        for (i, c) in cands.enumerated() {
            let src = c.url
            func rec(_ state: String, _ detail: String, dest: String = "") {
                results.append(ActionResult(state: state, name: c.title, detail: detail, cid: c.id))
                if state == "MOVED" {
                    manifest.items.append(QItem(id: UUID().uuidString, original: src.path, destination: dest,
                                                reason: c.category + (c.note.isEmpty ? "" : " — " + c.note),
                                                timestamp: iso(), state: "MOVED", bytes: c.bytes))
                }
            }
            guard present(src.path) else { rec("MISSING", "Source no longer exists"); continue }
            if src.standardized.path.hasPrefix(root.standardized.path + "/") { rec("SKIPPED", "Already inside the quarantine root"); continue }
            let parentClass = Storage.classify(src.deletingLastPathComponent())
            guard parentClass.scannable, !Storage.isBoundary(src) else {
                rec("SKIPPED", "\(parentClass.rawValue) — not moved by local quarantine"); continue
            }
            guard sameVolume(src.deletingLastPathComponent(), itemsDir) else {
                rec("SKIPPED", "Different volume from quarantine root (a move would copy)"); continue
            }
            let dest = itemsDir.appendingPathComponent(String(format: "%03d-", i + 1) + src.lastPathComponent)
            do { try fm.moveItem(at: src, to: dest) } catch { rec("FAILED", error.localizedDescription); continue }
            let srcGone = !present(src.path)
            let destThere = present(dest.path)
            if srcGone && destThere { rec("MOVED", fmtBytes(c.bytes), dest: dest.path) }
            else { rec("FAILED", "Verification failed (source still present: \(!srcGone), destination present: \(destThere))") }
        }
        save(manifest, to: opDir)
        return (opName, results)
    }

    // MARK: list / refresh (tolerates items removed by hand)

    static func loadOps() -> [QOp] {
        let root = Prefs.quarantineRoot
        guard let kids = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else { return [] }
        var ops: [QOp] = []
        for k in kids.sorted(by: { $0.lastPathComponent > $1.lastPathComponent }) {
            guard let d = try? Data(contentsOf: manifestURL(k)),
                  var m = try? JSONDecoder().decode(QManifest.self, from: d) else { continue }
            var changed = false
            for i in m.items.indices where m.items[i].state == "MOVED" && !present(m.items[i].destination) {
                m.items[i].state = "MISSING"; changed = true
            }
            if changed { save(m, to: k) }
            ops.append(QOp(folder: k, manifest: m))
        }
        return ops
    }

    // MARK: restore

    static func uniqueURL(_ u: URL) -> URL {
        let base = u.deletingPathExtension().lastPathComponent
        let ext = u.pathExtension
        let dir = u.deletingLastPathComponent()
        var n = 1
        while true {
            let name = ext.isEmpty ? "\(base) (restored \(n))" : "\(base) (restored \(n)).\(ext)"
            let c = dir.appendingPathComponent(name)
            if !present(c.path) { return c }
            n += 1
        }
    }

    static func restore(_ op: QOp, ids: Set<String>?) -> [ActionResult] {
        let fm = FileManager.default
        var m = op.manifest
        var results: [ActionResult] = []
        for i in m.items.indices {
            let it = m.items[i]
            if let ids = ids, !ids.contains(it.id) { continue }
            let name = URL(fileURLWithPath: it.original).lastPathComponent
            guard it.state == "MOVED" else {
                results.append(ActionResult(state: it.state == "RESTORED" ? "SKIPPED" : it.state, name: name, detail: "Item state is \(it.state)"))
                continue
            }
            guard present(it.destination) else {
                m.items[i].state = "MISSING"
                results.append(ActionResult(state: "MISSING", name: name, detail: "No longer in quarantine (removed manually?)"))
                continue
            }
            var target = URL(fileURLWithPath: it.original)
            do { try fm.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true) }
            catch { results.append(ActionResult(state: "FAILED", name: name, detail: "Cannot recreate parent: \(error.localizedDescription)")); continue }
            var note = "Restored to original path"
            if present(target.path) { target = uniqueURL(target); note = "Original path occupied — restored as \(target.lastPathComponent)" }
            do { try fm.moveItem(at: URL(fileURLWithPath: it.destination), to: target) }
            catch { results.append(ActionResult(state: "FAILED", name: name, detail: error.localizedDescription)); continue }
            if present(target.path) && !present(it.destination) {
                m.items[i].state = "RESTORED"
                results.append(ActionResult(state: "RESTORED", name: name, detail: note))
            } else {
                results.append(ActionResult(state: "FAILED", name: name, detail: "Verification failed"))
            }
        }
        save(m, to: op.folder)
        return results
    }

    static func delete(_ op: QOp) -> (ActionResult, Int64) {
        let bytes = op.manifest.items.filter { $0.state == "MOVED" }.reduce(Int64(0)) { $0 + $1.bytes }
        do { try FileManager.default.removeItem(at: op.folder) }
        catch { return (ActionResult(state: "FAILED", name: op.id, detail: error.localizedDescription), 0) }
        if present(op.folder.path) { return (ActionResult(state: "FAILED", name: op.id, detail: "Still present after delete"), 0) }
        return (ActionResult(state: "DELETED", name: op.id, detail: "Quarantine operation removed"), bytes)
    }

    // MARK: direct delete of exact, user-selected candidates

    static func deleteCandidates(_ cands: [Candidate]) -> (results: [ActionResult], reclaimed: Int64) {
        var results: [ActionResult] = []
        var reclaimed: Int64 = 0
        for c in cands {
            func rec(_ s: String, _ d: String) { results.append(ActionResult(state: s, name: c.title, detail: d, cid: c.id)) }
            guard present(c.url.path) else { rec("MISSING", "Already gone"); continue }
            let cls = Storage.classify(c.url.deletingLastPathComponent())
            guard cls.scannable, !Storage.isBoundary(c.url), c.url.pathComponents.count >= 4 else {
                rec("SKIPPED", "\(cls.rawValue) — not deleted locally"); continue
            }
            do { try FileManager.default.removeItem(at: c.url) } catch { rec("FAILED", error.localizedDescription); continue }
            if present(c.url.path) { rec("FAILED", "Still present after delete") }
            else { reclaimed += c.bytes; rec("DELETED", fmtBytes(c.bytes)) }
        }
        return (results, reclaimed)
    }
}
