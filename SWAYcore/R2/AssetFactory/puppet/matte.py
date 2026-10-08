"""Matte one figure from an upscaled board. usage: matte.py src x0 y0 x1 y1 out.png [model]
Free tools only: rembg (MIT) isnet-anime model; keeps largest connected component."""
import sys, numpy as np, cv2
from PIL import Image
from rembg import remove, new_session
src,x0,y0,x1,y1,out=sys.argv[1],*map(int,sys.argv[2:6]),sys.argv[6]
model=sys.argv[7] if len(sys.argv)>7 else "isnet-anime"
im=Image.open(src).convert("RGB").crop((x0,y0,x1,y1))
rgba=remove(im,session=new_session(model),post_process_mask=True)
a=np.array(rgba)[:,:,3]
n,lab,st,_=cv2.connectedComponentsWithStats((a>40).astype(np.uint8),8)
if n>1:
    k=1+int(np.argmax(st[1:,cv2.CC_STAT_AREA]))
    keep=(lab==k).astype(np.uint8)
    keep=cv2.dilate(keep,np.ones((5,5),np.uint8))
    a=(a*keep).astype(np.uint8)
res=np.dstack([np.array(im),a])
Image.fromarray(res,"RGBA").save(out)
# contact preview on checker
h,w=a.shape;chk=((np.indices((h,w)).sum(0)//32)%2*60+120).astype(np.uint8)
bg=np.dstack([chk]*3).astype(float);al=a[...,None]/255.0
prev=(np.array(im)*al+bg*(1-al)).astype(np.uint8)
Image.fromarray(prev).resize((w*600//h if h>w else 600, 600 if h>w else h*600//w)).save(out.replace(".png","_preview.png"))
print("ok",out,a.shape,int((a>128).sum()))
