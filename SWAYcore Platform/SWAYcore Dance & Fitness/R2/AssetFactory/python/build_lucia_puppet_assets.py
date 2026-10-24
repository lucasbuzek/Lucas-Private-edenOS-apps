#!/usr/bin/env python3
"""Reproducibly cut, flatten, trace and pose Lucia's reviewed source artwork.

The segmentation is deliberately data-driven: every mask is a reviewable polygon in
``lucia_segmentation_masks.json``.  SAM2 is not required and no model weights are
silently downloaded.  Pillow performs the deterministic raster operation and
vtracer (MIT) emits actual SVG paths rather than embedded raster images.
"""
from __future__ import annotations

import hashlib
import json
import math
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageOps
except ImportError as exc:
    raise SystemExit("MISSING TOOL: Pillow (Apache-2.0/Historical Permission Notice). Install with `python3 -m pip install Pillow`; asset generation was not run.") from exc
try:
    import vtracer
except ImportError as exc:
    raise SystemExit("MISSING TOOL: vtracer (MIT). Install with `python3 -m pip install vtracer`; true SVG tracing was not run.") from exc

R2 = Path(__file__).resolve().parents[2]
SOURCE = R2 / "Reference/ArtDirection/LUCIA_RIG_REFERENCE_TURNAROUND.jpeg"
BOARD = R2 / "Reference/ArtDirection/136-SWAY_BUILD110_CHARACTER_ASSET_DIRECTION.png"
MASKS = R2 / "AssetFactory/data/puppet/lucia_segmentation_masks.json"
MANIFEST = R2 / "AssetFactory/data/puppet/lucia_puppet_manifest.json"
RASTER = R2 / "App/SWAY/Resources/Puppets/Lucia"
VECTOR = R2 / "AssetFactory/vector/lucia"
SHEETS = R2 / "Docs/puppet_contact_sheets"

ANGLES = ["front", "front_three_quarter_right", "side_right", "back_three_quarter_right", "back", "back_three_quarter_left", "side_left", "front_three_quarter_left"]
AUTHORED = {"front", "side_right", "back", "side_left"}
FALLBACK = {"front_three_quarter_right":"side_right", "back_three_quarter_right":"back", "back_three_quarter_left":"back", "front_three_quarter_left":"side_left"}
PARTS = ["hairBack", "leftUpperArm", "rightUpperArm", "leftLowerArm", "rightLowerArm", "leftHand", "rightHand", "leftThigh", "rightThigh", "leftCalf", "rightCalf", "leftShoe", "rightShoe", "pelvis", "torso", "head", "hairFront"]
SEGMENTS = {"leftUpperArm":("leftShoulder","leftElbow"), "leftLowerArm":("leftElbow","leftHand"), "rightUpperArm":("rightShoulder","rightElbow"), "rightLowerArm":("rightElbow","rightHand"), "leftThigh":("leftHip","leftKnee"), "leftCalf":("leftKnee","leftFoot"), "rightThigh":("rightHip","rightKnee"), "rightCalf":("rightKnee","rightFoot")}
JOINTS = ["root","pelvis","spine","chest","neck","head","leftShoulder","leftElbow","leftWrist","leftHand","rightShoulder","rightElbow","rightWrist","rightHand","leftHip","leftKnee","leftAnkle","leftFoot","rightHip","rightKnee","rightAnkle","rightFoot","nose"]

def flatten(im: Image.Image) -> Image.Image:
    """Transparent, reduced-palette TV-cartoon treatment (base + one shadow family)."""
    rgba = im.convert("RGBA")
    rgb = rgba.convert("RGB").quantize(colors=24, method=Image.Quantize.MEDIANCUT).convert("RGB")
    rgb = rgb.filter(ImageFilter.SMOOTH)
    rgb.putalpha(rgba.getchannel("A"))
    return rgb

