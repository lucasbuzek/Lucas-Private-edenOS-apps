import json, os, sys, math, unittest, tempfile, random
HERE = os.path.dirname(os.path.abspath(__file__)); AF = os.path.join(HERE, ".."); sys.path.insert(0, os.path.join(AF, "python"))
import retarget_math as rm, provenance as pv, bone_aliases as ba, coach_pose_port as cp

APP = os.path.join(AF, "..", "App")
with open(os.path.join(APP, "AssetPipeline/contracts/SWAYHumanoid-v1.json")) as fh: CONTRACT = json.load(fh)
JOINTS = CONTRACT["joints"]
PARENT = {"Hips":"Root","Spine":"Hips","Spine1":"Spine","Chest":"Spine1","Neck":"Chest","Head":"Neck"}
CHILD = {"Root":"Hips","Hips":"Spine","Spine":"Spine1","Spine1":"Chest","Chest":"Neck","Neck":"Head"}
for s in ("Left","Right"):
    x = 1 if s == "Left" else -1
    PARENT.update({s+"Shoulder":"Chest", s+"UpperArm":s+"Shoulder", s+"LowerArm":s+"UpperArm", s+"Hand":s+"LowerArm",
                   s+"UpperLeg":"Hips", s+"LowerLeg":s+"UpperLeg", s+"Foot":s+"LowerLeg", s+"Toe":s+"Foot"})
    CHILD.update({s+"Shoulder":s+"UpperArm", s+"UpperArm":s+"LowerArm", s+"LowerArm":s+"Hand", s+"UpperLeg":s+"LowerLeg", s+"LowerLeg":s+"Foot", s+"Foot":s+"Toe"})
REST = {"Root":(0,0,0.95),"Hips":(0,0,1.0),"Spine":(0,0,1.12),"Spine1":(0,0,1.24),"Chest":(0,0,1.36),"Neck":(0,0,1.55),"Head":(0,0,1.65)}
for s, x in (("Left", 1), ("Right", -1)):
    REST.update({s+"Shoulder":(0.05*x,0,1.50), s+"UpperArm":(0.18*x,0,1.50), s+"LowerArm":(0.46*x,0,1.50), s+"Hand":(0.72*x,0,1.50),
                 s+"UpperLeg":(0.09*x,0,0.98), s+"LowerLeg":(0.09*x,0,0.55), s+"Foot":(0.09*x,0,0.10), s+"Toe":(0.09*x,-0.12,0.03)})

def rest_rot(j):
    c = CHILD.get(j)
    d = rm.vsub(REST[c], REST[j]) if c else (0, 0, 1)
    q = rm.aim((0, 1, 0), d)                       # Blender bones point along +Y; arbitrary but deterministic roll
    return rm.qmul(q, rm.qnorm((math.cos(0.3), 0, math.sin(0.3), 0)))   # extra roll about local Y to stress the conjugation

