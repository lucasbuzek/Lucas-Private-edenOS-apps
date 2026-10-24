import json, os, sys, tempfile, unittest, zipfile
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "Blender"))
import validate_manifest as vm

JOINTS = ["root","hips","spine","chest","neck","head","headEnd"] + [p+s for s in "LR" for p in
          ["shoulder","elbow","wrist","hand","hip","knee","ankle","toes"]]
CLIPS = vm.PROOF

def good():
    return {"contract": vm.CONTRACT, "characterID": "lucia", "displayName": "Lucia", "asset": "lucia.usdz",
            "blendSource": "Blend/lucia.blend", "upAxis": "Y", "metersPerUnit": 1.0, "heightMeters": 1.68,
            "joints": list(JOINTS), "meshes": list(vm.REQUIRED_MESHES), "materials": ["Skin"], "textures": ["lucia_skin.png"],
            "clips": list(CLIPS), "clipFiles": {}, "triangleCount": 30000, "maxSkinInfluences": 4, "visualQuality": "UNREVIEWED"}

class ManifestTests(unittest.TestCase):
    def test_joint_contract_is_23(self):
        self.assertEqual(len(JOINTS), 23); self.assertEqual(len(set(JOINTS)), 23)
    def test_good_manifest_passes(self):
        self.assertEqual(vm.validate_manifest(good(), JOINTS, CLIPS), [])
    def test_each_defect_detected(self):
        cases = {
            "contract": lambda m: m.update(contract="x"), "dup": lambda m: m["joints"].append("hips"),
            "missing joint": lambda m: m["joints"].remove("toesR"), "axis": lambda m: m.update(upAxis="Z"),
            "scale": lambda m: m.update(metersPerUnit=0.01), "height": lambda m: m.update(heightMeters=3.2),
            "mesh": lambda m: m["meshes"].remove("Hair"), "clip": lambda m: m["clips"].remove("sway_squat_v1"),
            "mat": lambda m: m.update(materials=[]), "tex": lambda m: m.update(textures=[]),
            "tris": lambda m: m.update(triangleCount=999999), "infl": lambda m: m.update(maxSkinInfluences=8),
            "accepted": lambda m: m.update(visualQuality="ACCEPTED"), "paths": lambda m: m.update(asset="")}
        for name, mut in cases.items():
            m = good(); mut(m)
            self.assertTrue(vm.validate_manifest(m, JOINTS, CLIPS), name)
    def test_file_validation_and_main(self):
        with tempfile.TemporaryDirectory() as d:
            ch = os.path.join(d, "Characters"); os.makedirs(os.path.join(ch, "textures")); os.makedirs(os.path.join(d, "Blend"))
            fx = os.path.join(d, "movements.json")
            json.dump({"joints": JOINTS, "movements": [{"id": c} for c in CLIPS]}, open(fx, "w"))
            m = good(); json.dump(m, open(os.path.join(ch, "lucia.character.json"), "w"))
            self.assertEqual(vm.main([ch, fx]), 1)                       # asset/blend/texture files absent -> FAIL
            with zipfile.ZipFile(os.path.join(ch, "lucia.usdz"), "w") as z: z.writestr("lucia.usdc", b"PXR-USDC")
            open(os.path.join(d, "Blend", "lucia.blend"), "wb").write(b"BLENDER")
            open(os.path.join(ch, "textures", "lucia_skin.png"), "wb").write(b"png")
            self.assertEqual(vm.main([ch, fx]), 0)
            self.assertEqual(vm.main([ch, fx, "--require-all"]), 1)       # other five characters missing
            open(os.path.join(ch, "lucia.usdz"), "wb").write(b"not a zip")
            self.assertEqual(vm.main([ch, fx]), 1)

if __name__ == "__main__":
    unittest.main()
