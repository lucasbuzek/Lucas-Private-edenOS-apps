"""Restore original CC0 Girush texture connections in an isolated diagnostic candidate.
Preserves geometry, UVs and skinning. Does not approve attire or runtime export."""
import bpy,os,sys,json
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from sway_common import args
A=args();out=os.path.abspath(A["out"])
if out==os.path.abspath(bpy.data.filepath):raise RuntimeError("source overwrite forbidden")
source=os.path.abspath("AssetFactory/sources/Girush")
mapping={"body":"baseMesh_A1_body.png","head":"baseMesh_A1_face.png","mat_eye":"black_eye.png","Material.000":"black_eye.png"}
report=[]
for name,file in mapping.items():
 mat=bpy.data.materials.get(name)
 if mat is None:raise RuntimeError("missing original material "+name)
 mat.use_nodes=True;nodes=mat.node_tree.nodes
 shader=next(n for n in nodes if n.type=="BSDF_PRINCIPLED")
 outputs=[n for n in nodes if n.type=="OUTPUT_MATERIAL"]
 output=outputs[0];output.is_active_output=True;output.target="ALL"
 for link in list(mat.node_tree.links):
  if link.to_node in outputs:mat.node_tree.links.remove(link)
 # A disconnected CYCLES-specific output overrides the connected ALL output
 # even when is_active_output is false. Keep a single exportable surface output.
 for other in outputs[1:]:nodes.remove(other)
 tex=nodes.new("ShaderNodeTexImage");tex.image=bpy.data.images.load(os.path.join(source,file),check_existing=True);tex.image.pack()
 mat.node_tree.links.new(tex.outputs["Color"],shader.inputs["Base Color"])
 shader.inputs["Roughness"].default_value=.65
 mat.node_tree.links.new(shader.outputs["BSDF"],output.inputs["Surface"])
 report.append({"material":name,"packedOriginalTexture":file})
hair=bpy.data.materials.get('mat_hair')
if hair:
 nodes=hair.node_tree.nodes;shader=next(n for n in nodes if n.type=='BSDF_PRINCIPLED')
 diffuse=next((n for n in nodes if n.type=='BSDF_DIFFUSE'),None)
 if diffuse:shader.inputs['Base Color'].default_value=diffuse.inputs['Color'].default_value
 outputs=[n for n in nodes if n.type=='OUTPUT_MATERIAL'];output=outputs[0]
 for other in outputs[1:]:nodes.remove(other)
 output.target='ALL';output.is_active_output=True
 for link in list(hair.node_tree.links):
  if link.to_node==output:hair.node_tree.links.remove(link)
 hair.node_tree.links.new(shader.outputs['BSDF'],output.inputs['Surface'])
 report.append({'material':'mat_hair','originalDiffuseColor':list(shader.inputs['Base Color'].default_value),'singlePortableSurface':True})
for rig in (o for o in bpy.data.objects if o.type=="ARMATURE"):rig["sway_visual_quality"]="UNREVIEWED"
bpy.ops.wm.save_as_mainfile(filepath=out)
if A.get("report"):
 with open(A["report"],"w") as f:json.dump({"materials":report,"visualQuality":"UNREVIEWED","attireGate":"UNKNOWN"},f,indent=2)
print("ORIGINAL_GIRUSH_TEXTURE_CONNECTIONS",json.dumps(report))