class Retarget(unittest.TestCase):
    def test_contract_has_23_joints_and_hierarchy_matches(self):
        self.assertEqual(len(JOINTS), 23); self.assertEqual(set(JOINTS), set(REST))
        for j in JOINTS:
            if j != "Root": self.assertIn(PARENT[j], JOINTS)
    def test_aim_maps_rest_to_target(self):
        rng = random.Random(7)
        for _ in range(200):
            a = rm.vnorm((rng.uniform(-1,1), rng.uniform(-1,1), rng.uniform(-1,1))); b = rm.vnorm((rng.uniform(-1,1), rng.uniform(-1,1), rng.uniform(-1,1)))
            r = rm.qrot(rm.aim(a, b), a)
            for i in range(3): self.assertAlmostEqual(r[i], b[i], places=6)
        r = rm.qrot(rm.aim((0,0,1), (0,0,-1)), (0,0,1)); self.assertAlmostEqual(r[2], -1.0, places=6)   # antipodal
    def test_solved_basis_reproduces_target_directions_via_forward_kinematics(self):
        rng = random.Random(3)
        R = {j: rest_rot(j) for j in JOINTS}
        for trial in range(25):
            tgt = {}
            for j in JOINTS:                                  # target pose = rest joints rotated/perturbed per-bone so directions differ
                tgt[j] = tuple(REST[j][i] + rng.uniform(-0.25, 0.25) for i in range(3))
            q, basis = rm.solve_pose(JOINTS, PARENT, CHILD, REST, R, tgt)
            dirs = rm.forward_world_dirs(JOINTS, PARENT, CHILD, REST, R, basis)
            for j, d in dirs.items():
                want = rm.vnorm(rm.vsub(tgt[CHILD[j]], tgt[j]))
                for i in range(3): self.assertAlmostEqual(d[i], want[i], places=5, msg="%s trial %d" % (j, trial))
    def test_rest_target_gives_identity_basis(self):
        R = {j: rest_rot(j) for j in JOINTS}; q, basis = rm.solve_pose(JOINTS, PARENT, CHILD, REST, R, dict(REST))
        for j in JOINTS:
            self.assertAlmostEqual(abs(basis[j][0]), 1.0, places=6, msg=j)

class CoachPort(unittest.TestCase):
    def test_in_sync_with_swift_source(self): cp.assert_in_sync(os.path.join(APP, "SWAY/Views/StickFigureView.swift"))
    def test_all_supported_moves_produce_complete_deterministic_poses(self):
        # All 26 bundled official Moves have a real, deterministic pose port.
        # The separate 20-clip baked asset fixture remains a historical gate.
        self.assertGreaterEqual(len(cp.AUTHORED), 26)
        for m in cp.AUTHORED:
            a = cp.pose(m, 1.234, 120); b = cp.pose(m, 1.234, 120)
            self.assertEqual(a, b); self.assertEqual(set(a), set(cp.JOINTS))
    def test_cycle_wraps_after_eight_beats_for_periodic_moves(self):
        for m in cp.AUTHORED:
            a = cp.pose(m, 0.0, 120); b = cp.pose(m, 8 * 0.5, 120)
            for k in cp.JOINTS:
                for i in (0, 1): self.assertAlmostEqual(a[k][i], b[k][i], places=6, msg="%s %s" % (m, k))
    def test_20_bpm_is_not_clamped_to_40(self):
        self.assertAlmostEqual(cp.pose("march", 3.0, 20)["leftKnee"][1], cp.pose("march", 3.0, 10)["leftKnee"][1])   # 10 clamps to 20
        self.assertNotAlmostEqual(cp.pose("march", 0.5, 20)["leftKnee"][1], cp.pose("march", 0.5, 40)["leftKnee"][1], places=3)
    def test_pose_to_rig_mapping_is_mirror_and_complete(self):
        self.assertEqual(set(rm.POSE_TO_RIG), set(cp.JOINTS)); self.assertEqual(len(set(rm.POSE_TO_RIG.values())), len(cp.JOINTS))
        self.assertTrue(set(rm.POSE_TO_RIG.values()) <= set(JOINTS))
        self.assertEqual(rm.POSE_TO_RIG["leftHand"], "RightHand")     # ND-012 mirror display
    def test_display_to_rig_axes(self):
        p = rm.display_to_rig((0.6, 0.4), (0.5, 0.56), 1.0); self.assertGreater(p[0], 0); self.assertGreater(p[2], 0)   # right of hips & above

