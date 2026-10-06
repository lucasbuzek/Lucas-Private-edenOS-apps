"""Executes the Swift engine test scenarios against the Python mirror (see engine_mirror.py caveat)."""
import os, sys, unittest
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "reference_ports"))
from engine_mirror import *

class Cal(unittest.TestCase):
    def setUp(self): self.clock = 0.0
    def frame(self, t, ready=True, present=True, root=0.55, lw=Pt(.35,.55), rw=Pt(.65,.55), la=Pt(.45,.90), ra=Pt(.55,.90), **k):
        return Frame(t, present, ready, Pt(.5, root) if root is not None else None, lw, rw, la, ra)
    def pump(self, m, n, make):
        ev = []
        for i in range(n): ev += m.ingest(make(i/30 + self.clock, i))
        self.clock += n/30; return ev
    def wave(self, x0, i): return Pt(x0 + (0.03 if i%2==0 else -0.03), 0.40)
    def advance(self, target):
        m = Machine(); self.pump(m, 8, lambda t,i: self.frame(t))
        if target == WAVE_L: return m
        self.pump(m, 30, lambda t,i: self.frame(t, lw=self.wave(.35,i)))
        if target == WAVE_R: return m
        self.pump(m, 30, lambda t,i: self.frame(t, rw=self.wave(.65,i)))
        if target == LIFT_L: return m
        self.pump(m, 6, lambda t,i: self.frame(t, la=Pt(.45,.80)))
        if target == LIFT_R: return m
        self.pump(m, 6, lambda t,i: self.frame(t, ra=Pt(.55,.80))); return m
    def test_titles(self): self.assertEqual(TITLES, ["STEP INTO VIEW","WAVE LEFT","WAVE RIGHT","LIFT LEFT FOOT","LIFT RIGHT FOOT","JUMP","READY TO SWAY"])
    def test_happy_path(self):
        m = self.advance(JUMP); self.assertEqual(m.stage, JUMP)
        ev = self.pump(m, 4, lambda t,i: self.frame(t, root=0.45))
        self.assertTrue(m.is_ready); self.assertEqual(m.completed, [FRAME,WAVE_L,WAVE_R,LIFT_L,LIFT_R,JUMP]); self.assertEqual(ev.count("ready"), 1)
    def test_wrong_gesture(self):
        m = self.advance(WAVE_L)
        self.pump(m, 40, lambda t,i: self.frame(t, rw=self.wave(.65,i))); self.assertEqual(m.stage, WAVE_L)
        self.pump(m, 20, lambda t,i: self.frame(t, la=Pt(.45,.80))); self.assertEqual(m.stage, WAVE_L)
        m2 = self.advance(LIFT_L); self.pump(m2, 20, lambda t,i: self.frame(t, ra=Pt(.55,.80))); self.assertEqual(m2.stage, LIFT_L)
    def test_repeated_gesture_advances_once(self):
        m = self.advance(WAVE_L); self.pump(m, 120, lambda t,i: self.frame(t, lw=self.wave(.35,i)))
        self.assertEqual(m.stage, WAVE_R); self.assertEqual(m.completed, [FRAME, WAVE_L])
    def test_jitter_never_waves(self):
        m = self.advance(WAVE_L); self.pump(m, 900, lambda t,i: self.frame(t, lw=Pt(.35 + (0.0015 if i%2==0 else -0.0015), .55)))
        self.assertEqual(m.stage, WAVE_L)
    def test_missing_limb_and_low_conf(self):
        m = self.advance(WAVE_L); self.pump(m, 60, lambda t,i: self.frame(t, lw=None)); self.assertEqual(m.stage, WAVE_L); self.assertEqual(m.status, "SHOW YOUR LEFT HAND")
        f = Machine(); self.pump(f, 60, lambda t,i: self.frame(t, ready=False)); self.assertEqual(f.stage, FRAME); self.assertEqual(f.status, "STEP BACK — SHOW YOUR FEET")
        l = self.advance(LIFT_L); self.pump(l, 30, lambda t,i: self.frame(t, la=None)); self.assertEqual(l.stage, LIFT_L); self.assertEqual(l.status, "SHOW BOTH FEET")
    def test_tracking_loss_and_recovery(self):
        m = self.advance(LIFT_L); self.pump(m, 3, lambda t,i: self.frame(t, la=Pt(.45,.80)))
        lost = self.pump(m, 5, lambda t,i: self.frame(t, present=False, root=None, lw=None, rw=None, la=None, ra=None))
        self.assertIn("trackingLost", lost); self.assertTrue(m.lost); self.assertEqual(m.status, "STEP INTO VIEW")
        rec = self.pump(m, 1, lambda t,i: self.frame(t, la=Pt(.45,.80))); self.assertIn("trackingRecovered", rec); self.assertEqual(m.stage, LIFT_L)
        self.pump(m, 3, lambda t,i: self.frame(t, la=Pt(.45,.80))); self.assertEqual(m.stage, LIFT_R)
        self.assertEqual(m.completed, [FRAME, WAVE_L, WAVE_R, LIFT_L])
    def test_leaving_frame_never_completes_framing(self):
        m = Machine(); self.pump(m, 5, lambda t,i: self.frame(t))
        self.pump(m, 40, lambda t,i: self.frame(t, present=False, root=None, lw=None, rw=None, la=None, ra=None))
        self.pump(m, 5, lambda t,i: self.frame(t)); self.assertEqual(m.stage, FRAME)
    def test_timeout_once_and_continue(self):
        m = Machine(); ev = []
        for i in range(70*30): ev += m.ingest(self.frame(i/30, ready=False))
        self.assertEqual(ev.count(("timedOut", FRAME)), 1); self.assertTrue(m.timed_out); m.continue_after_timeout(); self.assertFalse(m.timed_out)
    def test_cancel_terminal(self):
        m = self.advance(WAVE_R); self.assertEqual(m.cancel(), ["cancelled"])
        ev = self.pump(m, 40, lambda t,i: self.frame(t, rw=self.wave(.65,i))); self.assertEqual(ev, []); self.assertEqual(m.stage, WAVE_R); self.assertEqual(m.cancel(), [])
    def test_orientation_change_invalidates_baseline(self):
        m = self.advance(LIFT_R); self.pump(m, 6, lambda t,i: self.frame(t, ra=Pt(.55,.80))); self.assertEqual(m.stage, JUMP)
        m.geometry_changed(); self.pump(m, 6, lambda t,i: self.frame(t, root=0.30)); self.assertEqual(m.stage, JUMP)
        self.pump(m, 12, lambda t,i: self.frame(t, root=0.30)); self.pump(m, 4, lambda t,i: self.frame(t, root=0.24)); self.assertTrue(m.is_ready)
    def test_slow_drift_is_not_a_jump(self):
        m = self.advance(LIFT_R); self.pump(m, 6, lambda t,i: self.frame(t, ra=Pt(.55,.80))); self.assertEqual(m.stage, JUMP)
        self.pump(m, 200, lambda t,i: self.frame(t, root=0.55 - i*0.0005)); self.assertEqual(m.stage, JUMP)
    def test_skip_jump_only_at_jump(self):
        m = self.advance(WAVE_L); self.assertEqual(m.skip_jump(), []); self.assertEqual(m.stage, WAVE_L)
        j = self.advance(LIFT_R); self.pump(j, 6, lambda t,i: self.frame(t, ra=Pt(.55,.80)))
        ev = j.skip_jump(); self.assertIn("ready", ev); self.assertTrue(j.low_impact); self.assertTrue(j.is_ready)

