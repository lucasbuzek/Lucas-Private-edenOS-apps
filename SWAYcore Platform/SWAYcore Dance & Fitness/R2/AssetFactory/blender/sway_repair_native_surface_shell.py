"""Isolated 2026-10-21 SWAY native surface repair, not production approval.
Run against the original unapproved 44-module .blend; outputs a DIFFERENT .blend.

Reuse the licensed Girush-derived skinned BODY and FACE geometry, face-adjacent
feature neighborhoods and skin groups. Use topology-aware face isolation,
surface offset + a shell, not scaling the whole character then Z-cropping.
"""
import bpy, bmesh, collections, hashlib, json, os, sys
from mathutils import Vector

argv=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
if len(argv)!=1:raise SystemExit("Expected exactly one new .blend candidate output path")
output=os.path.abspath(argv[0])
if os.path.exists(output):raise SystemExit("NO_CLOBBER: "+output)
if not os.path.isdir(os.path.dirname(output)):raise SystemExit("existing candidate parent required")
body=bpy.data.objects.get('YD_Body_Balanced')
head=bpy.data.objects.get('YD_Face_Oval')
hair=bpy.data.objects.get('YD_Hair_Short')
arm=next((o for o in bpy.data.objects if o.type=='ARMATURE' and o.get('sway_native_skinning')),None)
if not all((body,head,hair,arm)):raise SystemExit("missing licensed native source or rig")
if len([o for o in bpy.data.objects if o.type=='MESH' and o.get('sway_module')])!=44:
 raise SystemExit("wrong original module count")
required_id='SWAYHumanoid-v1'
bpy.context.view_layer.update()

# Polygon graph from ORIGINAL licensed face. Never treat head-wide duplicates as
# eyelids, brows, lips or facial hair.
def connected_polygon_sets(mesh):
 edge_faces=collections.defaultdict(set)
 for p in mesh.polygons:
  v=list(p.vertices)
  for pair in zip(v,v[1:]+v[:1]):
   edge_faces[tuple(sorted(pair))].add(p.index)
 neighbors=collections.defaultdict(set)
 for fi in edge_faces.values():
  for idx in fi:neighbors[idx].update(fi-{idx})
 unassigned=set(p.index for p in mesh.polygons)
 result=[]
 while unassigned:
  seed=next(iter(unassigned));todo={seed};group=set()
  while todo:
   node=todo.pop()
   if node not in unassigned:continue
   unassigned.remove(node);group.add(node);todo.update(neighbors[node]&unassigned)
  result.append(group)
 return sorted(result,key=len,reverse=True),neighbors

components,head_neighbors=connected_polygon_sets(head.data)
print("SWAY_HEAD_COMPONENT_FACE_COUNTS",[len(c) for c in components],flush=True)
major=components[0]
eyeballs=[c for c in components[1:] if 5<=len(c)<=60]
print("SWAY_EYE_COMPONENT_FACE_COUNTS",[len(c) for c in eyeballs],flush=True)
if len(major)<200 or len(eyeballs)<2:raise RuntimeError("unrecognized native face topology, refuse arbitrary masking")
eye_indices=set().union(*eyeballs[:2])

def face_neighborhood(point,rings):
 candidates=major
 start=min(candidates,key=lambda idx:(head.data.polygons[idx].center-Vector(point)).length_squared)
 active={start}
 for _ in range(rings):active.update(v for u in list(active) for v in head_neighbors[u] if v in candidates)
 return active

def surface_mask(mesh,indices):
 bm=bmesh.new();bm.from_mesh(mesh)
 bm.faces.ensure_lookup_table();bm.faces.index_update()
 to_delete=[f for f in bm.faces if f.index not in indices]
 bmesh.ops.delete(bm,geom=to_delete,context='FACES')
 isolated=[v for v in bm.verts if not v.link_faces]
 if isolated:bmesh.ops.delete(bm,geom=isolated,context='VERTS')
 bm.to_mesh(mesh);bm.free();mesh.update()

