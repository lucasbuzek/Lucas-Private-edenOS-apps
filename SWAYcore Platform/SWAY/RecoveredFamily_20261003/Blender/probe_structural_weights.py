"""Regression probe: generated instructor bodies must meet the structural skin-weight contract."""
import os, subprocess, sys
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
blender = "/Applications/Blender.app/Contents/MacOS/Blender"
failed = []
for cid in ("lucia", "nandi", "thabo", "zuri", "kyle"):
    blend = os.path.join(root, "Assets/Blend", cid + ".blend")
    manifest = os.path.join(root, "Assets/Characters", cid + ".character.json")
    cmd = [blender, "--background", "--factory-startup", blend, "--python", os.path.join(root, "Blender/validate_blend.py"), "--",
           "--manifest", manifest, "--fixtures", os.path.join(root, "Assets/Fixtures/movements.json")]
    p = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if p.returncode != 0:
        failed.append(cid)
        print(p.stdout)
if failed:
    print("PROBE FAIL: structural validation failed for " + ", ".join(failed))
    sys.exit(1)
print("PROBE PASS: all generated instructor bodies satisfy structural validation")
