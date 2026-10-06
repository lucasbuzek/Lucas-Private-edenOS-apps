"""Python port of SwayCoachPoseEngine.pose (App/SWAY/Views/StickFigureView.swift, as received in Build 153 candidate).
PURPOSE: the 3D COACH clips must come from the SAME movement truth as Learn/Workout/matching. Swift remains the authority;
this port lets the asset factory sample that truth without a Swift toolchain. DRIFT GUARD: PINNED_SOURCE_SHA256 must equal the
sha256 of the Swift file, otherwise `assert_in_sync` fails and clip baking refuses to run until the port is re-verified."""
import math, hashlib, os

PINNED_SOURCE_SHA256 = "d1ae4f6a38a7657f7410bd65dcb8542e437f35cab3ecc2ee05c2cc689f3c0d72"
AUTHORED = ["march","step-touch","double-step","side-tap","hip-sway","heel-dig","knee","grapevine","arm-reach","v-step","box-step",
            "mambo","cha-cha","squat-pulse","side-lunge","cross-step","body-roll","jumping-jack","skater","pivot-turn"]
JOINTS = ["head","neck","leftShoulder","rightShoulder","leftElbow","rightElbow","leftHand","rightHand","hip","leftKnee","rightKnee","leftFoot","rightFoot"]
NEUTRAL = {"head":(0.5,0.12),"neck":(0.5,0.24),"leftShoulder":(0.40,0.28),"rightShoulder":(0.60,0.28),"leftElbow":(0.35,0.43),"rightElbow":(0.65,0.43),
           "leftHand":(0.33,0.58),"rightHand":(0.67,0.58),"hip":(0.5,0.56),"leftKnee":(0.44,0.73),"rightKnee":(0.56,0.73),"leftFoot":(0.42,0.91),"rightFoot":(0.58,0.91)}

def assert_in_sync(swift_path):
    with open(swift_path, "rb") as fh: h = hashlib.sha256(fh.read()).hexdigest()
    if h != PINNED_SOURCE_SHA256:
        raise RuntimeError("coach_pose_port is OUT OF SYNC with %s (sha256 %s != pinned %s). Re-verify the port, then update PINNED_SOURCE_SHA256." % (swift_path, h, PINNED_SOURCE_SHA256))