class Provenance(unittest.TestCase):
    good = {"id": "x", "name": "n", "url": "https://example.org", "licence_id": "CC0-1.0", "decision": "ADAPT", "retrieved": "2026-10-04",
            "licence_text_sha256": "ab", "rights": {"commercial": True, "modification": True, "redistribution": True, "app_distribution": True}}
    def test_cc0_with_confirmed_rights_passes(self): self.assertEqual(pv.validate_entry(dict(self.good)), [])
    def test_unknown_or_unlisted_licence_cannot_be_incorporated(self):
        for lic in ("", "CC-BY-4.0", "proprietary", "unknown"):
            e = dict(self.good, licence_id=lic); self.assertTrue(pv.validate_entry(e), lic)
    def test_reference_or_reject_may_have_any_licence(self):
        for d in ("REFERENCE", "REJECT"): self.assertEqual(pv.validate_entry(dict(self.good, licence_id="proprietary", decision=d, rights={})), [])
    def test_missing_rights_or_licence_archive_blocks_adoption(self):
        e = dict(self.good); e["rights"] = dict(e["rights"], commercial=False); self.assertTrue(pv.validate_entry(e))
        e = dict(self.good); del e["licence_text_sha256"]; self.assertTrue(pv.validate_entry(e))
    def test_files_checksum_verified(self):
        with tempfile.TemporaryDirectory() as d:
            p = os.path.join(d, "m.glb"); open(p, "wb").write(b"abc")
            e = dict(self.good, files=[{"path": "m.glb", "sha256": pv.sha256_file(p)}]); self.assertEqual(pv.validate_entry(e, d, True), [])
            open(p, "wb").write(b"tampered"); self.assertTrue(pv.validate_entry(e, d, True))
    def test_shipped_ledger_is_consistent(self):
        ledger = os.path.join(AF, "PROVENANCE", "ledger.json")
        res = pv.validate_ledger(ledger, os.path.join(AF, ".."), require_files=False)
        self.assertTrue(res); self.assertEqual({k: v for k, v in res.items() if v}, {})

class Aliases(unittest.TestCase):
    def test_ue_style_rig_maps_completely(self):
        m = ba.load_map(os.path.join(AF, "data", "retarget_map_ue_mannequin.json"))
        bones = ["root","pelvis","spine_01","spine_02","spine_03","neck_01","head","clavicle_l","upperarm_l","lowerarm_l","hand_l","index_01_l",
                 "clavicle_r","upperarm_r","lowerarm_r","hand_r","thigh_l","calf_l","foot_l","ball_l","thigh_r","calf_r","foot_r","ball_r","jaw"]
        got, missing = ba.resolve(bones, m); self.assertEqual(missing, []); self.assertEqual(set(got), set(JOINTS))
    def test_case_and_suffix_variants_and_missing_reported_not_guessed(self):
        m = ba.load_map(os.path.join(AF, "data", "retarget_map_ue_mannequin.json"))
        got, missing = ba.resolve(["Pelvis", "UpperArm_L", "upperarm.R", "Head"], m)
        self.assertEqual(got["Hips"], "Pelvis"); self.assertEqual(got["LeftUpperArm"], "UpperArm_L"); self.assertEqual(got["RightUpperArm"], "upperarm.R")
        self.assertIn("LeftHand", missing); self.assertIn("Root", missing)

