"""Rebuild the non-Lucia puppet mattes and cutter configurations from board 136.

The source crop coordinates are deliberately kept here (rather than shipping duplicate
board crops).  Background removal is deterministic: only board-coloured pixels connected
to a crop edge are removed.  The resulting art is a source-preserving cut-out, not a
repaint or generated likeness.
"""
from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

ROOT = Path(__file__).resolve().parents[2]
PUPPET = ROOT / "AssetFactory" / "puppet"
BOARD = ROOT / "Reference/ArtDirection/upscaled_x4/136-SWAY_BUILD110_CHARACTER_ASSET_DIRECTION.x4.png"

# Original-board x bounds.  Each crop contains one figure and no neighbouring figure.
# YOUR DANCER intentionally uses Kyle's plain, unbranded parts-kit-compatible neutral base;
# it is not represented as Lucas and its replaceable layer mapping is recorded separately.
CROPS = {
    "nandi": {"front": (340, 435), "side": (435, 510), "back": (510, 580)},
    "thabo": {"front": (650, 760), "side": (760, 825), "back": (825, 900)},
    "zuri": {"front": (958, 1050), "side": (1050, 1120), "back": (1120, 1195)},
    "kyle": {"front": (1250, 1340), "side": (1340, 1410), "back": (1410, 1480)},
    "yourDancer": {"front": (1250, 1340), "side": (1340, 1410), "back": (1410, 1480)},
}


def matte(crop: Image.Image) -> Image.Image:
    a = np.asarray(crop.convert("RGB"), dtype=np.int16)
    h, w = a.shape[:2]
    border = np.concatenate((a[:12].reshape(-1, 3), a[-12:].reshape(-1, 3),
                             a[:, :8].reshape(-1, 3), a[:, -8:].reshape(-1, 3)))
    bg = np.median(border, axis=0)
    dist = np.linalg.norm(a - bg, axis=2)
    mx, mn = a.max(2), a.min(2)
    neutral = (mx - mn) < 55
    # Keep white shirts and shoes: unlike the warm board backdrop they are neutral,
    # but can be edge-connected through antialiasing in a tight turnaround crop.
    candidate = (dist < 52) | (neutral & (dist < 68))
    seeds = np.zeros((h, w), bool)
    seeds[[0, -1], :] = True
    seeds[:, [0, -1]] = True
    outside = ndi.binary_propagation(seeds, mask=candidate)
    fg = ~outside
    fg = ndi.binary_opening(fg, iterations=1)
    labels, count = ndi.label(fg)
    sizes = ndi.sum(fg, labels, range(1, count + 1))
    keep = [i + 1 for i, size in enumerate(sizes) if size > 350]
    fg = np.isin(labels, keep)
    rgba = np.dstack((a.astype(np.uint8), (fg * 255).astype(np.uint8)))
    return Image.fromarray(rgba, "RGBA")


PARTS = [
    ("head", "Neck", "HeadTop", 0, 95), ("chest", "Spine", "Neck", 64, 40),
    ("pelvis", "Hips", "Spine", 60, 50),
    ("rightUpperArm", "RightUpperArm", "RightLowerArm", 28, 35),
    ("rightLowerArm", "RightLowerArm", "RightHand", 24, 70),
    ("rightHand", "RightHand", "RightHandTip", 18, 80),
    ("leftUpperArm", "LeftUpperArm", "LeftLowerArm", 28, 35),
    ("leftLowerArm", "LeftLowerArm", "LeftHand", 24, 70),
    ("leftHand", "LeftHand", "LeftHandTip", 18, 80),
    ("rightThigh", "RightUpperLeg", "RightLowerLeg", 44, 30),
    ("rightCalf", "RightLowerLeg", "RightFoot", 38, 10),
    ("rightShoe", "RightFoot", "RightToe", 36, 20),
    ("leftThigh", "LeftUpperLeg", "LeftLowerLeg", 44, 30),
    ("leftCalf", "LeftLowerLeg", "LeftFoot", 38, 10),
    ("leftShoe", "LeftFoot", "LeftToe", 36, 20),
]


