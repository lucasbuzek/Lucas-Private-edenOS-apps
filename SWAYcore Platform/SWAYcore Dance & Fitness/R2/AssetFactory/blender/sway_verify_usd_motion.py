"""Compare every exported joint sample with the actual native Blender pose."""
import bpy
import json
import os
import sys
from pathlib import Path
from mathutils import Vector
from pxr import Usd, UsdGeom, UsdSkel
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sway_common import args, find_sway_armature
A = args()
root = Path(A['root']).resolve()
# Each isolated runtime export contains exactly one character manifest.
# Hard-coding Lucia would silently preclude validation of the user's dancer.
manifests = sorted(root.glob('*.character.json'))
if len(manifests) != 1:
    raise RuntimeError(f'expected exactly one character manifest in {root}, found {len(manifests)}')
manifest = json.loads(manifests[0].read_text())
driver = find_sway_armature()
native = next(o for o in bpy.data.objects if o.type == 'ARMATURE' and o.get('sway_native_skinning'))
driver.animation_data_create()
rows = []
for entry in manifest['animations'].values():
    clip = entry['resource']
    driver.animation_data.action = bpy.data.actions[clip]
    stage = Usd.Stage.Open(str(root / 'Animations' / (clip + '.usdc')))
    skeleton = next(UsdSkel.Skeleton(p) for p in stage.Traverse() if p.IsA(UsdSkel.Skeleton))
    cache = UsdSkel.Cache()
    for prim in stage.Traverse():
        if prim.IsA(UsdSkel.Root):
            cache.Populate(UsdSkel.Root(prim), Usd.PrimDefaultPredicate)
    query = cache.GetSkelQuery(skeleton)
    indices = {str(j).split('/')[-1]: i for i, j in enumerate(query.GetJointOrder())}
    worst = 0.0
    for frame in range(int(stage.GetStartTimeCode()), int(stage.GetEndTimeCode()) + 1):
        bpy.context.scene.frame_set(frame)
        transforms = query.ComputeJointWorldTransforms(UsdGeom.XformCache(Usd.TimeCode(frame)))
        for joint, bone in manifest['retargetSourceMapping'].items():
            point = native.matrix_world @ native.pose.bones[bone].head
            # Blender's explicit Y-up / -Z-forward export basis.
            expected = Vector((point.x, point.z, -point.y))
            actual = Vector(transforms[indices[joint]].ExtractTranslation())
            worst = max(worst, (expected - actual).length)
    rows.append({'clip': clip, 'maxJointPositionErrorMeters': worst})
driver.animation_data.action = None
report = {'status': 'PASS' if all(r['maxJointPositionErrorMeters'] <= 0.001 for r in rows) else 'FAIL',
          'toleranceMeters': 0.001, 'clips': rows, 'realityKitPlayback': 'UNKNOWN'}
Path(A['report']).write_text(json.dumps(report, indent=2) + '\n')
print('[usd-motion] ' + report['status'] + ': all ' + str(len(rows)) + ' clips; worst meters ' + str(max(r['maxJointPositionErrorMeters'] for r in rows)))
if report['status'] != 'PASS':
    raise SystemExit(1)
