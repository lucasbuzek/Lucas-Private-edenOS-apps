"""Export unapproved runtime candidates (base USDC + one USDC per clip, armature+meshes+materials+animation),
plus a character manifest compatible with the app's lucia.character.json schema.

blender --background --factory-startup <char.blend> --python AssetFactory/blender/sway_export_runtime.py -- \
   --id lucia --display-name Lucia --clips AssetFactory/data/clip_manifest.json --out Assets/Runtime/Characters/Lucia"""
import bpy, os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sway_common import *
A = args(); manifest = load(A["clips"]); out = os.path.abspath(A["out"]); cid = A["id"]
anim_dir = os.path.join(out, "Animations"); os.makedirs(anim_dir, exist_ok=True)
arm = find_sway_armature() or fail("SWAY contract armature missing")
objs = [o for o in bpy.data.objects if o.type == "MESH" and any(m.type == "ARMATURE" for m in o.modifiers)] + [arm]
export_arm=arm;ephemeral=[];native_adapter=False
native=next((o for o in bpy.data.objects if o.type=='ARMATURE' and o!=arm and o.get('sway_native_skinning')),None)
if native:
    # Export the actual skinning rig, never the unskinned animation driver.
    # Canonical names are applied to isolated copies; all native helpers remain.
    mapping={j:n[0] for j,n in load(A.get('map',os.path.join(HERE,'../data/retarget_map_girush.json')))['map'].items()}
    inverse={source:joint for joint,source in mapping.items()}
    if len(inverse)!=len(mapping):fail('retarget map aliases native joints')
    export_arm=native.copy();export_arm.data=native.data.copy();export_arm.name='SWAYRuntimeSkeleton'
    bpy.context.collection.objects.link(export_arm);ephemeral.append(export_arm)
    for source,joint in inverse.items():
        if source not in export_arm.data.bones:fail('native export bone missing '+source)
        export_arm.data.bones[source].name='__SWAY_EXPORT_'+joint
    for joint in mapping:export_arm.data.bones['__SWAY_EXPORT_'+joint].name=joint
    def attached(obj):
        if any(m.type=='ARMATURE' and m.object==native for m in obj.modifiers):return True
        parent=obj.parent
        while parent:
            if parent==native:return True
            parent=parent.parent
        return False
    sources=[o for o in list(bpy.data.objects) if o.type=='MESH' and attached(o)]
    copies={}
    for original in sources:
        copy=original.copy();copy.data=original.data.copy();copy.name=original.name+'_runtime'
        bpy.context.collection.objects.link(copy);ephemeral.append(copy);copies[original]=copy
        # USD skeletal export does not apply additional mesh modifiers. Bake
        # the native mirror/displacement/triangulation on isolated mesh copies,
        # with skin evaluation disabled, preserving UVs and deform-weight layers.
        skin=[m for m in copy.modifiers if m.type=='ARMATURE']
        visibility=[m.show_viewport for m in skin]
        for modifier in skin:modifier.show_viewport=False
        bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get()
        copy.data=bpy.data.meshes.new_from_object(copy.evaluated_get(dg),preserve_all_data_layers=True,depsgraph=dg)
        for modifier in list(copy.modifiers):
            if modifier.type!='ARMATURE':copy.modifiers.remove(modifier)
        for modifier,visible in zip(skin,visibility):modifier.show_viewport=visible
        for group in copy.vertex_groups:
            if group.name in inverse:group.name='__SWAY_EXPORT_'+inverse[group.name]
        for group in copy.vertex_groups:
            if group.name.startswith('__SWAY_EXPORT_'):group.name=group.name[len('__SWAY_EXPORT_'):]
        for modifier in copy.modifiers:
            if modifier.type=='ARMATURE' and modifier.object==native:modifier.object=export_arm
    for original,copy in copies.items():
        if original.parent==native:
            copy.parent=export_arm
            if original.parent_type=='BONE':copy.parent_bone=inverse.get(original.parent_bone,original.parent_bone)
        elif original.parent in copies:copy.parent=copies[original.parent]
    objs=list(copies.values())+[export_arm];native_adapter=True
    parent=export_arm.parent
    while parent:
        if parent not in objs:objs.append(parent)
        parent=parent.parent
