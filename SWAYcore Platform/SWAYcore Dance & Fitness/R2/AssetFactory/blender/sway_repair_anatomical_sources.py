"""Repair isolated native modules from actual source anatomy; never approve runtime."""
import bpy,bmesh,sys,os,json,math
from mathutils import Vector
out=os.path.abspath(sys.argv[sys.argv.index('--')+1])
assert not os.path.exists(out),"NO_CLOBBER"
assert os.path.isdir(os.path.dirname(out))
arm=bpy.data.objects['Armature']
body=bpy.data.objects['body.001']
head=bpy.data.objects['baseMesh1_A1.001']
assert arm.get('sway_native_skinning')
bpy.context.view_layer.update()
sources={}
def source_copy(src,name):
 o=src.copy();o.data=src.data.copy();bpy.context.collection.objects.link(o)
 o.name=name;o.hide_viewport=False;o.hide_render=False;o.hide_set(False)
 world=src.matrix_world.copy();o.parent=None;o.matrix_world=world
 for m in list(o.modifiers):
  if m.type=='ARMATURE':m.show_viewport=False;m.show_render=False
 bpy.context.view_layer.update()
 dg=bpy.context.evaluated_depsgraph_get()
 o.data=bpy.data.meshes.new_from_object(o.evaluated_get(dg),preserve_all_data_layers=True,depsgraph=dg)
 for m in list(o.modifiers):o.modifiers.remove(m)
 m=o.modifiers.new('NativeSkin','ARMATURE');m.object=arm
 o['sway_module']=False
 return o
bs=source_copy(body,'SWAYRepairBodySource')
hs=source_copy(head,'SWAYRepairHeadSource')
es=source_copy(bpy.data.objects['eye.L'],'SWAYRepairEyesSource')
er=source_copy(bpy.data.objects['eye.R'],'SWAYRepairRightEye')
bpy.ops.object.select_all(action='DESELECT')
es.select_set(True);er.select_set(True);bpy.context.view_layer.objects.active=es
bpy.ops.object.join()
def material_from(src,name):
 m=src.data.materials[0].copy();m.name=name
 return m
skin=material_from(bs,'YD_Mat_Skin_Body')
face=material_from(hs,'YD_Mat_Skin_Face')
eyes=material_from(es,'YD_SourceEyes')
for o,mat in [(bs,skin),(hs,face),(es,eyes)]:
 o.data.materials.clear();o.data.materials.append(mat)
 for p in o.data.polygons:p.material_index=0
def mask(mesh,keep):
 bm=bmesh.new();bm.from_mesh(mesh);bm.faces.ensure_lookup_table()
 bmesh.ops.delete(bm,geom=[f for f in bm.faces if f.index not in keep],context='FACES')
 loose=[v for v in bm.verts if not v.link_faces]
 if loose:bmesh.ops.delete(bm,geom=loose,context='VERTS')
 bm.to_mesh(mesh);bm.free();mesh.update()
def replace(name,src,predicate=None,offset=0,material=None,deform=None):
 old=bpy.data.objects[name];oldmat=old.data.materials[0]
 o=src.copy();o.data=src.data.copy();bpy.context.collection.objects.link(o)
 o.name=name+'_repair'
 if predicate is not None:
  keep={p.index for p in o.data.polygons if predicate(p.center)}
  assert len(keep)>=2,(name,len(keep))
  mask(o.data,keep)
 if deform:
  for v in o.data.vertices:deform(v)
 o.data.update()
 normals=[v.normal.copy() for v in o.data.vertices]
 for v,n in zip(o.data.vertices,normals):v.co+=n*offset
 o.data.materials.clear();o.data.materials.append(material or oldmat)
 for p in o.data.polygons:p.material_index=0;p.use_smooth=True
 o.data.update()
 o['sway_module']=True;o['sway_shared_rig']='SWAYHumanoid-v1'
 o['sway_candidate_quality']='UNREVIEWED'
 o['sway_anatomical_source']=src.name
 o.hide_render=True;o.hide_viewport=True
 bpy.data.objects.remove(old,do_unlink=True);o.name=name
 assert any(m.type=='ARMATURE' and m.object==arm for m in o.modifiers)
 assert all(v.groups for v in o.data.vertices),(name,'unweighted')
 return o
