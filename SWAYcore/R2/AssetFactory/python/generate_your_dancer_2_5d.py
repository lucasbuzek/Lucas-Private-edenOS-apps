#!/usr/bin/env python3
"""Build the deterministic YOUR DANCER separated 2.5D component library.

The checked-in PNGs are generated art, not downloaded art.  Geometry is derived
from Build 143's pixel-aligned UserPose masks; every output remains an isolated
transparent layer so the runtime never falls back to a flattened character.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / "App/SWAY/Assets.xcassets"


def source(pose: int, kind: str) -> Image.Image:
    folder = CATALOG / f"UserPose{pose:02d}{kind}.imageset"
    return Image.open(folder / f"UserPose{pose:02d}{kind}.png").convert("RGBA")


def alpha(im: Image.Image) -> Image.Image:
    return im.getchannel("A")


def rgba_mask(mask: Image.Image, rgb=(255, 255, 255)) -> Image.Image:
    out = Image.new("RGBA", mask.size, (*rgb, 0)); out.putalpha(mask); return out


def head_box(mask: Image.Image):
    box = mask.getbbox() or (145, 25, 240, 165)
    x0, y0, x1, y1 = box
    w, h = x1-x0, y1-y0
    # skin contains limbs: the head is around the upper centre of the art frame.
    cx = (x0+x1)//2
    return (cx-max(34,w//5), max(18,y0), cx+max(34,w//5), min(170,y0+max(82,h//3)))


def shape_mask(size, draw_fn):
    m = Image.new("L", size); d = ImageDraw.Draw(m); draw_fn(d); return m


def component(layer: str, option: str, pose: int) -> Image.Image:
    skin, detail, hair, accent = (source(pose, k) for k in ("Skin", "Detail", "Hair", "Accent"))
    sm, dm, hm, am = map(alpha, (skin, detail, hair, accent))
    size = skin.size; hx0,hy0,hx1,hy1 = head_box(sm); cx=(hx0+hx1)//2; cy=(hy0+hy1)//2
    if layer == "body":
        factors={"balanced":1.0,"soft":1.10,"athletic":.92}; f=factors.get(option,1)
        resized=sm.resize((max(1,int(size[0]*f)),size[1]),Image.Resampling.BICUBIC)
        canvas=Image.new("L",size); canvas.paste(resized,((size[0]-resized.width)//2,0)); return rgba_mask(canvas)
    if layer == "face":
        dims={"soft":(1.08,1.03),"oval":(.94,1.08),"angular":(1.02,.96)}.get(option,(1,1))
        m=shape_mask(size,lambda d:d.rounded_rectangle((cx-30*dims[0],hy0+16,cx+30*dims[0],hy0+78*dims[1]),radius=18,fill=255))
        return rgba_mask(ImageChops.multiply(m,sm))
    if layer in ("eyes","brows","nose","mouth","facialHair"):
        m=Image.new("L",size); d=ImageDraw.Draw(m)
        if layer=="eyes":
            r={"bright":5,"classic":4,"wide":7}.get(option,4)
            for x in (cx-12,cx+12): d.ellipse((x-r,cy-11-r//2,x+r,cy-11+r//2),fill=255)
        elif layer=="brows":
            w={"soft":2,"arched":3,"bold":5}.get(option,3)
            d.arc((cx-23,cy-27,cx-3,cy-11),195,335,fill=255,width=w); d.arc((cx+3,cy-27,cx+23,cy-11),205,345,fill=255,width=w)
        elif layer=="nose":
            span={"button":4,"straight":7,"broad":10}.get(option,6); d.arc((cx-span,cy-9,cx+span,cy+15),60,120,fill=255,width=3)
        elif layer=="mouth":
            span={"smile":11,"soft":8,"grin":15}.get(option,10); d.arc((cx-span,cy+5,cx+span,cy+22),10,170,fill=255,width=4)
        elif option != "none":
            if option in ("stubble","beard"): d.rounded_rectangle((cx-25,cy+3,cx+25,hy1-6),radius=15,fill=130 if option=="stubble" else 255)
            if option in ("moustache","beard"): d.polygon((cx-22,cy+7,cx,cy+14,cx+22,cy+7,cx,cy+24),fill=255)
        if layer == "facialHair" and option == "none": m.putpixel((0, 0), 1)
        return rgba_mask(m,(46,30,37))
    if layer in ("hairBack","hairFront"):
        m=hm.filter(ImageFilter.MaxFilter({"short":5,"long":15,"braids":9,"afro":25,"bun":11}.get(option,7)|1))
        d=ImageDraw.Draw(m)
        if option=="long": d.rounded_rectangle((hx0-8,hy0+18,hx1+8,hy1+54),radius=18,fill=230)
        elif option=="braids":
            for x in range(hx0-4,hx1+5,11): d.rounded_rectangle((x,hy0+30,x+5,hy1+48),radius=3,fill=255)
        elif option=="afro": d.ellipse((hx0-20,hy0-18,hx1+20,hy1-12),fill=255)
        elif option=="bun": d.ellipse((cx-21,hy0-24,cx+21,hy0+16),fill=255)
        # split behind/front at face centre; masks remain separate assets.
        split=Image.new("L",size); sd=ImageDraw.Draw(split)
        sd.rectangle((0,0,size[0],cy+8 if layer=="hairBack" else size[1]),fill=255)
        if layer=="hairFront": sd.rectangle((0,0,size[0],hy0+25),fill=0)
        return rgba_mask(ImageChops.multiply(m,split))
    if layer in ("outfitTop","outfitBottom"):
        m=ImageChops.lighter(dm,am); crop=Image.new("L",size); d=ImageDraw.Draw(crop)
        if layer=="outfitTop": d.rectangle((0,hy1-20,size[0],250),fill=255)
        else: d.rectangle((0,225,size[0],size[1]),fill=255)
        variants={"studio":0,"power":1,"classic":2,"bright":3,"sport":4}; inset=variants.get(option,0)
        m=ImageChops.multiply(m,crop).filter(ImageFilter.MaxFilter(3+2*(inset%3)))
        return rgba_mask(m)
    if layer == "footwear":
        m=ImageChops.lighter(dm,am); crop=Image.new("L",size); ImageDraw.Draw(crop).rectangle((0,330,size[0],size[1]),fill=255)
        m=ImageChops.multiply(m,crop)
        if option=="barefoot":
            # Bare feet expose the skin component at the shoe anchors.
            return rgba_mask(m)
        m=m.filter(ImageFilter.MaxFilter({"trainer":3,"highTop":9,"dance":5}.get(option,3)))
        if option == "none": m.putpixel((0, 0), 1)  # transparent-in-practice, non-corrupt mask sentinel
        return rgba_mask(m,(255,255,255))
    if layer == "accessory":
        m=Image.new("L",size); d=ImageDraw.Draw(m)
        if option=="cap": d.pieslice((hx0-9,hy0-22,hx1+9,hy0+38),180,360,fill=255); d.ellipse((cx,hy0+5,hx1+24,hy0+16),fill=255)
        elif option=="headband": d.rounded_rectangle((hx0-6,hy0+13,hx1+6,hy0+24),radius=5,fill=255)
        elif option=="wristbands": d.ellipse((hx0-42,200,hx0-22,217),fill=255); d.ellipse((hx1+22,200,hx1+42,217),fill=255)
        elif option=="gloves": d.ellipse((hx0-50,205,hx0-18,237),fill=255); d.ellipse((hx1+18,205,hx1+50,237),fill=255)
        elif option=="glasses": d.rounded_rectangle((cx-29,cy-20,cx-3,cy-2),radius=6,outline=255,width=4); d.rounded_rectangle((cx+3,cy-20,cx+29,cy-2),radius=6,outline=255,width=4); d.line((cx-3,cy-12,cx+3,cy-12),fill=255,width=3)
        return rgba_mask(m,(255,255,255))
    raise ValueError(f"unsupported layer {layer}")


def main():
    p=argparse.ArgumentParser(); p.add_argument("--manifest",type=Path,default=ROOT/"AssetFactory/data/your_dancer_2_5d_components.json"); p.add_argument("--catalog",type=Path,default=CATALOG); a=p.parse_args()
    data=json.loads(a.manifest.read_text())
    for layer in data["layers"]:
        for opt in layer["options"]:
            for pose in range(1,data["poseCount"]+1):
                name=f"YD2D_{layer['id']}_{opt['id']}_P{pose:02d}"; folder=a.catalog/f"{name}.imageset"; folder.mkdir(parents=True,exist_ok=True)
                component(layer["id"],opt["id"],pose).save(folder/f"{name}.png",optimize=True)
                (folder/"Contents.json").write_text(json.dumps({"images":[{"filename":f"{name}.png","idiom":"universal","scale":"1x"}],"info":{"author":"xcode","version":1}},indent=2)+"\n")
    print(f"generated {sum(len(x['options']) for x in data['layers'])*data['poseCount']} separated assets")
if __name__ == "__main__": main()
