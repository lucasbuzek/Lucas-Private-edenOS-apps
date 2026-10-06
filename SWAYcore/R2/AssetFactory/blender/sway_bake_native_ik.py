"""Bake native Blender connected-chain IK onto an existing SWAY driver.
Requires a distinct output; preserves native rest basis, deform helpers and skin.
Run after the authored pose bake, then all unchanged gates and rendered review."""
import bpy,json,sys,os,math
from mathutils import Vector,Matrix
sys.path.insert(0,os.path.abspath("AssetFactory/blender"));from sway_common import *
import coach_pose_port as cp
A=args();out=os.path.abspath(A["out"]);source=bpy.data.filepath
if out==os.path.abspath(source):raise RuntimeError("source overwrite forbidden")
cp.assert_in_sync(os.path.abspath("App/SWAY/Views/StickFigureView.swift"))
arm=find_sway_armature();joints=[b.name for b in arm.data.bones];mw=arm.matrix_world.copy();rest={j:mw@arm.data.bones[j].head_local for j in joints};rr={j:(mw@arm.data.bones[j].matrix_local).to_quaternion() for j in joints};manifest=load(A["clips"]);bpm=float(manifest.get("tempoBPM",120));fps=bpm*12/60
bpy.ops.object.armature_add(enter_editmode=True);ctrl=bpy.context.object;ctrl.name="IKcontrolExperiment"
for b in list(ctrl.data.edit_bones):ctrl.data.edit_bones.remove(b)
chains={}
for side,display in [("Left","right"),("Right","left")]:
 for kind,names in [("Arm",("UpperArm","LowerArm","Hand")),("Leg",("UpperLeg","LowerLeg","Foot"))]:
  u,l,e=[side+n for n in names];upper=ctrl.data.edit_bones.new(u);lower=ctrl.data.edit_bones.new(l);upper.head=rest[u];upper.tail=rest[l];lower.head=rest[l];lower.tail=rest[e];lower.parent=upper;lower.use_connect=True
  for b,j in [(upper,u),(lower,l)]:b.align_roll((mw@arm.data.bones[j].matrix_local).to_3x3().col[2])
  chains[(side,kind)]=(display,u,l,e)
bpy.ops.object.mode_set(mode="OBJECT");controls={};objects=[]
for key,(display,u,l,e) in chains.items():
 t=bpy.data.objects.new(l+"target",None);p=bpy.data.objects.new(l+"pole",None);bpy.context.collection.objects.link(t);bpy.context.collection.objects.link(p);objects.extend([t,p]);c=ctrl.pose.bones[l].constraints.new("IK");c.target=t;c.pole_target=p;c.chain_count=2;c.use_tail=True;c.use_stretch=False;c.iterations=200;controls[key]=(t,p)
