"""Inspect actual binary USD candidates using Blender's bundled OpenUSD.

This is an export gate, never a RealityKit or human visual approval.
"""
import json
import math
import os
import sys
from pathlib import Path
from pxr import Sdf, Usd, UsdGeom, UsdSkel

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sway_common import args

A = args()
root = Path(A['root']).resolve()
manifest = json.loads((root / 'lucia.character.json').read_text())
required = set(manifest['retargetSourceMapping'])
issues = []
receipts = []
reference_joints = None
paths = [(root / (manifest['assetBaseName'] + '.usdc'), None)]
paths += [(root / 'Animations' / (entry['resource'] + '.usdc'), entry)
          for entry in manifest['animations'].values()]
for path, entry in paths:
    stage = Usd.Stage.Open(str(path))
    if not stage:
        issues.append(str(path) + ': cannot open')
        continue
    skeletons = [UsdSkel.Skeleton(p) for p in stage.Traverse() if p.IsA(UsdSkel.Skeleton)]
    meshes = [UsdGeom.Mesh(p) for p in stage.Traverse() if p.IsA(UsdGeom.Mesh)]
    for prim in stage.Traverse():
        for attribute in prim.GetAttributes():
            value = attribute.Get()
            if isinstance(value, Sdf.AssetPath) and value.path:
                resolved = value.resolvedPath or str(path.parent / value.path)
                if not Path(resolved).is_file():
                    issues.append(str(path.relative_to(root)) + ': missing referenced asset ' + value.path)
    row = {'file': str(path.relative_to(root)), 'skeletons': len(skeletons), 'meshes': len(meshes)}
    if len(skeletons) != 1:
        issues.append(row['file'] + ': expected one skinning skeleton')
        receipts.append(row)
        continue
    joints = list(skeletons[0].GetJointsAttr().Get())
    leaves = {str(j).split('/')[-1] for j in joints}
    if not required <= leaves:
        issues.append(row['file'] + ': missing canonical joints ' + str(sorted(required - leaves)))
    if reference_joints is None:
        reference_joints = joints
    elif joints != reference_joints:
        issues.append(row['file'] + ': skeleton differs from base')
    row['joints'] = len(joints)
    skin_rows = []
    for mesh in meshes:
        binding = UsdSkel.BindingAPI(mesh.GetPrim())
        inherited = binding.GetInheritedSkeleton()
        if not inherited or inherited.GetPath() != skeletons[0].GetPath():
            issues.append(row['file'] + ': mesh not bound to exported native skeleton ' + str(mesh.GetPath()))
        index_pv = binding.GetJointIndicesPrimvar()
        weight_pv = binding.GetJointWeightsPrimvar()
        indices = list(index_pv.ComputeFlattened() or [])
        weights = list(weight_pv.ComputeFlattened() or [])
        size = weight_pv.GetElementSize()
        used = set()
        if not weights or len(weights) != len(indices) or size < 1 or size > 4:
            issues.append(row['file'] + ': invalid skin arrays ' + str(mesh.GetPath()))
        else:
            for offset in range(0, len(weights), size):
                w = weights[offset:offset + size]
                if any(not math.isfinite(v) or v < 0 for v in w) or abs(sum(w) - 1) > 1e-4:
                    issues.append(row['file'] + ': non-normalized skin ' + str(mesh.GetPath()))
                    break
                for index, weight in zip(indices[offset:offset + size], w):
                    if weight > 0:
                        used.add(index)
                        if index < 0 or index >= len(joints):
                            issues.append(row['file'] + ': joint index outside skeleton')
        skin_rows.append({'mesh': str(mesh.GetPath()), 'vertices': len(mesh.GetPointsAttr().Get() or []),
                          'influences': size, 'weightedJoints': len(used)})
    if len(meshes) != 5:
        issues.append(row['file'] + ': expected body, head, hair and two eyes')
    if skin_rows and max(skin_rows, key=lambda r: r['vertices'])['weightedJoints'] < 18:
        issues.append(row['file'] + ': largest body has fewer than 18 weighted joints')
    row['skin'] = skin_rows
    if entry:
        duration = (stage.GetEndTimeCode() - stage.GetStartTimeCode()) / stage.GetTimeCodesPerSecond()
        expected = entry['beatsPerCycle'] * 60 / manifest['authoredBPM']
        row['durationSeconds'] = duration
        if abs(duration - expected) > 1e-6:
            issues.append(row['file'] + ': musical cycle duration mismatch')
        animations = [UsdSkel.Animation(p) for p in stage.Traverse() if p.IsA(UsdSkel.Animation)]
        samples = max((len(a.GetRotationsAttr().GetTimeSamples()) for a in animations), default=0)
        row['rotationSamples'] = samples
        if samples < 2:
            issues.append(row['file'] + ': missing sampled motion')
    receipts.append(row)
report = {'status': 'FAIL' if issues else 'PASS', 'issues': issues, 'files': receipts,
          'realityKitPlayback': 'UNKNOWN', 'humanVisualGate': 'UNKNOWN',
          'runtimeApproved': manifest['runtimeApproved'], 'visualQuality': manifest['visualQuality']}
Path(A['report']).write_text(json.dumps(report, indent=2) + '\n')
print('[runtime-usd] ' + report['status'] + ': ' + str(len(receipts)) + ' actual binary stages; ' + str(len(issues)) + ' issues')
for issue in issues:
    print('[runtime-usd] ' + issue)
if issues:
    raise SystemExit(1)
