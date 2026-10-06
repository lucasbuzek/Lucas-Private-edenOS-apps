"""Inspect EVERY baked frame and optionally render every clip's representative/extreme frames.
Never sets runtimeApproved. Run on an immutable candidate with --report PATH [--renders DIR].
This complements, and never replaces, sway_validate_character.py or human motion review.
"""
import bpy,os,sys,json,math,hashlib
from mathutils import Vector,Quaternion
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from sway_common import args,load,find_sway_armature,HERE
from motion_evidence import representative_frames,rotation_distance,direction_error
import coach_pose_port as cp
cp.assert_in_sync(os.path.join(os.path.abspath(os.path.join(HERE,"../..")),"App/SWAY/Views/StickFigureView.swift"))
A=args();root=os.path.abspath(os.path.join(HERE,'../..'))
manifest=load(A.get('clips',os.path.join(root,'AssetFactory/data/clip_manifest.json')))
mapping={j:n[0] for j,n in load(A.get('map',os.path.join(root,'AssetFactory/data/retarget_map_girush.json')))['map'].items()}
driver=find_sway_armature();native=next((o for o in bpy.data.objects if o.type=='ARMATURE' and o!=driver and o.get('sway_native_skinning')),None)
if not driver or not native:raise RuntimeError('native rig and SWAY driver required')
issues=[];pose_issues=[];rest_errors={};clips=[]
for j,n in mapping.items():
    if j not in driver.data.bones or n not in native.data.bones:raise RuntimeError('missing mapped bone '+j)
    rest_errors[j]=rotation_distance(tuple((driver.matrix_world@driver.data.bones[j].matrix_local).to_quaternion()),tuple((native.matrix_world@native.data.bones[n].matrix_local).to_quaternion()))
    if rest_errors[j]>1:issues.append('rest orientation mismatch '+j)
