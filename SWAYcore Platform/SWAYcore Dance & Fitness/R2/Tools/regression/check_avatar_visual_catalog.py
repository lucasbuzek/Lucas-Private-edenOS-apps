#!/usr/bin/env python3
"""Source-level acceptance checks for the SWAYcore Sims-inspired YOUR DANCER baseline.

This is intentionally stricter than the existing build/compile regression:
no recolored coach silhouette counts as an independent avatar, and a single
catalog option is not a customizable category. No EA assets are involved.
"""
from __future__ import annotations
from pathlib import Path
import re
import sys

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
MATTES = ROOT / "AssetFactory" / "puppet" / "mattes"
CATALOG = ROOT / "App" / "SWAY" / "Avatar" / "SWAYCharacterStage.swift"
views = ("front", "back", "side")
failed: list[str] = []
for view in views:
    a = np.asarray(Image.open(MATTES / f"kyle_{view}_rgba.png").convert("RGBA"))
    b = np.asarray(Image.open(MATTES / f"yourDancer_{view}_rgba.png").convert("RGBA"))
    clone = a.shape == b.shape and np.array_equal(a[..., 3], b[..., 3])
    print(f"{view}: source_alpha_is_kyle_clone={clone}", flush=True)
    if clone:
        failed.append(f"YOUR DANCER {view} geometry identical to Kyle")
src = CATALOG.read_text()
match = re.search(r"private static let counts:.*?=\s*\[(.*?)\]", src, re.S)
if not match:
    failed.append("SWAYAvatarCatalog option table not found")
else:
    counts = {k: int(v) for k, v in re.findall(r"\.(\w+):\s*(\d+)", match.group(1))}
    for category in ("body", "skin", "face", "hair", "hairColor", "top", "bottom", "shoes", "accessory"):
        count = counts.get(category, 0)
        print(f"catalog {category}: options={count}", flush=True)
        if count < 2:
            failed.append(f"catalog {category}: fewer than two selectable variants")
    if "available: i == 0" in src:
        failed.append("catalog hardcodes option availability to first item")
for issue in failed:
    print("FAIL:", issue)
if failed:
    print(f"AVATAR_VISUAL_CATALOG_FAIL issues={len(failed)}")
    sys.exit(1)
print("AVATAR_VISUAL_CATALOG_STATIC_PASS (rendered-option and physical review still required)")
