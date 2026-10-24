"""Structural validation of a generated .blend (runs in Blender). Exit code != 0 on any failure.
blender --background <file.blend> --python Blender/validate_blend.py -- --manifest Assets/Characters/<id>.character.json
Structural evidence only: passing does NOT establish visual/production quality."""
import bpy, os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sway_blender_common import *
args = parse_kv(script_args()); man = load_json(args["manifest"]); fixtures = load_json(args["fixtures"])
issues = []
def fail(m): issues.append(m)

arm = bpy.data.objects.get("SWAYArmature")
if not arm: fail("armature SWAYArmature missing")
else:
    names = [b.name for b in arm.data.bones]
    if len(names) != len(set(names)): fail("duplicate bone names")
    if sorted(names) != sorted(fixtures["joints"]): fail("bone set != contract joints: %s" % sorted(set(fixtures["joints"]) ^ set(names)))
    if abs(arm.scale.x - 1) > 1e-6 or abs(arm.scale.z - 1) > 1e-6: fail("armature scale not applied")
for m in REQUIRED_MESHES:
    o = bpy.data.objects.get(m)
    if not o or o.type != 'MESH': fail("mesh %s missing" % m); continue
    if len(o.data.polygons) == 0: fail("mesh %s empty" % m)
    if len(o.data.materials) == 0: fail("mesh %s has no material" % m)
    if not o.data.uv_layers: fail("mesh %s has no UVs" % m)
    if not any(md.type == 'ARMATURE' for md in o.modifiers): fail("mesh %s has no Armature modifier" % m)
    if o.parent is not arm: fail("mesh %s not parented to armature" % m)
    if m in ("Body", "Outfit"):
        bad = 0
        for v in o.data.vertices:
            ws = [g.weight for g in v.groups if g.weight > 1e-4]
            if not ws or abs(sum(ws) - 1.0) > 0.02 or len(ws) > MAX_INFLUENCES: bad += 1
        if bad: fail("%s: %d vertices unweighted/unnormalized/>%d influences" % (m, bad, MAX_INFLUENCES))
        used = {o.vertex_groups[g.group].name for v in o.data.vertices for g in v.groups if g.weight > 1e-4}
        if m == "Body" and len(used) < 18: fail("Body weights use only %d bones" % len(used))
for img in bpy.data.images:
    if img.name == "Render Result": continue
    p = bpy.path.abspath(img.filepath) if img.filepath else ""
    if not (p and os.path.exists(p)) and not img.packed_file: fail("texture %s missing on disk" % img.name)
    elif img.size[0] < 64: fail("texture %s too small" % img.name)
    else:
        px = list(img.pixels[:4096]); 
        if max(px) - min(px) < 0.01: fail("texture %s is flat" % img.name)
if len(bpy.data.materials) == 0: fail("no materials")
clips = {a.name: a for a in bpy.data.actions}
for c in fixtures["movements"]:
    a = clips.get(c["id"])
    if not a: fail("clip %s missing" % c["id"]); continue
    fcs = []
    if hasattr(a, "fcurves"): fcs = list(a.fcurves)
    else:
        for l in a.layers:
            for s in l.strips:
                for cb in getattr(s, "channelbags", []): fcs += list(cb.fcurves)
    if len(fcs) < 23 * 4: fail("clip %s has only %d fcurves" % (c["id"], len(fcs)))
for c in PROOF_CLIPS:
    if c not in clips: fail("proof clip %s missing" % c)
h = man.get("heightMeters", 0)
if not (HEIGHT_RANGE[0] <= h <= HEIGHT_RANGE[1]): fail("height %.3f outside %s" % (h, HEIGHT_RANGE))
if man.get("triangleCount", 1e9) > MAX_TRIANGLES: fail("triangle budget exceeded: %s" % man.get("triangleCount"))
if man.get("visualQuality") == "ACCEPTED": fail("manifest claims ACCEPTED visual quality; only a human review may set that")
print("[sway-validate] %s: %s" % (man.get("characterID"), "PASS (structural)" if not issues else "FAIL"))
for i in issues: print("  - " + i)
sys.exit(0 if not issues else 1)
