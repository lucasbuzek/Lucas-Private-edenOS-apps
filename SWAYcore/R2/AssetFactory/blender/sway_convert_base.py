"""Convert a LEGALLY ACQUIRED humanoid base model into a SWAYHumanoid-v1 character .blend (editable master).

blender --background --factory-startup --python AssetFactory/blender/sway_convert_base.py -- \
   --base AssetFactory/sources/<model>.glb --map AssetFactory/data/retarget_map_ue_mannequin.json \
   --character AssetFactory/data/characters.json --id lucia --ledger-id quaternius-ubc --out Assets/Blend/lucia.blend

Pipeline: provenance gate -> import -> discover source bones -> map to the 23 contract joints (FAIL if any unmapped; never guess) ->
build the contract armature from the source's own bone head/tail/roll -> merge every non-contract deform weight into the nearest mapped
ancestor -> limit to 4 influences + normalise -> SWAY style pass (palette from characters.json) -> save. Visual quality is NOT judged here."""
import bpy, os, sys, json
from mathutils import Vector
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sway_common import *
import provenance, bone_aliases

A = args()
for k in ("base", "map", "character", "id", "out", "ledger-id"):
    if k not in A: fail("missing --" + k)
root = os.path.abspath(os.path.join(HERE, "..", ".."))
ledger = load(os.path.join(root, "AssetFactory", "PROVENANCE", "ledger.json"))
entry = next((e for e in ledger["sources"] if e["id"] == A["ledger-id"]), None)
if not entry: fail("ledger entry %s not found" % A["ledger-id"])
errs = provenance.validate_entry(entry, root, require_files=True)
if entry.get("decision") not in ("ADOPT", "ADAPT") or errs:
    fail("PROVENANCE GATE: %s cannot be incorporated: decision=%s %s" % (entry["id"], entry.get("decision"), errs))

CONTRACT = load(os.path.join(root, "App", "AssetPipeline", "contracts", "SWAYHumanoid-v1.json")); JOINTS = CONTRACT["joints"]
PARENT = {"Hips": "Root", "Spine": "Hips", "Spine1": "Spine", "Chest": "Spine1", "Neck": "Chest", "Head": "Neck"}
for s in ("Left", "Right"):
    PARENT.update({s+"Shoulder": "Chest", s+"UpperArm": s+"Shoulder", s+"LowerArm": s+"UpperArm", s+"Hand": s+"LowerArm",
                   s+"UpperLeg": "Hips", s+"LowerLeg": s+"UpperLeg", s+"Foot": s+"LowerLeg", s+"Toe": s+"Foot"})
chars = {c["id"]: c for c in load(A["character"])["characters"]}; ch = chars[A["id"]]

bpy.ops.wm.read_factory_settings(use_empty=True)
base = os.path.abspath(A["base"]); ext = os.path.splitext(base)[1].lower()
if ext in (".glb", ".gltf"): bpy.ops.import_scene.gltf(filepath=base)
elif ext == ".fbx": bpy.ops.import_scene.fbx(filepath=base)
elif ext == ".blend":
    with bpy.data.libraries.load(base) as (src, dst): dst.objects = src.objects
    for o in dst.objects:
        if o: bpy.context.collection.objects.link(o)
else: fail("unsupported base format " + ext)

arms = [o for o in bpy.data.objects if o.type == "ARMATURE"]
if len(arms) != 1: fail("expected exactly one source armature, found %d" % len(arms))
src = arms[0]; # Only skinned meshes belonging to the source humanoid are character geometry.
# Imported GLBs may contain cameras/lights/studio helper meshes (for example Cube/Icosphere);
# carrying those into the SWAY character corrupts height/weight/deformation validation.
all_meshes = [o for o in bpy.data.objects if o.type == "MESH"]
meshes = [o for o in all_meshes if o.parent == src or any(m.type == "ARMATURE" and m.object == src for m in o.modifiers)]
for o in [o for o in all_meshes if o not in meshes]: bpy.data.objects.remove(o, do_unlink=True)
# Normalize external source units to configured character height while preserving source rig/mesh alignment.
_bounds = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
_source_height = max(p.z for p in _bounds) - min(p.z for p in _bounds)
target_height = float(ch.get("heightMeters", 1.70))
if _source_height <= 1e-6: fail("source character has zero height")
scale_factor = target_height / _source_height
for _o in meshes + [src]: _o.scale = tuple(v * scale_factor for v in _o.scale)
bpy.context.view_layer.update()
mapping, missing = bone_aliases.resolve([b.name for b in src.data.bones], load(A["map"]))
if missing: fail("source rig lacks contract joints (add aliases to the map after inspecting the real bone names): %s" % missing)

