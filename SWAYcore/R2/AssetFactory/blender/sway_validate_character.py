"""Structural + deformation-sanity validation of a SWAY character .blend. Exit 0 only if every check passes.
Structural evidence ONLY: it can detect missing/duplicate joints, bad weights, missing clips/materials/textures, budget and scale
problems and gross mesh stretching/tearing during clips. It CANNOT judge whether the character looks good (reported as UNKNOWN).

blender --background --factory-startup <char.blend> --python AssetFactory/blender/sway_validate_character.py -- \
   --clips AssetFactory/data/clip_manifest.json --report Build/report/character_<id>.json [--max-tris 60000]"""
import bpy, os, sys, json
from mathutils import Vector
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sway_common import *
from skin_weights import weight_issues
A = args(); root = os.path.abspath(os.path.join(HERE, "..", ".."))
JOINTS = load(os.path.join(root, "App", "AssetPipeline", "contracts", "SWAYHumanoid-v1.json"))["joints"]
manifest = load(A["clips"]); MAX_TRIS = int(A.get("max-tris", 60000)); issues, notes = [], {}
def bad(m): issues.append(m)

arm = find_sway_armature(JOINTS)
if not arm: bad("armature SWAYArmature missing"); print(json.dumps({"issues": issues})); sys.exit(1)
names = [b.name for b in arm.data.bones]
if len(names) != len(set(names)): bad("duplicate bone names")
if sorted(names) != sorted(JOINTS): bad("bones != contract: %s" % sorted(set(names) ^ set(JOINTS)))
if any(abs(s - 1) > 1e-4 for s in arm.scale): bad("armature scale not applied %s" % (tuple(arm.scale),))
meshes = [o for o in bpy.data.objects if o.type == "MESH" and any(m.type == "ARMATURE" for m in o.modifiers)]
if not meshes: bad("no skinned meshes")
dg = bpy.context.evaluated_depsgraph_get(); tris = 0; zs = []
for m in meshes:
    if not m.data.uv_layers: bad("%s has no UVs" % m.name)
    if not m.data.materials: bad("%s has no material" % m.name)
    rigs = [md.object for md in m.modifiers if md.type == "ARMATURE" and md.object]
    allowed = {b.name for rig in rigs for b in rig.data.bones}
    rows = [{m.vertex_groups[g.group].name: g.weight for g in v.groups} for v in m.data.vertices]
    # Native helpers are valid bones, never an exemption from normalization or <=4 weights.
    body = max(meshes, key=lambda obj: len(obj.data.vertices))
    minimum_used = 18 if m == body else 0
    for problem in weight_issues(rows, allowed, minimum_used=minimum_used): bad(m.name + ": " + problem)
    ev = m.evaluated_get(dg); me = ev.to_mesh(); tris += sum(len(p.vertices) - 2 for p in me.polygons)
    zs += [(m.matrix_world @ Vector(c)).z for c in m.bound_box]; ev.to_mesh_clear()
if tris > MAX_TRIS: bad("triangle budget %d > %d" % (tris, MAX_TRIS))
height = (max(zs) - min(zs)) if zs else 0; notes["triangles"] = tris; notes["heightMeters"] = round(height, 4)
if not (1.4 <= height <= 2.0): bad("height %.3f m outside 1.4-2.0" % height)
imgs = [i for i in bpy.data.images if i.name != "Render Result" and i.source != "VIEWER"]
mats = list(bpy.data.materials); notes["materials"] = len(mats); notes["textures"] = len(imgs)
if not mats: bad("no materials")
for i in imgs:
    if not i.packed_file and not (i.filepath and os.path.exists(bpy.path.abspath(i.filepath))): bad("texture missing on disk: " + i.name)

# --- clips present + deformation sanity (edge stretch / bbox drift / NaN) at sampled frames --------------------
acts = {a.name: a for a in bpy.data.actions}
body = max(meshes, key=lambda o: len(o.data.vertices)) if meshes else None
rest_edges = {}
if body:
    rest_len = [((body.matrix_world @ body.data.vertices[e.vertices[0]].co) - (body.matrix_world @ body.data.vertices[e.vertices[1]].co)).length for e in body.data.edges]
    notes["bodyEdges"] = len(rest_len)
