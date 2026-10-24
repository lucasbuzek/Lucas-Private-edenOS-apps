import pathlib,sys,unittest,math
sys.path.insert(0,str(pathlib.Path(__file__).resolve().parents[1]/'python'))
import retarget_math as rm

class NativeProportions(unittest.TestCase):
 def test_short_native_neck_preserves_length_at_large_authored_displacement(self):
  endpoint=rm.rest_relative_endpoint((.1,0,1.4),(0,0,.025),(0,0,.12),(-.06,0,.12))
  offset=rm.vsub(endpoint,(.1,0,1.4))
  self.assertAlmostEqual(rm.vlen(offset),.025)
  self.assertGreater(offset[2],0)
  self.assertAlmostEqual(rm.vdot(rm.vnorm(offset),rm.vnorm((-.06,0,.12))),1)
 def test_neutral_preserves_native_rest(self):
  self.assertEqual(rm.rest_relative_endpoint((0,0,1),(0,.01,.03),(0,0,.12),(0,0,.12)),(0,.01,1.03))
