"""Experimental, UNAPPROVED: rotation-only body-roll articulation applied to EXISTING native IK.
Run: blender -b <verified-foot-contact.blend> --python AssetFactory/blender/sway_trial_lucia_fk_bodyroll.py -- --out-blend <unused-candidate.blend>
This modifies only the body-roll action in a DISTINCT output, never the Swift choreography source or original rig. 21-clip tests and final human visual review remain mandatory.
"""
import bpy,math,os,sys,json
from mathutils import Quaternion,Vector
sys.path.insert(0,os.path.abspath("AssetFactory/blender"))
from sway_common import find_sway_armature,action_fcurves,args
arm=find_sway_armature()
assert arm is not None and arm.get("sway_native_ik") is True
act=bpy.data.actions["sway_body_roll_v1"]
before_actions={a.name:(len(action_fcurves(a)),tuple(a.frame_range)) for a in bpy.data.actions if a.name.startswith("sway_")}
assert len(before_actions)>=21
assert int(act.frame_range[0])==1 and int(act.frame_range[1])==25
for name in ("Spine","Spine1","Chest"):
 assert name in arm.pose.bones
arm.animation_data_create()
arm.animation_data.action=act
# World X bending axis expressed in each native rest basis; only local rotation, no translations.
profile={"Spine":(3.8,0.0),"Spine1":(5.2,-0.70),"Chest":(3.3,-1.35)}
rest={name:arm.data.bones[name].matrix_local.to_quaternion() for name in profile}
originals={}
for frame in range(1,26):
 bpy.context.scene.frame_set(frame)
 originals[frame]={name:arm.pose.bones[name].rotation_quaternion.copy() for name in profile}
assert all((originals[1][j].rotation_difference(originals[25][j]).angle)<1e-5 for j in profile)
for frame in range(1,26):
 phase=(frame-1)/24
 for name,(amplitude,offset) in profile.items():
  pb=arm.pose.bones[name]
  local_axis=rest[name].inverted()@Vector((1.,0.,0.))
  delta=Quaternion(local_axis,math.radians(amplitude)*math.sin(2*math.pi*phase+offset))
  pb.rotation_mode="QUATERNION"
  pb.rotation_quaternion=originals[frame][name]@delta
  pb.keyframe_insert("rotation_quaternion",frame=frame,group=name)
assert all(a.name in before_actions for a in bpy.data.actions if a.name.startswith("sway_"))
arm.animation_data.action=None
for pb in arm.pose.bones:pb.rotation_quaternion=(1,0,0,0);pb.location=(0,0,0)
driver_hash={"driver":"SWAYHumanoid-v1","baseline":"candidate_foot_contact_20261018.blend","mode":"existing-bone-local-rotation-only","axisWorld":[1,0,0],"profileDegrees":profile,"noIndependentTranslation":True,"bodyRollOnly":True}
arm["sway_bodyroll_fk_trial"]=json.dumps(driver_hash)
arm["sway_visual_quality"]="UNREVIEWED"
dest=os.path.abspath(args()["out-blend"])
assert dest != os.path.abspath(bpy.data.filepath), "original .blend overwrite is prohibited"
assert not os.path.exists(dest)
bpy.ops.wm.save_as_mainfile(filepath=dest)
print("ISOLATED_FK_TORSO_ROTATION_CREATED",dest, "original21clips",len(before_actions),"profile",profile)

