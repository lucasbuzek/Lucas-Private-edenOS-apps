"""Add SWAYHumanoid-v1 animation driver while preserving a source rig's native skinning/twist chains."""
import bpy, json, os, sys
from mathutils import Vector,Matrix
sys.path.insert(0,os.path.abspath("AssetFactory/blender")); from sway_common import *
A=args(); root=os.path.abspath(os.path.join(HERE,'..','..')); mapping={k:v[0] for k,v in load(A['map'])['map'].items()}; JOINTS=load(os.path.join(root,'App','AssetPipeline','contracts','SWAYHumanoid-v1.json'))['joints']
source=[o for o in bpy.data.objects if o.type=='ARMATURE' and o.name!='SWAYArmature'][0]
# Driver uses exact source rest transforms and source object transform.
bpy.ops.object.armature_add(enter_editmode=True); drv=bpy.context.object; drv.name='SWAYArmature'; drv.data.name='SWAYHumanoid-v1'
for b in list(drv.data.edit_bones):drv.data.edit_bones.remove(b)
P={'Hips':'Root','Spine':'Hips','Spine1':'Spine','Chest':'Spine1','Neck':'Chest','Head':'Neck'}
for s in ('Left','Right'):P.update({s+'Shoulder':'Chest',s+'UpperArm':s+'Shoulder',s+'LowerArm':s+'UpperArm',s+'Hand':s+'LowerArm',s+'UpperLeg':'Hips',s+'LowerLeg':s+'UpperLeg',s+'Foot':s+'LowerLeg',s+'Toe':s+'Foot'})
for j in JOINTS:
 sb=source.data.bones[mapping[j]]; b=drv.data.edit_bones.new(j); b.head=sb.head_local; b.tail=sb.tail_local
 # Preserve native endpoints AND roll. Assigning matrix_local then length slightly
 # changes legacy imported endpoints; aligning its Z axis reproduces the rest basis
 # without that endpoint drift (checked by the actual Blender rest contract).
 b.align_roll(sb.matrix_local.to_3x3().col[2])
 if (b.tail-b.head).length<1e-4:b.tail=b.head+Vector((0,0,1))
for j in JOINTS:
 if j!='Root':drv.data.edit_bones[j].parent=drv.data.edit_bones[P[j]]
bpy.ops.object.mode_set(mode='OBJECT'); drv.parent=source.parent; drv.matrix_world=source.matrix_world.copy()
# Mapped endpoints copy the driver. Intermediate native deform bones interpolate between surrounding mapped bones.
inv={sn:j for j,sn in mapping.items()}; CHILD_FRACTION={}
for b in source.data.bones:
 if b.name in inv:continue
 anc=b.parent
 while anc and anc.name not in inv:anc=anc.parent
 if not anc:continue
 desc=[]
 def walk(x,d=1):
  for c in x.children:
   if c.name in inv:desc.append((d,c))
   else:walk(c,d+1)
 walk(b)
 if not desc:continue
 _,dn=min(desc,key=lambda x:x[0]); chain=[]; cur=dn
 while cur and cur!=anc:chain.append(cur); cur=cur.parent
 chain=list(reversed(chain)); idx=next((i for i,x in enumerate(chain) if x.name==b.name),None)
 if idx is not None:CHILD_FRACTION[b.name]=(inv[anc.name],inv[dn.name],(idx+1)/(len(chain)+1))
for sn,j in inv.items():
 pb=source.pose.bones[sn]
 # Native helper parents differ from the contract hierarchy. Local offsets compound
 # their rotations; world replacement follows the mapped orientation without rebinding.
 c=pb.constraints.new('COPY_ROTATION'); c.name='SWAY_DRIVER_ROT'; c.target=drv; c.subtarget=j; c.target_space='WORLD'; c.owner_space='WORLD'; c.mix_mode='REPLACE'; c.influence=1.0
# Verified Girush calf helpers copied the animated parent's LOCAL basis again,
# doubling knee rotation. Normal parent inheritance retains the native rest
# offset and skinning. Mute only this exact legacy constraint signature.
muted=[]
for pb in source.pose.bones:
 if pb.name not in ('Tibia.L.001','Tibia.R.001') or pb.name in inv:continue
 for c in pb.constraints:
  if c.type=='COPY_ROTATION' and c.target==source and pb.parent and c.subtarget==pb.parent.name and c.owner_space=='LOCAL' and c.target_space=='LOCAL' and c.mix_mode=='REPLACE':
   c.mute=True;muted.append(pb.name+':'+c.name)
source['sway_muted_legacy_local_parent_copies']=json.dumps(muted)
# Girush spine and pelvis are sibling branches under Sacrum. Whole-body authored
# displacement belongs to Root so both branches translate together.
pb=source.pose.bones[mapping['Root']]; c=pb.constraints.new('COPY_LOCATION'); c.name='SWAY_DRIVER_ROOT_LOC'; c.target=drv; c.subtarget='Root'; c.target_space='LOCAL'; c.owner_space='LOCAL'; c.use_offset=True
# Hips retains its separate contract channel; it must never alias Root.
pb=source.pose.bones[mapping['Hips']]; c=pb.constraints.new('COPY_LOCATION'); c.name='SWAY_DRIVER_LOC'; c.target=drv; c.subtarget='Hips'; c.target_space='LOCAL'; c.owner_space='LOCAL'; c.use_offset=True
source['sway_native_skinning']=True;drv['sway_contract']='SWAYHumanoid-v1';drv['sway_source_ledger_id']=A['ledger-id'];drv['sway_visual_quality']='UNREVIEWED'
# Girush eyes were static children of the import root, not their native eye
# bones. Rigid one-bone skinning preserves their exact rest geometry/UVs and
# follows the existing head/eye chain, including USD skeletal playback.
attachments=[]
for name in ('eye.L','eye.R'):
 eye=bpy.data.objects.get(name)
 if not eye or eye.type!='MESH' or name not in source.data.bones:continue
 if any(m.type=='ARMATURE' and m.object for m in eye.modifiers):continue
 transform=source.matrix_world.inverted()@eye.matrix_world
 eye.data=eye.data.copy();eye.data.transform(transform)
 eye.parent=source;eye.parent_type='OBJECT';eye.matrix_parent_inverse=Matrix.Identity(4);eye.matrix_basis=Matrix.Identity(4)
 source.data.bones[name].use_deform=True
 group=eye.vertex_groups.get(name) or eye.vertex_groups.new(name=name)
 group.add(list(range(len(eye.data.vertices))),1.0,'REPLACE')
 eye.modifiers.new('SWAY_NATIVE_RIGID_ATTACHMENT','ARMATURE').object=source
 attachments.append({'mesh':name,'nativeBone':name,'vertices':len(eye.data.vertices),'influences':1})
source['sway_rigid_native_attachments']=json.dumps(attachments)
bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(A['out']))
print('[sway-factory] native driver',len(CHILD_FRACTION),'intermediate bones')
