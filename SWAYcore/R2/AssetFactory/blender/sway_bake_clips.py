"""Bake the coach clips onto a SWAYHumanoid-v1 character .blend from the SAME movement truth the app uses.

blender --background --factory-startup <character.blend> --python AssetFactory/blender/sway_bake_clips.py -- \
   --clips AssetFactory/data/clip_manifest.json --out-blend Assets/Blend/lucia.blend

Source of motion: coach_pose_port (pinned to SwayCoachPoseEngine by sha256). Display poses are mirrored (ND-012) and converted
to rig-frame joint targets; per-bone rotations come from retarget_math.solve_pose (unit-tested incl. forward-kinematics round trip)."""
import bpy, os, sys, math
from mathutils import Vector, Quaternion
sys.path.insert(0, os.path.abspath("AssetFactory/blender"))
from sway_common import *
import coach_pose_port as cp, retarget_math as rm

A = args()
root = os.path.abspath(os.path.join(HERE, "..", ".."))
cp.assert_in_sync(os.path.join(root, "App", "SWAY", "Views", "StickFigureView.swift"))
manifest = load(A["clips"]); BPM = float(manifest.get("tempoBPM", 120)); FPB = 12           # 12 frames per beat @ 120 BPM = 24 fps
JOINTS = load(os.path.join(root, "App", "AssetPipeline", "contracts", "SWAYHumanoid-v1.json"))["joints"]
arm = find_sway_armature(JOINTS) or fail("SWAY contract armature not found")
if sorted(b.name for b in arm.data.bones) != sorted(JOINTS): fail("armature bones != SWAYHumanoid-v1")
PARENT = {b.name: (b.parent.name if b.parent else None) for b in arm.data.bones}
CHILD = {}
for j in JOINTS:
    kids = [b.name for b in arm.data.bones if b.parent and b.parent.name == j]
    pref = {"Hips": "Spine", "Chest": "Neck", "Root": "Hips"}.get(j)
    CHILD[j] = pref if pref in kids else (kids[0] if kids else None)
# Root is the stationary animation origin, not a segment aimed at the translated
# pelvis. A squat/step crossing the rest pelvis height must not rotate the root.
CHILD['Root'] = None
mw = arm.matrix_world
REST_POS = {j: tuple(mw @ arm.data.bones[j].head_local) for j in JOINTS}
REST_ROT = {j: tuple((mw.to_3x3() @ arm.data.bones[j].matrix_local.to_3x3()).to_quaternion()) for j in JOINTS}

hips0 = REST_POS["Hips"]; neck0 = REST_POS["Neck"]
rig_torso = neck0[2] - hips0[2]; DISPLAY_TORSO = cp.NEUTRAL["hip"][1] - cp.NEUTRAL["neck"][1]; SCALE = rig_torso / DISPLAY_TORSO
ORIGIN = cp.NEUTRAL["hip"]

def targets_for(pose):
    """Rest-calibrated rig targets: NEUTRAL is exact rig rest; coach pose contributes displacement only."""
    T={j:REST_POS[j] for j in JOINTS}
    neutral=cp.NEUTRAL
    for pj,rj in rm.POSE_TO_RIG.items():
        d=rm.display_to_rig(pose[pj],neutral[pj],SCALE)
        T[rj]=tuple(REST_POS[rj][i]+d[i] for i in range(3))
    # Carry the whole torso with the authored pelvis, preserving native segment
    # proportions. Leaving spine targets at rest collapses motion into the pelvis.
    torso=rm.aim(rm.display_to_rig(neutral['neck'],neutral['hip'],1),
                 rm.display_to_rig(pose['neck'],pose['hip'],1))
    for j in ('Spine','Spine1','Chest','Neck','LeftShoulder','RightShoulder','LeftUpperArm','RightUpperArm','LeftUpperLeg','RightUpperLeg'):
        offset=rm.qrot(torso,rm.vsub(REST_POS[j],REST_POS['Hips']))
        T[j]=tuple(T['Hips'][i]+offset[i] for i in range(3))
    # The graphical coach has a long head/neck segment; the native rig's neck
    # is much shorter. Absolute display displacement can invert that segment.
    # Transfer its authored direction at the actual native length instead.
    T['Head']=rm.rest_relative_endpoint(T['Neck'],rm.vsub(REST_POS['Head'],REST_POS['Neck']),
        rm.display_to_rig(neutral['head'],neutral['neck'],1),
        rm.display_to_rig(pose['head'],pose['neck'],1))
    # Preserve actual rig segment lengths while following authored 2D direction changes.
    for side in ("Left","Right"):
        for a,b in [(side+"UpperLeg",side+"LowerLeg"),(side+"LowerLeg",side+"Foot"),(side+"UpperArm",side+"LowerArm"),(side+"LowerArm",side+"Hand")]:
            raw=Vector(T[b])-Vector(T[a]); L=(Vector(REST_POS[b])-Vector(REST_POS[a])).length
            if raw.length>1e-6:T[b]=tuple(Vector(T[a])+raw.normalized()*L)
        T[side+"Toe"]=tuple(Vector(T[side+"Foot"])+(Vector(REST_POS[side+"Toe"])-Vector(REST_POS[side+"Foot"])))
    return T

