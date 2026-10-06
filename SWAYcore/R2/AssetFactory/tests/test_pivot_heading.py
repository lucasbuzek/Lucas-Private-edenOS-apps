import math
import pathlib
import sys
import unittest
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / 'python'))
import coach_pose_port as cp

class PivotHeading(unittest.TestCase):
    def test_pivot_turns_both_sides_and_wraps_at_authored_cycle(self):
        self.assertAlmostEqual(cp.heading('pivot-turn', .5, 120), math.pi * 5 / 12)
        self.assertAlmostEqual(cp.heading('pivot-turn', 1.5, 120), -math.pi * 5 / 12)
        self.assertAlmostEqual(cp.heading('pivot-turn', 2, 120), 0)

    def test_heading_uses_the_same_tempo_and_floor_as_pose(self):
        self.assertAlmostEqual(cp.heading('pivot-turn', 3, 20), cp.heading('pivot-turn', .5, 120))
        self.assertAlmostEqual(cp.heading('pivot-turn', 3, 10), cp.heading('pivot-turn', 3, 20))
        self.assertEqual(cp.heading('pivot-turn', -1, 120), 0)

    def test_other_authored_moves_do_not_acquire_a_turn(self):
        for move in cp.AUTHORED:
            if move != 'pivot-turn':
                self.assertEqual(cp.heading(move, .5, 120), 0)

    def test_heading_is_time_derived_and_continuous(self):
        previous = cp.heading('pivot-turn', 0, 120)
        for frame in range(1, 49):
            current = cp.heading('pivot-turn', frame / 24, 120)
            self.assertLess(abs(current - previous), math.radians(11))
            self.assertEqual(current, cp.heading('pivot-turn', frame / 24, 120))
            previous = current
