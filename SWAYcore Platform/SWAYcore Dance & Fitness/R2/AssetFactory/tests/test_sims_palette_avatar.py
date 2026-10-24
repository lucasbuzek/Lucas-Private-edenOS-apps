import json
import unittest
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "App/SWAY/Resources/Puppets/YourDancerRig"


class SimsInspiredPaletteContract(unittest.TestCase):
    """Production CAS choices must resolve to actual distinct offline art."""

    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads((ASSETS / "yourDancer_palette_manifest.json").read_text())

    def test_real_skins_and_outfits_have_nine_resolutions_per_part(self):
        catalog = self.manifest
        self.assertEqual(catalog["format"], "SWAY-YOUR-DANCER-PALETTE")
        self.assertEqual(catalog["version"], 1)
        self.assertEqual(catalog["skins"], ["Light", "Medium", "Umber"])
        self.assertEqual(catalog["outfits"], ["Emerald", "Ocean", "Violet"])
        self.assertEqual((catalog["defaultSkin"], catalog["defaultOutfit"]), (2, 0))
        self.assertEqual(len(catalog["assets"]), 45)
        self.assertGreater(catalog["generatedCount"], 80)
        for base, choices in catalog["assets"].items():
            self.assertTrue(base.startswith("yourDancer_"))
            self.assertEqual(len(choices), 9, base)
            self.assertEqual(choices["skin2_outfit0"], base, base)
            for s in range(3):
                for o in range(3):
                    name = choices[f"skin{s}_outfit{o}"]
                    self.assertTrue((ASSETS / name).is_file(), name)

    def test_every_generated_png_preserves_original_alpha_and_geometry(self):
        inspected = set()
        for base, choices in self.manifest["assets"].items():
            with Image.open(ASSETS / base) as source:
                width, height = source.size
                original_alpha = source.convert("RGBA").getchannel("A").tobytes()
                original_rgb = source.convert("RGBA").convert("RGB").tobytes()
            for name in choices.values():
                if name in inspected:
                    continue
                inspected.add(name)
                with Image.open(ASSETS / name) as image:
                    self.assertEqual(image.size, (width, height), name)
                    rgba = image.convert("RGBA")
                    self.assertEqual(rgba.getchannel("A").tobytes(), original_alpha, name)
                    if name != base:
                        self.assertNotEqual(rgba.convert("RGB").tobytes(), original_rgb, name)

    def test_visible_choice_differences_exist_in_all_three_views(self):
        for view in ("front", "back", "side"):
            head = self.manifest["assets"][f"yourDancer_{view}_head.png"]
            chest = self.manifest["assets"][f"yourDancer_{view}_chest.png"]
            self.assertNotEqual(head["skin0_outfit0"], head["skin2_outfit0"])
            self.assertNotEqual(head["skin1_outfit0"], head["skin2_outfit0"])
            self.assertNotEqual(chest["skin2_outfit1"], chest["skin2_outfit0"])
            self.assertNotEqual(chest["skin2_outfit2"], chest["skin2_outfit0"])


if __name__ == "__main__":
    unittest.main()