def cut(source: Image.Image, polygon: list[list[int]]) -> Image.Image:
    x0=min(p[0] for p in polygon); y0=min(p[1] for p in polygon)
    x1=max(p[0] for p in polygon); y1=max(p[1] for p in polygon)
    # Twelve source pixels of joint overlap prevent transparent seams when bent.
    pad=12; box=(max(0,x0-pad),max(0,y0-pad),min(source.width,x1+pad),min(source.height,y1+pad))
    crop=source.crop(box).convert("RGBA")
    mask=Image.new("L",crop.size); draw=ImageDraw.Draw(mask)
    draw.polygon([(x-box[0],y-box[1]) for x,y in polygon],fill=255)
    # Source paper is also removed, including JPEG off-white pixels.
    pix=crop.load(); alpha=mask.load()
    for y in range(crop.height):
        for x in range(crop.width):
            r,g,b,_=pix[x,y]
            if r>242 and g>242 and b>242: alpha[x,y]=0
    crop.putalpha(mask)
    return flatten(crop)

def write_part(image: Image.Image, angle: str, part: str, option: str="base") -> dict:
    stem=f"lucia_{angle}_{option}_{part}"
    out=RASTER/angle/option/f"{stem}.png"; out.parent.mkdir(parents=True,exist_ok=True)
    scale=1024/max(image.size); size=(max(1,round(image.width*scale)),max(1,round(image.height*scale)))
    image.resize(size,Image.Resampling.LANCZOS).save(out,format="PNG",compress_level=9)
    svg=VECTOR/angle/option/f"{stem}.svg"; svg.parent.mkdir(parents=True,exist_ok=True)
    # Trace the flattened source resolution (capped at 256) instead of wasting
    # CPU retracing Lanczos-interpolated pixels in the 1024 fallback.
    trace_image=image.copy(); trace_image.thumbnail((256,256),Image.Resampling.LANCZOS)
    trace_png=svg.with_suffix(".trace.png"); trace_image.save(trace_png,compress_level=6)
    vtracer.convert_image_to_svg_py(str(trace_png),str(svg),colormode="color",hierarchical="stacked",mode="spline",filter_speckle=4,color_precision=6,layer_difference=16,corner_threshold=60,length_threshold=4.0,max_iterations=10,splice_threshold=45,path_precision=3)
    trace_png.unlink()
    return {"png1024":str(out.relative_to(R2)),"svg":str(svg.relative_to(R2)),"rasterSize":list(size),"pivot":{"x":0.5,"y":0.08 if part in SEGMENTS else 0.5},"sha256":hashlib.sha256(out.read_bytes()).hexdigest()}