driver.animation_data_create()
rest_chest=(native.matrix_world@native.data.bones[mapping['Chest']].matrix_local).to_quaternion()
rest_rotations={j:(native.matrix_world@native.data.bones[sn].matrix_local).to_quaternion() for j,sn in mapping.items()}
rest_hips=driver.matrix_world@driver.data.bones['Hips'].head_local
rest_neck=driver.matrix_world@driver.data.bones['Neck'].head_local
torso_scale=(rest_neck.z-rest_hips.z)/(cp.NEUTRAL['hip'][1]-cp.NEUTRAL['neck'][1])
for entry in manifest['clips']:
    name=entry['clip'];act=bpy.data.actions.get(name)
    if not act:issues.append('missing clip '+name);continue
    driver.animation_data.action=act;first,last=map(int,act.frame_range);severity={};previous={};samples=[]
    for frame in range(first,last+1):
        bpy.context.scene.frame_set(frame);dg=bpy.context.evaluated_depsgraph_get();d=driver.evaluated_get(dg);n=native.evaluated_get(dg)
        worst_orientation=worst_position=worst_jump=0.;joints={}
        for j,sn in mapping.items():
            db=d.pose.bones[j];nb=n.pose.bones[sn];dm=d.matrix_world@db.matrix;nm=n.matrix_world@nb.matrix
            dq,nq=tuple(dm.to_quaternion()),tuple(nm.to_quaternion())
            orientation=rotation_distance(dq,nq);position=(dm.translation-nm.translation).length
            jump=rotation_distance(previous[j],nq) if j in previous else 0.;previous[j]=nq
            worst_orientation=max(worst_orientation,orientation);worst_position=max(worst_position,position);worst_jump=max(worst_jump,jump)
            joints[j]={'position':list(nm.translation),'rotation':list(nq),'driverPositionErrorMeters':position,'driverOrientationErrorDegrees':orientation,'frameRotationDegrees':jump}
        severity[frame]=max(worst_orientation,worst_jump)
        elapsed=(frame-first)/24.0
        intended=cp.NEUTRAL if entry.get('synthetic') else cp.pose(entry['move'],elapsed,float(manifest.get('tempoBPM',120)))
        intended_heading=0 if entry.get('synthetic') else cp.heading(entry['move'],elapsed,float(manifest.get('tempoBPM',120)))
        unturn=Quaternion((0,0,1),-intended_heading)
        root_delta=Quaternion(joints['Root']['rotation'])@rest_rotations['Root'].inverted()
        forward=root_delta@Vector((1,0,0));actual_heading=math.atan2(forward.y,forward.x)
        heading_error=abs(math.degrees(math.atan2(math.sin(actual_heading-intended_heading),math.cos(actual_heading-intended_heading))))
        if heading_error>5:pose_issues.append(f'{name}:{frame} authored heading differs >5 degrees')
        def angle(a,b,c):
            u,v=Vector(a)-Vector(b),Vector(c)-Vector(b)
            if u.length<1e-8 or v.length<1e-8:return None
            return math.degrees(u.angle(v))
        bends={};canonical_errors={}
        for side,display in [('Left','right'),('Right','left')]:
            for joint,chain,pose_chain in [('Elbow',('UpperArm','LowerArm','Hand'),('Shoulder','Elbow','Hand')),('Knee',('UpperLeg','LowerLeg','Foot'),(None,'Knee','Foot'))]:
                actual=angle(*(joints[side+x]['position'] for x in chain))
                canonical=angle(*(intended[display+x] if x else intended['hip'] for x in pose_chain))
                bends[side+joint]=actual
                canonical_errors[side+joint]=abs(actual-canonical) if actual is not None and canonical is not None else None
                if actual is None:issues.append(f'{name}:{frame} degenerate {side}{joint} chain')
        arm_errors={}
        for side,display in [("Left","right"),("Right","left")]:
            shoulder,hand=joints[side+"UpperArm"]["position"],joints[side+"Hand"]["position"]
            a,b=intended[display+"Shoulder"],intended[display+"Hand"]
            relative=unturn@(Vector(hand)-Vector(shoulder))
            error=direction_error((relative.x,relative.z),(b[0]-a[0],a[1]-b[1]))
            arm_errors[side]=error
            if error>35:pose_issues.append(f"{name}:{frame} {side} arm direction differs from authored pose >35 degrees")
        symmetry={}
        if all(abs(intended['left'+j][0]+intended['right'+j][0]-1)<1e-5 and abs(intended['left'+j][1]-intended['right'+j][1])<1e-5 for j in ('Shoulder','Elbow','Hand')):
            # Authored display directions map to fixed rig/world X-Z axes
            # (ND-012), not a leaning chest's local frame. Compare like frames.
            for joint in ('LowerArm','Hand'):
                l=unturn@(Vector(joints['Left'+joint]['position'])-Vector(joints['LeftUpperArm']['position']))
                r=unturn@(Vector(joints['Right'+joint]['position'])-Vector(joints['RightUpperArm']['position']))
                error=(l-Vector((-r.x,r.y,r.z))).length;symmetry[joint]=error
                if error>.03:pose_issues.append(f'{name}:{frame} authored symmetric {joint} differs >3 cm')
        hip_error=None
        if not entry.get('synthetic'):
            x,y=intended['hip'];nx,ny=cp.NEUTRAL['hip']
            expected=rest_hips+Vector(((x-nx)*torso_scale,0,-(y-ny)*torso_scale))
            hip_error=(Vector(joints['Hips']['position'])-expected).length
            if hip_error>.015:pose_issues.append(f'{name}:{frame} authored pelvis displacement differs >1.5 cm')
        wrist_errors={};foot_tilts={}
        for side in ('Left','Right'):
            forearm,hand=side+'LowerArm',side+'Hand'
            posed=Quaternion(joints[forearm]['rotation']).inverted()@Quaternion(joints[hand]['rotation'])
            rest=rest_rotations[forearm].inverted()@rest_rotations[hand]
            error=rotation_distance(tuple(posed),tuple(rest));wrist_errors[side]=error
            if error>25:pose_issues.append(f'{name}:{frame} {side} wrist differs from native alignment >25 degrees')
            foot=side+'Foot';delta=Quaternion(joints[foot]['rotation'])@rest_rotations[foot].inverted()
            up=delta@Vector((0,0,1));tilt=math.degrees(math.acos(max(-1,min(1,up.z))));foot_tilts[side]=tilt
            if tilt>50:pose_issues.append(f'{name}:{frame} {side} foot tilt >50 degrees')
        severity[frame]=max(severity[frame],*arm_errors.values())
        samples.append({'frame':frame,'joints':joints,'intendedDisplayPose':intended,'intendedHeadingRadians':intended_heading,'canonicalHeadingErrorDegrees':heading_error,'bendAnglesDegrees':bends,'canonicalAngleErrorDegrees':canonical_errors,'canonicalArmDirectionErrorDegrees':arm_errors,'symmetricArmErrorMeters':symmetry,'canonicalPelvisDisplacementErrorMeters':hip_error,'nativeWristErrorDegrees':wrist_errors,'footTiltDegrees':foot_tilts})
        if worst_orientation>5:issues.append(f'{name}:{frame} native/driver orientation >5 degrees')
        if worst_position>.03:issues.append(f'{name}:{frame} mapped joint attachment error >3 cm')
        if worst_jump>45:issues.append(f'{name}:{frame} rotation discontinuity >45 degrees/frame')
    clips.append({'clip':name,'frameRange':[first,last],'renderFrames':representative_frames(first,last,severity),'samples':samples})