class RuntimeAssetValidator(unittest.TestCase):
    def setUp(self):
        import validate_runtime_assets as v; self.v = v
        with open(os.path.join(AF, "data", "clip_manifest.json")) as fh: self.clips = json.load(fh)["clips"]
    def fixture_validate(self, argv):
        import contextlib, io
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            result = self.v.main(argv)
        label = "NEGATIVE_FIXTURE" if result else "POSITIVE_FIXTURE"
        for line in output.getvalue().splitlines():
            print(label + ": " + line)
        return result

    def make(self, d, approved=False, drop=None, tiny=False):
        os.makedirs(os.path.join(d, "Animations"), exist_ok=True)
        open(os.path.join(d, "LuciaReality.usdc"), "wb").write(b"PXR-USDC" + b"0" * (10 if tiny else 30000))
        anims = {}
        for c in self.clips:
            anims[c["move"]] = {"resource": c["clip"], "beatsPerCycle": c["beatsPerCycle"], "loop": True}
            if c["clip"] != drop: open(os.path.join(d, "Animations", c["clip"] + ".usdc"), "wb").write(b"PXR-USDC" + b"0" * 100)
        json.dump({"characterID": "lucia", "skeletonContract": "SWAYHumanoid-v1", "rootJoint": "Root", "hipsJoint": "Hips", "assetBaseName": "LuciaReality",
                   "animations": anims, "runtimeApproved": approved}, open(os.path.join(d, "lucia.character.json"), "w"))
    def test_valid_set_passes_structurally(self):
        with tempfile.TemporaryDirectory() as t:
            self.make(os.path.join(t, "Lucia")); self.assertEqual(self.fixture_validate([t, os.path.join(AF, "data", "clip_manifest.json"), "--require", "Lucia"]), 0)
    def test_missing_clip_tiny_base_and_self_approval_fail(self):
        cm = os.path.join(AF, "data", "clip_manifest.json")
        for kw in ({"drop": "sway_march_v1"}, {"tiny": True}, {"approved": True}):
            with tempfile.TemporaryDirectory() as t:
                self.make(os.path.join(t, "Lucia"), **kw); self.assertEqual(self.fixture_validate([t, cm]), 1, kw)
    def test_explicit_alpha_scope_does_not_require_or_approve_broken_beta(self):
        cm = os.path.join(AF, "data", "clip_manifest.json")
        with tempfile.TemporaryDirectory() as t:
            self.make(os.path.join(t, "Lucia")); self.make(os.path.join(t, "YourDancer"))
            os.mkdir(os.path.join(t, "Nandi"))
            self.assertEqual(self.fixture_validate([t, cm, "--require", "Lucia,YourDancer", "--only-required"]), 0)
            self.assertEqual(self.fixture_validate([t, cm]), 1)

    def test_alpha_scope_still_fails_missing_yourdancer(self):
        cm = os.path.join(AF, "data", "clip_manifest.json")
        with tempfile.TemporaryDirectory() as t:
            self.make(os.path.join(t, "Lucia"))
            self.assertEqual(self.fixture_validate([t, cm, "--require", "Lucia,YourDancer", "--only-required"]), 1)

    def test_absent_required_character_fails_and_empty_is_unknown_not_pass(self):
        cm = os.path.join(AF, "data", "clip_manifest.json")
        with tempfile.TemporaryDirectory() as t:
            self.assertEqual(self.fixture_validate([t, cm, "--require", "Lucia"]), 1); self.assertEqual(self.fixture_validate([t, cm]), 1)

class ClipManifest(unittest.TestCase):
    def test_periods_are_true_periods_and_names_unique_and_proof_clips_kept(self):
        with open(os.path.join(AF, "data", "clip_manifest.json")) as fh: m = json.load(fh)
        names = [c["clip"] for c in m["clips"]]; self.assertEqual(len(names), len(set(names)))
        for p in CONTRACT["requiredAnimations"]: self.assertIn(p, names)
        self.assertEqual(len([c for c in m["clips"] if not c.get("synthetic")]), 20)          # all 20 authored coach moves
        for c in m["clips"]:
            if c.get("synthetic"): continue
            spb = 0.5; n = c["beatsPerCycle"] * spb
            for i in range(40):
                t = i * 0.041; a = cp.pose(c["move"], t, 120); b = cp.pose(c["move"], t + n, 120)
                for k in a:
                    for j in (0, 1): self.assertAlmostEqual(a[k][j], b[k][j], places=6, msg=c["move"])
    def test_characters_json_has_the_six_identities(self):
        with open(os.path.join(AF, "data", "characters.json")) as fh: ids = [c["id"] for c in json.load(fh)["characters"]]
        self.assertEqual(ids, ["lucia", "nandi", "thabo", "zuri", "kyle", "yourdancer"])
if __name__ == "__main__": unittest.main(verbosity=1)