def selected_body_faces(kind,style):
 selected=set()
 for p in body.data.polygons:
  c=p.center; x=abs(float(c.x));z=float(c.z)
  if kind=='Top':
   zmin={'Tee':100,'Tank':106,'Jacket':95}[style]
   # Respect separate source torso/sleeve components and avoid hands.
   # Sleeve length is controlled anatomically along the horizontal arm.
   end={'Tee':48,'Tank':26,'Jacket':60}[style]
   allow=(zmin<z<144 and ((x<22) or (22<=x<end and z>113)))
  elif kind=='Bottom':
   zmin={'Legging':16,'Short':75,'Jogger':13}[style]
   zmax={'Legging':106,'Short':106,'Jogger':105}[style]
   allow=zmin<z<zmax and x<24
  elif kind=='Shoes':
   zmax={'Trainers':19,'HighTops':25,'Barefoot':12}[style]
   allow=-3<z<zmax and x<25
  elif kind=='Accessory':
   if style in ('Wristbands','Gloves'):
    minx,maxx=(53,64) if style=='Wristbands' else (61,90)
    allow=minx<x<maxx and 114<z<146
   else:allow=False
  else:allow=False
  if allow:selected.add(p.index)
 return selected

def head_accessory_faces(style):
 # Follow the scalp surface instead of selecting entire torso/head copy.
 if style=='Cap':return {p.index for p in head.data.polygons if p.index in major and p.center.z>163}
 if style=='Headband':return {p.index for p in head.data.polygons if p.index in major and 160<p.center.z<165}
 return set()

feature_masks={}
for name in ('Eyes','Brows','Nose','Mouth','Facial_Hair'):
 if name=='Eyes':
  feature_masks[name]=eye_indices
 elif name=='Brows':
  feature_masks[name]=face_neighborhood((-9,-3,151),2)|face_neighborhood((9,-3,151),2)
 elif name=='Nose':
  feature_masks[name]=face_neighborhood((0,-4,149),3)
 elif name=='Mouth':
  feature_masks[name]=face_neighborhood((0,-4,144),2)
 elif name=='Facial_Hair':
  feature_masks[name]=face_neighborhood((-6,-3,143),2)|face_neighborhood((6,-3,143),2)|face_neighborhood((0,-4,143),1)
print("SWAY_FACIAL_FEATURE_POLYGONS",{k:len(v) for k,v in feature_masks.items()},flush=True)

def new_mesh_option(name,source,faces,color,offset=0.38,thickness=0.35,scale=1.0,local_scale=None):
 old=bpy.data.objects.get(name)
 if old is None:raise RuntimeError("missing option "+name)
 if len(faces)<5:raise RuntimeError("empty/inadequate selected topology "+name+" "+str(len(faces)))
 old_mat=old.data.materials[0] if old.data.materials else None
 original_parent=old.parent
 old_collection=old.users_collection[0] if old.users_collection else bpy.context.collection
 # Isolated copies preserve all vertex groups, weights and armature modifiers.
 new=source.copy()
 new.data=source.data.copy()
 new.name=name+"_isolated_repair"
 old_collection.objects.link(new)
 surface_mask(new.data,faces)
 if len(new.data.polygons)<5:raise RuntimeError("module lost faces after extraction "+name)
 if local_scale is not None or scale!=1.0:
  verts=new.data.vertices
  center=sum((v.co for v in verts),Vector())/len(verts)
  if local_scale is None:local_scale=(scale,scale,scale)
  for v in verts:
   d=v.co-center
   v.co=center+Vector((d.x*local_scale[0],d.y*local_scale[1],d.z*local_scale[2]))
  new.data.update()
 # Small outward offset in source mesh units; surface normals are preserved.
 normals=[v.normal.copy() for v in new.data.vertices]
 for vertex,normal in zip(new.data.vertices,normals):
  vertex.co+=normal*offset
 new.data.update()
 if old_mat is not None:
  new.data.materials.clear();new.data.materials.append(old_mat)
 if thickness>0:
  shell=new.modifiers.new("SWAY_CoherentGarmentShell","SOLIDIFY")
  shell.thickness=thickness
  shell.offset=0.5
  shell.use_even_offset=True
 new.parent=original_parent
 # SOURCE object carries native 0.008780... scale; matrix_world in the
 # unopened background depsgraph may be stale/identity. Preserve source
 # LOCAL transform instead of assigning matrix_world (which resets scale=1).
 new.matrix_parent_inverse=source.matrix_parent_inverse.copy()
 new.location=source.location.copy()
 new.scale=source.scale.copy()
 new.rotation_mode=source.rotation_mode
 if source.rotation_mode=="QUATERNION":new.rotation_quaternion=source.rotation_quaternion.copy()
 else:new.rotation_euler=source.rotation_euler.copy()
 new["sway_module"]=True
 new["sway_shared_rig"]=required_id
 new["sway_candidate_quality"]="UNREVIEWED"
 new.hide_render=True;new.hide_viewport=True
 bpy.data.objects.remove(old,do_unlink=True)
 new.name=name
 if not any(m.type=="ARMATURE" and m.object==arm for m in new.modifiers):
  raise RuntimeError("lost licensed native armature skin "+name)
 return (name,len(new.data.vertices),len(new.data.polygons))

