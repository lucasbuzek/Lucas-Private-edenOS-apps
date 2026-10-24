"""Export 44 separately controllable native skinned YOUR DANCER module bases,
plus ONE shared 21-clip skeleton animation library. Experimental, not approved.

Run Blender on the native skinned 44-module .blend:
  blender -b <unapproved-dancer.blend> --python AssetFactory/blender/sway_export_modular_runtime.py -- \
    --contract AssetFactory/data/your_dancer_modules.json \
    --clips AssetFactory/data/clip_manifest.json --out <new-existing-parent>/<new-name>

No assets are promoted, published or installed; no input .blend or authoring source
is modified. Existing single-module export and validation remain unchanged.
"""
import bpy, hashlib, json, os, pathlib, runpy, shutil, sys, tempfile, time
sys.path.insert(0, os.path.abspath("AssetFactory/blender"))
from sway_common import args, load, fail
A=args()
for key in ("contract","clips","out"):
    if key not in A:fail("missing --"+key)
contract=load(A["contract"])
manifest=load(A["clips"])
if contract["skeletonContract"]!="SWAYHumanoid-v1":fail("unsupported rig")
if len(manifest["clips"])!=21 or len(set(x["clip"] for x in manifest["clips"]))!=21:
    fail("expected original 21 authored clips")
native=next((o for o in bpy.data.objects if o.type=="ARMATURE" and o.get("sway_native_skinning")),None)
if native is None:fail("native articulated skinned source missing")
required=set()
for group in contract["slots"].values():
    for v in group.values():
        required.update(v if isinstance(v,list) else [v])
if len(required)!=44:fail("expected exactly 44 contracted native options")
meshes={o.name:o for o in bpy.data.objects if o.type=="MESH" and o.get("sway_module")}
if set(meshes)!=required:fail("module inventory mismatch")
for name, mesh in meshes.items():
    if not mesh.data.vertices or not mesh.vertex_groups or not any(m.type=="ARMATURE" and m.object==native for m in mesh.modifiers):
        fail("unskinned module "+name)
    if len(mesh.data.materials)!=1 or mesh.data.materials[0] is None:
        fail("invalid module PBR material "+name)
    mat=mesh.data.materials[0]
    if not mat.use_nodes or not any(n.type=="BSDF_PRINCIPLED" for n in mat.node_tree.nodes):
        fail("required PBR shader graph missing "+name)
destination=pathlib.Path(A["out"]).absolute()
if destination.exists():fail("destination already exists: "+str(destination))
if not destination.parent.is_dir():fail("destination parent does not exist")
destination.mkdir()
begin=time.perf_counter()
old_args=sys.argv[:]
exporter=os.path.abspath("AssetFactory/blender/sway_export_runtime.py")
scratch=destination/"_export_scratch"
scratch.mkdir()
contracts=scratch/"contracts"
contracts.mkdir()
initial=manifest.copy()
initial["clips"]=[x for x in manifest["clips"] if x["clip"]=="sway_step_touch_v1"]
if len(initial["clips"])!=1:fail("missing benchmark clip sway_step_touch_v1")
(initial_path:=scratch/"one_clip.json").write_text(json.dumps(initial))
files=[]
def invoke(source_contract,clip_contract,out_path):
    out_path.parent.mkdir(parents=True,exist_ok=True)
    sys.argv=["blender","--","--id","user","--display-name","Your Dancer","--asset-base","SWAYModule",
        "--modules",str(source_contract),"--clips",str(clip_contract),"--out",str(out_path)]
    try: runpy.run_path(exporter,run_name="__main__")
    finally:sys.argv=old_args
