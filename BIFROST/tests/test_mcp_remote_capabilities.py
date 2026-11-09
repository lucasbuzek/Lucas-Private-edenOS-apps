import sys
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "headless"))

import shortcalls
import mcp_remote_capabilities as discovery


class BifrostRemoteCapabilityDiscoveryTests(unittest.TestCase):
    def test_only_existing_mapped_readonly_actions_are_reported(self):
        for platform in ("macos", "linux", "windows"):
            with self.subTest(platform=platform):
                with mock.patch.object(shortcalls, "call", side_effect=AssertionError("Must not execute")):
                    result = discovery.snapshot(system=platform)
                self.assertEqual(result["schema"], "bifrost.mcp.capabilities.v1")
                self.assertEqual(result["platform"], platform)
                self.assertEqual(result["mappedCount"], len(result["mappedReadOnly"]))
                self.assertFalse(result["runtimeVerified"])
                self.assertEqual(result["liveProviderCountVerified"], 0)
                self.assertEqual(result["execution"], "not-granted-by-discovery")
                self.assertIn("bifrost.system.platform.read",
                              [x["id"] for x in result["mappedReadOnly"]])
                for item in result["mappedReadOnly"]:
                    self.assertEqual(item["effect"], "read")
                    self.assertTrue(item["executorMapped"])
                    self.assertFalse(item["runtimeVerified"])
                    self.assertTrue(shortcalls.resolve(item["id"], platform)["available"])

    def test_unimplemented_and_privileged_actions_are_not_exposed(self):
        names = {x["id"] for x in discovery.snapshot(system="macos")["mappedReadOnly"]}
        for prohibited in ("bifrost.device.pair", "bifrost.app.install",
                           "bifrost.host.delegate", "bifrost.task.cancel",
                           "conductor.launch.official", "forgemaster.product.go"):
            self.assertNotIn(prohibited, names)

    def test_unknown_platform_has_no_executable_mapping(self):
        result = discovery.snapshot(system="unknown")
        self.assertEqual(result["mappedCount"], 0)
        self.assertFalse(result["runtimeVerified"])

    def test_inconsistent_effect_is_denied_even_if_resolve_claims_available(self):
        with mock.patch.object(shortcalls, "resolve",
                               return_value={"available": True, "effect": "write",
                                             "action": "bifrost.system.platform.read"}):
            with self.assertRaises(shortcalls.ShortCallError):
                discovery.snapshot(system="macos")

    def test_remote_mcp_tool_requires_authenticated_scope(self):
        source = (Path(__file__).resolve().parents[1] / "headless/mcp_remote.py").read_text()
        self.assertIn('@server.tool(name="bifrost.capabilities.list")', source)
        self.assertIn('def list_capabilities() -> dict:', source)
        self.assertIn('identity = get_access_token()', source)
        self.assertIn('SCOPE not in identity.scopes', source)
        self.assertIn('return mcp_remote_capabilities.snapshot()', source)
        self.assertNotIn('subprocess', source)
        self.assertNotIn('shell=True', source)


if __name__ == "__main__":
    unittest.main()
