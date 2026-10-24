#!/usr/bin/env python3
"""SWAYcore portable verification (runs on any OS with Python 3). Establishes STATIC PASS / FAIL / UNKNOWN. It NEVER claims BUILD, ENVIRONMENT or PHYSICAL.
Usage: verify_all.py [root] [--json out.json] [--skip-suites]"""
import hashlib, json, os, re, subprocess, sys, time

ROOT = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
sys.path.insert(0, os.path.join(ROOT, "Tools")); sys.path.insert(0, os.path.join(ROOT, "AssetFactory", "python"))
results = []                      # (tier, name, status, detail)
def rec(tier, name, status, detail=""): results.append((tier, name, status, detail)); print("  [%-7s] %s%s" % (status, name, ("  - " + detail) if detail else ""))
def read(p):
    with open(os.path.join(ROOT, p), encoding="utf-8", errors="replace") as fh: return fh.read()
def walk(exts, skip=("Build", ".build", "DerivedData", ".git", "Reference", "__pycache__", "sources")):
    for d, ds, fs in os.walk(ROOT):
        ds[:] = [x for x in ds if x not in skip and not x.endswith(".xcodeproj")]
        for f in fs:
            if f.endswith(exts): yield os.path.relpath(os.path.join(d, f), ROOT)
def run(cmd, timeout=600):
    try: p = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=timeout); return p.returncode, (p.stdout + p.stderr)
    except Exception as e: return 99, str(e)

print("SWAYcore verify_all  root=%s" % ROOT)

# ---------------------------------------------------------------- T0 package integrity
print("T0 package integrity")
inv = os.path.join(ROOT, "INVENTORY.sha256")
if os.path.isfile(inv):
    bad = []; n = 0
    for line in open(inv, encoding="utf-8").read().splitlines():
        if not line.strip(): continue
        h, p = line.split("  ", 1); fp = os.path.join(ROOT, p[2:] if p.startswith("./") else p); n += 1
        if not os.path.isfile(fp): bad.append("missing " + p); continue
        if hashlib.sha256(open(fp, "rb").read()).hexdigest() != h: bad.append("changed " + p)
    rec("T0", "inventory checksums (%d files)" % n, "STATIC PASS" if not bad else "FAIL", "; ".join(bad[:5]))
else: rec("T0", "inventory checksums", "UNKNOWN", "no INVENTORY.sha256 (running from a working tree, not a distribution)")

# ---------------------------------------------------------------- T1 static
print("T1 static")
REQUIRED = """VERSION SWAYcore.root README.md BUILD_SWAYCORE_ENGINE.command BUILD_DANCE_FITNESS.command BUILD_ASSETS.command VERIFY_ALL.command BUILD_ALL.command
Scripts/factory_lib.sh Scripts/devicesupport_guard.sh Tools/verify_all.py Tools/swiftlex.py
Authority/START_HERE.md App/project.yml App/SWAY/SWAY.entitlements
Packages/SWAYcoreEngine/Package.swift Packages/SWAYcoreEngine/Sources/SWAYcoreEngine/SwayCalibrationMachine.swift
AssetFactory/python/retarget_math.py AssetFactory/blender/sway_convert_base.py AssetFactory/blender/sway_bake_clips.py AssetFactory/blender/sway_validate_character.py AssetFactory/blender/sway_export_runtime.py
AssetFactory/PROVENANCE/ledger.json AssetFactory/data/clip_manifest.json Docs/RESEARCH_AND_ADOPTION_REPORT.md""".split()
missing = [r for r in REQUIRED if not os.path.exists(os.path.join(ROOT, r))]
rec("T1", "required files (%d)" % len(REQUIRED), "STATIC PASS" if not missing else "FAIL", ", ".join(missing[:6]))

