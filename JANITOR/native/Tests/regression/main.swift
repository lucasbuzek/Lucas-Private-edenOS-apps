import Foundation

var failures = 0
func check(_ cond: Bool, _ msg: String) { print(cond ? "PASS" : "FAIL", "-", msg); if !cond { failures += 1 } }

let fm = FileManager.default
let tmp = fm.temporaryDirectory.appendingPathComponent("janitor-fixture-\(UUID().uuidString)")
try! fm.createDirectory(at: tmp, withIntermediateDirectories: true)
func url(_ rel: String) -> URL { tmp.appendingPathComponent(rel) }
func write(_ rel: String, _ data: Data) {
    let u = url(rel)
    try! fm.createDirectory(at: u.deletingLastPathComponent(), withIntermediateDirectories: true)
    try! data.write(to: u)
}
UserDefaults.standard.set(url("Q").path, forKey: "quarantineRoot")

// ---------- fixtures for the Oct 6 failure ----------
let blob = Data((0..<2_000_000).map { _ in UInt8.random(in: 0...255) })
let blob2 = Data((0..<2_000_000).map { _ in UInt8.random(in: 0...255) })
write("media/a/photo.bin", blob)
try! fm.setAttributes([.modificationDate: Date(timeIntervalSinceNow: -86400)], ofItemAtPath: url("media/a/photo.bin").path)
write("media/b/photo copy.bin", blob)
write("media/proj/.git/HEAD", Data("x".utf8)); write("media/proj/data.bin", blob)
write("media/Backups-2026/objects/ab12", blob)
write("media/#Review&Delete/q/dup.bin", blob)
write("media/pkgproj/package.json", Data("{}".utf8)); write("media/pkgproj/dup.bin", blob)
write("media/.hidden/dup.bin", blob)
write("media/lkg-reference/dup.bin", blob)
write("media/other.bin", blob2)

// 1. duplicate scan only reports unmanaged copies and records the keeper
let d = Modes.duplicates(root: url("media"))
check(d.candidates.count == 1, "duplicates: exactly 1 candidate (managed trees excluded) — got \(d.candidates.count)")
check(d.candidates.first?.url.lastPathComponent == "photo copy.bin", "duplicates: newer copy is the candidate")
check(d.candidates.first?.keeper?.lastPathComponent == "photo.bin", "duplicates: candidate records its keeper")
for bad in [".git", "Backups-2026", "#Review", "pkgproj", ".hidden", "lkg-reference"] {
    check(!d.candidates.contains { $0.url.path.contains(bad) || ($0.keeper?.path.contains(bad) ?? false) }, "duplicates: nothing from \(bad)")
}

// 2. broad roots are refused
var o = ScanOutput(title: "t")
let roots = Modes.resolveMediaRoots(Storage.home, &o)
check(roots.count == 4 && (o.lines.first?.hasPrefix("REFUSED") ?? false), "home root refused, falls back to 4 media folders")
check(Storage.isBroadRoot(Storage.home) && Storage.isBroadRoot(URL(fileURLWithPath: "/Users")) && Storage.isBroadRoot(URL(fileURLWithPath: "/")), "isBroadRoot: home, /Users, / are broad")
check(!Storage.isBroadRoot(Storage.home.appendingPathComponent("Downloads")), "isBroadRoot: ~/Downloads is not broad")
let bf = Modes.buildFamilies(root: Storage.home)
check(bf.candidates.isEmpty && (bf.lines.first?.hasPrefix("REFUSED") ?? false), "buildFamilies refuses home")
let dep = Modes.dependencies(root: Storage.home)
check(dep.candidates.isEmpty && (dep.lines.first?.hasPrefix("REFUSED") ?? false), "dependencies refuses home")

