"""Actual candidate material gate, not a human appearance or RealityKit approval."""
import bpy
for name in ["body","head","mat_eye","Material.000","mat_hair"]:
 mat=bpy.data.materials[name];nodes=mat.node_tree.nodes;outputs=[n for n in nodes if n.type=="OUTPUT_MATERIAL"]
 assert len(outputs)==1 and outputs[0].target=="ALL",name+" renderer-specific output may override portable surface"
 surface=outputs[0].inputs["Surface"];assert len(surface.links)==1,name+" disconnected output"
 shader=surface.links[0].from_node;assert shader.type=="BSDF_PRINCIPLED",name+" missing portable shader"
 if name!="mat_hair":
  links=shader.inputs["Base Color"].links;assert len(links)==1 and links[0].from_node.type=="TEX_IMAGE",name+" missing original texture"
  img=links[0].from_node.image;assert img and img.packed_file,name+" texture is not packed"
print("CANDIDATE_MATERIAL_CONTRACT PASS; appearance and RealityKit UNKNOWN")
