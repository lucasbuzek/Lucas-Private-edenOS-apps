#!/usr/bin/env python3
"""Build one ORIGINAL neutral YOUR DANCER front puppet, using the existing joint contract.

Scope: one front-facing test character, never replace other views/characters.
Stylized art is composited from physically overlapping shapes, not crops of Kyle.
The generator is deterministic and uses Pillow (an existing, provenance-recorded tool).
"""
from __future__ import annotations
import json, math
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "App/SWAY/Resources/Puppets/YourDancerRig"
RIG_FILE = DEST / "yourDancer_front_rig.json"
S = 2
CANVAS = (360, 1400)
SKIN = "#b87958"
SKIN_HI = "#d79b75"
SKIN_SHADOW = "#8f553d"
HAIR = "#292334"
HAIR_LIT = "#51405c"
TOP = "#13a9a0"
TOP_HI = "#40c7b6"
TOP_DARK = "#096c72"
PANTS = "#37394e"
PANTS_HI = "#5a607a"
SHOE = "#f3eee6"
SOLE = "#84899d"

def pt(v):
    return tuple(int(round(x*S)) for x in v)

def box(v):
    return tuple(int(round(x*S)) for x in v)

def ellipse(draw, rect, color):
    draw.ellipse(box(rect), fill=color)

def poly(draw, coords, color):
    draw.polygon([pt(x) for x in coords], fill=color)

def line(draw, coords, color, width=2):
    draw.line([pt(x) for x in coords], fill=color, width=max(1,int(width*S)), joint="curve")

def capsule(draw, a, b, ra, rb, color):
    vx,vy=b[0]-a[0],b[1]-a[1]
    ln=max(1,math.hypot(vx,vy))
    nx,ny=-vy/ln,vx/ln
    poly(draw,[(a[0]+nx*ra,a[1]+ny*ra),
               (b[0]+nx*rb,b[1]+ny*rb),
               (b[0]-nx*rb,b[1]-ny*rb),
               (a[0]-nx*ra,a[1]-ny*ra)],color)
    ellipse(draw,(a[0]-ra,a[1]-ra,a[0]+ra,a[1]+ra),color)
    ellipse(draw,(b[0]-rb,b[1]-rb,b[0]+rb,b[1]+rb),color)

def shaded_capsule(draw,a,b,ra,rb,base,highlight,shadow):
    capsule(draw,a,b,ra+1.5,rb+1.5,shadow)
    capsule(draw,a,b,ra,rb,base)
    delta=(-ra*0.32,-rb*0.32)
    capsule(draw,(a[0]+delta[0],a[1]),(b[0]+delta[1],b[1]),
            ra*.34,rb*.34,highlight)