worst_stretch = 0.0; worst_clip = None; worst_gross_delta = 0.0; worst_gross_clip = None; gross_deltas = []
arm.animation_data_create()
for c in manifest["clips"]:
    a = acts.get(c["clip"])
    if not a: bad("clip missing: " + c["clip"]); continue
    if len(action_fcurves(a)) < 23 * 3: bad("clip %s has too few fcurves (%d)" % (c["clip"], len(action_fcurves(a)))); continue
    if int(a.get("sway_beats_per_cycle", 0)) != int(c["beatsPerCycle"]): bad("clip %s beatsPerCycle metadata mismatch" % c["clip"])
    arm.animation_data.action = a
    f0, f1 = int(a.frame_range[0]), int(a.frame_range[1])
    for f in sorted({f0, f0 + (f1 - f0) // 4, f0 + (f1 - f0) // 2, f0 + 3 * (f1 - f0) // 4}):
        bpy.context.scene.frame_set(f); dg = bpy.context.evaluated_depsgraph_get()
        if body:
            ev = body.evaluated_get(dg); me = ev.to_mesh()
            if len(me.vertices) != len(body.data.vertices): ev.to_mesh_clear(); continue
            for e, r in zip(body.data.edges, rest_len):
                if r < 1e-5: continue
                mw_eval = ev.matrix_world
                l = ((mw_eval @ me.vertices[e.vertices[0]].co) - (mw_eval @ me.vertices[e.vertices[1]].co)).length
                if l != l: bad("NaN vertex in %s frame %d" % (c["clip"], f)); break
                s = l / r
                if s > worst_stretch: worst_stretch, worst_clip = s, c["clip"]
                # Ratio alone is unstable on millimetre-scale topology edges. A 4 mm edge becoming 25 mm
                # is 6x but not evidence of body tearing. Gross deformation requires BOTH >2.2x and
                # >3% of character height absolute edge growth; keep ratio as a diagnostic metric.
                delta = max(0.0, l - r); gross_deltas.append(delta)
                if s > 2.2 and delta > worst_gross_delta: worst_gross_delta, worst_gross_clip = delta, c["clip"]
            ev.to_mesh_clear()
arm.animation_data.action = None
notes["worstEdgeStretch"] = round(worst_stretch, 3); notes["worstEdgeStretchClip"] = worst_clip
notes["worstGrossEdgeGrowthMeters"] = round(worst_gross_delta, 4); notes["worstGrossEdgeGrowthClip"] = worst_gross_clip
gross_limit = max(0.05, height * 0.03)
notes["grossEdgeGrowthLimitMeters"] = round(gross_limit, 4)
gross_deltas.sort(); p99 = gross_deltas[int(0.99 * (len(gross_deltas)-1))] if gross_deltas else 0.0
notes["p99EdgeGrowthMeters"] = round(p99, 4)
catastrophic_limit = max(0.15, height * 0.10)
if p99 > gross_limit or worst_gross_delta > catastrophic_limit: bad("gross deformation: p99 %.3f m / max %.3f m in %s exceeds limits %.3f / %.3f m (ratio diagnostic max %.2fx)" % (p99, worst_gross_delta, worst_gross_clip, gross_limit, catastrophic_limit, worst_stretch))
if arm.get("sway_visual_quality") == "ACCEPTED" and not arm.get("sway_reviewed_by"): bad("ACCEPTED without reviewer")

rep = {"character": os.path.basename(bpy.data.filepath), "structural": "PASS" if not issues else "FAIL", "issues": issues, "metrics": notes,
       "visualQuality": arm.get("sway_visual_quality", "UNREVIEWED"), "silhouette": "UNKNOWN (human review required)",
       "blender": bpy.app.version_string}
if "report" in A:
    os.makedirs(os.path.dirname(os.path.abspath(A["report"])), exist_ok=True); json.dump(rep, open(A["report"], "w"), indent=2)
print("[sway-validate] %s: %s %s" % (rep["character"], rep["structural"], notes))
for i in issues: print("   - " + i)
sys.exit(0 if not issues else 1)
