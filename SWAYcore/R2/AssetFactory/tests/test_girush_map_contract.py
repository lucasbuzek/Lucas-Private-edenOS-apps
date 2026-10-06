import json, pathlib, unittest
ROOT=pathlib.Path(__file__).resolve().parents[2]
class GirushMapContract(unittest.TestCase):
 def test_root_and_hips_do_not_alias_same_source_bone(self):
  m=json.load(open(ROOT/'AssetFactory/data/retarget_map_girush.json'))['map']
  self.assertTrue(set(m['Root']).isdisjoint(m['Hips']), 'Root and Hips must not map to the same source bone')
 def test_limb_joints_are_not_distal_helper_endpoints(self):
  m=json.load(open(ROOT/'AssetFactory/data/retarget_map_girush.json'))['map']
  for side,suffix in [('Left','L'),('Right','R')]:
   self.assertEqual(m[side+'LowerArm'],['LowerArm.'+suffix])
   self.assertEqual(m[side+'LowerLeg'],['Tibia.'+suffix])
if __name__=='__main__': unittest.main()
