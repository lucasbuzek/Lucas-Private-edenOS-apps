import json
import unittest
from unittest.mock import patch

from bifrost.apple_capabilities import discover_apple_capabilities, main


class AppleCapabilitiesTests(unittest.TestCase):
    def test_macos_detects_commands_but_not_authorization(self):
        found = {"shortcuts", "osascript", "xcodebuild", "xcrun"}
        result = discover_apple_capabilities("Darwin", lambda command: "/bin/" + command if command in found else None, lambda: True)
        items = {entry["id"]: entry for entry in result["capabilities"]}
        self.assertEqual(items["apple.xcode.mcpbridge"]["status"], "tool_detected")
        self.assertEqual(items["apple.shortcuts.cli"]["status"], "tool_detected")
        self.assertEqual(items["apple.applescript.cli"]["permission"], "not_checked")
        self.assertEqual(items["apple.icloud.mail"]["status"], "connection_not_checked")
        self.assertTrue(result["read_only"])

    def test_mcp_missing_even_when_xcrun_found(self):
        result = discover_apple_capabilities("Darwin", lambda name: "/usr/bin/xcrun" if name == "xcrun" else None, lambda: False)
        item = next(c for c in result["capabilities"] if c["id"] == "apple.xcode.mcpbridge")
        self.assertEqual(item["status"], "not_detected")

    def test_nonmac_does_not_run_probes(self):
        def forbidden(name):
            raise AssertionError("host binary probing on non-macOS")
        result = discover_apple_capabilities("Linux", forbidden, forbidden)
        self.assertTrue(all(c["status"] != "tool_detected" for c in result["capabilities"]))

    def test_deterministic_read_only_inventory(self):
        kwargs = {"os_name": "Darwin", "which": lambda _: None}
        a = discover_apple_capabilities(**kwargs)
        b = discover_apple_capabilities(**kwargs)
        self.assertEqual(json.dumps(a, sort_keys=True), json.dumps(b, sort_keys=True))
        self.assertEqual(len(a["capabilities"]), len({c["id"] for c in a["capabilities"]}))
        self.assertNotIn("credentials", json.dumps(a).lower())

    def test_json_cli(self):
        with patch("bifrost.apple_capabilities.discover_apple_capabilities", return_value={"read_only": True}), patch("builtins.print") as output:
            self.assertEqual(main(["--json"]), 0)
            self.assertEqual(json.loads(output.call_args.args[0]), {"read_only": True})


if __name__ == "__main__":
    unittest.main()
