#!/usr/bin/env python3
"""Static verification of the SWAYcore tree. Works on any OS. Establishes STATIC PASS only:
file inventory, script syntax/exec bits, JSON validity, Python compile, Swift lexical balance, banned-fallback scan,
secret scan, contract cross-checks, and a spec-coverage matrix (symbol presence = IMPLEMENTED-in-source, nothing more)."""
import json, os, re, subprocess, sys, py_compile, stat

root = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), ".."))
fails, notes = [], []
def fail(m): fails.append(m)
def read(p): return open(os.path.join(root, p), encoding="utf-8").read()
def walk(ext, skip=("Build", ".build", "DerivedData", ".git")):
    for d, ds, fs in os.walk(root):
        ds[:] = [x for x in ds if x not in skip]
        for f in fs:
            if f.endswith(ext): yield os.path.relpath(os.path.join(d, f), root)

REQUIRED = """VERSION README.md Docs/IMPLEMENTATION_DECISIONS.md Docs/STATE_AND_EVIDENCE.md Docs/RECOVERY_LKG.md Docs/PHYSICAL_ACCEPTANCE.md
Docs/Spec/00_EMBEDDED_PROJECT_BIBLE.txt Docs/Spec/07_MACOS_ONE_CLICK_BUILDER_CONTRACT.txt
Packages/SWAYcoreKit/Package.swift Packages/SWAYStudioKit/Package.swift Packages/SWAYAppKit/Package.swift
Blender/generate_characters.py Blender/validate_blend.py Blender/validate_manifest.py Blender/characters.json Blender/sway_blender_common.py
Scripts/lib.sh Scripts/package_family.sh Scripts/verify_static.py Config/Signing.xcconfig Config/Signing.local.xcconfig.template
Apps/DanceFitness/project.yml Apps/SWAYZ/project.yml Apps/KidDancers/project.yml Apps/StudioManagement/project.yml
Build_SWAYcore_ALL.command Build_SWAYcore_Core.command Build_SWAYcore_DanceFitness.command Build_SWAYcore_SWAYZ.command Build_SWAYcore_KidDancers.command Build_SWAYcore_StudioManagement.command""".split()
for r in REQUIRED:
    if not os.path.exists(os.path.join(root, r)): fail("missing required file: " + r)

# scripts
for f in list(walk(".command")) + list(walk(".sh")):
    p = os.path.join(root, f)
    if not os.access(p, os.X_OK) and f.endswith(".command"): fail("not executable: " + f)
    if not read(f).startswith("#!"): fail("no shebang: " + f)
    if subprocess.run(["bash", "-n", p], capture_output=True).returncode: fail("bash -n failed: " + f)
for f in walk(".command"):
    t = read(f)
    if "source \"$HERE/Scripts/lib.sh\"" not in t: fail("builder does not source lib: " + f)
lib = read("Scripts/lib.sh")
for need in ["ensure_formula()", "ensure_cask()", "brew list --formula", "brew list --cask", "xcode-select -p", "xcodebuild -version", "xcrun --find", "preserve_lkg", "gate_unknown"]:
    if need not in lib: fail("lib.sh missing contract element: " + need)
if re.search(r"brew install (--cask )?xcode", lib, re.I): fail("lib.sh must never install Xcode via Homebrew")

# json + python
for f in walk(".json"):
    try: json.load(open(os.path.join(root, f)))
    except Exception as e: fail("invalid JSON %s: %s" % (f, e))
for f in walk(".py"):
    try: compile(read(f), f, "exec")
    except Exception as e: fail("python compile %s: %s" % (f, e))

# swift lexical balance + banned content
def strip_swift(s):
    s = re.sub(r'"""[\s\S]*?"""', '""', s)
    s = re.sub(r'//.*', '', s); s = re.sub(r'/\*[\s\S]*?\*/', '', s)
    s = re.sub(r'"(?:\\.|[^"\\\n])*"', '""', s)
    return s
