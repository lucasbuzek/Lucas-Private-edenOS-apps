#!/usr/bin/env python3
"""Build a deterministic SWAY 2.5D avatar contract from Lucia PNG masters.
No third-party Python modules required. Reads PNG IHDR only; emits weighted grid meshes.
This is an engineering Alpha asset compiler, not final art acceptance.
"""
import json, struct, sys, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/'ProductionAssets'/'Lucia'
OUT=ROOT/'SWAY'/'Resources'/'Avatars'/'Lucia2_5D'
OUT.mkdir(parents=True,exist_ok=True)
parts=['hairBack','torso','pelvis','leftUpperArm','leftLowerArm','leftHand','rightUpperArm','rightLowerArm','rightHand','leftThigh','leftCalf','leftShoe','rightThigh','rightCalf','rightShoe','head','hairFront']
# SWAY 2D Humanoid v1: semantic bones, renderer-independent move IDs.
bones=[
 ('root',-1,(0.50,0.80)),('hips',0,(0.50,0.62)),('spine',1,(0.50,0.50)),('chest',2,(0.50,0.36)),('neck',3,(0.50,0.25)),('head',4,(0.50,0.16)),
 ('leftShoulder',3,(0.40,0.35)),('leftUpperArm',6,(0.33,0.43)),('leftLowerArm',7,(0.27,0.54)),('leftHand',8,(0.23,0.64)),
 ('rightShoulder',3,(0.60,0.35)),('rightUpperArm',10,(0.67,0.43)),('rightLowerArm',11,(0.73,0.54)),('rightHand',12,(0.77,0.64)),
 ('leftUpperLeg',1,(0.45,0.68)),('leftLowerLeg',14,(0.43,0.82)),('leftFoot',15,(0.42,0.96)),
 ('rightUpperLeg',1,(0.55,0.68)),('rightLowerLeg',17,(0.57,0.82)),('rightFoot',18,(0.58,0.96))]
part_bones={
 'hairBack':['head','neck'],'head':['head','neck'],'hairFront':['head','neck'],'torso':['chest','spine','hips'],'pelvis':['hips','spine'],
 'leftUpperArm':['leftShoulder','leftUpperArm'],'leftLowerArm':['leftUpperArm','leftLowerArm'],'leftHand':['leftLowerArm','leftHand'],
 'rightUpperArm':['rightShoulder','rightUpperArm'],'rightLowerArm':['rightUpperArm','rightLowerArm'],'rightHand':['rightLowerArm','rightHand'],
 'leftThigh':['hips','leftUpperLeg'],'leftCalf':['leftUpperLeg','leftLowerLeg'],'leftShoe':['leftLowerLeg','leftFoot'],
 'rightThigh':['hips','rightUpperLeg'],'rightCalf':['rightUpperLeg','rightLowerLeg'],'rightShoe':['rightLowerLeg','rightFoot']}
def png_size(p):
 b=p.read_bytes()[:24]
 if b[:8]!=b'\x89PNG\r\n\x1a\n': raise ValueError(f'not PNG: {p}')
 return struct.unpack('>II',b[16:24])
def mesh(part,w,h,cols=6,rows=10):
 names=part_bones[part]; verts=[]; indices=[]
 for y in range(rows+1):
  t=y/rows
  for x in range(cols+1):
   u=x/cols
   # Smooth two-bone blend along long axis; torso gets a 3-bone gradient.
   if len(names)==2: weights=[1-t,t]
   else:
    weights=[max(0,1-2*t),1-abs(2*t-1),max(0,2*t-1)]; s=sum(weights); weights=[v/s for v in weights]
   verts.append({'position':[u*w,t*h],'uv':[u,t],'bones':names,'weights':[round(v,6) for v in weights]})
 for y in range(rows):
  for x in range(cols):
   a=y*(cols+1)+x;b=a+1;c=a+(cols+1);d=c+1
   indices += [a,c,b,b,c,d]
 return {'texture':f'lucia_{part}.png','pixelSize':[w,h],'vertices':verts,'indices':indices,'drawLayer':parts.index(part)}
meshes={}
missing=[]
for p in parts:
 f=SRC/f'lucia_{p}.png'
 if not f.exists(): missing.append(str(f)); continue
 w,h=png_size(f); meshes[p]=mesh(p,w,h)
if missing: raise SystemExit('Missing: '+', '.join(missing))
contract={'format':'swayavatar','version':1,'renderProfile':'skeletal2d','characterID':'lucia','skeleton':{'id':'SWAY2DHumanoid-v1','bones':[{'name':n,'parent':par,'rest':list(rest)} for n,par,rest in bones]},'meshes':meshes,'animationContract':{'clock':'SWAYMusicalClock','moves':['idle','march','step_touch','grapevine','knee_lift','squat','side_lunge','jumping_jack','body_roll','pivot_turn']},'status':'ENGINEERING_ALPHA'}
(OUT/'lucia.swayavatar.json').write_text(json.dumps(contract,indent=2))
# Package source textures + contract for deterministic inspection/import.
with zipfile.ZipFile(OUT/'LuciaAlpha.swayavatar','w',zipfile.ZIP_DEFLATED) as z:
 z.write(OUT/'lucia.swayavatar.json','character.json')
 for p in parts: z.write(SRC/f'lucia_{p}.png',f'textures/lucia_{p}.png')
print(f'PASS: {len(bones)} bones, {len(meshes)} weighted meshes -> {OUT}/LuciaAlpha.swayavatar')
