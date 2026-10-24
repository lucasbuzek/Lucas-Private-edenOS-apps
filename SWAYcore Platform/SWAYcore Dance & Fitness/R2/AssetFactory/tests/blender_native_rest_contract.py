"""Behavioral Blender gate: run AFTER native driver creation, BEFORE baking.
The old head/tail-only driver loses native bone roll. This test must be executed by Blender;
ordinary Python suite discovery intentionally does not count it as executed.
"""
import bpy,json,math
from pathlib import Path
m=json.loads(Path('AssetFactory/data/retarget_map_girush.json').read_text())['map']
d=bpy.data.objects['SWAYArmature'];n=next(o for o in bpy.data.objects if o.type=='ARMATURE' and o!=d and o.get('sway_native_skinning'))
for joint,names in m.items():
 a=d.data.bones[joint];b=n.data.bones[names[0]]
 assert ((d.matrix_world @ a.head_local)-(n.matrix_world @ b.head_local)).length<1e-6,joint+' head'
 assert ((d.matrix_world @ a.tail_local)-(n.matrix_world @ b.tail_local)).length<1e-6,joint+' tail'
 error=a.matrix_local.to_quaternion().rotation_difference(b.matrix_local.to_quaternion()).angle
 assert math.degrees(error)<.001,(joint,'native roll lost',math.degrees(error))
for side,suffix in [('Left','L'),('Right','R')]:
 knee=n.data.bones[m[side+'LowerLeg'][0]]
 thigh=n.data.bones[m[side+'UpperLeg'][0]]
 assert (n.matrix_world @ knee.head_local-n.matrix_world @ thigh.tail_local).length<1e-6,'knee maps below anatomical joint'
 helper=n.pose.bones['Tibia.'+suffix+'.001']
 for c in helper.constraints:
  if c.type=='COPY_ROTATION' and c.target==n and c.subtarget==helper.parent.name and c.owner_space=='LOCAL' and c.target_space=='LOCAL':
   assert c.mute,'legacy calf constraint doubles parent rotation'
print('NATIVE_REST_CONTRACT PASS: full mapped matrices and endpoints agree')