def pose(move_id, t, bpm):
    spb = 60.0 / max(20.0, bpm)
    bp = max(0.0, t) / spb
    bi = int(math.floor(bp)); f = bp - math.floor(bp)
    pulse = (1.0 - math.cos(f * math.pi * 2.0)) * 0.5
    side = math.sin((bp / 2.0) * math.pi * 2.0)
    smooth = lambda x: x*x*(3.0-2.0*x)
    p = {k: list(v) for k, v in NEUTRAL.items()}
    X, Y = 0, 1
    if move_id == "march":
        if bi % 2 == 0:
            p["leftKnee"][Y] -= 0.16*pulse; p["leftFoot"][Y] -= 0.20*pulse; p["rightElbow"][X] -= 0.055*pulse; p["leftElbow"][X] += 0.04*pulse
        else:
            p["rightKnee"][Y] -= 0.16*pulse; p["rightFoot"][Y] -= 0.20*pulse; p["leftElbow"][X] += 0.055*pulse; p["rightElbow"][X] -= 0.04*pulse
        p["hip"][Y] -= 0.012*pulse
    elif move_id == "step-touch":
        dx = 0.085*side; p["hip"][X] += dx*0.45; p["neck"][X] += dx*0.30
        p["leftFoot"][X] -= max(0,-dx); p["rightFoot"][X] += max(0,dx)
        p["leftHand"][X] -= 0.07*side; p["rightHand"][X] -= 0.07*side
    elif move_id == "double-step":
        pair = bi % 4; d = -1.0 if pair < 2 else 1.0
        travel = d * (0.045 + 0.045*pulse); p["hip"][X] += travel; p["neck"][X] += travel*0.7
        if pair % 2 == 0: p["leftFoot"][X] += travel*1.6
        else: p["rightFoot"][X] += travel*1.6
        p["leftHand"][Y] -= 0.08*pulse; p["rightHand"][Y] -= 0.08*pulse
    elif move_id == "side-tap":
        d = -1.0 if bi % 2 == 0 else 1.0
        if d < 0: p["leftFoot"][X] -= 0.14*pulse
        else: p["rightFoot"][X] += 0.14*pulse
        p["hip"][X] += d*0.025*pulse; p["leftHand"][X] -= d*0.04*pulse; p["rightHand"][X] -= d*0.04*pulse
    elif move_id == "hip-sway":
        p["hip"][X] += 0.095*side; p["neck"][X] -= 0.03*side; p["leftHand"][Y] = 0.49; p["rightHand"][Y] = 0.49
    elif move_id == "heel-dig":
        r = 0.11*pulse
        if bi % 2 == 0: p["leftFoot"][X] -= r; p["leftFoot"][Y] -= 0.025*pulse
        else: p["rightFoot"][X] += r; p["rightFoot"][Y] -= 0.025*pulse
    elif move_id == "knee":
        if bi % 2 == 0: p["leftKnee"][Y] -= 0.18*pulse; p["leftFoot"][Y] -= 0.22*pulse
        else: p["rightKnee"][Y] -= 0.18*pulse; p["rightFoot"][Y] -= 0.22*pulse
    elif move_id == "grapevine":
        targets = [(-0.08,0.40,0.58),(-0.04,0.54,0.46),(0.08,0.42,0.60),(0.04,0.54,0.46)]
        i = bi % 4; n = (i+1) % 4; tt = smooth(f); a = targets[i]; b = targets[n]
        lerp = lambda x, y: x + (y-x)*tt
        travel = lerp(a[0], b[0]); p["hip"][X] += travel; p["neck"][X] += travel*0.72
        p["leftFoot"][X] = lerp(a[1], b[1]); p["rightFoot"][X] = lerp(a[2], b[2])
    elif move_id == "arm-reach":
        p["leftHand"] = [0.33-0.11*pulse, 0.58-0.34*pulse]; p["rightHand"] = [0.67+0.11*pulse, 0.58-0.34*pulse]
        p["leftElbow"] = [0.35-0.01*pulse, 0.43-0.09*pulse]; p["rightElbow"] = [0.65+0.01*pulse, 0.43-0.09*pulse]
    elif move_id == "v-step":
        targets = [(0.34,0.58),(0.34,0.66),(0.42,0.66),(0.42,0.58)]
        i = bi % 4; n = (i+1) % 4; tt = smooth(f); a = targets[i]; b = targets[n]
        p["leftFoot"][X] = a[0]+(b[0]-a[0])*tt; p["rightFoot"][X] = a[1]+(b[1]-a[1])*tt; p["hip"][X] += 0.018*side
    elif move_id == "box-step":
        q = bi % 4; targets = [(0.42,0.58),(0.42,0.64),(0.36,0.64),(0.36,0.58)]
        a = targets[q]; b = targets[(q+1) % 4]; tt = smooth(f)
        p["leftFoot"][X] = a[0]+(b[0]-a[0])*tt; p["rightFoot"][X] = a[1]+(b[1]-a[1])*tt; p["hip"][Y] -= 0.02*pulse
    elif move_id == "mambo":
        fwd = bi % 4 < 2; r = 0.10*pulse; p["hip"][Y] += (-0.015 if fwd else 0.015)*pulse
        if fwd: p["leftFoot"][Y] -= r
        else: p["rightFoot"][Y] += r*0.45
        p["leftHand"][X] += 0.05*side; p["rightHand"][X] += 0.05*side
    elif move_id == "cha-cha":
        q = bi % 4; shift = [-0.05,0.0,0.05,0.0][q]; p["hip"][X] += shift+0.025*side
        p["leftFoot"][X] += shift*1.4; p["rightFoot"][X] += shift*1.4; p["leftElbow"][Y] -= 0.04*pulse; p["rightElbow"][Y] -= 0.04*pulse
    elif move_id == "squat-pulse":
        drop = 0.10*pulse; p["hip"][Y] += drop; p["neck"][Y] += drop*0.55; p["leftKnee"][X] -= 0.055*pulse; p["rightKnee"][X] += 0.055*pulse
        p["leftHand"][Y] = 0.50; p["rightHand"][Y] = 0.50
    elif move_id == "side-lunge":
        d = 1.0 if side >= 0 else -1.0; amt = 0.11*abs(side); p["hip"][X] += d*amt*0.45
        if d > 0: p["rightFoot"][X] += amt; p["rightKnee"][X] += amt*0.45
        else: p["leftFoot"][X] -= amt; p["leftKnee"][X] -= amt*0.45
    elif move_id == "cross-step":
        c = 0.10*side; p["hip"][X] += c*0.35; p["leftFoot"][X] += max(0,c); p["rightFoot"][X] += min(0,c)
        p["leftHand"][Y] -= 0.10*pulse; p["rightHand"][Y] -= 0.10*pulse
    elif move_id == "body-roll":
        wave = math.sin(bp * math.pi); p["hip"][X] += 0.025*wave; p["neck"][X] -= 0.035*wave; p["hip"][Y] += 0.025*pulse
        p["leftHand"][Y] = 0.50; p["rightHand"][Y] = 0.50
    elif move_id == "jumping-jack":
        o = pulse; p["leftFoot"][X] -= 0.12*o; p["rightFoot"][X] += 0.12*o
        p["leftHand"] = [0.31-0.08*o, 0.58-0.43*o]; p["rightHand"] = [0.69+0.08*o, 0.58-0.43*o]
    elif move_id == "skater":
        d = -1.0 if bi % 2 == 0 else 1.0; amt = 0.10*pulse; p["hip"][X] += d*amt; p["neck"][X] += d*amt*0.65
        if d < 0: p["rightFoot"][X] = 0.48; p["rightFoot"][Y] -= 0.04*pulse
        else: p["leftFoot"][X] = 0.52; p["leftFoot"][Y] -= 0.04*pulse
    elif move_id == "pivot-turn":
        turn = math.sin(bp * math.pi/2); p["leftShoulder"][X] += 0.055*turn; p["rightShoulder"][X] -= 0.055*turn
        p["leftFoot"][X] += 0.045*side; p["rightFoot"][X] += 0.045*side; p["hip"][X] += 0.02*side
    return {k: tuple(v) for k, v in p.items()}

def sample_cycle(move_id, bpm=120.0, beats=8, fps_per_beat=8):
    """Samples a full cycle (beats) at fps_per_beat steps per beat, plus the wrap frame. Deterministic."""
    spb = 60.0 / bpm
    return [(i / fps_per_beat, pose(move_id, i / fps_per_beat * spb, bpm)) for i in range(beats * fps_per_beat + 1)]

def heading(move_id, t, bpm):
    """Port of SwayCoachPose.bodyYaw; radians on the same absolute musical clock."""
    if move_id != 'pivot-turn':
        return 0.0
    beat_position = max(0.0, t) / (60.0 / max(20.0, bpm))
    return math.sin(beat_position * math.pi / 2) * math.pi / 3