swift_files = list(walk(".swift")); sources_text = ""
for f in swift_files:
    raw = read(f); s = strip_swift(raw)
    for a, b in ("{}", "()", "[]"):
        if s.count(a) != s.count(b): fail("unbalanced %s%s in %s (%d vs %d)" % (a, b, f, s.count(a), s.count(b)))
    if "Tests" in f and "XCTestCase" not in raw and "main.swift" not in f and not f.endswith("TestSupport.swift"): fail("test file without XCTestCase: " + f)
    if "/Sources/" in f: sources_text += raw + "\n"
    if re.search(r'fatalError\("(unimplemented|not implemented|TODO)', raw, re.I) or re.search(r'\bTODO\b|\bFIXME\b', raw): fail("placeholder marker in " + f)
    if re.search(r'(api[_-]?key|secret|password|passwd|bearer)\s*[:=]\s*"[^"]{6,}"', raw, re.I) or "BEGIN PRIVATE KEY" in raw: fail("possible embedded secret in " + f)
for f in swift_files:
    if f.startswith("Apps/") and "/Sources/" in f:
        raw = read(f)
        if re.search(r"StickFigure|SkeletonView|Image\(\"(coach|lucia|cutout)|\.png\"", raw): fail("banned final-character fallback in " + f)

# contract cross-checks
pose = read("Packages/SWAYcoreKit/Sources/SWAYcoreKit/Pose.swift")
enum = re.search(r"enum SWAYJoint[^{]*\{([\s\S]*?)\n    public var mirrored", pose).group(1)
joints = re.findall(r"case ([^\n]+)", enum); swift_joints = [j.strip() for line in joints for j in line.split(",")]
if len(swift_joints) != 23 or len(set(swift_joints)) != 23: fail("SWAYJoint must have 23 unique joints, found %d" % len(swift_joints))
pyt = read("Tests/Python/test_manifest_validator.py")
for j in ("root", "hips", "spine", "chest", "neck", "head", "headEnd"):
    if j not in swift_joints: fail("joint missing in Swift enum: " + j)
rig = read("Packages/SWAYcoreKit/Sources/SWAYcoreKit/Rig.swift")
bl = read("Blender/sway_blender_common.py"); vm = read("Blender/validate_manifest.py")
clips_swift = re.findall(r'"(sway_[a-z_]+_v1)"', rig.split("proofClips")[1].split("requiredCharacters")[0])
clips_py = re.findall(r'"(sway_[a-z_]+_v1)"', bl.split("PROOF_CLIPS")[1].split("HEIGHT_RANGE")[0])
if clips_swift != clips_py or len(clips_swift) != 10: fail("proof clip lists disagree/not 10: %s vs %s" % (clips_swift, clips_py))
lib_ids = re.findall(r'make\("(sway_[a-z_]+_v1)"', read("Packages/SWAYcoreKit/Sources/SWAYcoreKit/MoveLibrary.swift"))
if len(lib_ids) < 26 or len(set(lib_ids)) != len(lib_ids): fail("bundled library must have >=26 unique moves, has %d" % len(lib_ids))
for c in clips_swift:
    if c not in lib_ids: fail("proof clip not in bundled library: " + c)
chars = [c["id"] for c in json.load(open(os.path.join(root, "Blender/characters.json")))["characters"]]
if chars != ["lucia", "nandi", "thabo", "zuri", "kyle", "yourdancer"]: fail("characters.json must define the six identities in order: %s" % chars)
if "MAX_INFLUENCES = 4" not in bl or "MAX_TRIANGLES = 60000" not in bl: fail("blender budgets drifted from Swift RigContract")
# project specs reference real dirs
for app in ("DanceFitness", "SWAYZ", "KidDancers", "StudioManagement"):
    y = read("Apps/%s/project.yml" % app)
    if "CODE_SIGNING" in y and "CODE_SIGNING_ALLOWED: YES" in y: fail("signing hard-coded in " + app)
    if re.search(r"DEVELOPMENT_TEAM:\s*[A-Z0-9]{10}", y): fail("team id embedded in " + app)
    if not os.path.isdir(os.path.join(root, "Apps", app, "Sources")): fail("no Sources for " + app)
