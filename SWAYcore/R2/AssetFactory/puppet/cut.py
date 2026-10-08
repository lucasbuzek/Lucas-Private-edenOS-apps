"""Cut a matted view into SWAYHumanoid-v1 puppet parts.
usage: cut.py view.json   (json: {"src": rgba.png, "out": dir, "view": "front", "joints": {...}, "parts": [...]})
Each part: name, bone [proximal, distal], radius (assignment), cap (joint-cap radius), z.
Pixels go to the nearest bone (distance - radius). Head owns everything above the neck line.
Caps: discs at both bone joints, clipped to the silhouette, coloured from the part's own
nearest pixels so rotation never opens a gap. Free tools only (numpy/scipy/Pillow)."""
import json, sys, os, numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi
cfg=json.load(open(sys.argv[1]))
J={k:np.array(v,float) for k,v in cfg["joints"].items()}
im=np.array(Image.open(cfg["src"]).convert("RGBA"))
H,W=im.shape[:2]; alpha=im[...,3].copy()
yy,xx=np.mgrid[0:H,0:W].astype(float)
# despill: board background kept inside enclosed gaps (e.g. arm/waist) -> transparent
bgc=np.median(im[...,:3][alpha<10],axis=0)
dist_bg=np.linalg.norm(im[...,:3].astype(float)-bgc,axis=2)
rgbf=im[...,:3].astype(float)/255;mx=rgbf.max(2);mn=rgbf.min(2);sat=(mx-mn)/np.maximum(mx,1e-6)
bglike=(dist_bg<cfg.get("despill",24))|((sat<0.25)&(mx>0.38)&(mx<0.9)&(dist_bg<90))
# only background-like pixels connected to the outside (flood from transparency)
spill=ndi.binary_propagation(alpha<10,mask=bglike|(alpha<10))&(alpha>=10)
spill&=(yy<cfg.get("despillMaxY",1e9))
for e in cfg.get("erase",[]):
    x0,y0,x1,y1=e["box"];m=(xx>=x0)&(xx<x1)&(yy>=y0)&(yy<y1)&(alpha>=10)
    if e.get("bglike",True): m&=(dist_bg<e.get("dist",110))&(sat<e.get("sat",0.33))
    print("erase",e["box"],int(m.sum()));spill|=m
alpha[spill]=0;im[...,3]=alpha;print("bg",bgc,"despilled",int(spill.sum()))
sil=alpha>100
EDT=ndi.distance_transform_edt(sil)
os.makedirs(cfg['out'],exist_ok=True);Image.fromarray((sil*255).astype(np.uint8)).save(os.path.join(cfg['out'],f"{cfg['prefix']}_{cfg['view']}_sil.png"))
_r,_g,_b=[im[...,i].astype(float) for i in range(3)]
SKIN=(_r>105)&(_r>_g)&(_g>=_b)&((_r-_g)>18)&((_r-_g)<135)&(_g>45)
_k=np.hypot(*np.mgrid[-18:19,-18:19])<=18
SILC=ndi.binary_closing(np.pad(sil,20),structure=_k)[20:-20,20:-20]|sil  # creases filled, outline kept
# cut lines split the silhouette into groups (e.g. arm vs torso along the armhole)
from PIL import ImageDraw as _D
cm=Image.new("L",(W,H),0);_d=_D.Draw(cm)
for line in cfg.get("cuts",[]): _d.line([tuple(p) for p in line],fill=255,width=3)
cutm=np.array(cm)>0
lab,_n=ndi.label(sil&~cutm)
_,(iy0,ix0)=ndi.distance_transform_edt(lab==0,return_indices=True)
lab=lab[iy0,ix0];lab[~sil]=0
def segdist0(a,b):
    a,b=np.array(cfg["joints"][a],float),np.array(cfg["joints"][b],float);d=b-a;L=max((d*d).sum(),1e-6)
    t=np.clip(((xx-a[0])*d[0]+(yy-a[1])*d[1])/L,0,1)
    return np.hypot(xx-(a[0]+t*d[0]),yy-(a[1]+t*d[1]))
group_of={};grpmask={}
for g,spec in cfg.get("groups",{}).items():
    sx,sy=np.array(cfg["joints"][spec["seed"]]).astype(int)
    grpmask[g]=lab==lab[sy,sx]
    for n in spec["parts"]: group_of[n]=g
    if "reach" in spec:  # limit to pixels near the group's own bones
        bones=[pp["bone"] for pp in cfg["parts"] if pp["name"] in spec["parts"]]
        dmin=np.min([segdist0(a,b) for a,b in bones],axis=0)
        grpmask[g]&=dmin<spec["reach"]
    if "skinBelowY" in spec:
        need=(yy>spec["skinBelowY"])&~ndi.binary_dilation(SKIN,iterations=spec.get("outline",4))
        for x0,y0,x1,y1 in spec.get("allow",[]): need&=~((xx>=x0)&(xx<x1)&(yy>=y0)&(yy<y1))
        grpmask[g]&=~need
anygrp=np.zeros((H,W),bool)
for m in grpmask.values(): anygrp|=m
def segdist(a,b):
    a,b=J[a],J[b];d=b-a;L=max((d*d).sum(),1e-6)
    t=np.clip(((xx-a[0])*d[0]+(yy-a[1])*d[1])/L,0,1)
    return np.hypot(xx-(a[0]+t*d[0]),yy-(a[1]+t*d[1]))
parts=cfg["parts"];cost=[]
for p in parts:
    segs=p.get("segs",[p["bone"]])
    c=np.min([segdist(a,b) for a,b in segs],axis=0)-p["radius"]
    g=group_of.get(p["name"])
    c=np.where(grpmask[g],c,1e9) if g else np.where(anygrp,1e9,c)
    cost.append(c)
