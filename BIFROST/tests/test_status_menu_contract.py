"""One BIFROST native application with an opt-in, independently owned Headless service.

Source checks do not prove macOS compile, signing, menu rendering or click acceptance.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Sources"
MENU = ROOT / "MenuController"


class BifrostOneAppMenuContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.menu = (MENU / "BIFROSTMenuControllerView.swift").read_text()
        cls.native = (SOURCE / "BIFROSTApp.swift").read_text()
        cls.client = (SOURCE / "HeadlessClient.swift").read_text()
        cls.project = (ROOT / "project.yml").read_text()

    def test_one_built_mac_app_owns_the_window_and_status_item(self):
        self.assertEqual(self.project.count("type: application"), 1)
        self.assertIn('PRODUCT_BUNDLE_IDENTIFIER: eden.private.bifrost', self.project)
        self.assertNotIn('PRODUCT_BUNDLE_IDENTIFIER: eden.private.bifrost.menu', self.project)
        self.assertIn('WindowGroup("BIFROST", id: "main")', self.native)
        self.assertIn("MenuBarExtra {", self.native)
        self.assertIn(".menuBarExtraStyle(.menu)", self.native)
        self.assertIn("BIFROSTMenuControllerView(headless: system.headless, peers: peers)", self.native)
        self.assertIn("BIFROSTStatusLabel(headless: system.headless, peers: peers)", self.native)
        self.assertIn('path: MenuController/BIFROSTMenuControllerView.swift', self.project)
        self.assertNotIn('path: MenuController/BIFROSTMenuControllerApp.swift', self.project)
        self.assertEqual(self.native.count("@main"), 1)

    def test_live_rainbow_and_truthful_status_are_in_one_menu_label(self):
        icon = (SOURCE / "VisualIdentity.swift").read_text()
        self.assertIn("BifrostBridgeSymbol(width: 24, height: 18)", self.native)
        self.assertIn("BridgeArc(inset: 0)", icon)
        self.assertIn("BridgeArc(inset: 5)", icon)
        self.assertIn("BridgeArc(inset: 10)", icon)
        self.assertIn("LinearGradient(colors:", icon)
        self.assertIn("headless.caffeinateActive", self.native)
        self.assertIn('Image(systemName: "sun.max.fill")', self.native)
        self.assertIn('headless.isRegisteredWithLaunchd == true', self.native)
        self.assertIn(".accessibilityReduceMotion", self.native)
        self.assertIn("isLowPowerModeEnabled", self.native)

    def test_menu_reopens_its_own_window_without_an_app_selector(self):
        self.assertIn("@Environment(\\.openWindow)", self.menu)
        self.assertIn('openWindow(id: "main")', self.menu)
        self.assertIn("NSApplication.shared.activate(ignoringOtherApps: true)", self.menu)
        self.assertNotIn("BIFROSTNativeAppLauncher", self.menu)
        self.assertNotIn("Locate Existing BIFROST App", self.menu)
        self.assertNotIn("BIFROSTNativeAppLocation", self.menu)
        self.assertNotIn("Process()", self.menu)

    def test_headless_is_explicit_and_survives_native_quit(self):
        self.assertIn('Label("Start Headless"', self.menu)
        self.assertIn('"Stop Headless"', self.menu)
        self.assertIn("headless.start()", self.menu)
        self.assertIn("headless.stop()", self.menu)
        self.assertIn("confirmStop()", self.menu)
        self.assertIn('let alert = NSAlert()', self.menu)
        self.assertIn("Quit BIFROST App · Keep Headless", self.menu)
        self.assertIn("NSApplication.shared.terminate(nil)", self.menu)
        self.assertNotIn("headless.start()", self.native)
        self.assertIn("RunAtLoad", self.client)
        self.assertIn("runtime.recovery.", self.client)
        self.assertNotIn("fm.removeItem(at: runtimeURL)", self.client)

    def test_keep_awake_one_action_duration_and_visible_end_time(self):
        self.assertIn("headless.activateCaffeinate(minutes: minutes)", self.menu)
        self.assertIn("headless.awakeUntil", self.menu)
        self.assertIn("headless.caffeinateActive", self.menu)
        self.assertIn("headless.systemCaffeinateObserved != true", self.menu)
        self.assertIn("func activateCaffeinate(minutes: Int)", self.client)
        self.assertIn("        start()\n        Task { @MainActor in", self.client)
        self.assertNotIn('.disabled(!headless.isRunning || !canStartKeepAwake)', self.menu)
        self.assertNotIn("killall caffeinate", self.menu)
        overview = (SOURCE / "Views.swift").read_text()
        self.assertIn("system.headless.activateCaffeinate(minutes: minutes)", overview)
        self.assertIn("system.headless.awakeUntil", overview)

    def test_one_actual_loopback_identity_and_no_remote_dependency(self):
        self.assertIn('identity["productId"] as? String == "eden.bifrost.headless"', self.client)
        self.assertIn("Unverified Headless identity on localhost", self.client)
        self.assertNotIn("RavenNest", self.client)
        self.assertNotIn("Cloudflare", self.menu)
        self.assertNotIn("Codex Cloud", self.menu)


class BifrostHeadlessWebHandoff(unittest.TestCase):
    def test_headless_explicit_fixed_bifrost_launch(self):
        server = (ROOT / "headless/server.py").read_text()
        html = (ROOT / "headless/index.html").read_text()
        script = (ROOT / "headless/dashboard.js").read_text()
        self.assertIn('def open_native_bifrost():', server)
        self.assertIn('approved_native_app_path()', server)
        self.assertIn('["/usr/bin/open", "-a", str(chosen)]', server)
        self.assertIn('"native-app.json"', server)
        self.assertIn('set(data) != {"action"}', server)
        self.assertIn('if action == "app.open":', server)
        self.assertIn('id="openNativeApp"', html)
        self.assertIn('action: "app.open"', script)
        self.assertIn("uiVisibleVerified", server)
        self.assertNotIn("shell=True", server)


if __name__ == "__main__":
    unittest.main()
