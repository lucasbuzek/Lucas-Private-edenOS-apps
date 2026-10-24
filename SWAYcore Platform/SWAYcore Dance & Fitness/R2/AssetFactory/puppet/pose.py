"""Reference compositor for SWAY cut-out puppets (same math the Swift renderer uses).
usage: pose.py rig.json out.png  -> contact sheet of test poses.
Part placement: pivot -> target proximal joint; rotation = target bone angle - rest angle;
uniform scale only (no stretching). Terminal parts without a target distal joint inherit
their parent's rotation (hands follow forearms, head follows chest) or stay at rest (shoes)."""
import json, sys, math, os
from PIL import Image, ImageDraw
rig=json.load(open(sys.argv[1]));base=os.path.dirname(sys.argv[1])
R={k:tuple(v) for k,v in rig["joints"].items()}
PARENT={"Spine":"Hips","Neck":"Spine","HeadTop":"Neck",
 "RightUpperArm":"Spine","RightLowerArm":"RightUpperArm","RightHand":"RightLowerArm","RightHandTip":"RightHand",
 "LeftUpperArm":"Spine","LeftLowerArm":"LeftUpperArm","LeftHand":"LeftLowerArm","LeftHandTip":"LeftHand",
 "RightUpperLeg":"Hips","RightLowerLeg":"RightUpperLeg","RightFoot":"RightLowerLeg","RightToe":"RightFoot",
 "LeftUpperLeg":"Hips","LeftLowerLeg":"LeftUpperLeg","LeftFoot":"LeftLowerLeg","LeftToe":"LeftFoot"}
INHERIT={"head":"chest","rightHand":"rightLowerArm","leftHand":"leftLowerArm"}
def chain(j):
    out=[]
    while j in PARENT: j=PARENT[j];out.append(j)
    return out
def fk(deltas,offset=(0,0)):
    """deltas: joint -> degrees (screen clockwise) applied at that joint to its descendants."""
    P={"Hips":R["Hips"]}
    def place(j,acc):
        for c,p in PARENT.items():
            if p!=j: continue
            a=acc+math.radians(deltas.get(j,0))  # rotation at joint j moves child c
            vx,vy=R[c][0]-R[j][0],R[c][1]-R[j][1]
            ca,sa=math.cos(a),math.sin(a)
            P[c]=(P[j][0]+ca*vx-sa*vy,P[j][1]+sa*vx+ca*vy)
            place(c,a)
    place("Hips",0.0)
    return {k:(v[0]+offset[0],v[1]+offset[1]) for k,v in P.items()}
def angle(a,b): return math.atan2(b[1]-a[1],b[0]-a[0])
def render(T,size,scale=1.0,mirror=False,show_joints=False):
    W,H=size;canvas=Image.new("RGBA",(W,H),(0,0,0,0));rot={}
    parts=sorted(rig["parts"],key=lambda p:p["z"])
    for p in rig["parts"]:
        a,b=p["bone"]
        if a in T and b in T: rot[p["name"]]=angle(T[a],T[b])-p["restAngle"]
    for p in rig["parts"]:
        if p["name"] not in rot: rot[p["name"]]=rot.get(INHERIT.get(p["name"],""),0.0)
    for p in parts:
        img=Image.open(os.path.join(base,p["file"])).convert("RGBA")
        d=rot[p["name"]];c,s=math.cos(d),math.sin(d)
        tx,ty=T[p["bone"][0]];px,py=p["pivot"]
        A=(c/scale,s/scale,px-(c*tx+s*ty)/scale,-s/scale,c/scale,py-(-s*tx+c*ty)/scale)
        canvas.alpha_composite(img.transform((W,H),Image.AFFINE,A,resample=Image.BICUBIC))
    if show_joints:
        dr=ImageDraw.Draw(canvas)
        for v in T.values(): dr.ellipse([v[0]-5,v[1]-5,v[0]+5,v[1]+5],fill=(255,0,0,255))
    if mirror: canvas=canvas.transpose(Image.FLIP_LEFT_RIGHT)
    return canvas
POSES={
 "rest":{},
 "arms out":{"RightUpperArm":75,"LeftUpperArm":-75},
 "arms up":{"RightUpperArm":150,"LeftUpperArm":-150,"RightLowerArm":10,"LeftLowerArm":-10},
 "point+knee":{"Spine":-8,"Neck":6,"RightUpperArm":160,"LeftUpperArm":-40,"LeftLowerArm":-100,
               "LeftUpperLeg":-75,"LeftLowerLeg":95},
 "squat":{"RightUpperLeg":50,"LeftUpperLeg":-50,"RightLowerLeg":-75,"LeftLowerLeg":75,
          "RightUpperArm":60,"LeftUpperArm":-60,"RightLowerArm":-80,"LeftLowerArm":80},
 "lean+hip":{"Hips":0,"Spine":14,"Neck":-10,"RightUpperArm":30,"RightLowerArm":60,"LeftUpperArm":-110,
             "LeftUpperLeg":-15,"RightUpperLeg":10},
}
if __name__=="__main__":
    W,H=rig["canvas"];cell=(W+200,H+200);tiles=[]
    for name,dl in POSES.items():
        if rig.get('view')=='back': dl={k:-v for k,v in dl.items()}
        T=fk(dl,(100,100+(220 if name=="squat" else 0)))
        bg=Image.new("RGBA",cell,(236,232,226,255));bg.alpha_composite(render(T,cell))
        ImageDraw.Draw(bg).text((12,12),name,fill=(0,0,0,255))
        tiles.append(bg)
    sheet=Image.new("RGBA",(cell[0]*len(tiles),cell[1]),(255,255,255,255))
    for i,t in enumerate(tiles): sheet.paste(t,(i*cell[0],0))
    sheet.convert("RGB").resize((sheet.width*700//sheet.height,700),Image.LANCZOS).save(sys.argv[2])
    print("ok",sys.argv[2])
