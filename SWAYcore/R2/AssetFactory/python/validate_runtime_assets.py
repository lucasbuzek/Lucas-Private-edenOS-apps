#!/usr/bin/env python3
"""Validate exported runtime character assets (no Blender needed). Structural evidence only; never certifies visual quality.
Usage: validate_runtime_assets.py <Characters root> <clip_manifest.json> [--require Lucia[,Nandi,...]] [--only-required] [--report out.json]
Each character dir must contain <id>.character.json, <AssetBase>.usdc and Animations/<clip>.usdc for every manifest clip."""
import json, os, sys, hashlib

def is_usd(path):
    try:
        with open(path, "rb") as fh: head = fh.read(16)
    except OSError: return False
    return head.startswith(b"PXR-USDC") or head.startswith(b"#usda") or head[:4] == b"PK\x03\x04"   # crate, ascii, usdz(zip)

def check_character(d, clips):
    errs = []; man_path = None
    for f in os.listdir(d):
        if f.endswith(".character.json"): man_path = os.path.join(d, f)
    if not man_path: return ["no *.character.json in " + d], {}
    with open(man_path) as fh: m = json.load(fh)
    for k in ("characterID", "skeletonContract", "rootJoint", "hipsJoint", "assetBaseName", "animations", "runtimeApproved"):
        if k not in m: errs.append("manifest missing " + k)
    if m.get("skeletonContract") != "SWAYHumanoid-v1": errs.append("skeletonContract != SWAYHumanoid-v1")
    base = os.path.join(d, m.get("assetBaseName", "?") + ".usdc")
    if not is_usd(base): errs.append("base asset missing/not USD: " + os.path.basename(base))
    elif os.path.getsize(base) < 20_000: errs.append("base asset suspiciously small (%d B)" % os.path.getsize(base))
    for c in clips:
        a = (m.get("animations") or {}).get(c["move"])
        if not a: errs.append("manifest lacks animation for move " + c["move"]); continue
        if a.get("resource") != c["clip"]: errs.append("%s resource %s != %s" % (c["move"], a.get("resource"), c["clip"]))
        if int(a.get("beatsPerCycle", 0)) != int(c["beatsPerCycle"]): errs.append("%s beatsPerCycle mismatch" % c["move"])
        p = os.path.join(d, "Animations", c["clip"] + ".usdc")
        if not is_usd(p): errs.append("clip missing/not USD: " + c["clip"])
    if m.get("runtimeApproved") is True and not m.get("approvedBy"): errs.append("runtimeApproved without approvedBy (only a human gate may set this)")
    if m.get("visualQuality") == "ACCEPTED" and not m.get("reviewedBy"): errs.append("ACCEPTED without reviewedBy")
    sizes = {"baseBytes": os.path.getsize(base) if os.path.isfile(base) else 0,
             "clipBytes": sum(os.path.getsize(os.path.join(d, "Animations", f)) for f in os.listdir(os.path.join(d, "Animations")) if f.endswith(".usdc")) if os.path.isdir(os.path.join(d, "Animations")) else 0}
    return errs, sizes

def main(argv):
    root, clipman = argv[0], argv[1]
    require = []; report = None
    if "--require" in argv: require = [x for x in argv[argv.index("--require") + 1].split(",") if x]
    if "--report" in argv: report = argv[argv.index("--report") + 1]
    with open(clipman) as fh: clips = json.load(fh)["clips"]
    dirs = sorted(x for x in os.listdir(root) if os.path.isdir(os.path.join(root, x))) if os.path.isdir(root) else []
    out = {}; ok = True
    if "--only-required" in argv:
        if not require:
            print("FAIL explicit validation scope requires --require"); return 1
        excluded = sorted(set(dirs) - set(require))
        for name in excluded:
            out[name] = {"status": "UNKNOWN", "errors": ["outside explicitly requested release scope; not validated"]}
        dirs = [d for d in dirs if d in require]
    for r in require:
        if r not in dirs: out[r] = {"status": "FAIL", "errors": ["character directory missing"]}; ok = False
    for d in dirs:
        errs, sizes = check_character(os.path.join(root, d), clips)
        out[d] = {"status": "PASS" if not errs else "FAIL", "errors": errs, "sizes": sizes, "scope": "structural only"}; ok &= not errs
    if not dirs and not require: out["_"] = {"status": "UNKNOWN", "errors": ["no characters present"]}; ok = False
    for k, v in out.items():
        print("%s %s %s" % (v["status"], k, "" if not v["errors"] else "; ".join(v["errors"])))
    if report:
        os.makedirs(os.path.dirname(os.path.abspath(report)), exist_ok=True)
        with open(report, "w") as fh: json.dump({"overall": "PASS" if ok else "FAIL", "validationScope": require if "--only-required" in argv else "all present characters", "characters": out}, fh, indent=2)
    return 0 if ok else 1

if __name__ == "__main__": sys.exit(main(sys.argv[1:]))