// 3. keeper guard
let a = url("media/a/photo.bin"), b = url("media/b/photo copy.bin")
let c1 = Candidate(url: b, category: "EXACT DUPLICATE", bytes: 2_000_000, note: "", preselect: false, keeper: a)
check(Model.splitKeepers([c1]).ok.count == 1, "keeper ok → allowed")
let ckeep = Candidate(url: a, category: "EXACT DUPLICATE", bytes: 2_000_000, note: "", preselect: false)
check(Model.splitKeepers([c1, ckeep]).blocked.count == 1, "keeper also selected → blocked")
let c2 = Candidate(url: b, category: "EXACT DUPLICATE", bytes: 2_000_000, note: "", preselect: false, keeper: url("nope.bin"))
check(Model.splitKeepers([c2]).blocked.count == 1, "keeper missing → blocked")

// 4. quarantine: verified move, manual removal tolerated, collision-safe restore, no re-quarantine
write("work/x.txt", Data("hello".utf8)); write("work/y.txt", Data("world".utf8))
let cx = Candidate(url: url("work/x.txt"), category: "T", bytes: 5, note: "", preselect: false)
let cy = Candidate(url: url("work/y.txt"), category: "T", bytes: 5, note: "", preselect: false)
let mv = Quarantine.move([cx, cy], label: "Test")
check(mv.results.filter { $0.state == "MOVED" }.count == 2, "quarantine: 2 MOVED")
check(!fm.fileExists(atPath: url("work/x.txt").path) && !fm.fileExists(atPath: url("work/y.txt").path), "quarantine: sources gone")
var ops = Quarantine.loadOps()
check(ops.count == 1 && ops[0].manifest.items.count == 2, "quarantine: manifest lists 2 items")
try! fm.removeItem(atPath: ops[0].manifest.items[0].destination)
ops = Quarantine.loadOps()
check(ops[0].manifest.items.filter { $0.state == "MISSING" }.count == 1 && ops[0].manifest.items.filter { $0.state == "MOVED" }.count == 1, "quarantine: manually removed item → MISSING, other intact")
let live = ops[0].manifest.items.first { $0.state == "MOVED" }!
write(String(live.original.dropFirst(tmp.path.count + 1)), Data("occupied".utf8))
let rs = Quarantine.restore(ops[0], ids: nil)
check(rs.contains { $0.state == "RESTORED" && $0.detail.contains("restored 1") }, "restore: collision restored under a new name")
check(rs.contains { $0.state == "MISSING" }, "restore: missing item reported, no hang")
write("Q/stray.txt", Data("s".utf8))
let st = Quarantine.move([Candidate(url: url("Q/stray.txt"), category: "T", bytes: 1, note: "", preselect: false)], label: "Self")
check(st.results.first?.state == "SKIPPED", "quarantine refuses items already inside the quarantine root")

// 5. sizing is not truncated by depth
var deep = "deep"
for i in 0..<14 { deep += "/d\(i)" }
write(deep + "/big.bin", blob)
let sz = Scan.size(of: url("deep"), deadline: Date().addingTimeInterval(20))
check(sz.bytes >= 2_000_000 && sz.status == .complete, "size(): 14-deep file counted, status COMPLETE (\(sz.bytes) B, \(sz.status.rawValue))")

// 6. disclosure levels (0.2.0)
check(Level.simple < Level.advanced && Level.advanced < Level.expert, "levels: ordered simple < advanced < expert")
check(Model.Mode.clean.minLevel == .simple && Model.Mode.crew.minLevel == .simple, "levels: Clean and Full Crew visible at Simple")
check(Model.Mode.developer.minLevel == .advanced && Model.Mode.tools.minLevel == .advanced, "levels: Developer and Tools start at Advanced")
check(Model.Mode.allCases.filter { $0.minLevel <= .simple }.count == 4, "levels: Simple sidebar has 4 sections (Clean, Organize, Full Crew, Recovery)")

try? fm.removeItem(at: tmp)
UserDefaults.standard.removeObject(forKey: "quarantineRoot")
print(failures == 0 ? "\nALL PASS" : "\n\(failures) FAILURE(S)")
exit(failures == 0 ? 0 : 1)
