"""Shared helpers for SWAY asset-factory Blender scripts (run inside Blender 5.2.x LTS, headless). Pure helpers import cleanly without bpy."""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "python"))

def args():
    argv = sys.argv; a = argv[argv.index("--") + 1:] if "--" in argv else []
    out, i = {}, 0
    while i < len(a):
        if a[i].startswith("--"):
            k = a[i][2:]
            if i + 1 < len(a) and not a[i + 1].startswith("--"): out[k] = a[i + 1]; i += 2
            else: out[k] = True; i += 1
        else: i += 1
    return out

def load(path):
    with open(path) as fh: return json.load(fh)

def fail(msg, code=3):
    print("[sway-factory] FAIL: " + msg); sys.exit(code)

def filtered(op, **kw):
    """Call a bpy operator with only the keyword args this Blender version supports; log what was skipped (API drift across 4.x/5.x)."""
    props = {p.identifier for p in op.get_rna_type().properties}
    use = {k: v for k, v in kw.items() if k in props}; skipped = sorted(set(kw) - set(use))
    if skipped: print("[sway-factory] operator %s skipped unsupported args: %s" % (op, skipped))
    return op(**use)

def action_fcurves(act):
    if hasattr(act, "fcurves"): return list(act.fcurves)
    out = []
    for layer in getattr(act, "layers", []):
        for strip in layer.strips:
            for cb in getattr(strip, "channelbags", []): out += list(cb.fcurves)
    return out

def find_sway_armature(joints=None):
    """The contract armature: object named SWAYArmature or SWAYHumanoid-v1 (Build 153 name), else the only armature whose bones equal the contract."""
    import bpy
    for n in ("SWAYArmature", "SWAYHumanoid-v1"):
        o = bpy.data.objects.get(n)
        if o and o.type == "ARMATURE": return o
    cands = [o for o in bpy.data.objects if o.type == "ARMATURE" and (joints is None or sorted(b.name for b in o.data.bones) == sorted(joints))]
    return cands[0] if len(cands) == 1 else None
