import pathlib,sys,unittest
sys.path.insert(0,str(pathlib.Path(__file__).resolve().parents[1]/'python'))
import motion_evidence as me

class MotionEvidenceTests(unittest.TestCase):
    def test_a_pose_cannot_pass_authored_arms_down(self):
        self.assertGreater(me.direction_error((.427,-.178),(.07,-.30)),35)
    def test_projected_direction_preserves_native_proportions(self):
        self.assertAlmostEqual(me.direction_error((.14,-.60),(.07,-.30)),0,places=5)
    def test_extreme_frame_is_included_between_quarter_samples(self):
        frames=me.representative_frames(1,49,{7:9.0,13:2.0,25:1.0})
        self.assertEqual(frames,[1,7,13,25,37,49])
    def test_nonfinite_measurements_fail_closed(self):
        with self.assertRaises(ValueError):me.representative_frames(1,49,{7:float('nan')})
    def test_quaternion_sign_flip_is_not_a_motion_jump(self):
        self.assertAlmostEqual(me.rotation_distance((1,0,0,0),(-1,0,0,0)),0)
    def test_quarter_turn_is_detected(self):
        from math import sqrt
        self.assertAlmostEqual(me.rotation_distance((1,0,0,0),(sqrt(.5),0,0,sqrt(.5))),90)
    def test_zero_quaternion_is_rejected(self):
        with self.assertRaises(ValueError):me.rotation_distance((0,0,0,0),(1,0,0,0))
if __name__=='__main__':unittest.main()