def art(name,j):
    canvas=Image.new("RGBA",(CANVAS[0]*S,CANVAS[1]*S))
    d=ImageDraw.Draw(canvas)
    a=lambda key: tuple(j[key])
    if name=="head":
        # Neck, ears, face, distinctive dark curly hair and expressive details.
        capsule(d,(180,431),(180,389),29,30,SKIN_SHADOW)
        capsule(d,(180,429),(180,390),25,29,SKIN)
        ellipse(d,(90,268,120,325),SKIN_SHADOW)
        ellipse(d,(240,268,270,325),SKIN_SHADOW)
        ellipse(d,(98,146,262,414),SKIN_SHADOW)
        ellipse(d,(104,148,256,407),SKIN)
        ellipse(d,(120,154,246,362),SKIN_HI)
        ellipse(d,(98,130,262,281),HAIR)
        ellipse(d,(106,178,129,297),HAIR)
        ellipse(d,(231,176,253,283),HAIR)
        # Curl silhouettes, unlike Kyle's cap/hair.
        for cx,cy,r in [(117,163,31),(145,132,38),(181,121,38),(218,131,37),(242,162,28),
                        (110,211,26),(246,206,24),(138,161,28),(204,162,30)]:
            ellipse(d,(cx-r,cy-r,cx+r,cy+r),HAIR if cy%2 else HAIR_LIT)
        ellipse(d,(133,275,158,284),HAIR)
        ellipse(d,(203,275,228,284),HAIR)
        ellipse(d,(137,292,157,304),"#fff9ee")
        ellipse(d,(204,292,224,304),"#fff9ee")
        ellipse(d,(145,292,155,306),"#302f38")
        ellipse(d,(209,292,219,306),"#302f38")
        ellipse(d,(150,294,153,298),"#ffffff")
        ellipse(d,(214,294,217,298),"#ffffff")
        line(d,[(179,307),(174,336),(185,338)],SKIN_SHADOW,2)
        line(d,[(159,364),(172,370),(184,370),(199,363)],"#8d4551",3)
        ellipse(d,(123,342,141,351),"#cb866d")
        ellipse(d,(218,342,236,351),"#cb866d")
    elif name=="chest":
        # Wide collar bone and socket cover all upper-arm pivots.
        poly(d,[(133,439),(227,439),(282,466),(307,521),(266,572),
                (264,716),(244,781),(116,781),(96,718),(94,572),(53,520),(77,471)],TOP_DARK)
        poly(d,[(131,445),(229,445),(280,475),(299,517),(257,552),
                (252,716),(233,776),(127,776),(108,716),(103,552),(61,517),(80,475)],TOP)
        poly(d,[(119,502),(147,468),(180,484),(212,468),(241,502),
                (222,524),(138,524)],TOP_HI)
        poly(d,[(148,439),(213,439),(205,464),(180,479),(155,464)],SKIN_SHADOW)
        poly(d,[(153,441),(207,441),(200,456),(180,468),(160,456)],SKIN)
        line(d,[(127,549),(115,708),(130,751)],TOP_HI,4)
        line(d,[(238,551),(247,700),(235,754)],TOP_DARK,5)
        line(d,[(129,742),(231,742)],TOP_DARK,3)
    elif name=="pelvis":
        poly(d,[(116,744),(243,744),(263,805),(258,878),(216,903),
                (182,879),(143,902),(100,873),(100,802)],"#292c42")
        poly(d,[(123,750),(238,750),(251,808),(245,874),(213,892),
                (181,866),(149,890),(112,867),(111,803)],PANTS)
        line(d,[(178,813),(181,873)],PANTS_HI,4)
        line(d,[(120,770),(238,770)],"#25283b",8)
        ellipse(d,(174,763,186,777),SOLE)
    elif name.endswith("UpperArm"):
        right=name.startswith("right")
        p=a("RightUpperArm" if right else "LeftUpperArm")
        q=a("RightLowerArm" if right else "LeftLowerArm")
        shaded_capsule(d,p,q,39,34,SKIN,SKIN_HI,SKIN_SHADOW)
        mid=(p[0]+(q[0]-p[0])*.25,p[1]+(q[1]-p[1])*.25)
        capsule(d,p,mid,42,39,TOP_DARK)
        capsule(d,p,mid,38,35,TOP)
        line(d,[(p[0]-22,mid[1]+10),(p[0]+22,mid[1]+12)],TOP_HI,3)
    elif name.endswith("LowerArm"):
        right=name.startswith("right")
        p=a("RightLowerArm" if right else "LeftLowerArm")
        q=a("RightHand" if right else "LeftHand")
        shaded_capsule(d,p,q,36,27,SKIN,SKIN_HI,SKIN_SHADOW)
        capsule(d,(q[0],q[1]-12),q,30,29,TOP_DARK)
        capsule(d,(q[0],q[1]-10),(q[0],q[1]-2),27,27,TOP)
    elif name.endswith("Hand"):
        right=name.startswith("right")
        p=a("RightHand" if right else "LeftHand")
        q=a("RightHandTip" if right else "LeftHandTip")
        shaded_capsule(d,p,(q[0],q[1]-14),27,23,SKIN,SKIN_HI,SKIN_SHADOW)
        for off in (-17,-6,6,17):
            capsule(d,(q[0]+off,q[1]-38),(q[0]+off,q[1]),6,5,SKIN)
        capsule(d,(p[0]+(-21 if right else 21),p[1]+18),
                (p[0]+(-37 if right else 37),p[1]+48),11,8,SKIN_HI)
    elif name.endswith("Thigh"):
        right=name.startswith("right")
        p=a("RightUpperLeg" if right else "LeftUpperLeg")
        q=a("RightLowerLeg" if right else "LeftLowerLeg")
        shaded_capsule(d,p,q,49,39,PANTS,PANTS_HI,"#22283c")
        line(d,[(p[0]-27,p[1]+51),(q[0]-22,q[1]-24)],PANTS_HI,4)
    elif name.endswith("Calf"):
        right=name.startswith("right")
        p=a("RightLowerLeg" if right else "LeftLowerLeg")
        q=a("RightFoot" if right else "LeftFoot")
        shaded_capsule(d,p,q,40,30,PANTS,PANTS_HI,"#22283c")
        capsule(d,(q[0],q[1]-30),q,32,31,"#e2dcd5")
        line(d,[(q[0]-29,q[1]-21),(q[0]+29,q[1]-21)],SOLE,3)
    elif name.endswith("Shoe"):
        right=name.startswith("right")
        p=a("RightFoot" if right else "LeftFoot")
        q=a("RightToe" if right else "LeftToe")
        capsule(d,p,q,36,38,SOLE)
        capsule(d,p,q,33,35,SHOE)
        line(d,[(p[0]-17,p[1]-4),(p[0]+20,p[1]-4)],"#8ca7b7",4)
        line(d,[(q[0]-22,q[1]+13),(q[0]+20,q[1]+13)],TOP_DARK,3)
    else:
        raise ValueError(name)
    return canvas.resize(CANVAS,Image.Resampling.LANCZOS)

