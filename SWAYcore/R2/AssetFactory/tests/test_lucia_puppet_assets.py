import json
import subprocess
import unittest
from pathlib import Path

R2 = Path(__file__).resolve().parents[2]
MANIFEST = R2 / "AssetFactory/data/puppet/lucia_puppet_manifest.json"

class LuciaPuppetAssetsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        subprocess.run(["python3", str(R2 / "AssetFactory/python/build_lucia_puppet_assets.py")], check=True)
        cls.data = json.loads(MANIFEST.read_text())

    def test_sway_humanoid_has_23_unique_joints(self):
        joints = self.data["jointNames"]
        self.assertEqual(23, len(joints)); self.assertEqual(23, len(set(joints)))

    def test_pivots_round_trip_to_raster_with_half_pixel_precision(self):
        # The renderer obtains an exact pixel pivot from the normalized authored pivot.
        for part in self.data["parts"].values():
            width, height = part["rasterSize"]
            for x, y in part["pivots"].values():
                px, py = x * width, y * height
                self.assertLessEqual(abs(px / width - x) * width, 0.5)
                self.assertLessEqual(abs(py / height - y) * height, 0.5)

    def test_angles_are_ordered_and_missing_art_is_explicit(self):
        expected = ["front", "front_three_quarter_right", "side_right", "back_three_quarter_right", "back", "back_three_quarter_left", "side_left", "front_three_quarter_left"]
        self.assertEqual(expected, self.data["anglesInYawOrder"])
        self.assertEqual("available", self.data["angles"]["front"]["availability"])
        for name in expected[1:]:
            self.assertEqual("missing_fallback", self.data["angles"][name]["availability"])
            self.assertEqual("front", self.data["angles"][name]["fallbackAngle"])

    def test_option_fallbacks_never_claim_an_unavailable_swap(self):
        for category in ("hair", "top", "bottom", "shoes"):
            options = self.data["options"][category]
            self.assertEqual("available", options["base"]["availability"])
            self.assertEqual("missing", options["alternate"]["availability"])
            self.assertEqual("base", options["alternate"]["fallbackOption"])

    def test_all_declared_outputs_exist(self):
        for part in self.data["parts"].values():
            self.assertTrue((R2 / part["sourcePNG"]).is_file())
            self.assertTrue((R2 / part["png1024"]).is_file())
            self.assertTrue((R2 / part["svgPreservationCopy"]).is_file())

if __name__ == "__main__": unittest.main()