changes=[]
for garment in ('Tee','Tank','Jacket'):
 variant={'Tee':1.012,'Tank':1.018,'Jacket':1.045}[garment]
 changes.append(new_mesh_option('YD_Top_'+garment,body,selected_body_faces('Top',garment),
    'outfit',offset={'Tee':0.55,'Tank':0.46,'Jacket':0.83}[garment],
    thickness={'Tee':0.43,'Tank':0.36,'Jacket':0.60}[garment],local_scale=(variant,variant,1)))
for garment in ('Legging','Short','Jogger'):
 variant={'Legging':1.01,'Short':1.02,'Jogger':1.052}[garment]
 changes.append(new_mesh_option('YD_Bottom_'+garment,body,selected_body_faces('Bottom',garment),
    'outfit',offset=0.53,thickness=0.44,local_scale=(variant,variant,1)))
for style in ('Trainers','HighTops','Barefoot'):
 changes.append(new_mesh_option('YD_Shoes_'+style,body,selected_body_faces('Shoes',style),
    'shoes',offset=0.53 if style!='Barefoot' else 0.13,thickness=0.7 if style!='Barefoot' else 0.07,
    local_scale=(1.025 if style!='Barefoot' else 1,1.035 if style!='Barefoot' else 1,1)))
for style in ('Cap','Headband'):
 changes.append(new_mesh_option('YD_Accessory_'+style,head,head_accessory_faces(style),
    'outfit',offset=0.6,thickness=0.36))
for style in ('Gloves','Wristbands'):
 changes.append(new_mesh_option('YD_Accessory_'+style,body,selected_body_faces('Accessory',style),
    'outfit',offset=0.55,thickness=0.3))

for feature,faces in feature_masks.items():
 for idx in range(4):
  # Scale only LOCAL feature patches, not the entire head mesh.
  shape=1.0+(.018*idx)
  changes.append(new_mesh_option('YD_'+feature+'_'+str(idx),head,faces,
    'face',offset=.35+idx*.08,thickness=0.09,
    local_scale=(shape,shape,1.0+.008*idx)))

# Repair the TWO genuine 3-face hairstyle edge overlaps per variant.
for style in ('Short','Long','Braids','Afro','Bun'):
 o=bpy.data.objects.get('YD_Hair_'+style)
 bm=bmesh.new();bm.from_mesh(o.data)
 deleted=0
 for _ in range(6):
  bad=next((e for e in bm.edges if len(e.link_faces)>2),None)
  if bad is None:break
  # Pick the smallest attached face, retaining the broader scalp/tress shell.
  f=min(list(bad.link_faces),key=lambda f:f.calc_area())
  bmesh.ops.delete(bm,geom=[f],context='FACES')
  deleted+=1
 loose=[v for v in bm.verts if not v.link_faces]
 if loose:bmesh.ops.delete(bm,geom=loose,context='VERTS')
 remaining=sum(len(e.link_faces)>2 for e in bm.edges)
 bm.to_mesh(o.data);bm.free();o.data.update()
 print("SWAY_HAIR_REPAIR",style,'deletedFaces',deleted,'remainingMultiFaceEdges',remaining,flush=True)
 if remaining:raise RuntimeError("unfixed native hair shared edge "+style)

# Keep untouched provenance, all 44 slots, hair variants and the 23-joint
# contract. The stored source still contains its original rig and 21 actions.
assert len(changes)==33,len(changes)
modules=[o for o in bpy.data.objects if o.type=='MESH' and o.get('sway_module')]
assert len(modules)==44,len(modules)
assert arm.get("sway_native_skinning") and arm.get("sway_visual_quality")=="UNREVIEWED"
for o in modules:
 assert any(m.type=="ARMATURE" and m.object==arm for m in o.modifiers),o.name
arm["sway_visual_quality"]="UNREVIEWED"
bpy.ops.wm.save_as_mainfile(filepath=output)
print("SWAY_NATIVE_ISOLATED_REPAIR_SAVED",output,flush=True)
print("SWAY_NATIVE_REPAIRED_MODULES",len(changes),'TOTAL',len(modules),flush=True)
print("SWAY_NATIVE_MODULE_REPAIR_SUMMARY",json.dumps(changes),flush=True)
