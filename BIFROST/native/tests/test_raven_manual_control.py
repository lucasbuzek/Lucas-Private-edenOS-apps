"""RavenNest Mac bridge must be opt-in, visible and off by default.

These checks never launch the RavenNest process. They validate source contracts,
installed/manual-only launchd policy, and the legacy CLI denial path.
"""
from __future__ import annotations

import os
import pathlib
import plistlib
import subprocess
import sys
import unittest

PROJECT = pathlib.Path(__file__).resolve().parents[1]
# The standalone Raven source is beside BIFROST in edenOS, but may be
# checked out as a sibling GitHub repository subtree or not mounted at all.
RAVEN_CANDIDATES = [
    PROJECT.parent / "Online Plugins & Connectors/RavenNest",
    PROJECT.parents[1] / "RavenNest",
]
RAVEN = next((p for p in RAVEN_CANDIDATES if p.is_dir()), None)
# RDC secondary sessions can set HOME to an isolated account directory.
AGENT = PROJECT.parents[2] / "Library/LaunchAgents/eden.bifrost.raven-bridge.plist"
SOURCE = PROJECT / "Sources"


class ManualRavenTests(unittest.TestCase):
    def test_agent_installed_and_source_template_manual_only(self):
        if RAVEN is None or not AGENT.is_file():
            self.skipTest("RavenNest or an installed local Mac agent is not mounted")
        for path in (AGENT, RAVEN / "launchd/eden.bifrost.raven-bridge.plist"):
            with self.subTest(path=str(path)):
                policy = plistlib.loads(path.read_bytes())
                self.assertEqual(policy["Label"], "eden.bifrost.raven-bridge")
                self.assertFalse(policy["RunAtLoad"])
                self.assertFalse(policy["KeepAlive"])
                self.assertEqual(policy["WorkingDirectory"], str(RAVEN))
                self.assertEqual(policy["EnvironmentVariables"]["BIFROST_RAVEN_MANUAL_SESSION"], "1")
                self.assertEqual(policy["ProgramArguments"][-1], "raven-bridge")

    def test_new_controller_observes_only_until_explicit_confirm(self):
        text = (SOURCE / "RavenAgentController.swift").read_text()
        first = text.split("init() {", 1)[1].split("var localSummary:", 1)[0]
        self.assertIn("refresh()", first)
        self.assertNotIn("manualStart()", first)
        self.assertNotIn('launchctl(["bootstrap"', first)
        self.assertIn("guard alert.runModal() == .alertFirstButtonReturn else { return }", text)
        self.assertIn("let result = starting ? Self.manualStart() : Self.manualStop()", text)
        self.assertIn('launchctl(["enable", target])', text)
        self.assertIn('launchctl(["kickstart", target])', text)
        self.assertIn('launchctl(["disable", target])', text)
        self.assertIn('launchctl(["bootout", target])', text)
        self.assertIn('"RunAtLoad"] as? Bool == false', text)
        self.assertIn('"KeepAlive"] as? Bool == false', text)
        self.assertIn('BIFROST_RAVEN_MANUAL_SESSION', text)

    def test_native_app_has_visible_menu_and_settings_controls(self):
        app = (SOURCE / "BIFROSTApp.swift").read_text()
        menu = (SOURCE / "StatusMenu.swift").read_text()
        sections = (SOURCE / "SecondaryViews.swift").read_text()
        self.assertIn("@StateObject private var raven = RavenAgentController()", app)
        self.assertEqual(app.count(".environmentObject(raven)"), 3)
        self.assertIn("raven.isRunning ? \"circle.fill\" : \"circle\"", app)
        for phrase in ("Start RavenNest Mac Bridge", "Stop RavenNest Mac Bridge",
                       "RavenNest auto-start: Disabled"):
            self.assertIn(phrase, menu)
        self.assertIn("raven.requestStart()", menu)
        self.assertIn("raven.stop()", menu)
        self.assertIn("RavenNest · Optional Mac bridge", sections)
        self.assertIn("RavenNest · Manual Mac connection", sections)

    def test_normal_bifrost_quit_stops_the_manual_mac_session(self):
        controller = (SOURCE / "RavenAgentController.swift").read_text()
        menu = (SOURCE / "StatusMenu.swift").read_text()
        self.assertIn("NSApplication.willTerminateNotification", controller)
        self.assertIn("_ = Self.manualStop()", controller)
        self.assertIn("Quit BIFROST · Stop RavenNest Mac", menu)
        self.assertIn("Quitting also stops any manually started RavenNest Mac bridge", menu)

    def test_legacy_click_script_never_starts_an_agent(self):
        if RAVEN is None:
            self.skipTest("Standalone RavenNest source not mounted")
        source = (RAVEN / "Raven 3 Run bridge.command").read_text()
        self.assertNotIn("./bifrostctl raven-bridge", source)
        self.assertIn("Open BIFROST", source)

    def test_cli_refuses_unapproved_unattended_run(self):
        if RAVEN is None:
            self.skipTest("Standalone RavenNest source not mounted")
        env = os.environ.copy()
        env.pop("BIFROST_RAVEN_MANUAL_SESSION", None)
        result = subprocess.run(
            [sys.executable, str(RAVEN / "bifrostctl.py"), "raven-bridge"],
            env=env, capture_output=True, text=True, cwd=RAVEN,
            timeout=15, check=False,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("disabled by default", result.stderr)


if __name__ == "__main__":
    unittest.main()
