"""Blender behavioural regression for the recovered hidden-object poll defect.
Synthetic test fixture only; never a Lucia candidate or visual approval.
Run from R2 with blender --background --factory-startup --python THIS_FILE.
"""
import bpy,pathlib,runpy,sys,tempfile
from mathutils import Vector
root=pathlib.Path.cwd()
with tempfile.TemporaryDirectory(prefix='sway-hidden-skin-',dir='/private/tmp') as tmp:
 tmp=pathlib.Path(tmp);bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.object.armature_add(enter_editmode=True);arm=bpy.context.object;arm.name='NativeFixture'
 for b in list(arm.data.edit_bones):arm.data.edit_bones.remove(b)
 for i in range(18):
  b=arm.data.edit_bones.new('native.helper.'+str(i));b.head=Vector((i*.05,0,0));b.tail=b.head+Vector((0,0,.1))
 bpy.ops.object.mode_set(mode='OBJECT')
 mesh=bpy.data.meshes.new('HiddenMesh');mesh.from_pydata([(i*.05,0,0) for i in range(18)],[],[])
 obj=bpy.data.objects.new('Outfit_hidden',mesh);bpy.context.collection.objects.link(obj)
 groups=[obj.vertex_groups.new(name='native.helper.'+str(i)) for i in range(18)]
 for i in range(18):
  for j,w in enumerate([.4,.25,.15,.12,.08]):groups[(i+j)%18].add([i],w,'REPLACE')
 obj.modifiers.new('NativeSkin','ARMATURE').object=arm;obj.parent=arm
 obj.vertex_groups.new(name='removed.source.bone').add([0],1,'REPLACE')
 obj.hide_viewport=True;obj.hide_render=True
 source=tmp/'input.blend';output=tmp/'output.blend';bpy.ops.wm.save_as_mainfile(filepath=str(source))
 sys.argv=['probe','--','--out',str(output)]
 runpy.run_path(str(root/'AssetFactory/blender/sway_limit_native_weights.py'),run_name='__main__')
 assert obj.hide_viewport and obj.hide_render,'visibility was changed'
 assert obj.modifiers['NativeSkin'].object==arm,'native modifier was replaced'
 assert 'removed.source.bone' not in obj.vertex_groups,'orphan weights survived derivative repair'
 for v in obj.data.vertices:
  ws=[g.weight for g in v.groups if g.weight>1e-4]
  assert len(ws)<=4 and abs(sum(ws)-1)<1e-6,'invalid weights'
 assert output.exists(),'missing isolated output'
 print('HIDDEN_NATIVE_SKIN_FIXTURE PASS; fixture only, no production approval')
