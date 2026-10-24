#!/usr/bin/env python3
"""Generate offline, authored-material colorways for the 2.5D YOUR DANCER puppet.

Inputs are the existing accepted candidate part PNGs. Never edits base PNGs or coaches.
Output mapping deduplicates identical variants; alpha/geometry are unchanged.
Run AFTER regenerating puppet cutouts, BEFORE XcodeGen build and QA.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image

DEFAULT_ROOT = Path(__file__).resolve().parents[2]
SKINS = ("Light", "Medium", "Umber")
OUTFITS = ("Emerald", "Ocean", "Violet")
BASE_SKIN = 2
BASE_OUTFIT = 0


def material_masks(src: np.ndarray, part: str) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    a = src[..., 3] > 16
    r, g, b = [src[..., k].astype(np.float32) for k in range(3)]
    skin = a & (r > 75) & (r > 1.35 * g) & (r > 1.30 * b) & (g >= 0.70 * b)
    green = a & (g > 40) & (g > 1.28 * r) & (g > 1.17 * b)
    # Only shorts, not the hair/cap or wristbands, can be recolored as dark garment.
    shorts = a & part.endswith(("pelvis", "Thigh")) & (r < 105) & (g < 70) & (b < 115) & (r > 1.12 * g) & (b > 1.12 * g)
    return skin, green, shorts


def recolor(src: np.ndarray, part: str, skin: int, outfit: int) -> np.ndarray:
    pixels = src.copy()
    rgb = pixels[..., :3].astype(np.float32)
    original = rgb.copy()
    skin_mask, shirt_mask, shorts_mask = material_masks(src, part)
    if skin == 0:
        rgb[skin_mask, 0] = original[skin_mask, 0] * 1.25 + 36
        rgb[skin_mask, 1] = original[skin_mask, 1] * 1.38 + 31
        rgb[skin_mask, 2] = original[skin_mask, 2] * 1.40 + 37
    elif skin == 1:
        rgb[skin_mask, 0] = original[skin_mask, 0] * 1.11 + 16
        rgb[skin_mask, 1] = original[skin_mask, 1] * 1.18 + 15
        rgb[skin_mask, 2] = original[skin_mask, 2] * 1.24 + 15
    if outfit == 1:
        value = original[shirt_mask, 1]
        rgb[shirt_mask, 0] = value * 0.26 + 8
        rgb[shirt_mask, 1] = value * 0.83 + 5
        rgb[shirt_mask, 2] = value * 1.42 + 29
        rgb[shorts_mask, 0] = original[shorts_mask, 0] * 0.70 + 5
        rgb[shorts_mask, 1] = original[shorts_mask, 1] * 1.37 + 9
        rgb[shorts_mask, 2] = original[shorts_mask, 2] * 1.62 + 14
    elif outfit == 2:
        value = original[shirt_mask, 1]
        rgb[shirt_mask, 0] = value * 1.02 + 11
        rgb[shirt_mask, 1] = value * 0.57 + 12
        rgb[shirt_mask, 2] = value * 1.28 + 24
        rgb[shorts_mask, 0] = original[shorts_mask, 0] * 1.43 + 13
        rgb[shorts_mask, 1] = original[shorts_mask, 1] * 0.95 + 4
        rgb[shorts_mask, 2] = original[shorts_mask, 2] * 1.34 + 12
    pixels[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    return pixels


def generate(root: Path, output: Path) -> dict:
    source = root / "App/SWAY/Resources/Puppets/YourDancerRig"
    output.mkdir(parents=True, exist_ok=True)
    all_base = sorted(source.glob("yourDancer_*_*.png"))
    all_base = [p for p in all_base if not ("_skin" in p.stem or "_outfit" in p.stem)]
    assert len(all_base) == 45, f"expected 45 authored base PNGs; found {len(all_base)}"
    asset_map: dict[str, dict[str, str]] = {}
    material_counts = {"skin": 0, "shirt": 0, "shorts": 0}
    generated = 0
    for base_file in all_base:
        base = np.asarray(Image.open(base_file).convert("RGBA"))
        assert base.shape[0] <= 1024 and base.shape[1] <= 1024, base_file
        skin_mask, shirt_mask, shorts_mask = material_masks(base, base_file.stem)
        material_counts["skin"] += int(skin_mask.sum())
        material_counts["shirt"] += int(shirt_mask.sum())
        material_counts["shorts"] += int(shorts_mask.sum())
        fingerprints = {hashlib.sha256(base.tobytes()).digest(): base_file.name}
        mapping: dict[str, str] = {}
        for skin in range(len(SKINS)):
            for outfit in range(len(OUTFITS)):
                key = f"skin{skin}_outfit{outfit}"
                variant = recolor(base, base_file.stem, skin, outfit)
                assert np.array_equal(variant[..., 3], base[..., 3]), "alpha may never change"
                digest = hashlib.sha256(variant.tobytes()).digest()
                target_name = fingerprints.get(digest)
                if target_name is None:
                    target_name = f"{base_file.stem}_{key}.png"
                    Image.fromarray(variant, "RGBA").save(output / target_name, optimize=True)
                    fingerprints[digest] = target_name
                    generated += 1
                mapping[key] = target_name
        asset_map[base_file.name] = mapping
    manifest = {"format": "SWAY-YOUR-DANCER-PALETTE", "version": 1,
                "source": "author-owned board 136; no third-party character assets",
                "defaultSkin": BASE_SKIN, "defaultOutfit": BASE_OUTFIT,
                "skins": list(SKINS), "outfits": list(OUTFITS),
                "assets": asset_map, "materialPixels": material_counts,
                "generatedCount": generated}
    (output / "yourDancer_palette_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    assert material_counts["skin"] > 10000 and material_counts["shirt"] > 10000
    return manifest


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT)
    parser.add_argument("--output", type=Path, default=None)
    args = parser.parse_args()
    root = args.root.resolve()
    out = args.output.resolve() if args.output else root / "App/SWAY/Resources/Puppets/YourDancerRig"
    manifest = generate(root, out)
    print(json.dumps({"status": "PALETTE_GENERATION_PASS", "bases": len(manifest["assets"]),
                      "variants": manifest["generatedCount"], "materials": manifest["materialPixels"],
                      "output": str(out)}))


if __name__ == "__main__":
    main()
