import pathlib,sys,unittest
sys.path.insert(0,str(pathlib.Path(__file__).resolve().parents[1]/'python'))
import skin_weights as sw
class SkinWeightTests(unittest.TestCase):
 def test_limit_normalizes_strongest_four_without_renaming_native_bones(self):
  self.assertEqual(sw.limit_weights({'hand.helper':4,'arm':3,'twist':2,'wrist':1,'spine':.5}),{'hand.helper':.4,'arm':.3,'twist':.2,'wrist':.1})
 def test_hidden_visibility_is_irrelevant_to_weight_math(self):
  self.assertEqual(sw.limit_weights({'helper':.2,'bone':.3}),{'bone':.6,'helper':.4})
 def test_nonfinite_or_negative_inputs_are_rejected(self):
  for value in [float('nan'),float('inf'),-.1]:
   with self.assertRaises(ValueError):sw.limit_weights({'bone':value})
 def test_no_source_weights_are_not_invented(self):
  with self.assertRaises(ValueError):sw.limit_weights({})
 def test_native_body_cannot_bypass_four_influence_gate(self):
  self.assertTrue(sw.weight_issues([{str(i):.2 for i in range(5)}],{str(i) for i in range(5)}))
 def test_body_16_and_17_bones_fail_18_bone_contract(self):
  for count in [16,17]:self.assertIn('body coverage', ' '.join(sw.weight_issues([{str(i):1.} for i in range(count)],{str(i) for i in range(count)},minimum_used=18)))
  self.assertEqual(sw.weight_issues([{str(i):1.} for i in range(18)],{str(i) for i in range(18)},minimum_used=18),[])
 def test_native_body_cannot_bypass_normalization(self):
  self.assertTrue(sw.weight_issues([{'helper':.3}],{'helper'}))
 def test_foreign_and_unweighted_vertices_rejected(self):
  self.assertTrue(sw.weight_issues([{'missing':1.}],{'bone'}))
  self.assertTrue(sw.weight_issues([{}],{'bone'}))
if __name__=='__main__':unittest.main()
