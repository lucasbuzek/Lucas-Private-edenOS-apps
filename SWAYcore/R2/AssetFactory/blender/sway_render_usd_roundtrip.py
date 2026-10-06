"""Render reimported USD, independent of source scene objects/materials."""
import bpy
import json
import os
import sys
from pathlib import Path
from mathutils import Vector
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sway_common import args
A = args()
root = Path(A['root']).resolve()
dest = Path(A['out']).resolve()
dest.mkdir(parents=True, exist_ok=True)
manifest = json.loads((root / 'lucia.character.json').read_text())
receipts = []
for move in ('idle', 'knee', 'squat-pulse', 'jumping-jack', 'pivot-turn'):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    entry = manifest['animations'][move]
    path = root / 'Animations' / (entry['resource'] + '.usdc')
    bpy.ops.wm.usd_import(filepath=str(path))
    scene = bpy.context.scene
    divisor = 2 if entry['beatsPerCycle'] == 1 else 4
    scene.frame_set(1 + int(entry['beatsPerCycle'] * 12 / divisor))
    meshes = [o for o in scene.objects if o.type == 'MESH']
    rigs = [o for o in scene.objects if o.type == 'ARMATURE']
    assert len(meshes) == 5 and len(rigs) == 1, 'roundtrip lost mesh or rig'
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 16
    scene.render.resolution_x = 480
    scene.render.resolution_y = 640
    scene.render.resolution_percentage = 100
    scene.world = bpy.data.worlds.new('RoundtripWorld')
    scene.world.use_nodes = True
    scene.world.node_tree.nodes['Background'].inputs[0].default_value = (.12, .12, .12, 1)
    def aim(obj):
        obj.rotation_euler = (Vector((0, 0, .85)) - obj.location).to_track_quat('-Z', 'Y').to_euler()
    bpy.ops.object.camera_add(location=(0, -3.6, .9))
    camera = bpy.context.object
    camera.data.type = 'ORTHO'
    camera.data.ortho_scale = 2.1
    scene.camera = camera
    for position, energy in [((-2, -3, 3), 500), ((2, -1, 2), 250)]:
        bpy.ops.object.light_add(type='AREA', location=position)
        light = bpy.context.object
        light.data.energy = energy
        light.data.size = 3
        aim(light)
    for view, position in [('front', (0, -3.6, .9)), ('side', (3.6, 0, .9))]:
        camera.location = position
        aim(camera)
        scene.render.filepath = str(dest / (move + '_' + view + '.png'))
        bpy.ops.render.render(write_still=True)
    receipts.append({'move': move, 'meshes': len(meshes), 'rigs': len(rigs), 'frame': scene.frame_current})
(dest / 'receipt.json').write_text(json.dumps({'roundtripImport': 'PASS', 'renders': receipts,
    'humanVisualGate': 'UNKNOWN', 'realityKitPlayback': 'UNKNOWN'}, indent=2) + '\n')
print('[usd-roundtrip] five actual exported motions imported and rendered; human and RealityKit UNKNOWN')