noexec = [f for f in walk((".command",)) if not os.access(os.path.join(ROOT, f), os.X_OK)]
rec("T1", "builders executable", "STATIC PASS" if not noexec else "FAIL", ", ".join(noexec))
import shutil
badsh, unchecked = [], []
for f in walk((".sh", ".command")):
    first = read(f).split("\n", 1)[0]
    interp = "zsh" if "zsh" in first else "bash"
    if shutil.which(interp) is None: unchecked.append("%s (%s not installed)" % (f, interp)); continue
    if subprocess.run([interp, "-n", os.path.join(ROOT, f)], capture_output=True).returncode: badsh.append(f)
rec("T1", "shell syntax (per-shebang interpreter)", "STATIC PASS" if not badsh else "FAIL", ", ".join(badsh))
if unchecked: rec("T1", "shell scripts not syntax-checked", "UNKNOWN", "; ".join(unchecked))

import swiftlex
swift = list(walk((".swift",))); lex_bad = []
for f in swift:
    pr = swiftlex.check(read(f), f)
    if pr: lex_bad.append("%s:%d %s" % (f, pr[0][0], pr[0][1]))
rec("T1", "Swift lexical balance (%d files)" % len(swift), "STATIC PASS" if not lex_bad else "FAIL", "; ".join(lex_bad[:4]))

jbad = []
for f in walk((".json",)):
    try: json.loads(read(f))
    except Exception as e: jbad.append("%s: %s" % (f, e))
rec("T1", "JSON validity", "STATIC PASS" if not jbad else "FAIL", "; ".join(jbad[:3]))
try:
    import yaml
    yb = []
    for f in walk((".yml", ".yaml")):
        try: yaml.safe_load(read(f))
        except Exception as e: yb.append(f)
    rec("T1", "YAML validity", "STATIC PASS" if not yb else "FAIL", ", ".join(yb))
    y = yaml.safe_load(read("App/project.yml")); b = y["targets"]["SWAY"]["settings"]["base"]
    sign_ok = b.get("DEVELOPMENT_TEAM") == "XZ4VRP5S5G" and b.get("PRODUCT_BUNDLE_IDENTIFIER") == "com.lucasbuzek.private.sway" and b.get("CODE_SIGN_STYLE") == "Automatic"
    rec("T1", "signing/bundle identity preserved", "STATIC PASS" if sign_ok else "FAIL", "")
except ImportError: rec("T1", "YAML validity", "UNKNOWN", "PyYAML not installed")
pybad = []
for f in walk((".py",)):
    try: compile(read(f), f, "exec")
    except Exception as e: pybad.append("%s: %s" % (f, e))
rec("T1", "Python compiles", "STATIC PASS" if not pybad else "FAIL", "; ".join(pybad[:3]))

sec = []
pat = re.compile(r'(api[_-]?key|secret|password|passwd|token|bearer)\s*[:=]\s*["\'][^"\']{8,}["\']', re.I)
assert pat.search('api_key = "abcdefgh12345"'), "secret scanner self-test failed"
for f in walk((".swift", ".py", ".sh", ".command", ".yml", ".json", ".md", ".txt")):
    if f == "Tools/verify_all.py": continue          # contains the detector pattern itself (self-test above proves the pattern works)
    t = read(f)
    if pat.search(t) or "BEGIN PRIVATE KEY" in t or "BEGIN RSA PRIVATE" in t: sec.append(f)
rec("T1", "no embedded secrets", "STATIC PASS" if not sec else "FAIL", ", ".join(sec[:4]))

import provenance
led = provenance.validate_ledger(os.path.join(ROOT, "AssetFactory/PROVENANCE/ledger.json"), ROOT, require_files=True)
lbad = {k: v for k, v in led.items() if v}
rec("T1", "third-party ledger (unknown licence => not incorporated)", "STATIC PASS" if not lbad else "FAIL", str(lbad)[:200])

# tests inventory (existence of tests is not passing tests)
tcount = {}
for f in swift:
    if "Tests" in f:
        tcount[f.split("/")[1] if f.startswith("Packages/") else "App"] = tcount.get(f.split("/")[1] if f.startswith("Packages/") else "App", 0) + len(re.findall(r"func test\w+\(", read(f)))