def render_pose(manifest: dict, angle: str, pose: dict, size=(360,520)) -> Image.Image:
    canvas=Image.new("RGBA",size,(17,19,27,255)); resolved=angle if angle in AUTHORED else FALLBACK[angle]
    def xy(name):
        if name == "leftHip": p=(pose["hip"][0]-.04,pose["hip"][1])
        elif name == "rightHip": p=(pose["hip"][0]+.04,pose["hip"][1])
        else: p=pose[name]
        return (p[0]*size[0],p[1]*size[1])
    for part in PARTS:
        path=R2/manifest["partsByAngle"][resolved][part]["png1024"]
        art=Image.open(path).convert("RGBA")
        if part in SEGMENTS:
            a,b=map(xy,SEGMENTS[part]); length=math.dist(a,b); width=max(18,length*.43)
            art=art.resize((int(width),max(1,int(length*1.16))),Image.Resampling.LANCZOS)
            layer=Image.new("RGBA",(int(width*3),int(length*1.5)),(0,0,0,0)); layer.alpha_composite(art,((layer.width-art.width)//2,0))
            deg=math.degrees(math.atan2(b[1]-a[1],b[0]-a[0]))-90
            layer=layer.rotate(-deg,resample=Image.Resampling.BICUBIC,expand=True)
            # SWAYPuppetMath parity: the rendered limb is centred on the exact
            # endpoint midpoint after atan2(dy, dx) - pi/2 rotation.
            center=((a[0]+b[0])/2,(a[1]+b[1])/2)
            canvas.alpha_composite(layer,(round(center[0]-layer.width/2),round(center[1]-layer.height/2)))
        else:
            anchor={"head":"head","hairBack":"head","hairFront":"head","torso":"neck","pelvis":"hip","leftHand":"leftHand","rightHand":"rightHand","leftShoe":"leftFoot","rightShoe":"rightFoot"}.get(part)
            if not anchor: continue
            maxw={"head":105,"hairBack":115,"hairFront":115,"torso":115,"pelvis":105}.get(part,52)
            if part == "torso":
                top=xy("neck"); bottom=xy("hip"); art=art.resize((maxw,max(1,round((bottom[1]-top[1])*1.15))),Image.Resampling.LANCZOS); p=((top[0]+bottom[0])/2,(top[1]+bottom[1])/2)
            else:
                art.thumbnail((maxw,150),Image.Resampling.LANCZOS); p=xy(anchor)
            canvas.alpha_composite(art,(round(p[0]-art.width/2),round(p[1]-art.height/2)))
    return canvas

def make_evidence(manifest: dict) -> None:
    sys.path.insert(0,str(R2/"AssetFactory/python")); import coach_pose_port as coach
    SHEETS.mkdir(parents=True,exist_ok=True)
    neutral=coach.pose("step-touch",0,120)
    tiles=[]
    for i,a in enumerate(ANGLES):
        tile=render_pose(manifest,a,neutral); ImageDraw.Draw(tile).text((8,8),f"{a}\n{manifest['angles'][a]['availability']}",fill=(255,255,255,255)); tiles.append(tile)
    sheet=Image.new("RGB",(4*360,2*520),(9,10,14))
    for i,t in enumerate(tiles): sheet.paste(t,((i%4)*360,(i//4)*520))
    sheet.save(SHEETS/"lucia_angles_options.png",compress_level=9)
    for label,move in (("step_touch","step-touch"),("squat","squat-pulse"),("spin","pivot-turn")):
        strip=Image.new("RGB",(8*240,360),(9,10,14))
        track=[]
        for i in range(8):
            t=i*.125; p=coach.pose(move,t,120); yaw=coach.heading(move,t,120); idx=round((yaw%(2*math.pi))/(math.pi/4))%8
            frame=render_pose(manifest,ANGLES[idx],p,(240,360)); strip.paste(frame,(i*240,0)); track.append({"time":t,"yawRadians":yaw,"joints":p})
        strip.save(SHEETS/f"lucia_{label}_8_frames.png",compress_level=9)
        (SHEETS/f"lucia_{label}_joint_track.json").write_text(json.dumps(track,indent=2)+"\n")

def build() -> None:
    masks=json.loads(MASKS.read_text()); source=Image.open(SOURCE)
    parts={}
    for angle in sorted(AUTHORED):
        parts[angle]={}
        for part in PARTS: parts[angle][part]=write_part(cut(source,masks["views"][angle][part]),angle,part)
    angles={a:{"availability":"available" if a in AUTHORED else "nearest_angle_fallback","fallbackAngle":None if a in AUTHORED else FALLBACK[a],"mirrored":a in ("side_left","back_three_quarter_left","front_three_quarter_left"),"drawOrder":PARTS} for a in ANGLES}
    options={k:{"base":{"availability":"available"},"alternate":{"availability":"MISSING","fallbackOption":"base","reason":"Board 136 presents a parts kit, but no independently separated alternate was source-safe to refit without fabricating occluded geometry."}} for k in ("hair","top","bottom","shoes")}
    manifest={"schemaVersion":2,"characterID":"lucia","rig":"SWAYHumanoid-v1","jointNames":JOINTS,"sources":[str(SOURCE.relative_to(R2)),str(BOARD.relative_to(R2))],"segmentation":"deterministic-hand-authored-polygons","segmentationMasks":str(MASKS.relative_to(R2)),"jointOverlapSourcePixels":12,"anglesInYawOrder":ANGLES,"angles":angles,"options":options,"partsByAngle":parts,"evidence":{"visualQuality":"UNREVIEWED","sam2":"NOT USED — deterministic masks avoid unavailable model weights","threeQuarterViews":"MISSING_WITH_NEAREST_ANGLE_FALLBACK","alternateOptions":"MISSING","vectorTrace":"vtracer MIT true path SVG"}}
    MANIFEST.write_text(json.dumps(manifest,indent=2)+"\n"); make_evidence(manifest)

if __name__ == "__main__": build()
