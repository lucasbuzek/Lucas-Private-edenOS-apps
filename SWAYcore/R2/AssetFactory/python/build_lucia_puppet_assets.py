#!/usr/bin/env python3
"""Build Lucia puppet derivatives strictly from the reviewed cut-out PNGs.

No geometry is invented. Missing views/options are represented as explicit nearest-view
fallbacks so callers cannot mistake generated placeholders for approved art.
"""
import argparse, base64, json
from pathlib import Path
from PIL import Image, ImageDraw

R2 = Path(__file__).resolve().parents[2]
SOURCE = R2 / "App/ProductionAssets/Lucia"
MANIFEST_OUT = R2 / "AssetFactory/data/puppet/lucia_puppet_manifest.json"
VECTOR_OUT = R2 / "AssetFactory/vector/lucia/front"
RASTER_OUT = R2 / "App/SWAY/Resources/Puppets/Lucia/front/base"
SHEETS = R2 / "Docs/puppet_contact_sheets"
ANGLE_SEQUENCE = ["front", "front_three_quarter_right", "side_right", "back_three_quarter_right", "back", "back_three_quarter_left", "side_left", "front_three_quarter_left"]
AVAILABLE = {"front"}
JOINTS = ["root", "pelvis", "spine", "chest", "neck", "head", "leftShoulder", "leftElbow", "leftWrist", "leftHand", "rightShoulder", "rightElbow", "rightWrist", "rightHand", "leftHip", "leftKnee", "leftAnkle", "leftFoot", "rightHip", "rightKnee", "rightAnkle", "rightFoot", "nose"]
DRAW_ORDER = ["hairBack", "leftUpperArm", "rightUpperArm", "leftLowerArm", "rightLowerArm", "leftHand", "rightHand", "leftThigh", "rightThigh", "leftCalf", "rightCalf", "leftShoe", "rightShoe", "pelvis", "torso", "head", "hairFront"]

def build():
    source = json.loads((SOURCE / "lucia.manifest.json").read_text())
    VECTOR_OUT.mkdir(parents=True, exist_ok=True); RASTER_OUT.mkdir(parents=True, exist_ok=True)
    parts = {}
    for name in DRAW_ORDER:
        spec = source["parts"][name]; src = SOURCE / spec["file"]
        im = Image.open(src).convert("RGBA")
        scale = 1024 / max(im.size)
        out_size = tuple(max(1, round(v * scale)) for v in im.size)
        png = RASTER_OUT / f"{name}.png"
        im.resize(out_size, Image.Resampling.LANCZOS).save(png, optimize=True)
        data = base64.b64encode(src.read_bytes()).decode("ascii")
        svg = VECTOR_OUT / f"{name}.svg"
        # Lossless SVG container: explicitly raster-derived, not falsely called traced vector art.
        svg.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{im.width}" height="{im.height}" viewBox="0 0 {im.width} {im.height}"><image width="{im.width}" height="{im.height}" href="data:image/png;base64,{data}"/></svg>\n')
        parts[name] = {"sourcePNG": str(src.relative_to(R2)), "png1024": str(png.relative_to(R2)), "svgPreservationCopy": str(svg.relative_to(R2)), "sourceSize": list(im.size), "rasterSize": list(out_size), "pivots": spec["pivots"]}
    angles = {}
    for angle in ANGLE_SEQUENCE:
        angles[angle] = {"availability": "available" if angle in AVAILABLE else "missing_fallback", "fallbackAngle": None if angle in AVAILABLE else "front", "mirrored": False, "drawOrder": DRAW_ORDER}
    options = {category: {"base": {"availability": "available", "partNames": names}, "alternate": {"availability": "missing", "fallbackOption": "base", "reason": "No separately cut, reviewed source asset is present; primitive fabrication prohibited."}} for category,names in {"hair":["hairBack","hairFront"], "top":["torso"], "bottom":["pelvis"], "shoes":["leftShoe","rightShoe"]}.items()}
    manifest = {"schemaVersion": 1, "characterID": "lucia", "rig": "SWAYHumanoid-v1", "jointNames": JOINTS, "sourcePolicy": "reuse-only-no-generated-geometry", "anglesInYawOrder": ANGLE_SEQUENCE, "angles": angles, "options": options, "parts": parts, "evidence": {"visualQuality": "UNREVIEWED", "threeQuarterViews": "MISSING", "sideAndBackViews": "MISSING", "alternateOptions": "MISSING", "note": "Runtime must use declared nearest-angle/base-option fallback and must not report missing art as implemented."}}
    MANIFEST_OUT.parent.mkdir(parents=True, exist_ok=True); MANIFEST_OUT.write_text(json.dumps(manifest, indent=2) + "\n")
    contact_sheet(manifest)

def contact_sheet(manifest):
    SHEETS.mkdir(parents=True, exist_ok=True)
    tiles=[]
    for a in ANGLE_SEQUENCE:
        canvas=Image.new("RGB",(300,440),(20,21,27)); d=ImageDraw.Draw(canvas)
        d.text((12,10),a,fill=(255,79,142)); d.text((12,30),manifest["angles"][a]["availability"],fill=(220,220,225))
        # Source-derived composite preview, clearly labelled fallback where applicable.
        y=60
        for n in ["hairBack","head","hairFront","torso","pelvis","leftThigh","rightThigh","leftCalf","rightCalf","leftShoe","rightShoe"]:
            im=Image.open(RASTER_OUT/f"{n}.png").convert("RGBA"); im.thumbnail((110,55))
            canvas.paste(im,((300-im.width)//2,y),im); y += 29
        tiles.append(canvas)
    sheet=Image.new("RGB",(1200,880),(8,9,13))
    for i,t in enumerate(tiles): sheet.paste(t,((i%4)*300,(i//4)*440))
    sheet.save(SHEETS/"lucia_angles_options.png",optimize=True)
    (SHEETS/"README.md").write_text("# Lucia puppet contact sheets\n\n`lucia_angles_options.png` is pipeline evidence, not visual approval. Only FRONT source-separated art exists. Every other tile is visibly labelled `missing_fallback`; it repeats FRONT without claiming that a side/back/three-quarter drawing was created. Alternate hair/top/bottom/shoe source cuts are also MISSING. `visualQuality` remains **UNREVIEWED**. Motion strips remain MISSING until the renderer consumes the manifest.\n")

if __name__ == "__main__": build()
