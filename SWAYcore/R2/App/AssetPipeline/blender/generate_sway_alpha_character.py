# SWAY Alpha rig generator — run with Blender 4.x:
# blender --background --python generate_sway_alpha_character.py -- --output /path/SWAYAlpha.blend
import bpy, math, sys, os
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
out=args[args.index('--output')+1] if '--output' in args else os.path.abspath('SWAYAlpha.blend')
usd=args[args.index('--usd')+1] if '--usd' in args else None
usd_dir=args[args.index('--usd-dir')+1] if '--usd-dir' in args else None
# clean
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
# Armature in SWAYHumanoid-v1 names.
bpy.ops.object.armature_add(enter_editmode=True, location=(0,0,0))
arm=bpy.context.object; arm.name='SWAYHumanoid-v1'; eb=arm.data.edit_bones; eb.remove(eb[0])
def bone(name,head,tail,parent=None):
 b=eb.new(name); b.head=head; b.tail=tail
 if parent: b.parent=eb[parent]
 return b
bone('Root',(0,0,0),(0,0.08,0)); bone('Hips',(0,0.92,0),(0,1.08,0),'Root')
bone('Spine',(0,1.02,0),(0,1.20,0),'Hips'); bone('Spine1',(0,1.20,0),(0,1.38,0),'Spine'); bone('Chest',(0,1.38,0),(0,1.52,0),'Spine1'); bone('Neck',(0,1.52,0),(0,1.62,0),'Chest'); bone('Head',(0,1.62,0),(0,1.82,0),'Neck')
for side,s in [('Left',1),('Right',-1)]:
 bone(side+'Shoulder',(0.06*s,1.49,0),(0.20*s,1.49,0),'Chest'); bone(side+'UpperArm',(0.20*s,1.49,0),(0.48*s,1.39,0),side+'Shoulder'); bone(side+'LowerArm',(0.48*s,1.39,0),(0.70*s,1.22,0),side+'UpperArm'); bone(side+'Hand',(0.70*s,1.22,0),(0.78*s,1.15,0),side+'LowerArm')
 bone(side+'UpperLeg',(0.12*s,0.95,0),(0.14*s,0.55,0),'Hips'); bone(side+'LowerLeg',(0.14*s,0.55,0),(0.14*s,0.15,0),side+'UpperLeg'); bone(side+'Foot',(0.14*s,0.15,0),(0.14*s,0.07,-0.16),side+'LowerLeg'); bone(side+'Toe',(0.14*s,0.07,-0.16),(0.14*s,0.07,-0.30),side+'Foot')
bpy.ops.object.mode_set(mode='OBJECT')
# Build overlapping rounded geometry, join to one mesh, then automatic weights.
parts=[]
def uv(name,loc,scale):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=16, location=loc); o=bpy.context.object; o.name=name; o.scale=scale; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); parts.append(o)
def capsule(name,a,b,r):
 a,b=Vector(a),Vector(b); mid=(a+b)/2; d=b-a
 bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=r, depth=d.length, location=mid); o=bpy.context.object; o.name=name; o.rotation_mode='QUATERNION'; o.rotation_quaternion=d.to_track_quat('Z','Y'); bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); parts.append(o)
uv('Torso',(0,1.30,0),(0.30,0.39,0.18)); uv('Pelvis',(0,0.96,0),(0.25,0.20,0.17)); uv('Head',(0,1.72,0),(0.18,0.22,0.18))
for side,s in [('L',1),('R',-1)]:
 capsule(side+'UpperArm',(0.18*s,1.48,0),(0.48*s,1.39,0),0.09); capsule(side+'LowerArm',(0.48*s,1.39,0),(0.70*s,1.22,0),0.075); uv(side+'Hand',(0.74*s,1.18,0),(0.08,0.10,0.055))
 capsule(side+'Thigh',(0.12*s,0.92,0),(0.14*s,0.55,0),0.13); capsule(side+'Calf',(0.14*s,0.55,0),(0.14*s,0.15,0),0.105); uv(side+'Foot',(0.14*s,0.09,-0.14),(0.12,0.07,0.20))