base = A.get("asset-base", cid.capitalize() + "Reality")
modules = load(A["modules"]) if A.get("modules") else None
if modules:
    declared = {n for choices in modules["slots"].values() for value in choices.values()
                for n in (value if isinstance(value, list) else [value])}
    present = {o.name for o in objs if o.type == "MESH"}
    missing = sorted(declared - present)
    if missing: fail("module contract meshes absent from export: " + ", ".join(missing))
    for root_name in modules.get("transformParameters", {}).values():
        root = bpy.data.objects.get(root_name) or fail("module transform root absent: " + root_name)
        if root not in objs: objs.append(root)

def select_export(path, animation):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = export_arm
    properties=bpy.ops.wm.usd_export.get_rna_type().properties.keys()
    texture_options={'export_textures_mode':'NEW'} if 'export_textures_mode' in properties else {'export_textures':True}
    world_options={'convert_world_material':False} if 'convert_world_material' in properties else {}
    filtered(bpy.ops.wm.usd_export, filepath=path, selected_objects_only=True, export_animation=animation, export_armatures=True,
             export_meshes=True, export_materials=True, overwrite_textures=True, relative_paths=True,
             export_lights=False, export_cameras=False, visible_objects_only=False, **texture_options, **world_options,
             generate_preview_surface=True, convert_orientation=True, export_global_up_selection="Y", export_global_forward_selection="NEGATIVE_Z")

arm.animation_data_create(); arm.animation_data.action = None
for pb in arm.pose.bones: pb.rotation_mode = "QUATERNION"; pb.location = (0, 0, 0); pb.rotation_quaternion = (1, 0, 0, 0)
select_export(os.path.join(out, base + ".usdc"), False)
if A.get('debug-usda'):select_export(os.path.join(out,base+'.usda'),False)
res = {}
for c in manifest["clips"]:
    act = bpy.data.actions.get(c["clip"]) or fail("clip %s missing in .blend (run sway_bake_clips first)" % c["clip"])
    arm.animation_data.action = act
    bpy.context.scene.frame_start, bpy.context.scene.frame_end = int(act.frame_range[0]), int(act.frame_range[1])
    select_export(os.path.join(anim_dir, c["clip"] + ".usdc"), True)
    if A.get('debug-usda'):select_export(os.path.join(anim_dir,c['clip']+'.usda'),True)
    res[c["move"]] = {"resource": c["clip"], "beatsPerCycle": int(c["beatsPerCycle"]), "loop": True}
arm.animation_data.action = None
man = {"characterID": cid, "displayName": A.get("display-name", cid), "version": 2, "renderer": "realitykit", "assetBaseName": base,
       "skeletonContract": "SWAYHumanoid-v1", "rootJoint": "Root", "hipsJoint": "Hips", "authoredBPM": manifest.get("tempoBPM", 120),
       "runtimeApproved": False, "visualQuality": arm.get("sway_visual_quality", "UNREVIEWED"),
       "motionSource": arm.get("sway_motion_source", "unknown"), "sourceLedgerId": arm.get("sway_source_ledger_id", "none"),
       "blenderVersion": bpy.app.version_string, "animations": res}
if modules:
    man["moduleContract"] = modules
if native_adapter:
    man['nativeHelpersPreserved']=True
    man['exportedSkeleton']='SWAYRuntimeSkeleton'
    man['retargetSourceMapping']=mapping
with open(os.path.join(out, cid + ".character.json"), "w") as fh: json.dump(man, fh, indent=2, sort_keys=True)
print("[sway-factory] exported %s: base + %d clips -> %s" % (cid, len(res), out))
for obj in reversed(ephemeral):bpy.data.objects.remove(obj,do_unlink=True)