def run():
    rig=json.loads(RIG_FILE.read_text())
    assert rig["view"]=="front" and rig["canvas"]==[360,1400]
    assert len(rig["parts"])==15
    joints=rig["joints"]
    # Hands hang clear of the waist; avoid unnatural forearm-to-hip contact
    # that seals the intentional open space between torso and hanging arms.
    for joint,x in {"RightHand":26,"RightHandTip":20,"LeftHand":334,"LeftHandTip":340}.items():
        joints[joint][0]=x
    for p in rig["parts"]:
        name=p["name"]
        painted=art(name,joints)
        bbox=painted.getbbox()
        if bbox is None:
            raise ValueError(f"empty component: {name}")
        prox=joints[p["bone"][0]]
        # The anatomical joint may be outside the visible part; keep pivot in bounds.
        x0=max(0,min(bbox[0]-2,int(prox[0])))
        y0=max(0,min(bbox[1]-2,int(prox[1])))
        x1=min(CANVAS[0],max(bbox[2]+2,int(prox[0])+1))
        y1=min(CANVAS[1],max(bbox[3]+2,int(prox[1])+1))
        result=painted.crop((x0,y0,x1,y1))
        result.save(DEST/p["file"],optimize=True)
        p["origin"]=[x0,y0]
        p["pivot"]=[float(prox[0]-x0),float(prox[1]-y0)]
        p["size"]=[x1-x0,y1-y0]
        p["pivotNorm"]=[(prox[0]-x0)/(x1-x0),(prox[1]-y0)/(y1-y0)]
        dist=joints[p["bone"][1]]
        p["restAngle"]=math.atan2(dist[1]-prox[1],dist[0]-prox[0])
        p["restLength"]=math.hypot(dist[0]-prox[0],dist[1]-prox[1])
    RIG_FILE.write_text(json.dumps(rig,indent=2)+"\n")
    print("ORIGINAL_NEUTRAL_FRONT_GENERATED",len(rig["parts"]),DEST)

if __name__=="__main__":
    run()
