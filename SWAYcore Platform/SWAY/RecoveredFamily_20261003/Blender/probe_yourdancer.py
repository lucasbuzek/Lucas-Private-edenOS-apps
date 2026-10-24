"""Regression probe: YOUR DANCER must generate all required source outputs without hidden-object operator failures."""
import os, subprocess, sys, tempfile
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
blender = "/Applications/Blender.app/Contents/MacOS/Blender"
with tempfile.TemporaryDirectory(prefix="sway-yourdancer-") as td:
    out = os.path.join(td, "Characters")
    blend = os.path.join(td, "Blend")
    cmd = [blender, "--background", "--factory-startup", "--python", os.path.join(root, "Blender/generate_characters.py"), "--",
           "--fixtures", os.path.join(root, "Assets/Fixtures/movements.json"), "--characters", os.path.join(root, "Blender/characters.json"),
           "--out", out, "--blend", blend, "--only", "yourdancer"]
    p = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    required = [os.path.join(blend, "yourdancer.blend"), os.path.join(out, "yourdancer.character.json"), os.path.join(out, "yourdancer.usdz")]
    ok = p.returncode == 0 and "Traceback" not in p.stdout and all(os.path.exists(x) for x in required)
    if not ok:
        print(p.stdout[-5000:])
        print("PROBE FAIL: YOUR DANCER generation is incomplete or raised a traceback")
        sys.exit(1)
    print("PROBE PASS: YOUR DANCER generation produced blend, manifest and USDZ without traceback")
