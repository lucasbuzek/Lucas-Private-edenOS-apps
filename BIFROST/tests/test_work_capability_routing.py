"""Existing BIFROST capability router should expose work without assuming execution grants."""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
CAP=(ROOT/"Sources/BifrostWorkCapabilities.swift").read_text()
REG=(ROOT/"Sources/CapabilityRegistry.swift").read_text()
UI=(ROOT/"Sources/SecondaryViews.swift").read_text()

class WorkRoutingGuards(unittest.TestCase):
    def test_work_categories(self):
        for category in ("work.apps.open","work.apps.operate","work.files",
                         "work.images","work.video","work.render","work.build",
                         "work.apple.automation","work.remote"):
            self.assertIn('"'+category+'"', CAP)

    def test_existing_capability_registry_reused(self):
        self.assertIn("workItems: [BifrostWorkCapability]", REG)
        self.assertIn("BifrostWorkCapabilityProbe.discover()", REG)
        self.assertIn("ForEach(capabilities.workItems)", UI)
        self.assertIn('system.selectedSection = "App Management"', UI)

    def test_remote_is_not_assumed_inside_native_app(self):
        self.assertIn("RDC6 / CONDUCTOR / owner adapters", CAP)
        self.assertIn("detected: false", CAP)
        self.assertIn("NOT bundled or authenticated", CAP)

    def test_discovery_has_no_runtime_side_effects(self):
        self.assertNotIn("Process()", CAP)
        self.assertNotIn("NSWorkspace.shared.open", CAP)
        self.assertNotIn("subprocess", CAP)
        for banned in ("launchctl", "os.system", "shell", "curl", "killall"):
            self.assertNotIn('executableURL =', CAP)
            self.assertNotIn('Process(arguments:', CAP)

    def test_explicit_ownership_and_approval(self):
        for expected in ("DÜRER", "FORGE / Xcode", "Automation/Accessibility",
                         "app is not permission", "Exact approved files"):
            self.assertIn(expected, CAP)

    def test_chrome_never_selected_as_automation_provider(self):
        self.assertNotIn("Google Chrome", CAP)
        self.assertNotIn("Playwright", CAP)
        self.assertNotIn("Puppeteer", CAP)

if __name__=="__main__":
    unittest.main()
