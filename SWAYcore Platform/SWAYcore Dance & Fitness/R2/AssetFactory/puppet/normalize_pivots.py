"""Pad cut parts transparently so every runtime pivot is inside its PNG bounds."""
import json
import sys
from pathlib import Path
from PIL import Image

for argument in sys.argv[1:]:
    path = Path(argument)
    rig = json.loads(path.read_text())
    for part in rig["parts"]:
        image_path = path.parent / part["file"]
        image = Image.open(image_path).convert("RGBA")
        px, py = part["pivot"]
        left, top = max(0, int(-px + .999)), max(0, int(-py + .999))
        right, bottom = max(0, int(px - image.width + .999)), max(0, int(py - image.height + .999))
        if not any((left, top, right, bottom)):
            continue
        padded = Image.new("RGBA", (image.width + left + right, image.height + top + bottom))
        padded.alpha_composite(image, (left, top))
        padded.save(image_path, optimize=True)
        part["origin"] = [part["origin"][0] - left, part["origin"][1] - top]
        part["pivot"] = [px + left, py + top]
        part["size"] = [padded.width, padded.height]
        part["pivotNorm"] = [(px + left) / padded.width, (py + top) / padded.height]
    path.write_text(json.dumps(rig, indent=1) + "\n")