for name,strength in [('Balanced',0),('Athletic',.045),('Soft',-.035)]:
 def deform(v,s=strength):
  # Torso-only width change tapers to zero at neck, hip and arm seams.
  w=max(0,1-abs(v.co.z-130)/30)*max(0,1-abs(v.co.x)/24)
  v.co.x*=1+s*w
 replace('YD_Body_'+name,bs,material=skin,deform=deform)
for name,strength in [('Oval',0),('Round',.045),('Angular',-.035)]:
 def deform(v,s=strength):
  w=max(0,min(1,(v.co.z-165)/8))
  v.co.x*=1+s*w
 replace('YD_Face_'+name,hs,material=face,deform=deform)
for idx in range(4):
 def eye_deform(v,i=idx):
  # Keep each eye centered in its authored socket.
  c=3.34 if v.co.x>0 else -3.32
  v.co.x=c+(v.co.x-c)*(1+.018*i)
 replace('YD_Eyes_'+str(idx),es,material=eyes,deform=eye_deform)
# These patches use true facial surface/UVs, never shoulder/neck geometry.
features={
 'Brows':lambda c:174.8<c.z<178.5 and 1<abs(c.x)<7 and c.y<1,
 'Nose':lambda c:168.8<c.z<175 and abs(c.x)<2.7 and c.y<0,
 'Mouth':lambda c:165.8<c.z<170 and abs(c.x)<4.5 and c.y<0,
 'Facial_Hair':lambda c:163.5<c.z<168.5 and abs(c.x)<6 and c.y<1}
for feature,pred in features.items():
 for idx in range(4):
  replace('YD_'+feature+'_'+str(idx),hs,pred,offset=.035+.025*idx,material=face)
for style,end,low,offset in [('Tee',36,100,.65),('Tank',19,105,.55),('Jacket',61,96,.95)]:
 replace('YD_Top_'+style,bs,lambda c,e=end,l=low:l<c.z<159 and abs(c.x)<e,offset)
for style,low,offset in [('Legging',15,.55),('Short',76,.65),('Jogger',12,.9)]:
 replace('YD_Bottom_'+style,bs,lambda c,l=low:l<c.z<107 and abs(c.x)<25,offset)
for style,high,offset in [('Trainers',19,.7),('HighTops',25,.85),('Barefoot',11,.04)]:
 replace('YD_Shoes_'+style,bs,lambda c,h=high:c.z<h and abs(c.x)<25,offset,skin if style=='Barefoot' else None)
replace('YD_Accessory_Cap',hs,lambda c:c.z>179,.65)
replace('YD_Accessory_Headband',hs,lambda c:177<c.z<180,.6)
replace('YD_Accessory_Wristbands',bs,lambda c:56<abs(c.x)<64,.6)
replace('YD_Accessory_Gloves',bs,lambda c:abs(c.x)>64,.55)
for o in [bs,hs,es]:bpy.data.objects.remove(o,do_unlink=True)
modules=[o for o in bpy.data.objects if o.type=='MESH' and o.get('sway_module')]
assert len(modules)==44,len(modules)
# Regression for the original anatomical-source failure.
assert max(v.co.z for v in bpy.data.objects['YD_Body_Balanced'].data.vertices)>165
assert min(v.co.z for v in bpy.data.objects['YD_Face_Oval'].data.vertices)>160
assert max(abs(v.co.x) for v in bpy.data.objects['YD_Face_Oval'].data.vertices)<12
assert min(v.co.z for v in bpy.data.objects['YD_Eyes_0'].data.vertices)>170
# Flat material viewport colors must also reach the exported PBR shader.
for name,color in {'YD_Mat_Hair':(.045,.025,.018,1),'YD_Mat_Outfit':(.25,.08,.48,1),'YD_Mat_Shoes':(.16,.17,.20,1),'YD_Mat_Accent':(.8,.26,.12,1)}.items():
 mat=bpy.data.materials.get(name)
 if mat:
  mat.diffuse_color=color
  for n in mat.node_tree.nodes:
   if n.type=='BSDF_PRINCIPLED':
    n.inputs['Base Color'].default_value=color
    n.inputs['Roughness'].default_value=.7
for o in modules:o.hide_render=True;o.hide_viewport=True
bpy.ops.wm.save_as_mainfile(filepath=out)
print('ANATOMICAL_SOURCE_REPAIR_SAVED',out,'modules',len(modules),flush=True)
