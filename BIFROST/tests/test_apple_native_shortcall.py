"""Regression: Apple probe remains an allowlisted, Mac-only BIFROST shortNameCall."""
import subprocess
import sys
import unittest
from pathlib import Path
from unittest import mock

BASE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE / "headless"))
import shortcalls


class AppleNativeShortCallTests(unittest.TestCase):
    def test_registered_with_existing_dispatcher(self):
        entry = shortcalls.describe("APPLE.CAPABILITIES")
        self.assertEqual(entry["id"], "bifrost.apple.native.capabilities.read")
        self.assertEqual(entry["effect"], "read")
        self.assertFalse(entry["requiresApproval"])
        self.assertTrue(shortcalls.resolve("apple.native.read", "macos")["available"])
        self.assertFalse(shortcalls.resolve("apple.native.read", "linux")["available"])

    def test_foreign_host_execution_is_denied_before_probe(self):
        with mock.patch.object(shortcalls.platform, "system", return_value="Linux"):
            with mock.patch("apple_native_probe.inspect") as probe:
                with self.assertRaises(shortcalls.ShortCallError):
                    shortcalls.call("apple.capabilities", system="macos")
                probe.assert_not_called()

    def test_matching_host_invokes_one_bounded_probe(self):
        with mock.patch.object(shortcalls.platform, "system", return_value="Darwin"):
            with mock.patch("apple_native_probe.inspect", return_value={
                "schema": "bifrost.apple.native-preflight.v1", "status": "inventory-only",
                "readOnly": True, "capabilities": []}) as probe:
                result = shortcalls.call("apple.capabilities", system="macos")
                probe.assert_called_once_with()
        self.assertEqual(result["action"], "bifrost.apple.native.capabilities.read")
        self.assertTrue(result["effectsVerified"])
        self.assertTrue(result["result"]["readOnly"])

    def test_non_read_actions_remain_unavailable(self):
        self.assertFalse(shortcalls.resolve("bifrost.app.install", "macos")["available"])
        with mock.patch.object(shortcalls.platform, "system", return_value="Darwin"):
            with self.assertRaises(shortcalls.ShortCallError):
                shortcalls.call("bifrost.app.install", system="macos")


if __name__ == "__main__":
    unittest.main()
