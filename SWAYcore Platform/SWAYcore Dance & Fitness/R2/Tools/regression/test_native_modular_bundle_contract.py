"""SWAYcore Gate B: native 44-module / 21-clip bundle acceptance.
No avatars are approved by this test, and no app/device is launched.
Pass SWAY_QA_APP to verify the actual unsigned built iOS simulator bundle.
"""
from __future__ import annotations
import copy
from hashlib import sha256
import json
import os
from pathlib import Path
import unittest

R = Path(__file__).resolve().parents[2]
SRC = R / "Build/native3d_convergence_20261018/native_modular_surface_shell_44_shared21_unapproved_20261021"
QA = R / "App/SWAY/Resources/SWAYNativeUnapproved.bundle"
INNER = Path("Characters/UserAvatar")
FILES_REQUIRED = 44 + 21

def validate(manifest: dict, root: Path, check_disk: bool=True) -> list[Path]:
    if manifest.get("characterID") != "user":
        raise ValueError("wrong character")
    if manifest.get("skeletonContract") != "SWAYHumanoid-v1":
        raise ValueError("wrong skeleton")
    if manifest.get("runtimeApproved") is not False:
        raise ValueError("candidate must remain unapproved")
    if manifest.get("visualQuality") != "UNREVIEWED":
        raise ValueError("candidate must remain visually unreviewed")
    if manifest.get("maximumSimultaneousNativeModels") != 12:
        raise ValueError("model cap incorrect")
    modules = manifest.get("moduleAssets")
    names = manifest.get("moduleMeshNames")
    clips = manifest.get("sharedAnimationPaths")
    animations = manifest.get("animations")
    if not isinstance(modules, dict) or not isinstance(names, list) or len(modules)!=44 or len(names)!=44 or set(modules)!=set(names):
        raise ValueError("not exactly 44 contracted module options")
    if not isinstance(animations,dict) or not isinstance(clips,dict) or len(animations)!=21 or len(clips)!=21 or set(clips)!=set(animations):
        raise ValueError("not exactly 21 contracted clips")
    paths = []
    for name, value in modules.items():
        expected = "Modules/" + name + "/SWAYModule.usdc"
        if not name.startswith("YD_") or value != expected:
            raise ValueError("module path mismatch")
        paths.append(root / value)
    for move, value in clips.items():
        expected = "Animations/" + animations[move]["resource"] + ".usdc"
        if value != expected or not move or animations[move].get("beatsPerCycle",0)<=0:
            raise ValueError("shared animation path mismatch")
        paths.append(root / value)
    if len(set(paths)) != FILES_REQUIRED:
        raise ValueError("duplicate file paths")
    if check_disk and not all(p.is_file() and p.stat().st_size>0 for p in paths):
        raise ValueError("missing or empty physical resource")
    return paths


class NativeModularResourceAcceptance(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (SRC / "user.character.json").is_file():
            raise unittest.SkipTest("native 44/21 candidate absent, no acceptance claim")
        cls.m = json.loads((SRC / "user.character.json").read_text())

    def test_01_real_native_source_44_21_files(self):
        self.assertEqual(len(validate(self.m,SRC)),65)

    def test_02_QA_bundle_is_still_unapproved(self):
        m=json.loads((QA / INNER / "user.character.json").read_text())
        self.assertIs(m["runtimeApproved"],False)
        self.assertEqual(len(validate(m,QA/INNER)),65)

    def test_03_bundle_binary_hash_matches_source(self):
        receipt=json.loads((QA/"QA_RESOURCE_SHA256.json").read_text())
        self.assertEqual(receipt["status"],"UNAPPROVED_NOT_FOR_RELEASE")
        for rel,digest in receipt["files"].items():
            src=SRC/rel
            tgt=QA/INNER/rel
            self.assertEqual(sha256(src.read_bytes()).hexdigest(),digest)
            self.assertEqual(sha256(tgt.read_bytes()).hexdigest(),digest)
        self.assertEqual(len(receipt["files"]),66)

    def test_04_existing_app_manifest_preserved_and_disabled(self):
        p=R/"App/SWAY/Resources/Characters/UserAvatar/user.character.json"
        d=json.loads(p.read_text())
        self.assertIs(d["runtimeApproved"],False)
        self.assertIsNone(d.get("moduleAssets"))
        self.assertEqual(len(d["animations"]),10)

    def test_05_no_approved_candidate_in_runtime_paths(self):
        self.assertFalse((R/"App/SWAY/Resources/Characters/UserAvatar/Modules").exists())
        self.assertFalse((R/"App/SWAY/Resources/Characters/UserAvatar/Animations/sway_arm_reach_v1.usdc").exists())

    def test_06_reject_wrong_skeleton(self):
        m=copy.deepcopy(self.m);m["skeletonContract"]="puppet-v2"
        with self.assertRaisesRegex(ValueError,"skeleton"):validate(m,SRC,False)

    def test_07_reject_approval_flip(self):
        m=copy.deepcopy(self.m);m["runtimeApproved"]=True
        with self.assertRaisesRegex(ValueError,"unapproved"):validate(m,SRC,False)

    def test_08_reject_bad_module_count(self):
        m=copy.deepcopy(self.m);m["moduleAssets"].pop(next(iter(m["moduleAssets"])))
        with self.assertRaisesRegex(ValueError,"44"):validate(m,SRC,False)

    def test_09_reject_path_escape(self):
        m=copy.deepcopy(self.m);k=next(iter(m["moduleAssets"]))
        m["moduleAssets"][k]="../../private/secret.usdc"
        with self.assertRaisesRegex(ValueError,"path mismatch"):validate(m,SRC,False)

    def test_10_reject_clip_mismatch(self):
        m=copy.deepcopy(self.m);k=next(iter(m["sharedAnimationPaths"]))
        m["sharedAnimationPaths"][k]="Animations/missing.usdc"
        with self.assertRaisesRegex(ValueError,"animation path"):validate(m,SRC,False)

    def test_11_reject_model_cap_escalation(self):
        m=copy.deepcopy(self.m);m["maximumSimultaneousNativeModels"]=13
        with self.assertRaisesRegex(ValueError,"cap"):validate(m,SRC,False)

    def test_12_reject_missing_physical_module(self):
        m=copy.deepcopy(self.m)
        with self.assertRaisesRegex(ValueError,"physical resource"):
            validate(m,Path("/private/tmp/does-not-exist-SWAY-native-assets"),True)

    def test_13_actual_built_app_nested_QA_bundle(self):
        path=os.environ.get("SWAY_QA_APP")
        if not path:
            self.skipTest("pass SWAY_QA_APP after simulator build; not a release result")
        root=Path(path)/"SWAYNativeUnapproved.bundle"
        self.assertTrue(root.is_dir(),"QA bundle missing from actual built app")
        m=json.loads((root/INNER/"user.character.json").read_text())
        self.assertEqual(len(validate(m,root/INNER)),65)
        self.assertIs(m["runtimeApproved"],False)
        self.assertFalse((Path(path)/"Characters/UserAvatar/Modules").exists())
        self.assertTrue((Path(path)/"user.character.json").exists())
        self.assertIs(json.loads((Path(path)/"user.character.json").read_text())["runtimeApproved"],False)


if __name__ == "__main__":
    unittest.main()
