#!/usr/bin/env python3
from __future__ import annotations
import argparse,json,re
from pathlib import Path
DEFAULT_VIEWS=["front_three_quarter_hd","rear_three_quarter_hd","left_profile_hd","right_profile_hd","isometric_ingame"]
def slug(s):
    s=re.sub(r"[^a-zA-Z0-9._-]+","_",s.strip())
    return re.sub(r"_+","_",s).strip("_") or "asset"
def main():
    ap=argparse.ArgumentParser(); ap.add_argument("project",type=Path); ap.add_argument("-o","--output",type=Path); a=ap.parse_args()
    p=json.loads(a.project.read_text(encoding="utf-8")); views=p.get("views") or DEFAULT_VIEWS; items=[]
    for asset in p.get("assets",[]):
        aid=asset["asset_id"]; foundation=None
        for idx,view in enumerate(views):
            jid=f"{slug(aid)}__{slug(view)}"
            item={"job_id":jid,"asset_id":aid,"view":view,"prompt":f"{asset.get('description','')}\nCreate view: {view}. Preserve canonical identity.","reference_images":asset.get("reference_images",[]),"negative_prompt":p.get("negative_prompt",""),"metadata":asset.get("metadata",{}),"depends_on":[],"locked_features":asset.get("locked_features",[]),"allowed_variations":["camera","composition"],"qa_threshold":p.get("qa_threshold",95)}
            if idx==0: foundation=jid
            else: item["depends_on"]=[foundation]
            items.append(item)
    m={"batch_id":p["batch_id"],"output_dir":p.get("output_dir",f"outputs/{p['batch_id']}"),"project_context":p.get("project_context",""),"global_prompt":p.get("global_prompt","Use IRIS MASTER v1.1."),"asset_lock":p.get("asset_lock",""),"qa_prompt":p.get("qa_prompt","Use IRIS PANEL + RED TEAM. Correct all critical/major issues."),"max_retries":p.get("max_retries",2),"sequential":True,"continuity_graph":{},"provenance":p.get("provenance",[]),"items":items}
    out=a.output or a.project.with_name(a.project.stem+"_manifest.json"); out.write_text(json.dumps(m,indent=2),encoding="utf-8"); print(out)
if __name__=="__main__": main()
