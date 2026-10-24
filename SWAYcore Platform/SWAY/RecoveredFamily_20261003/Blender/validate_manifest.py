#!/usr/bin/env python3
"""Pure-Python (no Blender) validation of runtime character manifests and files. Mirrors Swift RigContract.
Usage: validate_manifest.py <Assets/Characters dir> <fixtures movements.json> [--require-all]
Exit 0 only if every checked character passes. Structural evidence only; never certifies visual quality."""
import json, os, sys, zipfile, hashlib

CONTRACT = "SWAYHumanoid-v2"
REQUIRED_MESHES = ["Body", "Head", "Eyes", "Hair", "Outfit"]
PROOF = ["sway_idle_v1", "sway_march_v1", "sway_step_touch_v1", "sway_grapevine_v1", "sway_knee_lift_v1",
         "sway_squat_v1", "sway_side_lunge_v1", "sway_jumping_jack_v1", "sway_body_roll_v1", "sway_pivot_turn_v1"]
CHARACTERS = ["lucia", "nandi", "thabo", "zuri", "kyle", "yourdancer"]

def validate_manifest(m, joints, clips_required):
    e = []
    if m.get("contract") != CONTRACT: e.append("contract mismatch")
    j = m.get("joints", [])
    if len(set(j)) != len(j): e.append("duplicate joints")
    miss = set(joints) - set(j)
    if miss: e.append("missing joints: %s" % sorted(miss))
    if m.get("upAxis") != "Y": e.append("upAxis must be Y")
    if abs(m.get("metersPerUnit", 0) - 1.0) > 1e-9: e.append("metersPerUnit must be 1.0")
    if not (1.4 <= m.get("heightMeters", 0) <= 2.0): e.append("height out of range")
    for r in REQUIRED_MESHES:
        if r not in m.get("meshes", []): e.append("missing mesh " + r)
    for c in clips_required:
        if c not in m.get("clips", []): e.append("missing clip " + c)
    if not m.get("materials"): e.append("no materials")
    if not m.get("textures"): e.append("no textures")
    t = m.get("triangleCount", 0)
    if t <= 0 or t > 60000: e.append("triangle budget (%s)" % t)
    if m.get("maxSkinInfluences", 99) > 4: e.append("skin influences > 4")
    if not m.get("asset") or not m.get("blendSource"): e.append("missing asset/blend path")
    if m.get("visualQuality") == "ACCEPTED" and not m.get("reviewedBy"): e.append("ACCEPTED without reviewer")
    return e

def validate_files(m, chardir, root):
    e = []
    a = os.path.join(chardir, m["asset"])
    if not os.path.isfile(a): e.append("asset file missing: " + m["asset"])
    elif not zipfile.is_zipfile(a): e.append("asset is not a valid usdz/zip: " + m["asset"])
    else:
        with zipfile.ZipFile(a) as z:
            bad = z.testzip()
            if bad: e.append("corrupt usdz member " + bad)
            if not any(n.endswith((".usd", ".usda", ".usdc")) for n in z.namelist()): e.append("usdz has no usd layer")
    for c, f in m.get("clipFiles", {}).items():
        p = os.path.join(chardir, f)
        if not os.path.isfile(p) or not zipfile.is_zipfile(p): e.append("clip file missing/invalid: " + f)
    bl = os.path.join(root, m["blendSource"]) if m.get("blendSource") else ""
    if not os.path.isfile(bl): e.append(".blend source missing: " + str(m.get("blendSource")))
    for t in m.get("textures", []):
        if not os.path.isfile(os.path.join(chardir, "textures", t)): e.append("texture missing: " + t)
    return e

def main(argv):
    chardir, fix = argv[0], argv[1]
    require_all = "--require-all" in argv
    fixtures = json.load(open(fix)); joints = fixtures["joints"]
    clips = [c["id"] for c in fixtures["movements"]]
    root = os.path.dirname(os.path.abspath(chardir))
    ok = True; seen = []
    for cid in CHARACTERS:
        p = os.path.join(chardir, cid + ".character.json")
        if not os.path.isfile(p):
            if require_all: print("FAIL %s: manifest missing" % cid); ok = False
            continue
        m = json.load(open(p)); seen.append(cid)
        errs = validate_manifest(m, joints, clips) + validate_files(m, chardir, root)
        if m.get("characterID") != cid: errs.append("characterID mismatch")
        print(("PASS" if not errs else "FAIL") + " %s (structural)" % cid)
        for x in errs: print("   - " + x)
        ok &= not errs
    if require_all and sorted(seen) != sorted(CHARACTERS): ok = False
    print("manifest validation: %s (%d/%d characters)" % ("PASS" if ok else "FAIL", len(seen), len(CHARACTERS)))
    return 0 if ok else 1

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
