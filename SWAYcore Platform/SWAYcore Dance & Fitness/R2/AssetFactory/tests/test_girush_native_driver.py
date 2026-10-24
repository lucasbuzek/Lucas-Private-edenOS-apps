import pathlib, unittest
class GirushNativeDriverContract(unittest.TestCase):
 def test_driver_preserves_native_deform_chain(self):
  p=pathlib.Path('AssetFactory/blender/sway_add_native_driver.py')
  self.assertTrue(p.exists(),'native driver production script missing')
  s=p.read_text()
  self.assertIn('COPY_ROTATION',s)
  self.assertIn('COPY_LOCATION',s)
  self.assertIn('sway_native_skinning',s)
  self.assertNotIn("constraints.new('COPY_TRANSFORMS')",s)
if __name__=='__main__': unittest.main()
