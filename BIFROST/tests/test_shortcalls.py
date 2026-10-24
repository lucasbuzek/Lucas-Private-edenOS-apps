"""Portable BIFROST action names must never silently become arbitrary commands."""
import json
import subprocess
import sys
import unittest
from pathlib import Path
from unittest import mock

BASE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE / "headless"))
import shortcalls


class ShortCallsTests(unittest.TestCase):
    def test_manifest_unique_and_hierarchical(self):
        d = shortcalls.catalog()
        self.assertEqual(d["schema"], "bifrost.shortcalls.v1")
        self.assertGreaterEqual(len(d["actions"]), 25)
        for a in d["actions"]:
            self.assertGreaterEqual(a["id"].count("."), 2)
            if a["state"] == "contract-only":
                self.assertFalse(a["executors"])

    def test_native_read_action_is_real(self):
        r = shortcalls.call("bifrost.system.platform.read", system="macos")
        self.assertTrue(r["effectsVerified"])
        self.assertTrue(r["result"]["system"])

    def test_unsupported_platform_and_proposed_calls_fail_closed(self):
        with self.assertRaises(shortcalls.ShortCallError):
            shortcalls.call("bifrost.system.platform.read", system="ios")
        with self.assertRaises(shortcalls.ShortCallError):
            shortcalls.call("bifrost.app.install", system="macos")
        with self.assertRaises(shortcalls.ShortCallError):
            shortcalls.call("bifrost.system.platform.read", payload={"command": "sh"})

    def test_unregistered_and_duplicate_commands_denied(self):
        with self.assertRaises(shortcalls.ShortCallError):
            shortcalls.call("shell.exec")
        with mock.patch.object(shortcalls, "MANIFEST", BASE / "tests" / "_no_such_manifest_.json"):
            with self.assertRaises(OSError):shortcalls.catalog()

    def test_aliases_resolve_and_conversational_calls_remain_nonexecutable(self):
        self.assertEqual(shortcalls.resolve("PLATFORM.READ", "macos")["action"], "bifrost.system.platform.read")
        self.assertEqual(shortcalls.resolve("Workflow.List", "macos")["action"], "bifrost.automation.catalog.read")
        self.assertEqual(shortcalls.resolve("conductor.currentproject", "macos")["state"], "contract-only")
        with self.assertRaises(shortcalls.ShortCallError):
            shortcalls.call("pGO", system="macos")

    def test_composed_readonly_workflow_and_denials(self):
        self.assertTrue(shortcalls.plan_workflow("STATUS.INSPECT", system="macos")["executable"])
        result = shortcalls.run_workflow("status.inspect", system="macos")
        self.assertTrue(result["effectsVerified"])
        self.assertEqual(len(result["results"]), 3)
        self.assertFalse(shortcalls.plan_workflow("bifrost.workstation.prepare", system="macos")["executable"])
        with self.assertRaises(shortcalls.ShortCallError):
            shortcalls.run_workflow("bifrost.workstation.prepare", system="macos")
        with self.assertRaises(shortcalls.ShortCallError):
            shortcalls.run_workflow("status.inspect", system="ios")

    def test_case_fold_collision_rejected(self):
        data = shortcalls.catalog()
        data["actions"][1]["aliases"] = ["PLATFORM.READ"]
        with mock.patch.object(shortcalls, "MANIFEST", BASE/"tests"/"_missing_manifest_.json"):
            with mock.patch("pathlib.Path.read_text", return_value=json.dumps(data)):
                with self.assertRaises(shortcalls.ShortCallError):
                    shortcalls.catalog()

    def test_cli_end_to_end(self):
        exe = [sys.executable, "-B", str(BASE/"headless/shortcalls.py")]
        p = subprocess.run(exe+["call","bifrost.system.platform.read"],capture_output=True,text=True,timeout=8)
        self.assertEqual(p.returncode,0,p.stderr)
        self.assertEqual(json.loads(p.stdout)["action"],"bifrost.system.platform.read")
        p = subprocess.run(exe+["call","bifrost.app.install"],capture_output=True,text=True,timeout=8)
        self.assertEqual(p.returncode,2)
        self.assertEqual(json.loads(p.stderr)["status"],"refused")


if __name__ == "__main__":
    unittest.main()
