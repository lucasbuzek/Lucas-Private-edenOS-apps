"""Protected-contract characterization tests (static, source-level).
They pin behaviour the Authority documents declare protected. They are STATIC evidence only:
a pass here is NOT a build, NOT a simulator test and NOT physical acceptance.
Usage: python3 -m unittest Tools/regression/test_protected_contracts.py  (ROOT auto-detected, or SWAY_APP_DIR)"""
import json, os, re, unittest

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
APP = os.environ.get("SWAY_APP_DIR", os.path.join(ROOT, "App"))

def src(rel):
    with open(os.path.join(APP, rel), encoding="utf-8") as fh:
        return fh.read()

def all_swift():
    out = {}
    for d, _, fs in os.walk(os.path.join(APP, "SWAY")):
        for f in fs:
            if f.endswith(".swift"):
                p = os.path.join(d, f)
                with open(p, encoding="utf-8") as fh:
                    out[os.path.relpath(p, APP)] = fh.read()
    return out

class Identity(unittest.TestCase):
    def test_target_bundle_display_name_and_signing_preserved(self):
        y = src("project.yml")
        for needle in ["name: SWAY\n", "PRODUCT_BUNDLE_IDENTIFIER: com.lucasbuzek.private.sway",
                       'INFOPLIST_KEY_CFBundleDisplayName: "SWAYcore Dance & Fitness"', "DEVELOPMENT_TEAM: XZ4VRP5S5G",
                       "CODE_SIGN_STYLE: Automatic", "iOS: '26.0'", 'TARGETED_DEVICE_FAMILY: "1,2"']:
            self.assertIn(needle, y, needle)
    def test_orientations_cover_iphone_and_ipad(self):
        y = src("project.yml")
        self.assertIn("UIInterfaceOrientationLandscapeLeft", y); self.assertIn("UIInterfaceOrientationPortraitUpsideDown", y)
    def test_privacy_strings_present(self):
        y = src("project.yml")
        for k in ["NSCameraUsageDescription", "NSMicrophoneUsageDescription", "NSAppleMusicUsageDescription", "NSHealthShareUsageDescription", "NSHealthUpdateUsageDescription"]:
            self.assertIn(k, y)
    def test_entitlements_present(self):
        e = src("SWAY/SWAY.entitlements"); self.assertIn("com.apple.developer.healthkit", e)

class Navigation(unittest.TestCase):
    def test_four_primary_tabs_in_canonical_order(self):
        r = src("SWAY/Views/RootView.swift")
        labels = re.findall(r'Label\("(Home|Moves|Beats|Profile|You)"', r)
        self.assertEqual([l.upper() for l in labels[:4]], ["HOME", "MOVES", "BEATS", "PROFILE"])

class Calibration(unittest.TestCase):
    def test_exact_six_actions_then_ready_order(self):
        c = src("SWAY/Views/CameraLabView.swift")
        eng = src("../Packages/SWAYcoreEngine/Sources/SWAYcoreEngine/SwayCalibrationMachine.swift")
        enum = re.search(r"enum SwayCalibrationStage[^{]*\{\s*case ([^\n]+)", eng).group(1)
        self.assertEqual([x.strip() for x in enum.split(",")], ["frame", "waveLeft", "waveRight", "liftLeft", "liftRight", "jump", "ready"])
        self.assertIn("typealias SwayCalibrationStep = SwayCalibrationStage", c)
    def test_canonical_titles(self):
        c = src("SWAY/Views/CameraLabView.swift")
        eng = src("../Packages/SWAYcoreEngine/Sources/SWAYcoreEngine/SwayCalibrationMachine.swift")
        titles = re.findall(r'case \.(\w+): return "([^"]+)"', eng.split("var title")[1].split("public struct SwayPoint")[0])
        got = {k: v for k, v in titles}
        self.assertEqual(len(got), 7); self.assertEqual(got.get("frame"), "STEP INTO VIEW"); self.assertEqual(got.get("waveLeft"), "WAVE LEFT")
        self.assertEqual(got.get("waveRight"), "WAVE RIGHT"); self.assertEqual(got.get("liftLeft"), "LIFT LEFT FOOT")
        self.assertEqual(got.get("liftRight"), "LIFT RIGHT FOOT"); self.assertEqual(got.get("ready"), "READY TO SWAY")
        self.assertEqual(got.get("jump"), "JUMP", "Authority requires exactly JUMP")
    def test_calibration_logic_is_not_trapped_in_a_view(self):
        c = src("SWAY/Views/CameraLabView.swift")
        self.assertIn("SwayCalibrationMachine", c, "calibration decisions must come from the testable engine type")
        for legacy in ["motionScore", "stableFrames", "baselineRootY"]: self.assertNotIn(legacy, c, "decision state must not live in the view: " + legacy)

class Timing(unittest.TestCase):
    def test_timeline_is_time_derived_not_delta_accumulated(self):
        n = src("SWAY/Services/NativeCapabilities.swift")
        self.assertIn("Engine clock is time-derived", n)
        self.assertNotIn("elapsed += ", n.split("final class SwayTimelineEngine")[1].split("struct PoseJoint")[0])
    def test_workout_view_has_no_independent_timers(self):
        w = src("SWAY/Views/WorkoutPlayerView.swift")
        self.assertNotRegex(w, r"Timer\.(scheduledTimer|publish)")
    def test_learn_tempo_range_20_to_180(self):
        self.assertIn("in:20...180", src("SWAY/Views/MoveLibraryView.swift"))
    def test_shazam_is_anchor_not_clock(self):
        n = src("SWAY/Services/NativeCapabilities.swift"); self.assertIn("synchronization anchors, not render clocks", n)

