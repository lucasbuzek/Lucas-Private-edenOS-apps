import json
import unittest
from unittest.mock import patch

import bifrostctl


class BifrostCLIAppleTests(unittest.TestCase):
    def test_default_remains_existing_remote_status(self):
        with patch("bifrostctl.RemoteProvider") as provider, patch("builtins.print") as output:
            provider.return_value.status.return_value = {"remote": "available"}
            self.assertEqual(bifrostctl.main([]), 0)
            self.assertEqual(json.loads(output.call_args.args[0]), {"remote": "available"})

    def test_apple_discovery_invokes_read_only_function(self):
        with patch("bifrostctl.discover_apple_capabilities", return_value={"read_only": True}), patch("builtins.print") as output:
            self.assertEqual(bifrostctl.main(["apple", "status"]), 0)
            self.assertEqual(json.loads(output.call_args.args[0]), {"read_only": True})

    def test_unknown_command_does_not_execute(self):
        with patch("bifrostctl.RemoteProvider") as provider, patch("bifrostctl.discover_apple_capabilities") as discovery, patch("sys.stderr"):
            self.assertEqual(bifrostctl.main(["remote", "restart"]), 2)
            provider.assert_not_called()
            discovery.assert_not_called()


if __name__ == "__main__":
    unittest.main()
