import unittest
from pathlib import Path
class ConverterHeightContract(unittest.TestCase):
 def test_converter_contains_character_height_normalization(self):
  s=Path('AssetFactory/blender/sway_convert_base.py').read_text()
  self.assertIn('heightMeters',s)
  self.assertIn('target_height',s)
  self.assertIn('scale_factor',s)
if __name__=='__main__': unittest.main()