def synthetic_idle(t_beats):
    p = {k: list(v) for k, v in cp.NEUTRAL.items()}; b = math.sin(t_beats * math.pi * 0.5)   # 4-beat breathing sway
    p["hip"][0] += 0.012 * b; p["neck"][0] -= 0.008 * b; p["leftHand"][1] -= 0.006 * (1 - b); p["rightHand"][1] -= 0.006 * (1 - b)
    return {k: tuple(v) for k, v in p.items()}

for pb in arm.pose.bones: pb.rotation_mode = "QUATERNION"
arm.animation_data_create()
RL = {j: Quaternion(REST_ROT[j]) for j in JOINTS}
for entry in manifest["clips"]:
    name, cycle = entry["clip"], int(entry["beatsPerCycle"])
    act = bpy.data.actions.get(name) or bpy.data.actions.new(name)
    for fc in action_fcurves(act): act.fcurves.remove(fc) if hasattr(act, "fcurves") else None
    arm.animation_data.action = act
    for pb in arm.pose.bones: pb.location = (0, 0, 0); pb.rotation_quaternion = (1, 0, 0, 0)
    spb = 60.0 / BPM; n = cycle * FPB
    for i in range(n + 1):
        tb = i / FPB
        pose = synthetic_idle(tb) if entry.get("synthetic") else cp.pose(entry["move"], tb * spb, BPM)
        q, basis = rm.solve_pose(JOINTS, PARENT, CHILD, REST_POS, REST_ROT, targets_for(pose))
        frame = 1 + i
        for j in JOINTS:
            pb = arm.pose.bones[j]; pb.rotation_quaternion = Quaternion(basis[j]); pb.keyframe_insert("rotation_quaternion", frame=frame)
        delta = Vector(targets_for(pose)["Hips"]) - Vector(hips0)               # hips translation (squat / jump height)
        # Source rigs may be centimetre-scaled through their parent. Convert the
        # world displacement before writing bone-local channels. Root translation
        # moves the native spine and pelvis sibling branches together.
        pb = arm.pose.bones['Root']
        pb.location = arm.data.bones['Root'].matrix_local.to_3x3().inverted() @ (mw.to_3x3().inverted() @ delta)
        pb.keyframe_insert('location', frame=frame)
        arm.pose.bones['Hips'].location=(0,0,0)
        arm.pose.bones['Hips'].keyframe_insert('location',frame=frame)
    for fc in action_fcurves(act):
        for kp in fc.keyframe_points: kp.interpolation = "LINEAR"
    act.use_fake_user = True; act["sway_beats_per_cycle"] = cycle; act["sway_move"] = entry["move"]; act["sway_tempo_bpm"] = BPM
arm.animation_data.action = None
for pb in arm.pose.bones: pb.location = (0, 0, 0); pb.rotation_quaternion = (1, 0, 0, 0)
arm["sway_clip_count"] = len(manifest["clips"]); arm["sway_motion_source"] = "SwayCoachPoseEngine@" + cp.PINNED_SOURCE_SHA256[:12]
bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(A["out-blend"]))
print("[sway-factory] baked %d clips" % len(manifest["clips"]))