results={};target_errors=[];pole_calibration={}
for entry in manifest["clips"]:
 act=bpy.data.actions[entry["clip"]];arm.animation_data.action=act;first,last=map(int,act.frame_range);frames=[]
 for f in range(first,last+1):
  bpy.context.scene.frame_set(f);bpy.context.view_layer.update();pose=cp.NEUTRAL if entry.get("synthetic") else cp.pose(entry["move"],(f-first)/fps,bpm)
  matrices={j:arm.pose.bones[j].matrix.copy() for j in joints}
  for key,(display,u,l,e) in chains.items():
   side,kind=key;t,p=controls[key];pivot=mw@arm.pose.bones[u].head;mat=ctrl.data.bones[u].matrix_local.copy();mat.translation=pivot;ctrl.pose.bones[u].matrix=mat;ctrl.pose.bones[l].rotation_mode="QUATERNION";ctrl.pose.bones[l].rotation_quaternion=(1,0,0,0)
   if kind=="Arm":
    reach=(rest[l]-rest[u]).length+(rest[e]-rest[l]).length;scale=reach/math.dist(cp.NEUTRAL[display+"Shoulder"],cp.NEUTRAL[display+"Hand"]);a,b=pose[display+"Shoulder"],pose[display+"Hand"];t.location=pivot+Vector(((b[0]-a[0])*scale,0,-(b[1]-a[1])*scale));el=pose[display+"Elbow"];p.location=pivot+Vector(((el[0]-a[0])*scale,.25,-(el[1]-a[1])*scale))
   else:
    scale=(rest[u].z-rest[e].z)/(.91-.56);a,b=cp.NEUTRAL[display+"Foot"],pose[display+"Foot"];lift=max(0,a[1]-b[1]);t.location=rest[e]+Vector(((b[0]-a[0])*scale,-lift*.9,lift*scale));p.location=rest[l]+Vector((0,-1,0))
  if not pole_calibration:
   # Calibrate Blender pole-angle conventions against each native rest roll.
   # Use a bent reference chain, then restore the actual authored target.
   for key,(display,u,l,e) in chains.items():
    target,pole=controls[key];saved=target.location.copy();pivot=ctrl.pose.bones[u].head.copy();target.location=pivot+(saved-pivot)*.85
    axis=(target.location-pivot).normalized();desired=pole.location-pivot;desired=(desired-axis*desired.dot(axis)).normalized();constraint=ctrl.pose.bones[l].constraints[0];best=(-2,0)
    for degrees in range(-180,180,5):
     constraint.pole_angle=math.radians(degrees);bpy.context.view_layer.update();bend=ctrl.pose.bones[l].head-pivot;bend=bend-axis*bend.dot(axis)
     score=bend.normalized().dot(desired) if bend.length>1e-8 else -2
     if score>best[0]:best=(score,degrees)
    constraint.pole_angle=math.radians(best[1]);target.location=saved;pole_calibration[u]={"degrees":best[1],"alignment":best[0]}
  bpy.context.view_layer.update()
  for key,(display,u,l,e) in chains.items():
   for j in [u,l]:
    q=ctrl.pose.bones[j].matrix.to_quaternion()@ctrl.data.bones[j].matrix_local.to_quaternion().inverted()@rr[j];m=(mw.to_quaternion().inverted()@q).to_matrix().to_4x4();m.translation=mw.inverted()@ctrl.pose.bones[j].head;matrices[j]=m
   endpoint=ctrl.pose.bones[l].tail.copy();target_errors.append((endpoint-controls[key][0].location).length)
   q=rr[e] if key[1]=="Leg" else ctrl.pose.bones[l].matrix.to_quaternion()@ctrl.data.bones[l].matrix_local.to_quaternion().inverted()@rr[e];m=(mw.to_quaternion().inverted()@q).to_matrix().to_4x4();m.translation=mw.inverted()@endpoint;matrices[e]=m
   if key[1]=="Leg":toe=key[0]+"Toe";matrices[toe]=m@arm.data.bones[e].matrix_local.inverted()@arm.data.bones[toe].matrix_local
  heading=0 if entry.get('synthetic') else cp.heading(entry['move'],(f-first)/fps,bpm)
  if heading:
   # Whole-body heading is part of the shared authored pose, never an
   # independently advancing presentation clock. Rotate all target matrices
   # around the native pelvis before converting them back to local channels.
   pivot=mw@matrices['Hips'].translation
   world_turn=Matrix.Translation(pivot)@Matrix.Rotation(heading,4,'Z')@Matrix.Translation(-pivot)
   local_turn=mw.inverted()@world_turn@mw
   matrices={j:local_turn@matrix for j,matrix in matrices.items()}
  frames.append((f,matrices))
 results[entry["clip"]]=frames
for o in objects+[ctrl]:bpy.data.objects.remove(o,do_unlink=True)
for name,frames in results.items():
 act=bpy.data.actions.new(name+"_connectedIK");arm.animation_data.action=act
 for f,matrices in frames:
  for j in joints:
   pb=arm.pose.bones[j];pb.rotation_mode="QUATERNION";bone=arm.data.bones[j];kwargs={}
   if bone.parent:kwargs={"parent_matrix":matrices[bone.parent.name],"parent_matrix_local":bone.parent.matrix_local}
   pb.matrix_basis=bone.convert_local_to_pose(matrices[j],bone.matrix_local,invert=True,**kwargs);pb.keyframe_insert("rotation_quaternion",frame=f);pb.keyframe_insert("location",frame=f)
 for fc in action_fcurves(act):
  for k in fc.keyframe_points:k.interpolation="LINEAR"
 old=bpy.data.actions[name]
 for key,value in old.items():act[key]=value
 bpy.data.actions.remove(old);act.name=name;act.use_fake_user=True
arm.animation_data.action=None
for pb in arm.pose.bones:pb.location=(0,0,0);pb.rotation_quaternion=(1,0,0,0)
native=next(o for o in bpy.data.objects if o.type=="ARMATURE" and o.get("sway_native_skinning"))
# Legacy calf constraint repair belongs to the verified native-driver stage.
for rig in [arm,native]:rig["sway_visual_quality"]="UNREVIEWED"
arm["sway_native_ik"]=True;arm["sway_pole_calibration"]=json.dumps(pole_calibration)
bpy.ops.wm.save_as_mainfile(filepath=out);arm["sway_native_ik"]=True;print("CONNECTED_NATIVE_IK",len(results),"clips; max endpoint target error",max(target_errors),"UNREVIEWED")
