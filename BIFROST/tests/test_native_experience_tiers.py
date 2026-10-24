"""Recovered BIFROST UX contract: actual tier-specific workflows and arch symbol.

These are source-preservation guards, not simulated manual clicks.
"""
from pathlib import Path
import plistlib
import re
import unittest

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/"Sources"
MENU=ROOT/"MenuController"


class BifrostExperienceTests(unittest.TestCase):
    def test_simple_is_a_distinct_task_home(self):
        source=(SRC/"RootView.swift").read_text()
        simple=(SRC/"BifrostExperienceViews.swift").read_text()
        self.assertIn("BifrostSimpleHomeView(",source)
        self.assertIn('case "Overview":',source)
        self.assertIn('system.complexity == .simple',source)
        for action in ("Find devices","My apps","Find a file","Automations"):
            self.assertIn('"'+action+'"',simple)
        self.assertIn("BifrostBridgeSymbol(width: 88, height: 70)",simple)
        self.assertIn("Manage Bridge…",simple)
        self.assertIn('navigate("Headless")',simple)
        self.assertNotIn("headless.start()",simple)
        self.assertNotIn("headless.stop()",simple)

    def test_native_interface_level_is_only_in_settings(self):
        # Presentation settings are never a permanent main-toolbar control.
        root = (SRC / "RootView.swift").read_text()
        settings = (SRC / "SecondaryViews.swift").read_text()
        self.assertIn('case "Settings":', root)
        self.assertIn('SettingsView()', root)
        self.assertIn('Picker("Interface complexity", selection: $system.complexity)', settings)
        self.assertNotIn('Picker("Interface level"', root)
        self.assertNotIn('.toolbar {', root)

    def test_simple_automation_requires_explicit_settings_change(self):
        # A home-card click may navigate; it must not change the disclosure level.
        simple = (SRC / "BifrostExperienceViews.swift").read_text()
        card = simple.split('simpleAction("Automations"', 1)[1].split('simpleAction(', 1)[0]
        self.assertIn('navigate("Settings")', card)
        self.assertNotIn('system.complexity = .advanced', card)
        self.assertNotIn('navigate("Capabilities")', card)

    def test_advanced_preserves_real_management_views(self):
        source=(SRC/"RootView.swift").read_text()
        self.assertIn("let fullWorkspace",source)
        for route in ("Connections","Capabilities","Representations","Install & Setup","JANITOR","Headless"):
            self.assertIn('"'+route+'"',source)
        self.assertIn("BifrostDashboardView(",source)
        self.assertIn("system.complexity == .advanced",source)
        self.assertIn('navigate("Settings")', (SRC/"BifrostExperienceViews.swift").read_text())

    def test_expert_uses_distinct_evidence_screen_and_live_inspection(self):
        root=(SRC/"RootView.swift").read_text()
        dash=(SRC/"BifrostDashboardView.swift").read_text()
        detail=(SRC/"BifrostExperienceViews.swift").read_text()
        self.assertIn("BifrostExpertDiagnosticsView()",root)
        self.assertIn('case "Diagnostics":',root)
        self.assertIn("if system.complexity == .expert",dash)
        self.assertIn("Inspect Diagnostics",dash)
        self.assertIn("/api/health",detail)
        self.assertIn("Headless · independent runtime",detail)
        self.assertIn("Folder Automation · permission boundary",detail)
        self.assertIn("Observed runtime identity",detail)
        self.assertIn("macOS TCC",detail)
        self.assertIn("Inspect Local State",detail)
        for prohibited in ("Process()", "launchctl bootstrap", "killall", "sudo"):
            self.assertNotIn(prohibited,detail)

    def test_menu_retains_vector_arch_and_original_independent_actions(self):
        icon=(SRC/"VisualIdentity.swift").read_text()
        app=(MENU/"BIFROSTMenuControllerApp.swift").read_text()
        menu=(MENU/"BIFROSTMenuControllerView.swift").read_text()
        self.assertIn("struct BifrostBridgeSymbol:",icon)
        self.assertIn("BridgeArc(inset: 0)",icon)
        self.assertIn("BridgeArc(inset: 5)",icon)
        self.assertIn("BridgeArc(inset: 10)",icon)
        self.assertIn("BifrostBridgeSymbol(width: 24, height: 18)",app)
        self.assertIn(".menuBarExtraStyle(.menu)",app)
        for label in ("Open BIFROST App","Start Headless","Stop Headless…",
                      "Keep Awake","Open Local Dashboard","Customize Menu Bar",
                      "Quit Menu Controller · Keep Headless"):
            self.assertIn(label,menu)
        self.assertIn("headless.isRegisteredWithLaunchd",app)
        self.assertIn("confirmStop()",menu)
        self.assertNotIn("headless.start()",app)

    def test_exact_named_release_pair_and_older_versionzero_preserved(self):
        menu=(MENU/"BIFROSTMenuControllerView.swift").read_text()
        self.assertIn('["BIFROST_" + suffix,',menu)
        self.assertIn('"BIFROST_VersionZero_" + suffix]',menu)
        self.assertIn("validated(parent.appendingPathComponent(partnerName))",menu)
        examples=[
            ("BIFROST_Menu_Orchestration_20261019_macOS_Custom_TEST.app",
             "BIFROST_Orchestration_20261019_macOS_Custom_TEST.app"),
            ("BIFROST_Menu_Automation_20261019_macOS_Custom_TEST.app",
             "BIFROST_Automation_20261019_macOS_Custom_TEST.app"),
            ("BIFROST_Menu_20261019_macOS_Custom_TEST_R3.app",
             "BIFROST_VersionZero_20261019_macOS_Custom_TEST_R3.app")
        ]
        for observed, expected in examples:
            suffix=observed.removeprefix("BIFROST_Menu_")
            matches={"BIFROST_"+suffix,"BIFROST_VersionZero_"+suffix}
            self.assertIn(expected,matches)

if __name__=="__main__":
    unittest.main()

