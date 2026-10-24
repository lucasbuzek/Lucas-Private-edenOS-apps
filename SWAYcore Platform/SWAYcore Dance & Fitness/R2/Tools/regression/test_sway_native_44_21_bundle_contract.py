"""Isolated SWAYcore YOUR DANCER Gate B manifest/resource acceptance.

Runs WITHOUT changing the active app bundle or runtimeApproved:false. Actual
model/clip RealityKit loading has a separate native Swift regression. The
production visual and physical tests remain independent mandatory FAIL/UNKNOWN.
"""
from __future__ import annotations
import copy
import json
from pathlib import Path
import tempfile
import unittest

R2 = Path(__file__).resolve().parents[2]
FIXTURE = (R2 / "Build/native3d_convergence_20261018"
              / "native_modular_surface_shell_44_shared21_unapproved_20261021")
BUNDLED = R2 / "App/SWAY/Resources/Characters/UserAvatar/user.character.json"
EXPECTED = {"YD_Body_Balanced", "YD_Face_Oval", "YD_Hair_Short",
            "YD_Top_Tee", "YD_Bottom_Legging", "YD_Shoes_Trainers",
            "YD_Eyes_0", "YD_Brows_0", "YD_Nose_0",
            "YD_Mouth_0", "YD_Facial_Hair_0"}


def verify(contract: dict, root: Path, require_assets: bool = True):
    if contract.get("runtimeApproved") is not False:
        raise ValueError("UNAPPROVED_CANDIDATE_MUST_STAY_DISABLED")
    if contract.get("visualQuality") != "UNREVIEWED":
        raise ValueError("CANDIDATE_VISUAL_STATUS_CHANGED")
    if contract.get("characterID") != "user" or contract.get("skeletonContract") != "SWAYHumanoid-v1":
        raise ValueError("WRONG_CHARACTER_RIG")
    if contract.get("maximumSimultaneousNativeModels") != 12:
        raise ValueError("NATIVE_12_MODEL_CAP_CHANGED")
    assets = contract.get("moduleAssets")
    names = contract.get("moduleMeshNames")
    if not isinstance(assets, dict) or len(assets) != 44 or not isinstance(names, list) or len(names) != 44:
        raise ValueError("REQUIRE_44_NATIVE_MODULES")
    if len(set(names)) != 44 or set(names) != set(assets):
        raise ValueError("INVALID_MODULE_IDENTITY_SET")
    if not EXPECTED.issubset(assets) or len(EXPECTED) != 11:
        raise ValueError("REQUIRED_11_PROFILE_NOT_SELECTABLE")
    clips = contract.get("sharedAnimationPaths")
    animations = contract.get("animations")
    if not isinstance(clips, dict) or not isinstance(animations, dict) or len(clips) != 21 or set(clips) != set(animations):
        raise ValueError("REQUIRE_21_MATCHED_SHARED_CLIPS")
    paths = []
    for name, relative in assets.items():
        if not name.startswith("YD_") or relative != f"Modules/{name}/SWAYModule.usdc":
            raise ValueError("UNEXPECTED_MODULE_RESOURCE_PATH")
        paths.append(relative)
    for move, relative in clips.items():
        data = animations[move]
        if relative != f"Animations/{data['resource']}.usdc":
            raise ValueError("UNEXPECTED_SHARED_CLIP_RESOURCE_PATH")
        paths.append(relative)
    if len(set(paths)) != 65:
        raise ValueError("DUPLICATE_RESOURCE_TARGET")
    if require_assets:
        for relative in paths:
            file = root / relative
            if not file.is_file():
                raise ValueError("MISSING_NATIVE_USD:"+relative)
            if file.stat().st_size < 32:
                raise ValueError("EMPTY_OR_CORRUPT_NATIVE_USD:"+relative)
            with file.open("rb") as stream:
                if stream.read(8) != b"PXR-USDC":
                    raise ValueError("NON_USDC_BINARY:"+relative)
    return paths


