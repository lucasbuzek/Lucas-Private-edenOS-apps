import binascii
import json
import struct
import subprocess
import unittest
import zlib
from pathlib import Path

R2 = Path(__file__).resolve().parents[2]
MANIFEST = R2 / "AssetFactory/data/puppet/lucia_puppet_manifest.json"
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"

def strict_png(path):
    """Decode every IDAT byte and validate every chunk CRC; no Pillow dependency."""
    data=path.read_bytes(); assert data.startswith(PNG_SIGNATURE), f"bad PNG signature: {path}"
    pos=8; packed=b""; seen_iend=False
    while pos < len(data):
        assert pos+12 <= len(data), f"truncated PNG chunk: {path}"
        length=struct.unpack(">I",data[pos:pos+4])[0]; kind=data[pos+4:pos+8]; end=pos+12+length
        assert end <= len(data), f"truncated {kind!r}: {path}"
        payload=data[pos+8:pos+8+length]; expected=struct.unpack(">I",data[pos+8+length:end])[0]
        assert binascii.crc32(kind+payload)&0xffffffff == expected, f"CRC failure in {kind!r}: {path}"
        if kind == b"IDAT": packed += payload
        if kind == b"IEND": seen_iend=True; assert end == len(data), f"bytes after IEND: {path}"
        pos=end
    assert seen_iend and packed, f"incomplete PNG: {path}"
    zlib.decompress(packed)

class LuciaPuppetAssetsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data=json.loads(MANIFEST.read_text())

    def test_sway_humanoid_has_23_unique_joints(self):
        self.assertEqual(23,len(self.data["jointNames"])); self.assertEqual(23,len(set(self.data["jointNames"])))

    def test_four_source_views_and_honest_three_quarter_fallbacks(self):
        for name in ("front","side_right","back","side_left"):
            self.assertEqual("available",self.data["angles"][name]["availability"])
        for name in ("front_three_quarter_right","back_three_quarter_right","back_three_quarter_left","front_three_quarter_left"):
            self.assertEqual("nearest_angle_fallback",self.data["angles"][name]["availability"])
            self.assertIn(self.data["angles"][name]["fallbackAngle"],("front","side_right","back","side_left"))

    def test_outputs_are_unique_true_vectors_and_pivots_normalized(self):
        names=[]
        for parts in self.data["partsByAngle"].values():
            for spec in parts.values():
                png=R2/spec["png1024"]; svg=R2/spec["svg"]
                self.assertTrue(png.is_file()); self.assertTrue(svg.is_file())
                self.assertIn("<path",svg.read_text())
                self.assertNotIn("data:image",svg.read_text())
                names.append(png.name)
                self.assertTrue(0 <= spec["pivot"]["x"] <= 1 and 0 <= spec["pivot"]["y"] <= 1)
        self.assertEqual(len(names),len(set(names)),"flat app-bundle basenames must never collide")

    def test_every_shipped_png_strictly_decodes(self):
        pngs=list((R2/"App/SWAY/Resources").rglob("*.png"))
        self.assertTrue(pngs)
        for path in pngs: strict_png(path)

    def test_posed_contact_sheets_and_tracks_exist(self):
        for name in ("lucia_angles_options.png","lucia_step_touch_8_frames.png","lucia_squat_8_frames.png","lucia_spin_8_frames.png"):
            strict_png(R2/"Docs/puppet_contact_sheets"/name)
        for name in ("lucia_step_touch_joint_track.json","lucia_squat_joint_track.json","lucia_spin_joint_track.json"):
            self.assertEqual(8,len(json.loads((R2/"Docs/puppet_contact_sheets"/name).read_text())))

    def test_alternates_are_explicitly_missing_not_fabricated(self):
        for category in ("hair","top","bottom","shoes"):
            self.assertEqual("MISSING",self.data["options"][category]["alternate"]["availability"])

if __name__ == "__main__": unittest.main()