try:
    for index,name in enumerate(sorted(required),1):
        part=dict(contract);part["slots"]={"isolatedOption":{"0":name}}
        source_contract=contracts/(name+".json")
        source_contract.write_text(json.dumps(part))
        temp=scratch/"module_exports"/name
        invoke(source_contract,initial_path,temp)
        base=temp/"SWAYModule.usdc"
        if not base.is_file() or base.stat().st_size==0:fail("single-module base not created "+name)
        folder=destination/"Modules"/name
        folder.mkdir(parents=True,exist_ok=True)
        target=folder/"SWAYModule.usdc"
        shutil.move(str(base),str(target))
        files.append(target)
        # USD PreviewSurface image paths are relative to each module root.
        # Preserve exported textures before deleting the temporary export.
        texture_source=temp/"textures"
        if texture_source.is_dir():
            texture_target=folder/"textures"
            shutil.copytree(texture_source,texture_target)
            files.extend(p for p in texture_target.rglob("*") if p.is_file())
        if index%11==0:print("SWAY_MODULAR_PROGRESS",index,"/44",round(time.perf_counter()-begin,1),flush=True)
    # 21 shared animation clips are authored only once and bound by the common
    # SWAYHumanoid-v1 skeleton resource names. The native Mac test independently
    # checks clip rebinding across different module model owners.
    selected_name=sorted(required)[0]
    shared_contract=contracts/(selected_name+".json")
    shared_tmp=scratch/"shared"
    invoke(shared_contract,pathlib.Path(A["clips"]).absolute(),shared_tmp)
    animation_dir=destination/"Animations"
    shutil.move(str(shared_tmp/"Animations"),str(animation_dir))
    # Shared clip USDs can reference ../textures from their export root.
    if (shared_tmp/"textures").is_dir():
        shutil.copytree(shared_tmp/"textures",destination/"textures")
        files.extend(p for p in (destination/"textures").rglob("*") if p.is_file())
    for item in manifest["clips"]:
        file=animation_dir/(item["clip"]+".usdc")
        if not file.is_file() or file.stat().st_size==0:fail("shared clip missing "+item["clip"])
        files.append(file)
    source=json.loads((shared_tmp/"user.character.json").read_text())
    source["assetBaseName"]="SWAYModule"
    source["modularAssetName"]="SWAYModule"
    source["moduleMeshNames"]=sorted(required)
    source["moduleAssets"]={name:"Modules/"+name+"/SWAYModule.usdc" for name in sorted(required)}
    source["runtimeApproved"]=False
    source["visualQuality"]="UNREVIEWED"
    source["modulePackaging"]="on-demand-independent-skinned-models"
    source["userApprovalRequired"]=True
    source["sharedAnimationPaths"]={key:"Animations/"+v["resource"]+".usdc" for key,v in source["animations"].items()}
    source["maximumSimultaneousNativeModels"]=12
    # Match the live SWAYAvatarManifestLoader user.character.json resource.
    # This remains isolated and runtimeApproved:false until visual/physical acceptance.
    manifestpath=destination/"user.character.json"
    manifestpath.write_text(json.dumps(source,indent=2,sort_keys=True)+"\n")
    files.append(manifestpath)
    countModules=len(list((destination/"Modules").rglob("*.usdc")))
    countClips=len(list(animation_dir.glob("*.usdc")))
    assert countModules==44 and countClips==21
    def sha(p):
        h=hashlib.sha256()
        with p.open("rb") as fd:
            for chunk in iter(lambda:fd.read(1024*1024),b""):h.update(chunk)
        return h.hexdigest()
    summary={"status":"UNREVIEWED_NATIVE_ASSET_CANDIDATE","blender":bpy.app.version_string,
        "sourceBlend":bpy.data.filepath,"sourceBlendSHA256":sha(pathlib.Path(bpy.data.filepath)),
        "modules":countModules,"sharedAnimationClips":countClips,"totalUSDCBytes":sum(x.stat().st_size for x in files if x.suffix==".usdc"),
        "assetCount":len(files),"uniqueModelPaths":len(set(x.name for x in files if x.suffix==".usdc")),
        "elapsedSeconds":round(time.perf_counter()-begin,3),
        "resources":{str(p.relative_to(destination)):{"size":p.stat().st_size,"sha256":sha(p)} for p in files}}
    (destination/"export_summary.json").write_text(json.dumps(summary,indent=2)+"\n")
    print("SWAY_ALL44_SHARED21_EXPORT_SUCCESS",summary["modules"],summary["sharedAnimationClips"],
        summary["totalUSDCBytes"],summary["elapsedSeconds"],flush=True)
finally:
    if scratch.exists():shutil.rmtree(scratch)

