"""Regression: BIFROST cannot lose canon targets because only macOS is built.

Test scope identity and evidence truth, not runtime functionality on other OSes.
"""
from __future__ import annotations
import json
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
DOC = ROOT / "docs" / "architecture" / "BIFROST_CROSS_PLATFORM_PRODUCT_CONTRACT.md"
MANIFEST = ROOT / "docs" / "architecture" / "bifrost.platform-targets.json"

EXPECTED = {
    "macos-native", "macos-headless",
    "windows-native", "windows-headless",
    "linux-native", "linux-headless",
}


class PlatformCanonTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data = json.loads(MANIFEST.read_text(encoding="utf-8"))
        cls.spec = DOC.read_text(encoding="utf-8")

    def test_six_os_roles_are_explicit(self):
        targets = self.data["deployment_targets"]
        self.assertEqual(len(targets), 6)
        self.assertEqual({x["id"] for x in targets}, EXPECTED)
        self.assertEqual({(x["platform"], x["role"]) for x in targets},
                         {(os, role) for os in ("macos", "windows", "linux")
                          for role in ("native", "headless")})

    def test_single_core_independent_headless(self):
        core = self.data["core"]
        for key in ("one_core", "versioned_contracts", "offline_first",
                    "standalone_service", "gui_optional",
                    "independent_app_domain_ownership", "hosting_transfer_reversible",
                    "cloud_optional", "windows_linux_official_dependency_free_from_apple"):
            self.assertTrue(core[key], key)

    def test_no_linux_windows_false_release_claims(self):
        for target in self.data["deployment_targets"]:
            self.assertFalse(target["release"])
            self.assertFalse(target["release_artifact_verified"])
            if target["platform"] in ("windows", "linux"):
                self.assertEqual(target["evidence"], "SPECIFIED_NOT_BUILT")
        states = {x["id"]: x["evidence"] for x in self.data["deployment_targets"]}
        self.assertEqual(states["macos-native"], "BUILT_PROCESS_LAUNCHED")
        self.assertEqual(states["macos-headless"], "RUNNING_PARTIALLY_TESTED")

    def test_project_contract_documents_every_target(self):
        for target in self.data["deployment_targets"]:
            self.assertIn(target["id"], self.spec, target["id"])
        for phrase in ("hosting is transferable", "DP0.1",
                       "Slindokuhle", "LEAN", "LOCAL", "ALPHA", "BETA"):
            self.assertIn(phrase.lower(), self.spec.lower(), phrase)

    def test_recovery_contract_keeps_authority_and_identity(self):
        self.assertEqual(self.data["product"], "BIFROST")
        self.assertEqual(self.data["identity"], "CONNECT · KEEP · RESOLVE")
        self.assertTrue(self.data["canon_sources"])
        self.assertEqual(len(self.data["dp01_steps"]), 10)
        self.assertIn("FULL_DP01_SCOPE_UNVERIFIED", self.data["dp01_evidence"])
        self.assertIn("backup", self.spec.lower())
        self.assertIn("six-target matrix", self.spec.lower())


if __name__ == "__main__":
    unittest.main()
