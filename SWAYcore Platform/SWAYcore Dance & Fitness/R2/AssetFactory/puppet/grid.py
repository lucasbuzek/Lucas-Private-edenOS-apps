import sys
from PIL import Image, ImageDraw
# usage: grid.py src x0 y0 x1 y1 out [step] [preview_w]
src,x0,y0,x1,y1,out=sys.argv[1],*map(int,sys.argv[2:6]),sys.argv[6]
step=int(sys.argv[7]) if len(sys.argv)>7 else 100
pw=int(sys.argv[8]) if len(sys.argv)>8 else 900
im=Image.open(src).convert("RGB").crop((x0,y0,x1,y1))
s=pw/im.width
im=im.resize((pw,int(im.height*s)),Image.LANCZOS)
d=ImageDraw.Draw(im)
for gx in range(0,x1-x0,step):
    X=gx*s;d.line([(X,0),(X,im.height)],fill=(0,255,255),width=1);d.text((X+2,2),str(gx),fill=(255,255,0))
for gy in range(0,y1-y0,step):
    Y=gy*s;d.line([(0,Y),(im.width,Y)],fill=(0,255,255),width=1);d.text((2,Y+2),str(gy),fill=(255,255,0))
im.save(out)
