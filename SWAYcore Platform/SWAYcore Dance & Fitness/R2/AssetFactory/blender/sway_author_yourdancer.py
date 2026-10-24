"""Author modular YOUR DANCER geometry on the existing articulated Girush CC0 character.

Run after the native-skin repair and before ``sway_export_runtime.py``.  This does not
create a primitive stand-in: every visible module is derived from the licensed,
armature-deformed production character and retains its vertex groups/armature modifier.
The resulting names are the runtime API declared by your_dancer_modules.json.
"""
import bpy, bmesh, json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sway_common import args, fail

A = args()
contract_path = A.get("contract", os.path.join(os.path.dirname(__file__), "../data/your_dancer_modules.json"))
with open(contract_path) as fh: contract = json.load(fh)
native = next((o for o in bpy.data.objects if o.type == "ARMATURE" and o.get("sway_native_skinning")), None)
if not native: fail("native articulated skinning rig missing; run REPAIR_NATIVE_SKIN first")
meshes = [o for o in bpy.data.objects if o.type == "MESH" and any(m.type == "ARMATURE" and m.object == native for m in o.modifiers)]
body = next((o for o in meshes if "body" in o.name.lower()), None)
hair = next((o for o in meshes if "hair" in o.name.lower()), None)
if not body or not hair: fail("licensed body/hair source meshes not found")

def material(name, color):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1.0)
    # A viewport diffuse swatch alone is not a USD/RealityKit material.
    # Author actual physically based shader inputs for UsdPreviewSurface export.
    m.use_nodes = True
    nodes = m.node_tree.nodes
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    shader = nodes.new("ShaderNodeBsdfPrincipled")
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    shader.inputs["Roughness"].default_value = 0.73
    shader.inputs["Metallic"].default_value = 0.0
    m.node_tree.links.new(shader.outputs["BSDF"], output.inputs["Surface"])
    return m

mats = {
    "skin": material("YD_Mat_Skin", (0.60, 0.42, 0.32)), "hair": material("YD_Mat_Hair", (0.10, 0.07, 0.05)),
    "outfit": material("YD_Mat_Outfit", (0.55, 0.30, 0.90)), "accent": material("YD_Mat_Accent", (0.95, 0.45, 0.25)),
    "shoes": material("YD_Mat_Shoes", (0.90, 0.90, 0.95)), "appearance": material("YD_Mat_Appearance", (1, 1, 1))}

def variant(source, name, scale=(1, 1, 1), mat=None, region=None):
    obj = source.copy(); obj.data = source.data.copy(); obj.name = name
    bpy.context.collection.objects.link(obj)
    # Skin-compatible shape choices must survive later parent-world rebasing.
    # Apply variant differences to COPY mesh vertices about their local centroid,
    # not to object.scale (which the parent assignment recalculates/reset).
    # Preserve original object/rest matrix and each original vertex group.
    if scale != (1, 1, 1):
        from mathutils import Matrix, Vector
        center = sum((v.co for v in obj.data.vertices), Vector()) / len(obj.data.vertices)
        sx,sy,sz=map(float,scale)
        shape=Matrix.Translation(center) @ Matrix.Diagonal((sx,sy,sz,1.0)) @ Matrix.Translation(-center)
        obj.data.transform(shape)
        obj.data.update()
    if region:
        bm = bmesh.new(); bm.from_mesh(obj.data)
        lo = min(v.co.z for v in bm.verts); hi = max(v.co.z for v in bm.verts); span = max(hi-lo, .001)
        doomed = [v for v in bm.verts if not region((v.co.z-lo)/span, abs(v.co.x), abs(v.co.y))]
        bmesh.ops.delete(bm, geom=doomed, context="VERTS"); bm.to_mesh(obj.data); bm.free()
        if not obj.data.vertices: fail("empty module region " + name)
    if mat: obj.data.materials.clear(); obj.data.materials.append(mat)
    obj["sway_module"] = True; obj["sway_shared_rig"] = "SWAYHumanoid-v1"; obj.hide_render = True; obj.hide_viewport = True
    return obj

