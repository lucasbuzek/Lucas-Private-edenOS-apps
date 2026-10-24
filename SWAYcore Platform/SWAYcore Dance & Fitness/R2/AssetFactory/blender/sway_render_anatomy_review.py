import bpy,sys,os,math
from mathutils import Vector
out=sys.argv[sys.argv.index('--')+1]
selected={'YD_Body_Balanced','YD_Face_Oval','YD_Eyes_0','YD_Brows_0','YD_Nose_0','YD_Mouth_0','YD_Facial_Hair_0','YD_Hair_Short','YD_Top_Tee','YD_Bottom_Legging','YD_Shoes_Trainers'}
for o in bpy.data.objects:
 if o.type=='MESH':
  show=o.name in selected;o.hide_render=not show;o.hide_viewport=not show
  o.hide_set(not show)
scene=bpy.context.scene
arm=bpy.data.objects['SWAYArmature']
arm.animation_data_create()
print('ACTIONS',[a.name for a in bpy.data.actions],flush=True)
action=next((a for a in bpy.data.actions if 'step' in a.name.lower()),None)
arm.animation_data.action=action
scene.frame_set(1)
bpy.context.view_layer.update()
for o in bpy.data.objects:
 if o.name in selected:
  coords=[o.matrix_world@v.co for v in o.data.vertices]
  print('BOUNDS',o.name,[round(min(v[i] for v in coords),3) for i in range(3)],[round(max(v[i] for v in coords),3) for i in range(3)])
for o in list(bpy.data.objects):
 if o.type in ('LIGHT','CAMERA'):bpy.data.objects.remove(o,do_unlink=True)
scene.render.engine='CYCLES';scene.cycles.samples=24
scene.render.resolution_x=600;scene.render.resolution_y=700;scene.render.resolution_percentage=100
scene.world.color=(.15,.15,.15)
for loc,power,size in [((-2,-3,3),650,4),((2,-1,2),400,3),((0,3,3),500,3)]:
 d=bpy.data.lights.new('RepairLight','AREA');d.energy=power;d.shape='DISK';d.size=size
 o=bpy.data.objects.new('RepairLight',d);scene.collection.objects.link(o);o.location=loc
 o.rotation_euler=(Vector((0,0,.9))-o.location).to_track_quat('-Z','Y').to_euler()
d=bpy.data.cameras.new('RepairCamera');o=bpy.data.objects.new('RepairCamera',d);scene.collection.objects.link(o);scene.camera=o
d.type='ORTHO';d.ortho_scale=1.95
scene.render.image_settings.file_format='PNG'
for name,loc in [('front',(0,-4,.9)),('quarter',(3,-4,.9)),('side',(4,0,.9))]:
 o.location=loc;o.rotation_euler=(Vector((0,0,.85))-o.location).to_track_quat('-Z','Y').to_euler()
 scene.render.filepath=os.path.join(out,'NATIVE_ANATOMY_'+name+'_20261022.png')
 bpy.ops.render.render(write_still=True)