class SWAYNativeBundleGateB(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not (FIXTURE / "user.character.json").is_file():
            raise unittest.SkipTest("isolated 44/21 candidate unavailable; never report PASS")
        cls.contract = json.loads((FIXTURE / "user.character.json").read_text())

    def test_all_65_native_files_resolve_and_are_binary_usdc(self):
        self.assertEqual(len(verify(self.contract, FIXTURE)), 65)

    def test_profile_has_11_active_options_under_12_cap(self):
        self.assertEqual(len(EXPECTED), 11)
        self.assertEqual(self.contract["maximumSimultaneousNativeModels"], 12)

    def test_active_app_bundle_not_silently_promoted(self):
        app = json.loads(BUNDLED.read_text())
        self.assertFalse(app["runtimeApproved"])
        self.assertNotIn("moduleAssets", app)
        self.assertEqual(len(app["animations"]), 10)
        self.assertFalse((BUNDLED.parent / "Modules").exists())

    def test_packaged_unapproved_native_bundle_matches_isolated_export(self):
        # Xcode includes a specifically UNAPPROVED resource-only bundle in
        # SWAY.app. It is NOT the production Bundle.main UserAvatar manifest.
        nested = (R2 / "App/SWAY/Resources/SWAYNativeUnapproved.bundle"
                  / "Characters/UserAvatar")
        self.assertTrue(nested.is_dir())
        self.assertEqual((nested / "user.character.json").read_bytes(), (FIXTURE / "user.character.json").read_bytes())
        self.assertFalse(json.loads((nested / "user.character.json").read_text())["runtimeApproved"])
        # Preserve the source/candidate as one exact byte-identical inventory.
        import hashlib
        for relative in verify(self.contract, FIXTURE, require_assets=False):
            packaged = nested / relative
            candidate = FIXTURE / relative
            self.assertTrue(packaged.is_file(), relative)
            self.assertEqual(hashlib.sha256(packaged.read_bytes()).digest(),
                             hashlib.sha256(candidate.read_bytes()).digest(), relative)

    def test_negative_approval_toggle_rejected(self):
        manifest = copy.deepcopy(self.contract); manifest["runtimeApproved"] = True
        with self.assertRaisesRegex(ValueError, "STAY_DISABLED"):
            verify(manifest, FIXTURE, require_assets=False)

    def test_negative_rig_mismatch_rejected(self):
        manifest = copy.deepcopy(self.contract); manifest["skeletonContract"] = "NonCanonicalHumanoid"
        with self.assertRaisesRegex(ValueError, "RIG"):
            verify(manifest, FIXTURE, require_assets=False)

    def test_negative_oversubscribed_cap_rejected(self):
        manifest = copy.deepcopy(self.contract); manifest["maximumSimultaneousNativeModels"] = 44
        with self.assertRaisesRegex(ValueError, "12_MODEL"):
            verify(manifest, FIXTURE, require_assets=False)

    def test_negative_traversal_path_rejected(self):
        manifest = copy.deepcopy(self.contract)
        name = sorted(manifest["moduleAssets"])[0]
        manifest["moduleAssets"][name] = "../../other/secret.usdc"
        with self.assertRaisesRegex(ValueError, "MODULE_RESOURCE_PATH"):
            verify(manifest, FIXTURE, require_assets=False)

    def test_negative_missing_clip_rejected(self):
        manifest = copy.deepcopy(self.contract)
        manifest["sharedAnimationPaths"].pop(sorted(manifest["sharedAnimationPaths"])[0])
        with self.assertRaisesRegex(ValueError, "21_MATCHED"):
            verify(manifest, FIXTURE, require_assets=False)

    def test_negative_missing_module_detected_before_promotion(self):
        with tempfile.TemporaryDirectory(prefix="sway_gateb_missing_") as tmp:
            root=Path(tmp)
            with self.assertRaisesRegex(ValueError, "MISSING_NATIVE_USD"):
                verify(self.contract, root)

    def test_negative_corrupted_usdc_header_detected(self):
        with tempfile.TemporaryDirectory(prefix="sway_gateb_corrupt_") as tmp:
            root=Path(tmp)
            links=verify(self.contract, FIXTURE, require_assets=False)
            for relative in links:
                dest=root/relative;dest.parent.mkdir(parents=True,exist_ok=True)
                dest.symlink_to(FIXTURE/relative)
            corrupt=root/links[0]
            corrupt.unlink()  # unlink symlink only; NEVER touch canonical candidate
            corrupt.write_bytes(b"broken binary" + b"0"*48)
            with self.assertRaisesRegex(ValueError, "NON_USDC_BINARY"):
                verify(self.contract,root)

    def test_source_runtime_has_transactional_restore_boundary(self):
        source=(R2/"App/SWAY/Avatar/SWAYAvatarRendering.swift").read_text()
        self.assertIn("func configure(visibleMeshes:Set<String>,materialTokens:[String:String]) async throws",source)
        self.assertIn("restore(previous:previous)",source)
        self.assertIn("try applyMaterialTokens(materialTokens)",source)
        self.assertIn("try await nativeModules.configure(visibleMeshes:resolved.visibleMeshes,",source)


if __name__ == "__main__":
    unittest.main()
