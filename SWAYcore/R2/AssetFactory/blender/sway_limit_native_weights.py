"""Limit imported native skin weights through data API, including hidden variants.
Requires a distinct --out path. Retains rig names, modifiers, helper chains and visibility.
No auto-parent, context-sensitive operator, inferred weights or visual approval.
"""
import bpy,os,sys,json
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from sway_common import args
from skin_weights import limit_weights,weight_issues
A=args();source=bpy.data.filepath;out=os.path.abspath(A['out'])
if out==os.path.abspath(bpy.data.filepath):raise RuntimeError('source overwrite forbidden')
report=[]
for obj in bpy.data.objects:
    rigs=[m.object for m in obj.modifiers if m.type=='ARMATURE' and m.object] if obj.type=='MESH' else []
    if not rigs:continue
    allowed={b.name for rig in rigs for b in rig.data.bones}
    rows=[];removed_mass=[]
    # Orphan groups cannot deform through any attached armature. Archive their
    # assignments before removing them from this isolated derivative, never source.
    orphan_groups={g.name:[(v.index,x.weight) for v in obj.data.vertices for x in v.groups if x.group==g.index] for g in obj.vertex_groups if g.name not in allowed}
    for v in obj.data.vertices:
        weights={obj.vertex_groups[g.group].name:g.weight for g in v.groups if obj.vertex_groups[g.group].name in allowed}
        limited=limit_weights(weights);rows.append(limited)
        removed_mass.append(sum(w for n,w in weights.items() if n not in limited))
    # Validate the whole mesh before mutating it; no visibility/selection changes required.
    problems=weight_issues(rows,allowed)
    if problems:raise RuntimeError(obj.name+': '+str(problems[:8]))
    for name in orphan_groups:obj.vertex_groups.remove(obj.vertex_groups[name])
    for group in obj.vertex_groups:
        if group.name in allowed:group.remove(list(range(len(rows))))
    groups={g.name:g for g in obj.vertex_groups}
    for index,row in enumerate(rows):
        for name,weight in row.items():groups[name].add([index],weight,'REPLACE')
    report.append({'mesh':obj.name,'vertices':len(rows),'usedBones':len({n for row in rows for n in row}),'maxInfluences':max(map(len,rows),default=0),'maxRemovedSourceMass':max(removed_mass,default=0),'hiddenViewport':obj.hide_viewport,'hiddenRender':obj.hide_render,'orphanGroupsArchived':orphan_groups})
for rig in (o for o in bpy.data.objects if o.type=='ARMATURE'):rig['sway_visual_quality']='UNREVIEWED'
os.makedirs(os.path.dirname(out),exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=out)
if A.get('report'):
    with open(A['report'],'w') as f:json.dump({'input':source,'meshes':report,'visualQuality':'UNREVIEWED'},f,indent=2)
print('NATIVE_WEIGHT_BUDGET',json.dumps(report))