# --- source world rest data -------------------------------------------------------------
mw = src.matrix_world
rest = {j: (mw @ src.data.bones[b].head_local, mw @ src.data.bones[b].tail_local, src.data.bones[b].matrix_local.to_3x3()) for j, b in mapping.items()}
bpy.ops.object.mode_set(mode="OBJECT") if bpy.context.object and bpy.context.object.mode != "OBJECT" else None

# --- nearest mapped ancestor for every source bone (for weight merging) ------------------
inv = {b: j for j, b in mapping.items()}
def target_joint(bone):
    cur = bone
    while cur is not None:
        if cur.name in inv: return inv[cur.name]
        cur = cur.parent
    return "Hips"
merge = {b.name: target_joint(b) for b in src.data.bones}

# --- contract armature -------------------------------------------------------------------
bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0)); new = bpy.context.active_object
new.name = "SWAYArmature"; new.data.name = "SWAYHumanoid-v1"
for b in list(new.data.edit_bones): new.data.edit_bones.remove(b)
eb = {}
for j in JOINTS:
    b = new.data.edit_bones.new(j)
    if j in rest: b.head, b.tail = rest[j][0], rest[j][1]
    else:   # Root: contract-only anchor on the floor below the hips
        h = rest["Hips"][0]; b.head = Vector((h.x, h.y, 0.0)); b.tail = Vector((h.x, h.y, max(0.05, h.z * 0.1)))
    if (b.tail - b.head).length < 1e-4: b.tail = b.head + Vector((0, 0, 0.02))
    eb[j] = b
# align orientation: tail of each bone toward its primary child where the source gave a degenerate/leaf bone
for j in JOINTS:
    if j != "Root": eb[j].parent = eb[PARENT[j]]; eb[j].use_connect = False
bpy.ops.object.mode_set(mode="OBJECT")

# --- weights: merge into contract groups --------------------------------------------------
for m in meshes:
    vg_src = {g.index: g.name for g in m.vertex_groups}
    acc = []
    for v in m.data.vertices:
        w = {}
        for g in v.groups:
            name = vg_src.get(g.group)
            if name in merge: w[merge[name]] = w.get(merge[name], 0.0) + g.weight
        acc.append(w)
    for g in list(m.vertex_groups): m.vertex_groups.remove(g)
    groups = {j: m.vertex_groups.new(name=j) for j in JOINTS}
    for i, w in enumerate(acc):
        top = sorted(w.items(), key=lambda kv: -kv[1])[:4]; tot = sum(x for _, x in top) or 1.0
        for j, x in top: groups[j].add([i], x / tot, "REPLACE")
    for mod in [x for x in m.modifiers if x.type == "ARMATURE"]: m.modifiers.remove(mod)
    mod = m.modifiers.new("Armature", "ARMATURE"); mod.object = new
    m.parent = new; m.matrix_parent_inverse = new.matrix_world.inverted()

bpy.data.objects.remove(src, do_unlink=True)

# --- SWAY style pass: palette only (shape/topology edits are authored in the .blend by an artist) --
def tint(mat, rgb):
    if not mat or not mat.use_nodes: return
    bs = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if bs and not bs.inputs["Base Color"].is_linked: bs.inputs["Base Color"].default_value = (*rgb, 1.0)
roles = ch.get("materialRoles", {})      # {"substring in source material name": "skin|hair|top|bottom|shoes|eye"}
for m in meshes:
    for slot in m.material_slots:
        nm = (slot.material.name if slot.material else "").lower()
        for key, role in roles.items():
            if key.lower() in nm:
                rgb = ch["skin"] if role == "skin" else ch["hairColor"] if role == "hair" else ch["eye"] if role == "eye" else ch["outfit"].get(role)
                if rgb: tint(slot.material, rgb)

# --- record provenance inside the .blend and save ---------------------------------------------
new["sway_contract"] = "SWAYHumanoid-v1"; new["sway_source_ledger_id"] = entry["id"]; new["sway_source_files"] = json.dumps(entry.get("files", []))
new["sway_visual_quality"] = "UNREVIEWED"
os.makedirs(os.path.dirname(os.path.abspath(A["out"])), exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(A["out"]))
print("[sway-factory] converted %s -> %s (%d joints, %d meshes)" % (os.path.basename(base), A["out"], len(JOINTS), len(meshes)))