def config(name: str, view: str, image: Image.Image) -> dict:
    alpha = np.asarray(image)[..., 3]
    ys, xs = np.nonzero(alpha)
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    cx, width, height = (x0 + x1) / 2, x1 - x0, y1 - y0
    def p(x: float, y: float) -> list[int]:
        return [round(cx + x * width), round(y0 + y * height)]
    side = view == "side"
    arm = .11 if side else .31
    leg = .055 if side else .15
    joints = {
        "Hips": p(0, .57), "Spine": p(0, .50), "Neck": p(0, .285), "HeadTop": p(0, .02),
        "RightUpperArm": p(-arm, .33), "RightLowerArm": p(-arm - (.035 if not side else 0), .47),
        "RightHand": p(-arm - (.055 if not side else 0), .59), "RightHandTip": p(-arm - (.06 if not side else 0), .66),
        "LeftUpperArm": p(arm, .33), "LeftLowerArm": p(arm + (.035 if not side else 0), .47),
        "LeftHand": p(arm + (.055 if not side else 0), .59), "LeftHandTip": p(arm + (.06 if not side else 0), .66),
        "RightUpperLeg": p(-leg, .58), "RightLowerLeg": p(-leg - .025, .76),
        "RightFoot": p(-leg - .035, .94), "RightToe": p(-leg - .10, .985),
        "LeftUpperLeg": p(leg, .58), "LeftLowerLeg": p(leg + .025, .76),
        "LeftFoot": p(leg + .035, .94), "LeftToe": p(leg + .10, .985),
    }
    scale = width / 400
    parts = []
    for part_name, a, b, radius, z in PARTS:
        if side and part_name.startswith("right"):
            z -= 45  # far limbs behind torso; cut.py darkens these via the config flag below
        caps = [] if part_name in ("head", "rightShoe", "leftShoe") else [[a, "auto"]]
        terminal = part_name.endswith("Hand") or part_name.endswith("Shoe")
        parts.append({"name": part_name, "bone": [a, b], "radius": max(8, round(radius * scale)),
                      "z": z, "caps": caps, **({} if terminal else {"main": True, "open": 1}),
                      **({"darken": .85} if side and part_name.startswith("right") else {})})
    # Lock the central garment regions to the body.  Without this ownership lock,
    # nearest-bone assignment can give a crescent of shirt to an arm that overlaps
    # the torso in the authored rest pose.
    terminal_force = [
        {"part": "chest", "box": [round(cx-width*.42), joints["Neck"][1],
                                     round(cx+width*.42), joints["Spine"][1]], "notSkin": True},
        {"part": "pelvis", "box": [round(cx-width*.42), joints["Spine"][1],
                                      round(cx+width*.42), joints["Hips"][1]], "notSkin": True},
    ]
    for part_name, joint_name in (("rightHand", "RightHand"), ("leftHand", "LeftHand"),
                                  ("rightShoe", "RightFoot"), ("leftShoe", "LeftFoot")):
        jx, jy = joints[joint_name]
        vertical_before = .05 if part_name.endswith("Shoe") else .015
        vertical_after = .10 if part_name.endswith("Shoe") else .075
        terminal_force.append({"part": part_name,
                               "box": [round(jx-width*.11), round(jy-height*vertical_before),
                                       round(jx+width*.11), round(jy+height*vertical_after)]})
    return {"src": f"mattes/{name}_{view}_rgba.png", "out": "parts", "prefix": name,
            "view": view, "neckY": joints["Neck"][1], "headHalfWidth": round(width * .42),
            "despill": 28, "despillMaxY": image.height, "joints": joints, "force": terminal_force,
            "parts": parts,
            "source": {"board": BOARD.name, "cropAt1x": list(CROPS.get(name, {}).get(view, (0, 0)))}}


def main() -> None:
    board = Image.open(BOARD)
    for name, views in CROPS.items():
        for view, (left, right) in views.items():
            raw = board.crop((left * 4, 0, right * 4, 350 * 4))
            rendered = matte(raw)
            mp = PUPPET / "mattes" / f"{name}_{view}_rgba.png"
            rendered.save(mp, optimize=True)
            cp = PUPPET / "configs" / f"{name}_{view}.json"
            cp.write_text(json.dumps(config(name, view, rendered), indent=2) + "\n")


if __name__ == "__main__":
    main()
