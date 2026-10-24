"""Shared helpers for SWAYcore Blender scripts. Runs inside Blender (bpy) except pure helpers."""
import json, hashlib, os, sys

CONTRACT = "SWAYHumanoid-v2"
REQUIRED_MESHES = ["Body", "Head", "Eyes", "Hair", "Outfit"]
PROOF_CLIPS = ["sway_idle_v1", "sway_march_v1", "sway_step_touch_v1", "sway_grapevine_v1", "sway_knee_lift_v1",
               "sway_squat_v1", "sway_side_lunge_v1", "sway_jumping_jack_v1", "sway_body_roll_v1", "sway_pivot_turn_v1"]
HEIGHT_RANGE = (1.4, 2.0)
MAX_TRIANGLES = 60000
MAX_INFLUENCES = 4

def script_args():
    """Arguments after the first '--' (Blender convention)."""
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []

def parse_kv(args):
    out, i = {}, 0
    while i < len(args):
        if args[i].startswith("--"):
            out[args[i][2:]] = args[i + 1] if i + 1 < len(args) and not args[i + 1].startswith("--") else True
            i += 2 if out[args[i][2:]] is not True else 1
        else:
            i += 1
    return out

def sway_to_blender(v):
    """SWAY (+x subject-left, +y up, +z forward) -> Blender (+X left, +Z up, forward = -Y)."""
    return (v[0], -v[2], v[1])

def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()

def load_json(path):
    with open(path) as f:
        return json.load(f)

def filtered_op(op, **kwargs):
    """Call a bpy operator passing only keyword arguments the running Blender version supports."""
    props = {p.identifier for p in op.get_rna_type().properties}
    use = {k: v for k, v in kwargs.items() if k in props}
    skipped = sorted(set(kwargs) - set(use))
    if skipped:
        print("[sway] operator %s: skipped unsupported args %s" % (op.idname() if hasattr(op, 'idname') else op, skipped))
    return op(**use)
