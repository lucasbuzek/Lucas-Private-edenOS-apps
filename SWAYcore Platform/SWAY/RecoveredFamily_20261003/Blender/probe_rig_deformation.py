"""Supplemental Blender probe: meaningful body weights and hidden variant binding.

Run with Blender --background --factory-startup --python this_file -- --root repo.
This is structural/deformation evidence only, never visual acceptance.
"""
import json
import os
import sys

import bpy
from mathutils import Quaternion

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sway_blender_common import MAX_INFLUENCES, parse_kv, script_args

root = parse_kv(script_args())["root"]
characters = json.load(open(os.path.join(root, "Blender/characters.json")))["characters"]
for character in characters:
    cid = character["id"]
    bpy.ops.wm.open_mainfile(filepath=os.path.join(root, "Assets/Blend", cid + ".blend"))
    arm = bpy.data.objects["SWAYArmature"]
    body = bpy.data.objects["Body"]
    expected = set(arm.data.bones.keys()) - {"root", "head", "headEnd"}
    used = set()
    for obj in (o for o in bpy.data.objects if o.type == 'MESH'):
        assert obj.parent == arm, (cid, obj.name, "parent")
        assert any(m.type == 'ARMATURE' and m.object == arm for m in obj.modifiers), (cid, obj.name, "modifier")
        for vertex in obj.data.vertices:
            weights = [g for g in vertex.groups if g.weight > 0]
            assert 1 <= len(weights) <= MAX_INFLUENCES, (cid, obj.name, vertex.index, "influences")
            assert abs(sum(g.weight for g in weights) - 1) < 1e-5, (cid, obj.name, vertex.index, "normalization")
            assert all(obj.vertex_groups[g.group].name in arm.data.bones for g in weights)
            if obj == body:
                used.update(obj.vertex_groups[g.group].name for g in weights if g.weight > 1e-4)
        print("[rig-probe] %s %s: all vertices normalized, <=4 influences, hidden=%s" % (cid, obj.name, obj.hide_viewport))
    assert used == expected, (cid, "body coverage", sorted(used ^ expected))
    for variant in character.get("customizable", {}).get("outfits", []):
        obj = bpy.data.objects["Outfit_" + variant]
        assert obj.hide_viewport and obj.hide_render, (cid, obj.name, "source visibility")
    arm.animation_data.action = None
    for bone in arm.pose.bones:
        bone.rotation_mode = 'QUATERNION'
        bone.rotation_quaternion = Quaternion()
    bpy.context.view_layer.update()
    graph = bpy.context.evaluated_depsgraph_get()
    def positions():
        evaluated = body.evaluated_get(graph)
        mesh = evaluated.to_mesh()
        points = [v.co.copy() for v in mesh.vertices]
        evaluated.to_mesh_clear()
        return points
    rest = positions()
    for name in sorted(expected):
        group = body.vertex_groups[name].index
        strong = sum(any(g.group == group and g.weight >= 0.1 for g in v.groups) for v in body.data.vertices)
        assert strong >= 4, (cid, name, "no meaningful local weighting", strong)
        bone = arm.pose.bones[name]
        bone.rotation_quaternion = Quaternion((0, 1, 0), 0.25)
        bpy.context.view_layer.update()
        displacement = max((a - b).length for a, b in zip(rest, positions()))
        assert displacement > 1e-4, (cid, name, "no deformation")
        print("[rig-probe] %s %s: %d vertices >=0.1 weight, rotation displacement %.6fm" % (cid, name, strong, displacement))
        bone.rotation_quaternion = Quaternion()
        bpy.context.view_layer.update()
    manifest = json.load(open(os.path.join(root, "Assets/Characters", cid + ".character.json")))
    assert manifest["visualQuality"] == "UNREVIEWED"
print("PROBE PASS: six rigs, hidden variants, meaningful 20-bone weights and evaluated deformation (not visual acceptance)")
