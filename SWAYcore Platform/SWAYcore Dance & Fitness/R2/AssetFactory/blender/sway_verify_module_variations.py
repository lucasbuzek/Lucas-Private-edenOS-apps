"""Reject distinct-looking option names that actually contain identical Blender geometry.
Run using Blender --background <character.blend> --python <this> -- --contract <json> --report <json>.
Only structural identity: passing does NOT accept artistic or visual quality.
"""
import bpy,hashlib,json,os,struct,sys
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from sway_common import args,load
A=args()
contract=load(A["contract"])
slots=contract["slots"]
arm=next((o for o in bpy.data.objects if o.type=="ARMATURE" and o.get("sway_native_skinning")),None)
assert arm is not None,"native skinned rig required"
required=set()
for choices in slots.values():
 for v in choices.values():required.update(v if isinstance(v,list) else [v])
meshes={o.name:o for o in bpy.data.objects if o.type=="MESH" and o.get("sway_module")}
issues=[]
if set(meshes)!=required:
 issues.append("contract meshes missing "+str(sorted(required-set(meshes)))+" extras "+str(sorted(set(meshes)-required)))
geometry={}
for name in sorted(required&set(meshes)):
 o=meshes[name]
 if len(o.data.vertices)<3 or not o.vertex_groups:
  issues.append(name+": non-skinned or too few vertices")
 if not any(m.type=="ARMATURE" and m.object==arm for m in o.modifiers):
  issues.append(name+": not bound to native rig")
 raw=b"".join(struct.pack("<fff",*(float(c) for c in v.co)) for v in o.data.vertices)
 geometry[name]=hashlib.sha256(raw).hexdigest()
for slot,choices in slots.items():
 variants=[]
 for label,choice in choices.items():
  names=choice if isinstance(choice,list) else [choice]
  variants.append((label,tuple(geometry.get(n,"MISSING") for n in names)))
 for i,(a,ah) in enumerate(variants):
  for b,bh in variants[i+1:]:
   if ah==bh:
    issues.append(slot+": visually distinct alternatives "+a+" / "+b+" have identical source geometry")
result={"status":"FAIL" if issues else "PASS","meshCount":len(meshes),"requiredCount":len(required),"slotCount":len(slots),"issues":issues,
        "geometrySHA256":geometry,"note":"Geometry-identity gate only, not artistic approval."}
with open(A["report"],"w") as f:json.dump(result,f,indent=2)
print("YOUR_DANCER_OPTION_GEOMETRY_GATE",result["status"],"MESHEs",len(meshes),"SLOTS",len(slots),"ISSUES",len(issues),issues[:8])
sys.exit(bool(issues))
