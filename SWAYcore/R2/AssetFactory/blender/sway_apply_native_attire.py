"""Apply existing R2 attire palette to native surface faces without rebind/topology edits.
Material attire is a candidate, not a human visual approval or simulated garment."""
import bpy,os,sys,json
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from sway_common import args,load
A=args();out=os.path.abspath(A["out"])
if out==os.path.abspath(bpy.data.filepath):raise RuntimeError("source overwrite forbidden")
config=next(c for c in load("AssetFactory/data/characters.json")["characters"] if c["id"]==A.get("id","lucia"))
meshes=[o for o in bpy.data.objects if o.type=="MESH" and any(m.type=="ARMATURE" for m in o.modifiers)]
body=max(meshes,key=lambda o:len(o.data.vertices))
rig=next(m.object for m in body.modifiers if m.type=="ARMATURE" and m.object)
mapping=load("AssetFactory/data/retarget_map_girush.json")["map"]
hips=(rig.matrix_world@rig.data.bones[mapping["Hips"][0]].head_local).z
shoulder=(rig.matrix_world@rig.data.bones[mapping["LeftUpperArm"][0]].head_local).z
ankle=(rig.matrix_world@rig.data.bones[mapping["LeftFoot"][0]].head_local).z
width=abs((rig.matrix_world@rig.data.bones[mapping["LeftUpperArm"][0]].head_local).x)*.96
indices={}
for role,color in config["outfit"].items():
 mat=bpy.data.materials.new(config["id"]+"_native_"+role);mat.use_nodes=True;shader=mat.node_tree.nodes.get("Principled BSDF");shader.inputs["Base Color"].default_value=(*color,1);shader.inputs["Roughness"].default_value=.8;body.data.materials.append(mat);indices[role]=len(body.data.materials)-1
counts={r:0 for r in indices}
for face in body.data.polygons:
 center=body.matrix_world@face.center
 role=None
 if center.z<ankle+.035:role="shoes"
 elif center.z<hips+.045:role="bottom"
 elif center.z<shoulder+.015 and abs(center.x)<width:role="top"
 if role:face.material_index=indices[role];counts[role]+=1
if not all(counts.values()):raise RuntimeError("native attire region missing: "+str(counts))
for o in bpy.data.objects:
 if o.type=="ARMATURE":o["sway_visual_quality"]="UNREVIEWED"
bpy.ops.wm.save_as_mainfile(filepath=out)
report={"character":config["id"],"paletteSource":"AssetFactory/data/characters.json","nativeMesh":body.name,"facesPerRole":counts,"visualQuality":"UNREVIEWED","method":"native face material assignment; topology, UVs, rig and weights preserved"}
if A.get("report"):
 with open(A["report"],"w") as f:json.dump(report,f,indent=2)
print("NATIVE_ATTIRE_CANDIDATE",json.dumps(report))