FLOORS = {"SWAYcoreEngine": 25, "App": 5}
low = [k for k, v in FLOORS.items() if tcount.get(k, 0) < v]
rec("T1", "Swift XCTest functions written (NOT executed)", "STATIC PASS" if not low else "FAIL", json.dumps(tcount) + (" below floor: %s" % low if low else ""))

# ---------------------------------------------------------------- T1b suites
if "--skip-suites" not in sys.argv:
    print("T1b executable suites (Python/shell; Swift tests need macOS)")
    for name, cmd in [("protected-contract regression", [sys.executable, "-W", "ignore", "-m", "unittest", "Tools/regression/test_protected_contracts.py"]),
                      ("as-received defect repro (documents D-001/D-002)", [sys.executable, "-W", "ignore", "-m", "unittest", "Tools/regression/test_candidate_defects_REPRO.py"]),
                      ("engine mirror scenarios (Swift-test equivalents)", [sys.executable, "-W", "ignore", "-m", "unittest", "Tools/regression/test_engine_mirror_scenarios.py"]),
                      ("asset-factory suite", [sys.executable, "-W", "ignore", "-m", "unittest", "discover", "-s", "AssetFactory/tests"]),
                      ("app function contracts (deterministic runner)", [sys.executable, "App/Tests/run_contract_tests.py"]),
                      ("builder evidence regression", [sys.executable, "-m", "unittest", "Tools/regression/test_builder_evidence.py"]),
                      ("DeviceSupport guard behaviour", ["bash", "Tools/regression/test_devicesupport_guard.sh"])]:
        rc, out = run(cmd, 300); last = [l for l in out.strip().splitlines() if l.strip()][-1:] or [""]
        rec("T1b", name, "STATIC PASS" if rc == 0 else "FAIL", last[0][:120])
else: rec("T1b", "executable suites", "UNKNOWN", "--skip-suites")

# ---------------------------------------------------------------- T3 assets
print("T3 assets")
rt = os.path.join(ROOT, "Assets", "Runtime", "Characters")
if os.path.isdir(rt) and os.listdir(rt):
    rc, out = run([sys.executable, "AssetFactory/python/validate_runtime_assets.py", rt, "AssetFactory/data/clip_manifest.json", "--require", "Lucia,YourDancer", "--only-required"])
    rec("T3", "runtime character assets (Alpha only; structural)", "STATIC PASS" if rc == 0 else "FAIL", out.strip().splitlines()[-1][:120] if out.strip() else "")
else: rec("T3", "runtime character assets", "UNKNOWN", "not generated: run BUILD_ASSETS.command (needs Blender and an acquired legal base model)")
rec("T3", "character visual quality / silhouette", "UNKNOWN", "requires human review; never auto-accepted")

# ---------------------------------------------------------------- summary
print("Summary")
tiers = {}
for t, n, s, d in results: tiers.setdefault(s, 0); tiers[s] += 1
fails = [r for r in results if r[2] == "FAIL"]
states = {"IMPLEMENTED": "see source", "STATIC PASS": "FAIL" if fails else "PASS", "BUILD PASS": "UNKNOWN (needs macOS Xcode gate)",
          "ENVIRONMENT PASS": "UNKNOWN (simulator gate)", "PHYSICAL PASS": "UNKNOWN (device gate)"}
print("  counts:", tiers); print("  states:", json.dumps(states))
out = None
if "--json" in sys.argv: out = sys.argv[sys.argv.index("--json") + 1]
else:
    os.makedirs(os.path.join(ROOT, "Build", "report"), exist_ok=True); out = os.path.join(ROOT, "Build", "report", "verify_all.json")
with open(out, "w") as fh: json.dump({"time": time.strftime("%Y-%m-%dT%H:%M:%S"), "host": sys.platform, "results": results, "states": states}, fh, indent=2)
print("  report:", out)
sys.exit(1 if fails else 0)