# Body and face alternatives remain genuinely skinned meshes, not image layers.
below_head=lambda z,x,y:z < .86
head=lambda z,x,y:z >= .84
for name, scale in (("YD_Body_Athletic", (1.05,.94,1)), ("YD_Body_Balanced", (1,1,1)), ("YD_Body_Soft", (1.08,1.06,.98))): variant(body,name,scale,mats["skin"],below_head)
for name, scale in (("YD_Face_Oval", (.98,.98,1.04)), ("YD_Face_Round", (1.06,1.04,.97)), ("YD_Face_Angular", (.94,1.02,1.01))): variant(body,name,scale,mats["skin"],head)
for name, scale in (("YD_Hair_Short", (1,.9,.72)), ("YD_Hair_Long", (1,1,1.28)), ("YD_Hair_Braids", (.82,.82,1.22)), ("YD_Hair_Afro", (1.25,1.25,1.18)), ("YD_Hair_Bun", (.78,.78,1.38))): variant(hair,name,scale,mats["hair"])
# Feature meshes are separately selectable, skinned facial regions. Their subtle
# silhouette changes are deliberately geometry, not painted/PNG facial overlays.
for prefix, scales in {
    "Eyes":((.94,1,1),(1,1,1),(1.06,1,1),(1.10,.96,1)),
    "Brows":((.94,1,.98),(1,1,1),(1.06,1,1.02),(1.10,.96,1.04)),
    "Nose":((.92,.94,1),(1,1,1),(1.06,1.04,1),(1.10,1.08,1.02)),
    "Mouth":((.92,1,.98),(1,1,1),(1.08,1,1.02),(1.12,.98,1.04)),
    "Facial_Hair":((.90,.96,.96),(1,1,1),(1.06,1.03,1.02),(1.12,1.06,1.04))}.items():
    for i, scale in enumerate(scales): variant(body,"YD_%s_%d"%(prefix,i),scale,mats["appearance"],head)

# Clothing/accessories use deformed source topology and therefore follow all 23 joints.
for name, scale, mat in [
 ("YD_Top_Tee",(1.025,1.025,.62),"outfit"),("YD_Top_Tank",(1.018,1.018,.54),"outfit"),("YD_Top_Jacket",(1.055,1.055,.68),"outfit"),
 ("YD_Bottom_Legging",(1.018,1.018,.58),"accent"),("YD_Bottom_Short",(1.035,1.035,.43),"accent"),("YD_Bottom_Jogger",(1.05,1.05,.62),"accent"),
 ("YD_Shoes_Trainers",(1.06,1.10,.18),"shoes"),("YD_Shoes_HighTops",(1.07,1.11,.25),"shoes"),("YD_Shoes_Barefoot",(1,1,.14),"skin"),
 ("YD_Accessory_Cap",(1.08,1.08,.22),"accent"),("YD_Accessory_Headband",(1.05,1.05,.08),"accent"),
 ("YD_Accessory_Wristbands",(.23,.23,.12),"accent"),("YD_Accessory_Gloves",(.26,.26,.18),"accent")]:
    if name.startswith("YD_Top_"): region=lambda z,x,y:.48 < z < .82
    elif name.startswith("YD_Bottom_"): region=lambda z,x,y:.12 < z < .54
    elif name.startswith("YD_Shoes_"): region=lambda z,x,y:z < .16
    elif name in ("YD_Accessory_Cap","YD_Accessory_Headband"): region=head
    else: region=lambda z,x,y:.45 < z < .72 and x > .22
    variant(body,name,scale,mats[mat],region)

body.hide_render = True; hair.hide_render = True
# Stable transform groups consumed by RealityKit. Preserve world transforms while
# parenting modules so body/head/limb/hair scale controls affect visible geometry.
roots={name:bpy.data.objects.get(name) for name in ("Body_Root","Head_Root","Limbs_Root","Hair_Root")}
for name,root in list(roots.items()):
    if not root: root=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(root);roots[name]=root
for obj in [o for o in bpy.data.objects if o.get("sway_module")]:
    world=obj.matrix_world.copy()
    if obj.name.startswith("YD_Hair_"): root=roots["Hair_Root"]
    elif any(x in obj.name for x in ("Face_","Eyes_","Brows_","Nose_","Mouth_","Facial_Hair_")): root=roots["Head_Root"]
    elif any(x in obj.name for x in ("Shoes_","Accessory_Wrist","Accessory_Gloves")): root=roots["Limbs_Root"]
    else: root=roots["Body_Root"]
    obj.parent=root;obj.matrix_world=world
# The final Blender source must preserve exactly the authoritative modular
# choices, each with actual vertices and the existing native skinning rig.
required=set()
for options in contract["slots"].values():
    for item in options.values():
        required.update(item if isinstance(item,list) else [item])
authored={obj.name:obj for obj in bpy.data.objects if obj.type=="MESH" and obj.get("sway_module")}
if set(authored)!=required:fail("native YOUR DANCER module mismatch: missing="+str(sorted(required-set(authored)))+" extra="+str(sorted(set(authored)-required)))
for obj in authored.values():
    if not obj.data.vertices or not any(m.type=="ARMATURE" and m.object==native for m in obj.modifiers):
        fail("invalid native skinned YOUR DANCER module "+obj.name)
native["sway_module_contract"] = os.path.basename(contract_path)
native["sway_visual_quality"] = "UNREVIEWED"
out = A.get("out")
if out: bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(out))
print("[sway-factory] authored %d contract-verified skinned YOUR DANCER modules; visual quality UNREVIEWED" % len(authored))