report={'source':bpy.data.filepath,'sourceSHA256':hashlib.sha256(open(bpy.data.filepath,'rb').read()).hexdigest(),'blender':bpy.app.version_string,'retargetMapping':mapping,'anatomicalTransfer':'FAIL' if issues else 'PASS','canonicalPoseRegression':'FAIL' if pose_issues else 'PASS','poseIssues':pose_issues,'humanVisualGate':'UNKNOWN','restOrientationErrorDegrees':rest_errors,'issues':issues,'clips':clips,'limits':{'orientationDegrees':5,'attachmentMeters':.03,'continuityDegreesPerFrame':45,'canonicalArmDirectionDegrees':35,'symmetricArmMeters':.03,'canonicalPelvisDisplacementMeters':.015,'wristAlignmentDegrees':25,'footTiltDegrees':50},'limitations':'Transfer agreement is not human anatomy approval. Joint angles, wrist/foot plausibility and canonical pose interpretation require rendered review; structural deformation validator remains mandatory.'}
out=os.path.abspath(A['report']);os.makedirs(os.path.dirname(out),exist_ok=True)
with open(out,'w') as f:json.dump(report,f,indent=2)
if A.get('renders'):
    dest=os.path.abspath(A['renders']);os.makedirs(dest,exist_ok=True);sc=bpy.context.scene
    sc.render.engine='CYCLES';sc.cycles.device='CPU';sc.cycles.samples=16
    sc.render.resolution_x=480;sc.render.resolution_y=640;sc.render.resolution_percentage=100;sc.render.image_settings.file_format='PNG'
    def track(obj,target):obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()
    bpy.ops.object.camera_add(location=(0,-3.6,.9));camera=bpy.context.object;camera.data.type='ORTHO';camera.data.ortho_scale=2.1;sc.camera=camera;track(camera,(0,0,.85))
    for pos,energy in [((-2,-3,3),650),((2,-1,2),350)]:
        bpy.ops.object.light_add(type='AREA',location=pos);light=bpy.context.object;light.data.energy=energy;light.data.size=3;track(light,(0,0,.9))
    for clip in clips:
        driver.animation_data.action=bpy.data.actions[clip['clip']]
        for frame in clip['renderFrames']:
            sc.frame_set(frame)
            for view,location in [('front',(0,-3.6,.9)),('side',(-3.6,0,.9))]:
                camera.location=location;track(camera,(0,0,.85));sc.render.filepath=os.path.join(dest,f"{clip['clip']}_{frame:03}_{view}.png");bpy.ops.render.render(write_still=True)
print('MOTION_TRANSFER',report['anatomicalTransfer'],'CANONICAL_POSE',report['canonicalPoseRegression'],'CLIPS',len(clips),'HUMAN_VISUAL_GATE UNKNOWN')
sys.exit(bool(issues or pose_issues))
