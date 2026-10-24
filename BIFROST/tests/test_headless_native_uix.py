"""Native macOS App is a separate view/controller of independent Headless."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Sources"


class NativeHeadlessUIXContracts(unittest.TestCase):
    def test_dedicated_headless_screen_is_a_real_native_view(self):
        screen = (SOURCE / "HeadlessServiceView.swift").read_text()
        self.assertIn("struct HeadlessServiceView: View", screen)
        self.assertIn("BifrostPanel(title: \"Service control\"", screen)
        self.assertIn("BifrostPanel(title: \"Local activity\"", screen)
        self.assertIn("BifrostPanel(title: \"Keep Awake\"", screen)
        self.assertIn("headless.isRegisteredWithLaunchd", screen)
        self.assertIn("Button(\"Start Headless\") { headless.start() }", screen)
        self.assertIn('confirmStop = true', screen)
        self.assertIn('.confirmationDialog("Stop the independent BIFROST Headless service?"', screen)
        self.assertIn("headless.openWeb()", screen)
        self.assertIn("headless.recordLocalObservation()", screen)
        self.assertIn("RunAtLoad off", screen)
        self.assertNotIn("launchctl", screen)
        self.assertNotIn("raven-bridge", screen)

    def test_native_dashboard_and_menu_link_to_one_control_screen(self):
        root = (SOURCE / "RootView.swift").read_text()
        menu = (ROOT / "MenuController" / "BIFROSTMenuControllerView.swift").read_text()
        overview = (SOURCE / "BifrostDashboardView.swift").read_text()
        self.assertIn('case "Headless":', root)
        self.assertIn("HeadlessServiceView()", root)
        self.assertIn('Label("Open BIFROST App"', menu)
        self.assertIn('onNavigate("Headless")', overview)
        self.assertIn('"Quit Menu Controller · Keep Headless"', menu)
        self.assertIn('"Stop Headless"', menu)
        self.assertIn('headless.isRegisteredWithLaunchd', menu)

    def test_opening_gui_and_readonly_shortcuts_do_not_start_service(self):
        app = (SOURCE / "BIFROSTApp.swift").read_text()
        system = (SOURCE / "BifrostSystem.swift").read_text()
        intents = (SOURCE / "BifrostAppIntents.swift").read_text()
        self.assertIn('WindowGroup("BIFROST"', app)
        self.assertNotIn("MenuBarExtra", app)
        helper = (ROOT / "MenuController" / "BIFROSTMenuControllerApp.swift").read_text()
        self.assertIn("MenuBarExtra", helper)
        self.assertNotIn("headless.start()", app)
        self.assertNotIn("headless.start()", system)
        self.assertIn('BifrostIntentRoute.request("Headless")', intents)
        self.assertNotIn("headless.start()", intents)


if __name__ == "__main__":
    unittest.main()
