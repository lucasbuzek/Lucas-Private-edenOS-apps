"""Static guards for the shared BIFROSTcore status contract; not physical UI tests."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SERVER = (ROOT / "headless/server.py").read_text()
CLIENT = (ROOT / "Sources/HeadlessClient.swift").read_text()
MENU = (ROOT / "MenuController/BIFROSTMenuControllerView.swift").read_text()
CONNECTIONS = (ROOT / "Sources/SecondaryViews.swift").read_text()
PROJECT = (ROOT / "project.yml").read_text()
CORE = (ROOT / "headless/core_runtime.py").read_text()


class BifrostCoreNativeContracts(unittest.TestCase):
    def test_one_authenticated_readonly_headless_route(self):
        self.assertEqual(SERVER.count('if route == "/api/core/v1":'), 1)
        self.assertIn('if not self.authentic():', SERVER)
        self.assertIn('"execution": "read-only-federation"', SERVER)
        self.assertIn('headless_identity=RUNTIME_IDENTITY', SERVER)
        self.assertNotIn('self.response(200, runtime_inventory.backup', SERVER)

    def test_shared_native_and_menu_observation(self):
        self.assertIn('func inspectCoreRuntime()', CLIENT)
        self.assertIn('coreRuntimeFeedback', CLIENT)
        self.assertIn('"bifrost.core.runtime-state.v1"', CLIENT)
        self.assertIn('headless.inspectCoreRuntime()', MENU)
        self.assertIn('headless.inspectCoreRuntime()', CONNECTIONS)
        self.assertIn('BIFROSTcore · Runtime identity', CONNECTIONS)
        self.assertIn('Sources/HeadlessClient.swift', PROJECT)
        self.assertIn('type: folder', PROJECT)

    def test_no_legacy_agent_start_in_status_path(self):
        # Core must not spawn an extra service, modify launchd or read
        # legacy account/provider credential files during observation.
        self.assertNotIn('launchctl", "kickstart"', CORE)
        self.assertNotIn('launchctl", "bootstrap"', CORE)
        self.assertNotIn('importlib', CORE)
        self.assertNotIn('from app import', CORE)
        self.assertIn('mode": "read-only-federation"', CORE)
        self.assertIn('"unifiedDatabase": False', CORE)

    def test_stale_identity_cleared_and_actions_are_optin(self):
        self.assertIn('Core observation stale · Headless disconnected', CLIENT)
        self.assertIn('Core observation stale · Headless identity unverified', CLIENT)
        self.assertIn('Core observation stale · Headless stopped', CLIENT)
        self.assertIn('Button("Inspect Runtime")', CONNECTIONS)
        self.assertIn('Label("Inspect BIFROSTcore…"', MENU)
        self.assertIn('config.add_argument("--apply"', CORE)


if __name__ == "__main__":
    unittest.main()
