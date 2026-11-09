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
README = (ROOT / "README.md").read_text()
ROLE = (ROOT / "docs/architecture/BIFROST_CROSS_PLATFORM_PRODUCT_CONTRACT.md").read_text()


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
        self.assertIn('path: Sources', PROJECT)
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


    def test_preserve_local_native_ai_boundary_and_universal_bridge_contract(self):
        # Current owner corrections: advanced global agentic orchestration belongs
        # to RAVENaIntelligence, but BIFROST retains deterministic local logic and
        # optional native/on-device intelligence. Universal BIFROSTbridge is a
        # permission-gated transport, not a planner or executor by implication.
        self.assertIn("local endpoint access and local environment management", README)
        self.assertIn("RAVENaIntelligence", ROLE)
        self.assertIn("BIFROSTbridge — UNIVERSAL SHARED TRANSPORT", ROLE)
        self.assertIn("BIFROSTAIcore — KEEP LOCAL NATIVE INTELLIGENCE", ROLE)
        self.assertIn("PENELOPE", ROLE)
        self.assertIn("ELYSIUM", ROLE)
        local_ai = (ROOT / "Sources/BifrostLocalIntelligence.swift").read_text()
        self.assertIn("FoundationModels", local_ai)
        self.assertIn("func refreshAvailability()", local_ai)
        self.assertIn("func explain(capabilities:", local_ai)
        self.assertNotIn("          - BifrostLocalIntelligence.swift", PROJECT)
        self.assertIn("BifrostLocalIntelligence()", CONNECTIONS)
        self.assertIn("Apple on-device intelligence · Optional", CONNECTIONS)
        self.assertIn("No project", local_ai)
        # This tests source/canon preservation only. Native build inclusion,
        # model availability and real execution require separate acceptance.
        self.assertIn('HOST = "127.0.0.1"', SERVER)
        self.assertIn('"connectionScope": "local-only"', SERVER)

    def test_all_six_desktop_headless_targets_remain_required(self):
        import json
        target_contract = json.loads(
            (ROOT / "docs/architecture/bifrost.platform-targets.json").read_text()
        )
        actual = {item["id"] for item in target_contract["deployment_targets"]}
        self.assertEqual(actual, {
            "macos-native", "macos-headless",
            "windows-native", "windows-headless",
            "linux-native", "linux-headless",
        })
        # A target record or CI build is not a release.
        self.assertTrue(all(not item["release"]
                            for item in target_contract["deployment_targets"]))


if __name__ == "__main__":
    unittest.main()
