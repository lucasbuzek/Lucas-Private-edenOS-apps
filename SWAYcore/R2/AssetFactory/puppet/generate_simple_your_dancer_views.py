#!/usr/bin/env python3
"""Original YOUR DANCER 2.5D back/profile attachments from one coherent skin.

Reuses generate_simple_your_dancer art and SWAYHumanoid rig metadata; remaps
each part's bone-aligned art instead of cutting or duplicating another coach.
"""
from pathlib import Path
import importlib.util, json, math
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[2]
STAGE=ROOT/"App/SWAY/Resources/Puppets/YourDancerRig"
FACTORY=ROOT/"AssetFactory/puppet/generate_simple_your_dancer.py"
spec=importlib.util.spec_from_file_location("sway_neutral_front",FACTORY)
front=importlib.util.module_from_spec(spec)
spec.loader.exec_module(front)

FRONT=json.loads((STAGE/"yourDancer_front_rig.json").read_text())
SRC={p["name"]:p for p in FRONT["parts"]}
J0=FRONT["joints"]
W,H=280,1400

def custom_head(view):
    # Author a real rear hairstyle and 3/4-friendly side silhouette.
    # Same hair identity and skin tones as front; no face printed on back.
    canvas=Image.new("RGBA",(720,2800))
    d=ImageDraw.Draw(canvas)
    el=lambda b,c:d.ellipse(tuple(round(q*2) for q in b),fill=c)
    line=lambda points,c,w=2:d.line([(round(x*2),round(y*2)) for x,y in points],fill=c,width=w*2)
    cap=front.capsule
    if view=="back":
        cap(d,(180,434),(180,397),26,28,front.SKIN)
        el((98,147,262,423),front.HAIR)
        el((105,154,255,397),front.HAIR_LIT)
        el((110,174,250,417),front.HAIR)
        for x,y,r in [(119,161,30),(150,130,37),(184,120,36),(216,135,37),
                      (242,164,28),(115,221,26),(245,224,26),(139,277,29),
                      (179,290,34),(222,279,29),(149,359,29),(202,356,28)]:
            el((x-r,y-r,x+r,y+r),front.HAIR if y%2 else front.HAIR_LIT)
        line([(149,385),(167,408),(189,408),(210,388)],front.HAIR_LIT,4)
    else:
        # Profile faces right; ear, brow, nose and lips visible at side heading.
        cap(d,(180,437),(180,391),25,27,front.SKIN)
        el((110,162,260,418),front.SKIN_SHADOW)
        el((116,165,258,410),front.SKIN)
        el((139,207,261,370),front.SKIN_HI)
        d.polygon([(round(x*2),round(y*2)) for x,y in [(246,307),(278,330),(257,340),
                   (262,358),(244,381),(211,405),(174,410),(150,379)]],fill=front.SKIN)
        el((137,297,166,327),front.SKIN_SHADOW)
        el((142,299,163,321),front.SKIN)
        el((222,300,235,309),"#fdf9f5")
        el((228,300,234,312),front.HAIR)
        line([(219,290),(239,288)],front.HAIR,3)
        line([(241,373),(254,376),(246,383)],"#8d4551",3)
        el((101,129,242,274),front.HAIR)
        for x,y,r in [(117,158,33),(140,135,37),(177,120,38),(212,136,35),
                      (226,175,31),(113,211,29),(141,247,30)]:
            el((x-r,y-r,x+r,y+r),front.HAIR if y%2 else front.HAIR_LIT)
    return canvas.resize((360,1400),Image.Resampling.LANCZOS)

def map_bone_image(image,source_a,source_b,target_a,target_b,width_factor):
    sv=(source_b[0]-source_a[0],source_b[1]-source_a[1])
    tv=(target_b[0]-target_a[0],target_b[1]-target_a[1])
    ls=max(1.0,math.hypot(*sv));lt=max(1.0,math.hypot(*tv))
    us=(sv[0]/ls,sv[1]/ls);ut=(tv[0]/lt,tv[1]/lt)
    ns=(-us[1],us[0]);nt=(-ut[1],ut[0])
    along=ls/lt;perp=1.0/width_factor
    b00=along*us[0]*ut[0]+perp*ns[0]*nt[0]
    b01=along*us[0]*ut[1]+perp*ns[0]*nt[1]
    b10=along*us[1]*ut[0]+perp*ns[1]*nt[0]
    b11=along*us[1]*ut[1]+perp*ns[1]*nt[1]
    bx=source_a[0]-b00*target_a[0]-b01*target_a[1]
    by=source_a[1]-b10*target_a[0]-b11*target_a[1]
    return image.transform((W,H),Image.Transform.AFFINE,
                           (b00,b01,bx,b10,b11,by),resample=Image.Resampling.BICUBIC)

def make(view):
    path=STAGE/f"yourDancer_{view}_rig.json"
    rig=json.loads(path.read_text())
    assert rig["view"]==view and rig["canvas"]==[280,1400]
    j=rig["joints"]
    if view=="back":
        for key,x in {"RightHand":20,"RightHandTip":15,"LeftHand":259,"LeftHandTip":264}.items():
            j[key][0]=x
    else:
        for key,x in {"RightLowerArm":90,"RightHand":73,"RightHandTip":68,
                      "LeftUpperArm":190,"LeftLowerArm":207,"LeftHand":230,"LeftHandTip":238}.items():
            j[key][0]=x
    for p in rig["parts"]:
        name=p["name"]
        art=custom_head(view) if name=="head" else front.art(name,J0)
        bone=p["bone"];s0=J0[bone[0]];s1=J0[bone[1]]
        t0=j[bone[0]];t1=j[bone[1]]
        width_factor=(0.8 if view=="back" else (0.66 if name in ("chest","pelvis") else 0.72))
        mapped=map_bone_image(art,s0,s1,t0,t1,width_factor)
        bbox=mapped.getbbox()
        if bbox is None:raise ValueError((view,name,"empty"))
        x0=max(0,min(bbox[0]-2,int(t0[0])))
        x1=min(W,max(bbox[2]+2,int(t0[0])+1))
        y0=max(0,min(bbox[1]-2,int(t0[1])))
        y1=min(H,max(bbox[3]+2,int(t0[1])+1))
        part=mapped.crop((x0,y0,x1,y1))
        part.save(STAGE/p["file"],optimize=True)
        p["origin"]=[x0,y0]
        p["pivot"]=[float(t0[0]-x0),float(t0[1]-y0)]
        p["size"]=[x1-x0,y1-y0]
        p["pivotNorm"]=[(t0[0]-x0)/(x1-x0),(t0[1]-y0)/(y1-y0)]
        p["restAngle"]=math.atan2(t1[1]-t0[1],t1[0]-t0[0])
        p["restLength"]=math.hypot(t1[0]-t0[0],t1[1]-t0[1])
    path.write_text(json.dumps(rig,indent=2)+"\n")
    print("ORIGINAL_NEUTRAL_"+view.upper()+"_GENERATED",len(rig["parts"]))

if __name__=="__main__":
    make("back")
    make("side")
