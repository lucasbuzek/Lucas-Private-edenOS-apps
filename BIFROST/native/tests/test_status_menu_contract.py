"""BIFROST status-bar regression: menu visibility, native contrast and service separation.

Static tests cannot prove physical menu-bar rendering, keyboard support or click
acceptance. Those remain separate macOS physical gates.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Sources"


class BifrostNativeStatusMenuContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.menu = (SOURCE / "StatusMenu.swift").read_text(encoding="utf-8")
        cls.app = (SOURCE / "BIFROSTApp.swift").read_text(encoding="utf-8")
        cls.client = (SOURCE / "HeadlessClient.swift").read_text(encoding="utf-8")

    def test_true_native_macos_status_item_with_title_and_symbol(self):
        self.assertIn('MenuBarExtra("BIFROST", systemImage: "network")', self.app)
        self.assertIn('.menuBarExtraStyle(.menu)', self.app)
        self.assertNotIn('.menuBarExtraStyle(.window)', self.app)
        self.assertNotIn('HeadlessMenuBarLabel', self.app)

    def test_system_controls_foreground_contrast_not_dark_canvas(self):
        self.assertIn('Group {', self.menu)
        self.assertNotIn('.background(BifrostUI.sidebar)', self.menu)
        self.assertNotIn('.preferredColorScheme(.dark)', self.app.split('MenuBarExtra(')[1].split('Settings {')[0])
        self.assertIn('Text("BIFROST · CONNECT · KEEP · RESOLVE")', self.menu)

    def test_primary_destinations_open_actual_main_view(self):
        for name in ("Overview", "Devices", "Connections", "Capabilities",
                     "JANITOR", "Settings"):
            self.assertIn('openSection("' + name + '")', self.menu)
        self.assertIn('system.selectedSection = section', self.menu)
        self.assertIn('openWindow(id: "main")', self.menu)

    def test_direct_headless_controls_visible_not_gated(self):
        self.assertIn('Label("Stop Headless"', self.menu)
        self.assertIn('Label("Start Headless"', self.menu)
        self.assertIn('Label("Open Headless Web"', self.menu)
        self.assertNotIn('DisclosureGroup(', self.menu)

    def test_stop_and_quit_distinct_from_quit_interface(self):
        self.assertIn('Quit Interface · Keep Headless', self.menu)
        self.assertIn('Stop Headless & Quit Interface', self.menu)
        self.assertIn('if stopped && quitInterface', self.menu)
        self.assertIn('confirmHeadlessShutdown(quitInterface: true)', self.menu)
        self.assertIn('confirmHeadlessShutdown(quitInterface: false)', self.menu)

    def test_macos_native_confirmation_is_real_alert(self):
        self.assertIn('let alert = NSAlert()', self.menu)
        self.assertIn('alert.runModal() == .alertFirstButtonReturn', self.menu)
        self.assertIn('headless.stop()', self.menu)

    def test_headless_stop_success_is_checked_not_guessed(self):
        self.assertIn('func stop() -> Bool', self.client)
        self.assertIn('guard code == 0 else {', self.client)
        self.assertIn('launchctl(["bootout"', self.client)
        self.assertIn('launchctl(["print"', self.client)
        self.assertIn('return false', self.client)
        self.assertIn('return true', self.client)

    def test_no_overwriting_live_headless_when_starting(self):
        self.assertIn('if launchctl(["print"', self.client)
        self.assertIn('already registered with launchd', self.client)

    def test_independent_raven_and_external_caffeinate_unaffected(self):
        self.assertIn('Text("Mobile pairing: Unverified")', self.menu)
        self.assertIn('External Caffeinate active (not controlled)', self.menu)
        self.assertIn('External Caffeinate — leave running', self.menu)
        self.assertIn('system.remote.managedByBifrost', self.menu)
        self.assertNotIn('killall caffeinate', self.menu)
        self.assertNotIn('eden.bifrost.raven-bridge"])', self.client)

    def test_unreachable_but_registered_headless_can_be_stopped(self):
        self.assertIn('headless.isRegisteredWithLaunchd == true', self.menu)
        self.assertIn('Headless: Registered · unreachable', self.menu)
        self.assertIn('observeHeadlessLaunchdRegistration()', self.client)
        self.assertIn('launchctl(["print",', self.client)

    def test_sensible_descriptive_status_summary(self):
        self.assertIn('Headless: Running', self.menu)
        self.assertIn('Headless: Not connected', self.menu)
        self.assertIn('RavenNest: ', self.menu)
        self.assertIn('Active tasks: Not verified', self.menu)
        self.assertIn('Refresh Status', self.menu)

if __name__ == "__main__":
    unittest.main()