# join mesh pieces into a single skinned mesh object
bpy.ops.object.select_all(action='DESELECT')
for p in parts: p.select_set(True)
bpy.context.view_layer.objects.active=parts[0]; bpy.ops.object.join(); mesh=bpy.context.object; mesh.name='SWAYAlphaMesh'
# Smooth mesh, explicit UVs, and a Principled material ready for authored maps.
for poly in mesh.data.polygons: poly.use_smooth=True
mat=bpy.data.materials.new('SWAY_Studio'); mat.diffuse_color=(0.95,0.06,0.28,1)
bsdf=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
bsdf.inputs['Base Color'].default_value=(0.95,0.06,0.28,1)
bsdf.inputs['Roughness'].default_value=0.68
mesh.data.materials.append(mat)
bpy.ops.object.select_all(action='DESELECT'); mesh.select_set(True); bpy.context.view_layer.objects.active=mesh
bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(island_margin=0.015); bpy.ops.object.mode_set(mode='OBJECT')
mesh.data.uv_layers.active.name='SWAYUV'
# Production contract is Z-up; legacy procedural coordinates are Y-up. Rotate the
# completed mesh and armature as one system around world origin, then apply transforms.
for _o in (mesh, arm):
    _o.rotation_euler[0] = math.radians(90.0)
    bpy.context.view_layer.objects.active = _o
    _o.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    _o.select_set(False)

# automatic weights
mesh.select_set(True); arm.select_set(True); bpy.context.view_layer.objects.active=arm; bpy.ops.object.parent_set(type='ARMATURE_AUTO')
required_bones={'Root','Hips','Spine','Spine1','Chest','Neck','Head'}
for side in ('Left','Right'):
 required_bones.update(side+n for n in ('Shoulder','UpperArm','LowerArm','Hand','UpperLeg','LowerLeg','Foot','Toe'))
assert mesh.type=='MESH' and len(mesh.data.vertices)>500, 'SWAY character mesh export is empty or incomplete'
assert set(mesh.vertex_groups.keys())==required_bones, 'SWAY mesh is not weighted to the shared 23-joint rig'
assert mesh.data.uv_layers.active and mesh.data.uv_layers.active.name=='SWAYUV', 'SWAY material UV contract is missing'
assert any(n.type=='BSDF_PRINCIPLED' for n in mat.node_tree.nodes), 'SWAY material is not PBR/texture-ready'
# Runtime skinning contract: <=4 normalized influences.
for _v in mesh.data.vertices:
    _weights=sorted([(_g.group,_g.weight) for _g in _v.groups if _g.weight>1e-8], key=lambda x:-x[1])
    for _gi,_w in _weights[4:]: mesh.vertex_groups[_gi].remove([_v.index])
    _weights=_weights[:4]; _total=sum(_w for _,_w in _weights)
    if _total>0:
        for _gi,_w in _weights: mesh.vertex_groups[_gi].add([_v.index],_w/_total,'REPLACE')

# idle action
bpy.context.view_layer.objects.active=arm; arm.animation_data_create()
def action(name,frames,keys):
 act=bpy.data.actions.new(name); arm.animation_data.action=act
 for f,poses in keys.items():
  for bn,rot in poses.items():
   pb=arm.pose.bones.get(bn)
   if pb: pb.rotation_mode='XYZ'; pb.rotation_euler=rot; pb.keyframe_insert('rotation_euler',frame=f)
 # Blender 5.x actions are layered and no longer expose Action.fcurves.
 # Keyframes inserted above already create valid action channels; interpolation
 # remains Blender's default Bezier, so no legacy fcurve traversal is required.
 return act
