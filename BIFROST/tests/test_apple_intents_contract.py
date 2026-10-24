"""Native Apple App Intents must be read-only navigation, not hidden execution."""
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Sources"


class AppleIntentsContract(unittest.TestCase):
    def test_registered_app_shortcuts(self):
        s = (SOURCE / "BifrostAppIntents.swift").read_text()
        for intent in ("OpenBifrostIntent", "ShowBifrostDevicesIntent",
                       "ShowBifrostConnectionsIntent", "ShowBifrostCapabilitiesIntent",
                       "ShowBifrostSetupIntent", "ShowBifrostIndexIntent",
                       "CheckBifrostHeadlessIntent",
                       "OpenBifrostHeadlessControlsIntent", "OpenElysiumOwnerDeskIntent",
                       "OpenApprovedAppleApplicationIntent"):
            self.assertIn("struct " + intent + ": AppIntent", s)
            self.assertIn("intent: " + intent + "()", s)
        self.assertIn("struct BifrostAppShortcuts: AppShortcutsProvider", s)
        # Seven original window-opening actions remain unchanged. Health check,
        # owner-preview and user-selected Apple app opening never open BIFROST
        # automatically or perform messaging or media actions.
        self.assertEqual(s.count("static let openAppWhenRun = true"), 7)
        self.assertEqual(s.count("static let openAppWhenRun = false"), 3)
        self.assertEqual(s.count("intent: "), 10)

    def test_elysium_owner_preview_is_local_explicit_and_non_mutating(self):
        s = (SOURCE / "BifrostAppIntents.swift").read_text()
        action = s.split("struct OpenElysiumOwnerDeskIntent: AppIntent", 1)[1].split(
            "struct BifrostAppShortcuts:", 1)[0]
        self.assertIn("openAppWhenRun = false", action)
        self.assertIn("FileManager.default.homeDirectoryForCurrentUser", action)
        self.assertIn("ELYSIUM_PWA_OWNER_PILOT/index.html", action)
        self.assertIn("attributesOfItem(atPath: file.path)", action)
        self.assertIn(".typeRegular", action)
        self.assertIn("NSWorkspace.shared.open(file)", action)
        for forbidden in ("launchctl", "kickstart", "URLSession.shared", "api_key",
                          "http://", "https://", "sendMessage", "system("):
            self.assertNotIn(forbidden, action)

    def test_only_known_local_routes(self):
        s = (SOURCE / "BifrostAppIntents.swift").read_text()
        self.assertIn("guard allowed.contains(section)", s)
        self.assertIn("UserDefaults.standard.removeObject(forKey: key)", s)
        for excluded in ("RavenNest", "cloud.submit", "caffeinate", "launchctl", "api_key"):
            self.assertNotIn(excluded + "()", s)

    def test_health_intent_is_identity_checked_and_non_mutating(self):
        s = (SOURCE / "BifrostAppIntents.swift").read_text()
        health = s.split("struct CheckBifrostHeadlessIntent: AppIntent", 1)[1].split(
            "struct BifrostAppShortcuts:", 1)[0]
        self.assertIn("http://127.0.0.1:8798/api/health", health)
        self.assertIn("eden.bifrost.headless", health)
        self.assertIn("bifrost.headless.identity.v1", health)
        self.assertIn("sourceSha256", health)
        self.assertIn("runtimeId", health)
        self.assertIn("timeoutInterval = 2", health)
        self.assertIn("No service was started.", health)
        for forbidden in ("launchctl", "kickstart", "caffeinate.start", "/api/control",
                          "raven-bridge", "URLSession.shared.upload"):
            self.assertNotIn(forbidden, health)

    def test_native_route_consumed(self):
        system = (SOURCE / "BifrostSystem.swift").read_text()
        root = (SOURCE / "RootView.swift").read_text()
        self.assertIn("BifrostIntentRoute.consume()", system)
        self.assertIn("system.consumeShortcutNavigation()", root)
        self.assertIn("didBecomeActiveNotification", root)


if __name__ == "__main__":
    unittest.main()