cost=np.stack(cost)
owner=np.argmin(cost,0)
names=[p["name"] for p in parts]
if "head" in names and "neckY" in cfg:
    hi=names.index("head");above=yy<cfg["neckY"]
    # arms may rise above the neck line in other views; only force pixels near the head column
    near=np.abs(xx-J[parts[hi]["bone"][0]][0])<cfg.get("headHalfWidth",1e9)
    owner[above&near]=hi
for rule in cfg.get("force",[]):  # {"part":name,"box":[x0,y0,x1,y1]}
    x0,y0,x1,y1=rule["box"];m=(xx>=x0)&(xx<x1)&(yy>=y0)&(yy<y1)
    if "onlyFrom" in rule: m&=np.isin(owner,[names.index(n) for n in rule["onlyFrom"]])
    if rule.get("notSkin"): m&=~SKIN
    if rule.get("skin"): m&=SKIN
    owner[m]=names.index(rule["part"])
os.makedirs(cfg["out"],exist_ok=True);rig={"view":cfg["view"],"canvas":[W,H],"joints":cfg["joints"],"parts":[]}
dbg=np.zeros((H,W,3),np.uint8);rng=np.random.default_rng(3);cols=rng.integers(60,255,(len(parts),3))
for i,p in enumerate(parts):
    own=sil&(owner==i)
    if p.get("open") or p.get("main"):
        k=p.get("open",0)
        if k: own=ndi.binary_opening(own,structure=np.hypot(*np.mgrid[-k:k+1,-k:k+1])<=k)
        lab_o,n_o=ndi.label(own)   # keep the main body of the part only
        if n_o>1:
            sz=ndi.sum(own,lab_o,range(1,n_o+1));own=lab_o==(1+int(np.argmax(sz)))
    if own.sum()==0: print("EMPTY",p["name"]);continue
    dbg[own]=cols[i]
    ext=own.copy()
    for jn,r in p.get("caps",[]):   # caps only on the part drawn UNDER at that joint
        if jn not in J: continue
        if isinstance(r,str):        # "auto[+N]": round joint = limb half-width, NOT clipped
            jx,jy=J[jn].astype(int);hw=float(EDT[max(0,jy-12):jy+13,max(0,jx-12):jx+13].max());r=hw+float(r[4:] or 0)
            ext|=(np.hypot(xx-J[jn][0],yy-J[jn][1])<=r)&SILC
        elif r>0:
            ext|=(np.hypot(xx-J[jn][0],yy-J[jn][1])<=r)&sil
    for fr in p.get("fillRows",[]):   # {"y":[y0,y1],"to":x}: span from real outer edge to x
        y0,y1=fr["y"];tx=fr["to"]
        for yv in range(y0,y1):
            xs_=np.nonzero(own[yv])[0]
            if len(xs_)==0: continue
            if tx>xs_.mean(): ext[yv,xs_.min():tx]=True
            else: ext[yv,tx:xs_.max()+1]=True
    for poly in p.get("fillPolys",[]):   # reconstruct outline hidden behind other parts
        pm=Image.new("L",(W,H),0);ImageDraw.Draw(pm).polygon([tuple(q) for q in poly],fill=255)
        ext|=np.array(pm)>0
    # colour ext from nearest own pixel
    src_fill=own&SKIN if (p.get("skinFill") and (own&SKIN).sum()>100) else own
    _,(iy,ix)=ndi.distance_transform_edt(~src_fill,return_indices=True)
    rgb=im[...,:3][iy,ix];rgb[own]=im[...,:3][own]
    a=np.where(own,alpha,0).astype(np.uint8);a[ext&~own]=255
    ys,xs=np.nonzero(a>0);x0,x1,y0,y1=xs.min(),xs.max()+1,ys.min(),ys.max()+1
    pad=2;x0=max(0,x0-pad);y0=max(0,y0-pad);x1=min(W,x1+pad);y1=min(H,y1+pad)
    out=np.dstack([rgb,a])[y0:y1,x0:x1]
    fn=f"{cfg['prefix']}_{cfg['view']}_{p['name']}.png"
    Image.fromarray(out,"RGBA").save(os.path.join(cfg["out"],fn))
    prox=J[p["bone"][0]];dist=J[p["bone"][1]]
    rig["parts"].append({"name":p["name"],"file":fn,"z":p["z"],"bone":p["bone"],
        "origin":[int(x0),int(y0)],"size":[int(x1-x0),int(y1-y0)],
        "pivot":[float(prox[0]-x0),float(prox[1]-y0)],
        "pivotNorm":[float((prox[0]-x0)/(x1-x0)),float((prox[1]-y0)/(y1-y0))],
        "restAngle":float(np.arctan2(dist[1]-prox[1],dist[0]-prox[0])),
        "restLength":float(np.hypot(*(dist-prox)))})
json.dump(rig,open(os.path.join(cfg["out"],f"{cfg['prefix']}_{cfg['view']}_rig.json"),"w"),indent=1)
# debug overlay
d=Image.fromarray((dbg*0.6+im[...,:3]*0.4).astype(np.uint8));dr=ImageDraw.Draw(d)
for p in parts:
    for a,b in p.get("segs",[p["bone"]]): dr.line([tuple(J[a]),tuple(J[b])],fill=(255,255,255),width=4)
for k,v in J.items(): dr.ellipse([v[0]-8,v[1]-8,v[0]+8,v[1]+8],outline=(255,0,0),width=3)
d.save(os.path.join(cfg["out"],f"{cfg['prefix']}_{cfg['view']}_debug.png"))
print("parts",len(rig["parts"]))
