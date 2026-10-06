"""Reproduction of defects found in the AS-RECEIVED candidate. These assert the DEFECT (they pass while the defect exists).
After repair, the Swift engine tests (Packages/SWAYcoreEngine) assert the corrected behaviour; this file documents the evidence."""
import os, sys, unittest
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "reference_ports"))
import candidate_matcher_port as m

class DEFECT_FalseCreditWithoutEvidence(unittest.TestCase):
    def test_zero_overlapping_joints_still_scores_partial(self):
        state, total = m.score({"leftElbow": 90, "rightElbow": 90}, {}, 0.0, 0.9, None)
        self.assertEqual(state, "partial")          # DEFECT: no observed joint overlaps the reference, yet PARTIAL
        self.assertGreater(total, 0.42)
        print("DEFECT D-001 reproduced: zero joint overlap -> %s total=%.3f" % (state, total))
    def test_one_joint_of_many_is_enough_for_credit(self):
        state, total = m.score({"leftElbow": 90, "rightElbow": 90, "leftKnee": 160, "rightKnee": 160}, {"leftElbow": 90}, 0.0, 0.9, None)
        self.assertEqual(state, "good")             # DEFECT: 1 of 4 reference joints -> GOOD
        print("DEFECT D-002 reproduced: 1/4 joints -> %s total=%.3f" % (state, total))

if __name__ == "__main__":
    unittest.main(verbosity=1)
