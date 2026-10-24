"""Independent BIFROST Menu ownership and Headless control contracts.

Source checks are not substitutes for physical menu-bar click acceptance.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Sources"
MENU = ROOT / "MenuController"


class BifrostIndependentMenuContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.menu = (MENU / "BIFROSTMenuControllerView.swift").read_text()
        cls.agent = (MENU / "BIFROSTMenuControllerApp.swift").read_text()
        cls.native = (SOURCE / "BIFROSTApp.swift").read_text()
        cls.client = (SOURCE / "HeadlessClient.swift").read_text()
        cls.project = (ROOT / "project.yml").read_text()

    def test_true_independent_native_status_item(self):
        self.assertIn("MenuBarExtra {", self.agent)
        self.assertIn("BifrostBridgeSymbol(width: 24, height: 18)", self.agent)
        self.assertIn('.menuBarExtraStyle(.menu)', self.agent)
        self.assertNotIn("MenuBarExtra {", self.native)
        self.assertIn('WindowGroup("BIFROST"', self.native)
        self.assertIn('PRODUCT_BUNDLE_IDENTIFIER: eden.private.bifrost.menu', self.project)
        self.assertIn('INFOPLIST_KEY_LSUIElement: YES', self.project)

    def test_menu_is_lightweight_and_separate_from_main_app(self):
        self.assertIn("path: MenuController", self.project)
        self.assertIn("path: Sources/HeadlessClient.swift", self.project)
        self.assertIn("path: Sources/VisualIdentity.swift", self.project)
        self.assertIn("path: headless", self.project)
        self.assertIn("path: core", self.project)
        self.assertNotIn('BifrostSystem()', self.agent)
        self.assertNotIn("RavenNest", self.menu)
        self.assertNotIn("Cloudflare", self.menu)
        self.assertNotIn("Codex Cloud", self.menu)

    def test_explicit_native_application_launch_only(self):
        self.assertIn('Label("Open BIFROST App"', self.menu)
        locator = (SOURCE / "BIFROSTNativeAppLocation.swift").read_text()
        self.assertIn('"eden.private.bifrost"', locator)
        self.assertIn('bundle.bundleIdentifier == nativeBundleID', locator)
        self.assertIn('BIFROSTNativeAppLocation.approve(selection)', self.menu)
        self.assertIn("Select the existing BIFROST native application", self.menu)
        self.assertIn('macOS accepted the BIFROST launch request', self.menu)
        self.assertNotIn('shell', self.menu)
        self.assertNotIn("Process()", self.menu)

    def test_headless_control_standalone_and_explicit(self):
        self.assertIn('Label("Start Headless"', self.menu)
        self.assertIn('"Stop Headless"', self.menu)
        self.assertIn('headless.start()', self.menu)
        self.assertIn('headless.stop()', self.menu)
        self.assertIn('let alert = NSAlert()', self.menu)
        self.assertIn('alert.runModal() == .alertFirstButtonReturn', self.menu)
        self.assertIn("RunAtLoad", self.client)
        self.assertNotIn('headless.start()', self.agent)

    def test_native_menu_customization_and_power_separation(self):
        self.assertIn('Label("Customize Menu Bar"', self.menu)
        self.assertIn('@AppStorage("bifrost.menu.showTitle")', self.agent)
        self.assertIn('@AppStorage("bifrost.menu.showHeadlessState")', self.agent)
        self.assertIn('Toggle("Show Keep Awake"', self.menu)
        self.assertIn('headless.systemCaffeinateObserved != true', self.menu)
        self.assertIn("Quit Menu Controller · Keep Headless", self.menu)
        self.assertNotIn("killall caffeinate", self.menu)

    def test_headless_identity_and_rollback_preserved(self):
        self.assertIn("func stop() -> Bool", self.client)
        self.assertIn('identity["productId"] as? String == "eden.bifrost.headless"', self.client)
        self.assertIn("Unverified Headless identity on localhost", self.client)
        self.assertIn("runtime.staging.", self.client)
        self.assertIn("runtime.recovery.", self.client)
        self.assertNotIn("fm.removeItem(at: runtimeURL)", self.client)
        self.assertNotIn("RavenNest", self.client)

    def test_no_side_effects_from_readonly_startup(self):
        self.assertNotIn("headless.start()", self.native)
        self.assertNotIn("headless.start()", self.agent)
        self.assertNotIn("raven.requestStart", self.native)
        self.assertIn('openApplication(', self.menu)


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
