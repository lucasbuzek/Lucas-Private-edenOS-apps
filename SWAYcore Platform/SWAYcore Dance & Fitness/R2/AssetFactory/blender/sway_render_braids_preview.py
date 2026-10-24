"""Render isolated, UNAPPROVED hair option for visual QA; never change source .blend."""
import bpy
import sys
from pathlib import Path
from mathutils import Vector

args = sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
if len(args) != 1:
    raise RuntimeError("Expected one output PNG path")
out = Path(args[0]).resolve()
if out.exists():
    raise RuntimeError("No-clobber: preview already exists")
selected = {"YD_Body_Balanced","YD_Face_Oval","YD_Eyes_0","YD_Brows_0",
            "YD_Nose_0","YD_Mouth_0","YD_Facial_Hair_0","YD_Hair_Braids",
            "YD_Top_Tank","YD_Bottom_Short","YD_Shoes_Trainers"}
for obj in bpy.data.objects:
    if obj.type == "MESH":
        visible = obj.name in selected
        obj.hide_render = not visible
        obj.hide_viewport = not visible
        obj.hide_set(not visible)
scene = bpy.context.scene
scene.frame_set(1)
for obj in list(bpy.data.objects):
    if obj.type in ("LIGHT","CAMERA"):
        bpy.data.objects.remove(obj,do_unlink=True)
scene.render.engine="CYCLES"
scene.cycles.samples=16
scene.render.resolution_x=450
scene.render.resolution_y=650
scene.render.resolution_percentage=100
scene.world.color=(0.18,0.18,0.18)
for loc,power,size in [((-2,-3,3),650,4),((2,-1,2),400,3),((0,3,3),500,3)]:
    light=bpy.data.lights.new("BraidsReviewLight","AREA")
    light.energy=power
    light.shape="DISK"
    light.size=size
    obj=bpy.data.objects.new("BraidsReviewLight",light)
    scene.collection.objects.link(obj)
    obj.location=loc
    obj.rotation_euler=(Vector((0,0,.9))-obj.location).to_track_quat("-Z","Y").to_euler()
camera=bpy.data.cameras.new("BraidsReviewCamera")
obj=bpy.data.objects.new("BraidsReviewCamera",camera)
scene.collection.objects.link(obj)
obj.location=(0,-4,.9)
obj.rotation_euler=(Vector((0,0,.85))-obj.location).to_track_quat("-Z","Y").to_euler()
camera.type="ORTHO"
camera.ortho_scale=2.0
scene.camera=obj
scene.render.image_settings.file_format="PNG"
scene.render.filepath=str(out)
bpy.ops.render.render(write_still=True)
print("SWAY_BRAIDS_PREVIEW",out,"UNAPPROVED")
