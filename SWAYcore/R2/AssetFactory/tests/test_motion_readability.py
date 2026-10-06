import math
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "python"))
import coach_pose_port as cp


class ProductionMotionReadability(unittest.TestCase):
    """Numeric intent gates complement renders; they never claim human visual approval."""

    def test_squat_has_production_depth_and_knee_tracking(self):
        pose = cp.pose("squat-pulse", 0.25, 120)
        self.assertGreaterEqual(pose["hip"][1] - cp.NEUTRAL["hip"][1], 0.15)
        self.assertGreaterEqual(cp.NEUTRAL["leftKnee"][0] - pose["leftKnee"][0], 0.085)
        self.assertGreaterEqual(pose["rightKnee"][0] - cp.NEUTRAL["rightKnee"][0], 0.085)

    def test_lunge_combines_travel_with_visible_level_change(self):
        pose = cp.pose("side-lunge", 0.25, 120)
        self.assertGreaterEqual(abs(pose["rightFoot"][0] - cp.NEUTRAL["rightFoot"][0]), 0.175)
        self.assertGreaterEqual(pose["hip"][1] - cp.NEUTRAL["hip"][1], 0.07)

    def test_body_roll_separates_upper_and_lower_landmarks(self):
        pose = cp.pose("body-roll", 0.25, 120)
        counter_travel = abs((pose["neck"][0] - cp.NEUTRAL["neck"][0]) -
                             (pose["hip"][0] - cp.NEUTRAL["hip"][0]))
        self.assertGreaterEqual(counter_travel, 0.105)
        self.assertGreaterEqual(cp.NEUTRAL["neck"][1] - pose["neck"][1], 0.04)

    def test_pivot_reaches_seventy_five_degrees(self):
        self.assertAlmostEqual(cp.heading("pivot-turn", 0.5, 120), math.radians(75))


if __name__ == "__main__":
    unittest.main()
