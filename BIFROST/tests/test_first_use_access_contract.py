"""Source-level guards for the native BIFROST first-use permission path.

The two Swift smoke tests exercise real isolated preferences and synthetic RDC
metadata; these checks preserve UI wiring and the no-agent-activation boundary.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
PERMISSION = (ROOT / "Sources/BifrostPermissionCenter.swift").read_text()
PANEL = (ROOT / "Sources/BifrostPermissionSettingsView.swift").read_text()
RDC = (ROOT / "Sources/BifrostRDCManagerReadOnlyView.swift").read_text()
UI = (ROOT / "Sources/SecondaryViews.swift").read_text()
APP = (ROOT / "Sources/BIFROSTApp.swift").read_text()


class BifrostFirstUseAccessContract(unittest.TestCase):
    def test_default_asks_and_once_never_persists(self):
        self.assertIn("return .ask", PERMISSION)
        self.assertNotIn("case allowOnce", PERMISSION)
        self.assertIn('Button("Allow Once")', UI)
        self.assertIn('Button("Allow All")', UI)
        self.assertIn('Button("Deny"', UI)
        self.assertIn("for: .rdcProfileDiscovery", UI)

    def test_app_and_settings_reuse_one_model(self):
        self.assertIn("@StateObject private var permissions = BifrostPermissionCenter()", APP)
        self.assertEqual(APP.count(".environmentObject(permissions)"), 2)
        self.assertIn("BifrostPermissionSettingsView()", UI)
        self.assertIn('Text("Ask")', PANEL)
        self.assertIn('Text("Allow All")', PANEL)
        self.assertIn('Text("Deny")', PANEL)
        self.assertIn("permissions.resetAll()", PANEL)

    def test_rdc_discovery_runs_only_after_sheet_presented(self):
        self.assertIn(".onAppear { snapshot = .read() }", RDC)
        self.assertIn("showRDCConsent = true", UI)
        self.assertIn("case .deny:", UI)
        self.assertIn("BifrostRDCManagerReadOnlyView()", UI)
        self.assertIn(".isSymbolicLinkKey", RDC)
        self.assertNotIn("device.json", RDC)
        self.assertNotIn("accessToken", RDC)
        self.assertNotIn("Process()", RDC)

    def test_automation_first_use_keeps_per_action_confirmation(self):
        self.assertIn("switch permissions.decision(for: .localAutomation)", UI)
        self.assertIn("showAutomationConsent = true", UI)
        self.assertIn("showAutomationActionReview()", UI)
        self.assertIn("confirmShortcut = true", UI)
        self.assertIn("confirmAutomator = true", UI)
        self.assertIn("workflowRunner.runConfirmedShortcut", UI)
        self.assertIn("workflowRunner.runConfirmedAutomator", UI)

    def test_not_integrated_capabilities_cannot_be_preapproved(self):
        self.assertIn("case .externalAccounts, .fileOperations: false", PERMISSION)
        self.assertIn(".disabled(!scope.isIntegrated)", PANEL)
        self.assertIn("Pending integration", PANEL)

    def test_os_permission_and_action_boundary_visible(self):
        self.assertIn("macOS Privacy & Security", PANEL)
        self.assertIn("Open macOS System Settings…", PANEL)
        self.assertIn("com.apple.systempreferences", PANEL)
        self.assertIn("individual device grants", PANEL)
        self.assertIn("separate approval", PERMISSION)
        self.assertIn("no account sign-in or device operation starts", UI)


if __name__ == "__main__":
    unittest.main()