class Match(unittest.TestCase):
    REF = {"leftElbow": 90, "rightElbow": 90, "leftKnee": 160, "rightKnee": 160}
    def test_D001_zero_overlap_is_unknown_not_partial(self):
        self.assertEqual(match_score(self.REF, {"other": 1}, 0, .9, None)[:2], ("unknown","insufficientJointCoverage"))
    def test_D002_single_joint_is_not_enough(self):
        self.assertEqual(match_score(self.REF, {"leftElbow": 90}, 0, .9, None)[:2], ("unknown","insufficientJointCoverage"))
    def test_perfect_is_good(self): self.assertEqual(match_score(self.REF, dict(self.REF), 0, .9, None)[0], "good")
    def test_poor_with_evidence_is_not_matched_not_unknown(self):
        r = match_score(self.REF, {"leftElbow": 10, "rightElbow": 170, "leftKnee": 20, "rightKnee": 30}, 0.3, .9, None); self.assertEqual(r[0], "notMatched")
    def test_stale_lowconf_noref_noobs(self):
        self.assertEqual(match_score(self.REF, dict(self.REF), 0, .9, None, age=0.5)[1], "staleObservation")
        self.assertEqual(match_score(self.REF, dict(self.REF), 0, .1, None)[1], "lowDetectorConfidence")
        self.assertEqual(match_score({}, dict(self.REF), 0, .9, None)[1], "noReference")
        self.assertEqual(match_score(self.REF, {}, 0, .9, None)[1], "noObservation")
        self.assertEqual(match_score(self.REF, dict(self.REF), 0, float("nan"), None)[1], "lowDetectorConfidence")
    def test_deterministic(self):
        a = match_score(self.REF, {"leftElbow": 80, "rightElbow": 95, "leftKnee": 150, "rightKnee": 170}, 0.05, .8, .6)
        self.assertEqual(a, match_score(self.REF, {"leftElbow": 80, "rightElbow": 95, "leftKnee": 150, "rightKnee": 170}, 0.05, .8, .6))

class Timeline(unittest.TestCase):
    def test_20bpm_floor_honoured(self):
        p = position(3.0, 20); self.assertEqual((p["beat"], p["count"]), (1, 2))      # 3 s per beat at 20 BPM
        self.assertEqual(position(3.0, 10)["beat"], 1)                                # clamps to 20, not 40
    def test_old_40_floor_would_be_wrong(self):
        self.assertEqual(int(3.0 / (60/40)), 2)                                       # documents defect D-005 (as received: beat 2)
    def test_count_wrap_bar_phrase(self):
        p = position(60/120*40, 120); self.assertEqual((p["beat"], p["count"], p["bar"], p["phrase"]), (40, 1, 10, 1))
        self.assertEqual(position(0, 100)["count"], 1); self.assertEqual(position(60/100*7, 100)["count"], 8)
    def test_grid(self):
        g = [0.0, 0.5, 1.0, 1.6, 2.2]
        self.assertEqual(position(1.2, 120, g, 100)["beat"], 2); self.assertEqual(position(-1.0, 120, g)["beat"], 0)
        p = position(5.0, 120, g, 100); self.assertEqual(p["beat"], 4); self.assertLess(p["phase"], 1.0)
    def test_deterministic_and_monotonic(self):
        last = -1
        for i in range(2000):
            b = position(i*0.01, 97)["beat"]; self.assertGreaterEqual(b, last); last = b

if __name__ == "__main__": unittest.main(verbosity=1)
