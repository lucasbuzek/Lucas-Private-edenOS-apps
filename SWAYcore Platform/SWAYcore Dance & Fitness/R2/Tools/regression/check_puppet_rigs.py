#!/usr/bin/env python3
"""Validate every bundled SWAY cut-out rig without requiring Xcode."""
import json
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[2]
puppets = root / "App/SWAY/Resources/Puppets"
required_joints = {"Hips", "Spine", "Neck", "HeadTop", "RightUpperArm", "RightLowerArm",
                   "RightHand", "RightHandTip", "LeftUpperArm", "LeftLowerArm", "LeftHand",
                   "LeftHandTip", "RightUpperLeg", "RightLowerLeg", "RightFoot", "RightToe",
                   "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "LeftToe"}
rigs = sorted(puppets.glob("*Rig/*_rig.json"))
assert len(rigs) == 18, f"expected 18 rigs, found {len(rigs)}"
for path in rigs:
    rig = json.loads(path.read_text())
    missing = required_joints - set(rig["joints"])
    assert not missing, f"{path}: missing joints {sorted(missing)}"
    assert rig["view"] in {"front", "back", "side"}
    for part in rig["parts"]:
        image_path = path.parent / part["file"]
        assert image_path.is_file(), f"{path}: missing {part['file']}"
        width, height = Image.open(image_path).size
        assert max(width, height) <= 1024, f"{image_path}: {width}x{height} exceeds limit"
        px, py = part["pivot"]
        assert 0 <= px <= width and 0 <= py <= height, f"{path}: {part['name']} pivot outside bounds"
print(f"PASS: {len(rigs)} rigs, all files/joints/pivots/dimensions valid")