class Scoring(unittest.TestCase):
    def test_matcher_delegates_to_engine_truth(self):
        n = src("SWAY/Services/NativeCapabilities.swift")
        self.assertIn("SwayMatchTruth.score(", n); self.assertIn("case notMatched", n)
        self.assertNotIn("let mean=pairs.isEmpty ? 90", n, "D-001 regression: empty joint overlap must not score")
    def test_tempo_floor_is_20_everywhere(self):
        for f, t in all_swift().items():
            self.assertNotRegex(t, r"max\(40(\.0)?\s*,", f + " reintroduces the 40 BPM floor (D-005)")
    def test_project_depends_on_engine_package(self):
        y = src("project.yml"); self.assertIn("SWAYcoreEngine", y); self.assertIn("../Packages/SWAYcoreEngine", y)

    def test_unknown_never_penalises(self):
        n = src("SWAY/Services/NativeCapabilities.swift")
        self.assertIn("UNKNOWN never punishes the dancer", n)
        eng = src("../Packages/SWAYcoreEngine/Sources/SWAYcoreEngine/SwayMatchTruth.swift")
        self.assertIn("detectorConfidence >= config.minDetectorConfidence", eng); self.assertIn("minDetectorConfidence = 0.30", eng)
    def test_tracking_states_include_loss_and_reacquire(self):
        n = src("SWAY/Services/NativeCapabilities.swift")
        for s in ["searching", "reacquiring", "lost", "bodyReady"]: self.assertIn("case " + s, n)

class Content(unittest.TestCase):
    def test_engine_contract_matches_json_authority(self):
        with open(os.path.join(APP, "AssetPipeline/contracts/SWAYHumanoid-v1.json")) as fh: c = json.load(fh)
        sw = src("../Packages/SWAYcoreEngine/Sources/SWAYcoreEngine/SwayHumanoidV1.swift")
        joints = re.findall(r'"([A-Za-z0-9]+)"', sw.split("public static let joints")[1].split("public static let requiredAnimations")[0])
        self.assertEqual(joints, c["joints"])
        clips = re.findall(r'"(sway_[a-z_0-9]+)"', sw.split("public static let requiredAnimations")[1].split("public static let parent")[0])
        self.assertEqual(clips, c["requiredAnimations"])
    def test_swaypack_envelope_v2_validates_and_limits(self):
        m = src("SWAY/Models/Move.swift")
        self.assertIn('format == "swaypack"', m); self.assertIn("(1...2).contains(version)", m); self.assertIn("duplicateIdentifiers", m)
    def test_music_providers_isolated(self):
        m = src("SWAY/Models/Move.swift")
        for p in ["appleMusic", "mediaLibrary", "localFile", "swayBeats"]: self.assertIn(p, m)
    def test_health_and_recording_symbols_exist(self):
        n = src("SWAY/Services/NativeCapabilities.swift")
        for s in ["SwayHealthWorkoutManager", "SwayPerformanceRecorder", "RPScreenRecorder", "HKWorkoutBuilder", "SHSession", "ApplicationMusicPlayer"]: self.assertIn(s, n)
    def test_twenty_authored_moves(self):
        s = src("SWAY/Views/StickFigureView.swift")
        ids = re.search(r"authoredMoveIDs:Set<String> = \[([^\]]+)\]", s).group(1)
        self.assertEqual(len(re.findall(r'"[^"]+"', ids)), 20)

class Assets(unittest.TestCase):
    def test_rig_contract_23_unique_joints_and_ten_clips(self):
        with open(os.path.join(APP, "AssetPipeline/contracts/SWAYHumanoid-v1.json")) as fh:
            c = json.load(fh)
        self.assertEqual(len(c["joints"]), 23); self.assertEqual(len(set(c["joints"])), 23); self.assertEqual(len(c["requiredAnimations"]), 10)
    def test_lucia_clips_bundled(self):
        d = os.path.join(APP, "SWAY/Resources/Characters/Lucia/Animations")
        self.assertEqual(len([f for f in os.listdir(d) if f.endswith(".usdc")]), 10)
    def test_no_stick_figure_selected_by_production_human_figure(self):
        s = src("SWAY/Views/StickFigureView.swift")
        tail = "\n".join(s.split("\n")[423:])
        self.assertNotIn("StickFigureView(", tail)

class Hazards(unittest.TestCase):
    def test_lexical_balance_all_swift(self):
        for f, t in all_swift().items():
            s = re.sub(r"/\*[\s\S]*?\*/", "", t)
            s = "\n".join(re.sub(r"//.*", "", re.sub(r'"(?:\\.|[^"\\])*"', '""', l)) for l in s.split("\n"))
            for a, b in ("{}", "()", "[]"): self.assertEqual(s.count(a), s.count(b), f + " " + a + b)

if __name__ == "__main__":
    unittest.main(verbosity=2)
