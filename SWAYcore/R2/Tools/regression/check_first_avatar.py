#!/usr/bin/env python3
"""M1: one distinct YOUR DANCER across front/back/side with six art-motion poses.

This focused gate does not reclassify the other five coaches as verified.
It runs the same independent full-release articulation checker on three rigs.
"""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[2]
assets = root / "App/SWAY/Resources/Puppets"
avatars = assets / "YourDancerRig"
checker = root / "Tools/regression/check_puppet_rigs.py"
names = {"head", "chest", "pelvis", "rightUpperArm", "rightLowerArm", "rightHand",
         "leftUpperArm", "leftLowerArm", "leftHand", "rightThigh", "rightCalf",
         "rightShoe", "leftThigh", "leftCalf", "leftShoe"}

for view in ("front", "back", "side"):
    path = avatars / f"yourDancer_{view}_rig.json"
    rig = json.loads(path.read_text())
    assert rig["view"] == view
    parts = {part["name"]: part for part in rig["parts"]}
    assert set(parts) == names, (view, sorted(set(names) ^ set(parts)))
    assert all(part["file"].startswith(f"yourDancer_{view}_") for part in rig["parts"])
    for name, part in parts.items():
        image = avatars / part["file"]
        assert image.is_file(), image
        coach = assets / "KyleRig" / f"kyle_{view}_{name}.png"
        assert coach.is_file(), coach
        digest = lambda p: hashlib.sha256(p.read_bytes()).digest()
        assert digest(image) != digest(coach), f"{view}/{name} still duplicates Kyle"
    result = subprocess.run([sys.executable, str(checker), "--rig", str(path)],
                            text=True, capture_output=True)
    print(result.stdout, end="", flush=True)
    if result.stderr:
        print(result.stderr, file=sys.stderr, flush=True)
    assert result.returncode == 0, f"YOUR DANCER {view} articulation FAIL"

print("PASS: YOUR DANCER distinct component art 45/45; 3 rigs x 6 poses = 18/18")
