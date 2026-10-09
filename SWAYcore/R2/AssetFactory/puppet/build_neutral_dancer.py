"""Build the unbranded YOUR DANCER neutral palette from board-kit pixels."""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).parent

for view in ("front", "back", "side"):
    path = ROOT / "mattes" / f"yourDancer_{view}_rgba.png"
    rgba = np.asarray(Image.open(path).convert("RGBA")).copy()
    rgb = rgba[..., :3]
    r, g, b = (rgb[..., index].astype(int) for index in range(3))

    # A deliberately neutral, non-coach identity: umber skin, teal separates,
    # and aubergine hair/cap. Preserve the board's hand-painted shading.
    skin = (r > 130) & (r > g * 1.12) & (g > b * .85) & (rgba[..., 3] > 0)
    rgb[skin] = np.clip(rgb[skin] * np.array([.62, .50, .43]), 0, 255)
    blue = (b > r * 1.15) & (b > g * 1.05) & (rgba[..., 3] > 0)
    old = rgb[blue].copy()
    rgb[blue, 0] = old[:, 0] * .30
    rgb[blue, 1] = np.clip(old[:, 2] * .75, 0, 255)
    rgb[blue, 2] = np.clip(old[:, 1] * .85, 0, 255)
    dark = (r < 65) & (g < 65) & (b < 75) & (rgba[..., 3] > 0)
    rgb[dark] = np.clip(rgb[dark] * np.array([1.30, .78, 1.22]), 0, 255)
    Image.fromarray(rgba, "RGBA").save(path, optimize=True)

