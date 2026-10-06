"""Pure-Python quaternion/retarget math (no bpy) so the asset factory's core maths is unit-testable off-Blender.
Quaternions are (w, x, y, z). Vectors are 3-tuples in the RIG frame: +X = character's left, +Y = backward (character faces -Y), +Z = up."""
import math

def qmul(a, b):
    aw, ax, ay, az = a; bw, bx, by, bz = b
    return (aw*bw - ax*bx - ay*by - az*bz, aw*bx + ax*bw + ay*bz - az*by, aw*by - ax*bz + ay*bw + az*bx, aw*bz + ax*by - ay*bx + az*bw)
def qinv(q): w, x, y, z = q; return (w, -x, -y, -z)
def qnorm(q):
    n = math.sqrt(sum(c*c for c in q)); return tuple(c/n for c in q) if n > 1e-12 else (1.0, 0.0, 0.0, 0.0)
def vsub(a, b): return (a[0]-b[0], a[1]-b[1], a[2]-b[2])
def vlen(a): return math.sqrt(a[0]*a[0]+a[1]*a[1]+a[2]*a[2])
def vnorm(a):
    l = vlen(a); return (a[0]/l, a[1]/l, a[2]/l) if l > 1e-12 else (0.0, 0.0, 0.0)
def vdot(a, b): return a[0]*b[0]+a[1]*b[1]+a[2]*b[2]
def vcross(a, b): return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])
def qrot(q, v):
    w, x, y, z = q; u = (x, y, z); s = w
    uv = vcross(u, v); uuv = vcross(u, uv)
    return tuple(v[i] + 2.0*(s*uv[i] + uuv[i]) for i in range(3))

def aim(rest_dir, target_dir):
    """Shortest-arc rotation taking rest_dir to target_dir (both normalised internally)."""
    a, b = vnorm(rest_dir), vnorm(target_dir)
    if vlen(a) == 0 or vlen(b) == 0: return (1.0, 0.0, 0.0, 0.0)
    d = vdot(a, b)
    if d > 0.999999: return (1.0, 0.0, 0.0, 0.0)
    if d < -0.999999:
        ax = vcross((1, 0, 0), a)
        if vlen(ax) < 1e-6: ax = vcross((0, 1, 0), a)
        ax = vnorm(ax); return (0.0, ax[0], ax[1], ax[2])
    c = vcross(a, b); return qnorm((1.0 + d, c[0], c[1], c[2]))

def solve_pose(joints, parent, child, rest_world_pos, rest_world_rot, target_pos):
    """World delta rotation per joint (aimed along primary child), then Blender-style local basis rotations.
    joints: ordered list; parent/child: dicts; rest_world_pos: joint->head position; rest_world_rot: joint->quat of bone rest orientation;
    target_pos: joint->desired world position (None entries inherit parent rotation).
    Returns (q_world_delta, basis) where basis[j] = R_j^-1 * q_parent^-1 * q_j * R_j  (derivation in Docs/ASSET_FACTORY.md)."""
    q = {}
    for j in joints:
        c = child.get(j)
        if c and c in target_pos and j in target_pos and c in rest_world_pos:
            q[j] = aim(vsub(rest_world_pos[c], rest_world_pos[j]), vsub(target_pos[c], target_pos[j]))
        else:
            q[j] = q[parent[j]] if parent.get(j) in q else (1.0, 0.0, 0.0, 0.0)
    basis = {}
    for j in joints:
        qp = q[parent[j]] if parent.get(j) in q else (1.0, 0.0, 0.0, 0.0)
        R = rest_world_rot[j]
        basis[j] = qnorm(qmul(qmul(qinv(R), qmul(qinv(qp), q[j])), R))
    return q, basis

def forward_world_dirs(joints, parent, child, rest_world_pos, rest_world_rot, basis):
    """Forward-kinematics check: world direction of every bone (joint->child) after applying local `basis` rotations."""
    W = {}
    for j in joints:
        p = parent.get(j)
        if p in W:
            Wp = W[p]; Rp = rest_world_rot[p]
            W[j] = qmul(Wp, qmul(qinv(Rp), qmul(rest_world_rot[j], basis[j])))
        else:
            W[j] = qmul(rest_world_rot[j], basis[j])
    out = {}
    for j in joints:
        c = child.get(j)
        if c and c in rest_world_pos:
            out[j] = vnorm(qrot(qmul(W[j], qinv(rest_world_rot[j])), vsub(rest_world_pos[c], rest_world_pos[j])))
    return out

# --- display(2D coach pose) -> rig frame --------------------------------------------------------
# Coach poses are in DISPLAY coordinates (x right, y DOWN, 0..1) and are drawn mirror-style (ND-012): the pose's "left*" joints
# appear on the viewer's left, i.e. they are driven by the character's RIGHT-side bones when the character faces the viewer.
POSE_TO_RIG = {
    "head": "Head", "neck": "Neck", "hip": "Hips",
    "leftShoulder": "RightUpperArm", "rightShoulder": "LeftUpperArm",
    "leftElbow": "RightLowerArm", "rightElbow": "LeftLowerArm",
    "leftHand": "RightHand", "rightHand": "LeftHand",
    "leftKnee": "RightLowerLeg", "rightKnee": "LeftLowerLeg",
    "leftFoot": "RightFoot", "rightFoot": "LeftFoot",
}
def display_to_rig(pt, origin_display, scale_m):
    """Display point -> rig-frame position relative to the hips. screen +x -> rig +X (character's left, facing viewer); screen up -> +Z."""
    return ((pt[0]-origin_display[0]) * scale_m, 0.0, -(pt[1]-origin_display[1]) * scale_m)

def rest_relative_endpoint(parent_target, rest_offset, neutral_direction, posed_direction):
    """Transfer authored direction onto native proportions without collapsing a segment."""
    offset = qrot(aim(neutral_direction, posed_direction), rest_offset)
    return tuple(parent_target[i] + offset[i] for i in range(3))