action('sway_idle_v1',(1,60),{1:{},30:{'Chest':(0,0,0.025)},60:{}})
action('sway_march_v1',(1,60),{1:{'LeftUpperLeg':(0.45,0,0),'RightUpperArm':(0,0,-0.35)},16:{'LeftUpperLeg':(0,0,0),'RightUpperLeg':(0.45,0,0),'LeftUpperArm':(0,0,0.35)},31:{'RightUpperLeg':(0,0,0),'LeftUpperLeg':(0.45,0,0),'RightUpperArm':(0,0,-0.35)},60:{'LeftUpperLeg':(0,0,0)}})
action('sway_step_touch_v1',(1,60),{1:{'Hips':(0,0,0.08),'LeftUpperLeg':(0,0,-0.12)},16:{'Hips':(0,0,-0.08),'RightUpperLeg':(0,0,0.12)},31:{'Hips':(0,0,0.08),'LeftUpperLeg':(0,0,-0.12)},60:{'Hips':(0,0,-0.08),'RightUpperLeg':(0,0,0.12)}})
action('sway_grapevine_v1',(1,60),{1:{'Hips':(0,0,0.10),'LeftUpperLeg':(0,0,-0.18)},16:{'RightUpperLeg':(0,0,0.22),'Chest':(0,0,-0.06)},31:{'Hips':(0,0,-0.10),'RightUpperLeg':(0,0,0.18)},46:{'LeftUpperLeg':(0,0,-0.22),'Chest':(0,0,0.06)},60:{}})
action('sway_knee_lift_v1',(1,60),{1:{'LeftUpperLeg':(0.95,0,0),'LeftLowerLeg':(-0.65,0,0),'RightUpperArm':(0,0,-0.40)},30:{},31:{'RightUpperLeg':(0.95,0,0),'RightLowerLeg':(-0.65,0,0),'LeftUpperArm':(0,0,0.40)},60:{}})
action('sway_squat_v1',(1,60),{1:{},20:{'Hips':(0.35,0,0),'LeftUpperLeg':(-0.55,0,0),'RightUpperLeg':(-0.55,0,0),'LeftLowerLeg':(0.75,0,0),'RightLowerLeg':(0.75,0,0)},40:{'Hips':(0.35,0,0),'LeftUpperLeg':(-0.55,0,0),'RightUpperLeg':(-0.55,0,0),'LeftLowerLeg':(0.75,0,0),'RightLowerLeg':(0.75,0,0)},60:{}})
action('sway_side_lunge_v1',(1,60),{1:{},20:{'Hips':(0,0,0.10),'LeftUpperLeg':(0,0,-0.30),'LeftLowerLeg':(0.25,0,0)},40:{'Hips':(0,0,-0.10),'RightUpperLeg':(0,0,0.30),'RightLowerLeg':(0.25,0,0)},60:{}})
action('sway_jumping_jack_v1',(1,60),{1:{},16:{'LeftUpperArm':(0,0,-1.15),'RightUpperArm':(0,0,1.15),'LeftUpperLeg':(0,0,-0.30),'RightUpperLeg':(0,0,0.30)},31:{},46:{'LeftUpperArm':(0,0,-1.15),'RightUpperArm':(0,0,1.15),'LeftUpperLeg':(0,0,-0.30),'RightUpperLeg':(0,0,0.30)},60:{}})
action('sway_body_roll_v1',(1,60),{1:{},15:{'Chest':(0.18,0,0),'Spine1':(0.10,0,0)},30:{'Chest':(-0.18,0,0),'Spine':(-0.10,0,0)},45:{'Chest':(0.10,0,0),'Spine1':(0.06,0,0)},60:{}})
action('sway_pivot_turn_v1',(1,60),{1:{},20:{'Root':(0,0,0.75),'Hips':(0,0,0.25)},40:{'Root':(0,0,1.55),'Hips':(0,0,0.25)},60:{'Root':(0,0,0)}})
# preserve actions and keep stable authored clip names for deterministic export
for a in bpy.data.actions: a.use_fake_user=True
bpy.ops.wm.save_as_mainfile(filepath=out)
print('SWAY_ASSET_PIPELINE_OUTPUT='+out)
if usd:
 os.makedirs(os.path.dirname(os.path.abspath(usd)),exist_ok=True)
 bpy.ops.wm.usd_export(filepath=usd, export_animation=True, export_armatures=True, export_meshes=True, export_materials=True)
 print('SWAY_RUNTIME_USD_OUTPUT='+usd)
if usd_dir:
 os.makedirs(usd_dir,exist_ok=True)
 # USD exports one active armature action per file. Export every authored action
 # as a named clip instead of silently emitting only the last-created action.
 for act in bpy.data.actions:
  arm.animation_data.action=act
  clip=os.path.join(usd_dir,act.name+'.usdc')
  bpy.ops.wm.usd_export(filepath=clip, export_animation=True, export_armatures=True, export_meshes=True, export_materials=True)
  print('SWAY_RUNTIME_USD_CLIP='+clip)
