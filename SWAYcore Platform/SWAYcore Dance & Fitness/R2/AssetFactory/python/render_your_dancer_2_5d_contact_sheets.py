#!/usr/bin/env python3
"""Render exhaustive option/pose and deterministic combination review sheets."""
from __future__ import annotations
import argparse, json, random
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[2]

def tint(im, color):
    c=color.lstrip('#'); rgb=tuple(int(c[i:i+2],16) for i in (0,2,4))
    out=Image.new('RGBA',im.size,(*rgb,0)); out.putalpha(im.getchannel('A')); return out

def load(cat,name): return Image.open(cat/f'{name}.imageset'/f'{name}.png').convert('RGBA')

def compose(cat, layers, pose, choices, palettes):
    first=layers[0]; first_name=f"YD2D_{first['options'][0]['assetStem']}_P{pose:02d}"
    canvas=Image.new('RGBA',load(cat,first_name).size); defaults={'skin':'#B86D50','hair':'#31201C','outfit':'#7C5CFF','accent':'#42D9C8'}
    for layer in sorted(layers,key=lambda x:x['drawOrder']):
        opt=choices[layer['id']]; name=f"YD2D_{layer['id']}_{opt}_P{pose:02d}"; im=load(cat,name)
        role=layer.get('tintRole'); color=defaults.get(role or '')
        if color: im=tint(im,color)
        canvas.alpha_composite(im)
    return canvas

def sheet(cells, labels, cols=6):
    cw,ch=210,240; rows=(len(cells)+cols-1)//cols
    out=Image.new('RGB',(cols*cw,rows*ch),(24,20,35)); d=ImageDraw.Draw(out)
    for i,(im,label) in enumerate(zip(cells,labels)):
        thumb=im.copy(); thumb.thumbnail((190,205),Image.Resampling.LANCZOS); x=(i%cols)*cw+(cw-thumb.width)//2; y=(i//cols)*ch
        out.paste(thumb,(x,y),thumb); d.text(((i%cols)*cw+7,y+210),label,fill=(245,242,255))
    return out

def main():
    p=argparse.ArgumentParser(); p.add_argument('--manifest',type=Path,default=ROOT/'AssetFactory/data/your_dancer_2_5d_components.json'); p.add_argument('--catalog',type=Path,default=ROOT/'App/SWAY/Assets.xcassets'); p.add_argument('--out',type=Path,default=ROOT/'Docs/avatar_contact_sheets'); a=p.parse_args()
    data=json.loads(a.manifest.read_text()); layers=data['layers']; a.out.mkdir(parents=True,exist_ok=True)
    defaults={l['id']:l['options'][0]['id'] for l in layers}
    # Every option in every pose, with the other separated components held constant.
    for layer in layers:
        cells=[]; labels=[]
        for opt in layer['options']:
            for pose in range(1,data['poseCount']+1):
                choices={**defaults,layer['id']:opt['id']}; cells.append(compose(a.catalog,layers,pose,choices,data.get('palettes',{}))); labels.append(f"{opt['id']} / P{pose:02d}")
        sheet(cells,labels).save(a.out/f"{layer['id']}_all_options_all_poses.png",optimize=True)
    rng=random.Random(250120261007); cells=[]; labels=[]
    for i in range(10):
        choices={l['id']:rng.choice(l['options'])['id'] for l in layers}; pose=rng.randrange(1,data['poseCount']+1)
        cells.append(compose(a.catalog,layers,pose,choices,data.get('palettes',{}))); labels.append(f"combo {i+1:02d} / P{pose:02d}")
    sheet(cells,labels,cols=5).save(a.out/'random_full_combinations_10.png',optimize=True)
    (a.out/'README.md').write_text('# YOUR DANCER 2.5D contact sheets\n\nDeterministically generated for human review. `visualQuality=UNREVIEWED`; presence here is not acceptance, verification, or release. Each category sheet shows every option in every pose. The combination sheet uses seed `250120261007`.\n')
    print(f"rendered {len(layers)+1} contact sheets; visualQuality=UNREVIEWED")
if __name__=='__main__': main()