# anti-duplication: apps must not reimplement core logic
for f in swift_files:
    if f.startswith("Apps/"):
        raw = read(f)
        for sym in ("struct MusicGrid", "enum Matcher", "struct CalibrationEngine", "struct SwayPack", "struct MovementDefinition", "struct SessionController"):
            if sym in raw: fail("app reimplements core type (%s) in %s" % (sym, f))
swayz = "\n".join(read(f) for f in swift_files if f.startswith("Apps/SWAYZ/"))
if "SwayPack" not in swayz or "MoveDraft" not in swayz: fail("SWAYZ must author via Core MoveDraft/SwayPack")
studio_apps = "\n".join(read(f) for f in swift_files if f.startswith("Apps/StudioManagement/"))
if "SWAYcoreKit" in studio_apps or "MovementDefinition" in studio_apps: fail("Studio Management must stay separate from the movement engine")

# spec coverage matrix (symbol presence only)
COVER = [
 ("Calibration: six actions + READY", "case stepIntoView, waveLeft, waveRight, liftLeftFoot, liftRightFoot, jump, ready"),
 ("MATCH / NOT MATCHED / UNKNOWN", "case match(error: Double)"), ("Unknown reasons incl. stale/out-of-frame", "case noObservation, stale"),
 ("Tracking loss + reacquisition fade", "youConfidence"), ("Pause/resume session", "mutating func resume"),
 ("Count 1-8 deterministic select", "mutating func select(count"), ("Half-time grid", "halfTime"),
 ("Beat/tempo/phase/downbeat analysis", "enum BeatAnalyzer"), ("Move hierarchy", "case move, variation, combination, routine, workout, challenge, program"),
 ("Mastery levels", "case discovered, learning, familiar, mastered"), ("Complexity levels", "case simple, easy, moderate, complex, expert"),
 (".swaypack versioned/validated/migrated", "static func migrate"), ("Rig contract validation", "enum RigContract"), ("Retargeting", "enum PoseRetargeter"),
 ("Coaches (5)", "case lucia, nandi, thabo, zuri, kyle"), ("CoachCue single source", "struct CoachCue"), ("Beat styles (10)", "BeatPattern(name: \"Minimal\""),
 ("Kids privacy defaults", "cameraMatchingEnabled = false"), ("Authoring (SWAYZ)", "struct MoveDraft"), ("Create Move capture", "enum PoseCapture"),
 ("Camera->Vision adapter", "VNDetectHumanBodyPoseRequest"), ("MusicKit", "ApplicationMusicPlayer"), ("ShazamKit", "SHManagedSession"), ("HealthKit", "HKWorkoutBuilder"),
 ("Speech non-overlapping", "AVSpeechSynthesizer"), ("RealityKit articulated runtime", "jointTransforms"), ("Recording (unverified)", "RPScreenRecorder"),
 ("Studio persistence+migration", "static func decode"), ("Studio billing", "func pay("), ("Studio attendance", "func record(attendance"),
]
allsrc = sources_text
matrix = []
for name, sym in COVER:
    ok = sym in allsrc; matrix.append((name, "IMPLEMENTED(source)" if ok else "MISSING"))
    if not ok: fail("spec coverage missing: %s (%s)" % (name, sym))

os.makedirs(os.path.join(root, "Build", "report"), exist_ok=True)
json.dump({"static": "PASS" if not fails else "FAIL", "failures": fails, "swiftFiles": len(swift_files), "coverage": matrix,
           "meaning": "Static evidence only. Not compile, not test, not build, not physical."},
          open(os.path.join(root, "Build", "report", "static.json"), "w"), indent=2)
print("STATIC: %s — %d Swift files, %d coverage items checked" % ("PASS" if not fails else "FAIL", len(swift_files), len(COVER)))
for f in fails: print("  FAIL: " + f)
sys.exit(1 if fails else 0)
