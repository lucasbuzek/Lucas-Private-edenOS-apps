import json
import unittest
from pathlib import Path

from PIL import Image


R2 = Path(__file__).resolve().parents[2]
MANIFEST_PATH = R2 / "AssetFactory/data/your_dancer_2_5d_components.json"
RUNTIME_MANIFEST_PATH = R2 / "App/SWAY/Resources/Avatars/User2_5D/your_dancer_2_5d_components.json"
CATALOG = R2 / "App/SWAY/Assets.xcassets"


class YourDancer2DComponentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest_bytes = MANIFEST_PATH.read_bytes()
        cls.manifest = json.loads(cls.manifest_bytes)

    def test_runtime_manifest_is_exact_factory_copy(self):
        self.assertEqual(RUNTIME_MANIFEST_PATH.read_bytes(), self.manifest_bytes)

    def test_manifest_contract_is_complete_and_explicit(self):
        manifest = self.manifest
        self.assertEqual(manifest["format"], "SWAY-YOUR-DANCER-2.5D-COMPONENTS")
        self.assertEqual(manifest["version"], 1)
        self.assertEqual(manifest["poseCount"], 12)
        layers = manifest["layers"]
        expected = {
            "hairBack", "body", "outfitBottom", "footwear", "outfitTop", "face",
            "eyes", "brows", "nose", "mouth", "facialHair", "hairFront", "accessory",
        }
        self.assertEqual({layer["id"] for layer in layers}, expected)
        orders = [layer["drawOrder"] for layer in layers]
        self.assertEqual(orders, sorted(orders))
        self.assertEqual(len(orders), len(set(orders)))
        self.assertTrue(all(layer["options"] for layer in layers))
        self.assertTrue(all("tintRole" in layer for layer in layers))

    def test_every_option_pose_is_an_rgba_pixel_aligned_asset(self):
        checked = 0
        for layer in self.manifest["layers"]:
            for option in layer["options"]:
                for pose in range(1, self.manifest["poseCount"] + 1):
                    reference_set = CATALOG / f"UserPose{pose:02d}Detail.imageset"
                    reference_png = next(reference_set.glob("*.png"))
                    with Image.open(reference_png) as reference:
                        expected_size = reference.size
                    asset_name = f"YD2D_{option['assetStem']}_P{pose:02d}"
                    imageset = CATALOG / f"{asset_name}.imageset"
                    self.assertTrue(imageset.is_dir(), f"missing imageset {asset_name}")
                    contents = json.loads((imageset / "Contents.json").read_text(encoding="utf-8"))
                    filenames = [entry.get("filename") for entry in contents["images"] if entry.get("filename")]
                    self.assertEqual(len(filenames), 1, f"{asset_name} must have one deterministic universal PNG")
                    png = imageset / filenames[0]
                    self.assertEqual(png.suffix.lower(), ".png")
                    with Image.open(png) as image:
                        self.assertEqual(image.size, expected_size, asset_name)
                        self.assertEqual(image.mode, "RGBA", f"{asset_name} must preserve alpha")
                        alpha_min, alpha_max = image.getchannel("A").getextrema()
                        self.assertLess(alpha_min, 255, f"{asset_name} has no transparent background")
                        if option["id"] != "none":
                            self.assertGreater(alpha_max, 0, f"{asset_name} is unexpectedly empty")
                    checked += 1
        self.assertGreater(checked, 0, "zero component assets checked")


if __name__ == "__main__":
    unittest.main()
