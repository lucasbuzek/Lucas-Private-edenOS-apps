#!/usr/bin/env python3
"""Reproducible distribution packager: sorted entries, fixed timestamps, preserved exec bits, INVENTORY.sha256 + BUILD_MANIFEST.json inside the archive,
and a sibling .sha256. Usage: package_distribution.py <root> <out_dir>"""
import hashlib, json, os, stat, sys, zipfile, time
root, out_dir = os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2])
SKIP_DIRS = {"Build", ".build", "DerivedData", "__pycache__", ".git", ".DS_Store"}
SKIP_FILES = {"INVENTORY.sha256", "BUILD_MANIFEST.json", ".DS_Store", "Signing.local.xcconfig"}
files = []
for d, ds, fs in os.walk(root):
    ds[:] = sorted(x for x in ds if x not in SKIP_DIRS and not x.endswith(".xcodeproj"))
    for f in sorted(fs):
        if f in SKIP_FILES or f.endswith(".pyc"): continue
        files.append(os.path.relpath(os.path.join(d, f), root))
files.sort()
def sha(p):
    h = hashlib.sha256()
    with open(os.path.join(root, p), "rb") as fh:
        for c in iter(lambda: fh.read(1 << 20), b""): h.update(c)
    return h.hexdigest()
inv_lines = ["%s  ./%s" % (sha(f), f) for f in files]
inv = "\n".join(inv_lines) + "\n"
version = open(os.path.join(root, "VERSION")).read().strip()
manifest = {"name": "SWAYcore", "package": "recovery-R2", "version": version, "fileCount": len(files),
            "treeSha256": hashlib.sha256(inv.encode()).hexdigest(),
            "source": "SWAYcore_CLAUDE_CURATED_HANDOFF_2026-10-04.zip (preserved under Reference/)",
            "evidenceStates": {"IMPLEMENTED": "source present", "STATIC PASS": "see Build/report or run VERIFY_ALL", "BUILD": "UNKNOWN", "SIMULATOR": "UNKNOWN", "PHYSICAL": "UNKNOWN", "RELEASE": "NO"},
            "note": "Manifest states are NOT evidence of build/test success."}
os.makedirs(out_dir, exist_ok=True)
name = "SWAYcore-%s" % version; zp = os.path.join(out_dir, name + ".zip")
if os.path.exists(zp): os.remove(zp)
EPOCH = (2026, 10, 4, 0, 0, 0)
def add(z, arc, data, mode):
    zi = zipfile.ZipInfo(arc, EPOCH); zi.compress_type = zipfile.ZIP_DEFLATED; zi.external_attr = (stat.S_IFREG | mode) << 16; z.writestr(zi, data)
with zipfile.ZipFile(zp, "w") as z:
    for f in files:
        st = os.stat(os.path.join(root, f)); mode = 0o755 if st.st_mode & stat.S_IXUSR else 0o644
        with open(os.path.join(root, f), "rb") as fh: add(z, name + "/" + f, fh.read(), mode)
    add(z, name + "/INVENTORY.sha256", inv.encode(), 0o644)
    add(z, name + "/BUILD_MANIFEST.json", json.dumps(manifest, indent=2, sort_keys=True).encode(), 0o644)
h = hashlib.sha256(open(zp, "rb").read()).hexdigest()
open(zp + ".sha256", "w").write("%s  %s\n" % (h, os.path.basename(zp)))
print("packaged %s (%d files + inventory + manifest) sha256=%s" % (zp, len(files), h))
