#!/usr/bin/env python3
"""Validate every bundled SWAY cut-out rig, including articulated silhouettes."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

root = Path(__file__).resolve().parents[2]
puppets = root / "App/SWAY/Resources/Puppets"
required_joints = {"Hips", "Spine", "Neck", "HeadTop", "RightUpperArm", "RightLowerArm",
                   "RightHand", "RightHandTip", "LeftUpperArm", "LeftLowerArm", "LeftHand",
                   "LeftHandTip", "RightUpperLeg", "RightLowerLeg", "RightFoot", "RightToe",
                   "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "LeftToe"}
all_rigs = sorted(puppets.glob("*Rig/*_rig.json"))
assert len(all_rigs) == 18, f"expected 18 rigs, found {len(all_rigs)}"

# Pillow/Scipy retain sizeable image work buffers. Isolate each rig so the complete
# release gate also runs reliably on memory-constrained CI workers.
if "--rig" not in sys.argv:
    failed_rigs = 0
    for candidate in all_rigs:
        result = subprocess.run(
            [sys.executable, __file__, "--rig", str(candidate)],
            text=True, capture_output=True,
        )
        print(result.stdout, end="")
        if result.stderr:
            print(result.stderr, end="", file=sys.stderr)
        failed_rigs += result.returncode != 0
    if failed_rigs:
        print(f"FAIL: articulation defects in {failed_rigs} of {len(all_rigs)} rigs")
        sys.exit(1)
    print(f"PASS: {len(all_rigs)} rigs x 6 poses; files/joints/pivots/dimensions/articulation valid")
    sys.exit(0)

rig_arg = Path(sys.argv[sys.argv.index("--rig") + 1]).resolve()
assert rig_arg in [path.resolve() for path in all_rigs], f"unknown rig: {rig_arg}"
rigs = [rig_arg]

pose_path = root / "AssetFactory/puppet/pose.py"
spec = importlib.util.spec_from_file_location("sway_pose", pose_path)
pose = importlib.util.module_from_spec(spec)
assert spec.loader is not None
original_argv = sys.argv
sys.argv = [str(pose_path), str(rigs[0])]
spec.loader.exec_module(pose)
sys.argv = original_argv


def silhouette_metrics(alpha: np.ndarray) -> tuple[int, int, int]:
    """Return significant components, largest enclosed hole, and opaque area."""
    opaque = alpha > 16
    ys, xs = np.nonzero(opaque)
    if not len(xs):
        return 0, 0, 0
    # Analyse only the padded silhouette bounds, not millions of empty canvas pixels.
    opaque = np.pad(opaque[ys.min():ys.max() + 1, xs.min():xs.max() + 1], 1)
    labels, count = ndi.label(opaque, structure=np.ones((3, 3), dtype=bool))
    sizes = ndi.sum(opaque, labels, range(1, count + 1))
    components = sum(int(size) >= 40 for size in sizes)

    background = ~opaque
    holes, hole_count = ndi.label(background, structure=np.ones((3, 3), dtype=bool))
    border = np.unique(np.concatenate((holes[0], holes[-1], holes[:, 0], holes[:, -1])))
    hole_sizes = ndi.sum(background, holes, range(1, hole_count + 1))
    enclosed = [int(size) for index, size in enumerate(hole_sizes, 1) if index not in border]
    return components, max(enclosed, default=0), int(opaque.sum())


failures = []
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

    # pose.py is also the renderer oracle used to produce the review contact sheets.
    pose.rig = rig
    pose.base = str(path.parent)
    pose.R = {key: tuple(value) for key, value in rig["joints"].items()}
    width, height = rig["canvas"]
    size = (width + 400, height + 400)

    def render_metrics(pose_name, source_deltas):
        deltas = source_deltas
        if rig.get("view") == "back":
            deltas = {key: -value for key, value in source_deltas.items()}
        targets = pose.fk(deltas, (200, 200))
        alpha = np.asarray(pose.render(targets, size).getchannel("A"))
        return silhouette_metrics(alpha)

    rest_area = render_metrics("rest", pose.POSES["rest"])[2]
    rig_name = path.stem.removesuffix("_rig")
    for pose_name, deltas in pose.POSES.items():
        components, largest_hole, area = render_metrics(pose_name, deltas)
        area_ratio = area / rest_area if rest_area else 0
        reasons = []
        if components > 1:
            reasons.append(f"components={components}")
        if largest_hole > 60:
            reasons.append(f"hole={largest_hole}px")
        if area_ratio < .85:
            reasons.append(f"area={area_ratio:.1%}")
        result = "PASS" if not reasons else "FAIL " + ", ".join(reasons)
        print(f"{rig_name:20} | {pose_name:11} | {result}")
        if reasons:
            failures.append((rig_name, pose_name, reasons))

if failures:
    print(f"FAIL: {len(failures)} of {len(rigs) * len(pose.POSES)} rig poses failed articulation")
    sys.exit(1)
print(f"PASS: {len(rigs)} rig x {len(pose.POSES)} poses; files/joints/pivots/dimensions/articulation valid")
