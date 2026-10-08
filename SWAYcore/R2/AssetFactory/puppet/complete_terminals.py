"""Complete a terminal limb from its source-art counterpart when a tight crop hides it."""
import json
import math
import sys
from pathlib import Path

from PIL import Image

rig_path = Path(sys.argv[1])
rig = json.loads(rig_path.read_text())
base = rig_path.parent
by_name = {part["name"]: part for part in rig["parts"]}
for missing, counterpart in (("leftShoe", "rightShoe"), ("rightShoe", "leftShoe"),
                             ("leftHand", "rightHand"), ("rightHand", "leftHand")):
    if missing in by_name or counterpart not in by_name:
        continue
    source = by_name[counterpart]
    side = "left" if missing.startswith("left") else "right"
    kind = "Shoe" if missing.endswith("Shoe") else "Hand"
    proximal = ("Left" if side == "left" else "Right") + ("Foot" if kind == "Shoe" else "Hand")
    distal = ("Left" if side == "left" else "Right") + ("Toe" if kind == "Shoe" else "HandTip")
    filename = source["file"].replace(counterpart, missing)
    image = Image.open(base / source["file"]).transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    image.save(base / filename, optimize=True)
    pivot = [image.width - source["pivot"][0], source["pivot"][1]]
    joint = rig["joints"][proximal]
    target = rig["joints"][distal]
    part = dict(source, name=missing, file=filename, bone=[proximal, distal],
                origin=[round(joint[0] - pivot[0]), round(joint[1] - pivot[1])],
                pivot=pivot, pivotNorm=[pivot[0] / image.width, pivot[1] / image.height],
                restAngle=math.atan2(target[1] - joint[1], target[0] - joint[0]),
                restLength=math.hypot(target[0] - joint[0], target[1] - joint[1]))
    rig["parts"].append(part)
    by_name[missing] = part
rig_path.write_text(json.dumps(rig, indent=1) + "\n")
