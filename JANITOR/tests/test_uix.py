"""Static UIX contract checks; functional native behavior also requires macOS runtime testing."""
import re
import unittest
from pathlib import Path

SRC = Path(__file__).resolve().parents[1] / "native" / "Sources" / "JANITOR"


class FinderUIXContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.shell = (SRC / "FinderShell.swift").read_text()
        cls.model = (SRC / "Model.swift").read_text()
        cls.views = (SRC / "Views.swift").read_text()
        cls.engine = (SRC / "SystemInspector.swift").read_text()
        cls.levels = (SRC / "Levels.swift").read_text()

    def test_interface_level_is_one_toolbar_picker(self):
        self.assertIn('Picker("Interface", selection: $m.level)', self.shell)
        self.assertIn(".pickerStyle(.menu)", self.shell)
        self.assertNotIn("LevelPicker()", self.shell)
        self.assertIn('["Standard", "Advanced", "Expert"]', self.levels)

    def test_permanent_quick_actions(self):
        for key in ("system", "quick", "storage", "duplicates", "recovery"):
            self.assertRegex(self.shell, r'quick\("[^"]+", icon: "[^"]+", key: "' + key + r'"\)')

    def test_expandable_advanced_categories(self):
        for name in ("Maintenance", "Developer", "Media", "Full Crew", "Cloud & Photos"):
            self.assertIn('SidebarTools(name: "' + name + '"', self.shell)
        self.assertIn("DisclosureGroup(isExpanded: Binding(", self.shell)
        self.assertIn('janitorExpandedGroups', self.model)

    def test_optional_context_inspector(self):
        self.assertIn("if m.showInspector", self.shell)
        self.assertIn("SystemInspectorPanel(run: perform)", self.shell)
        self.assertIn("m.inspectedCandidateID = c.id", self.views)
        self.assertIn('Button("Details")', self.views)

    def test_results_center_and_bottom_actions(self):
        self.assertIn("ResultsView()", self.shell)
        self.assertIn("ScrollView {", self.views)
        self.assertIn('Button("Move to Recovery…")', self.views)
        self.assertIn('Button("Delete permanently…"', self.views)

    def test_inspector_is_explicit_read_only(self):
        self.assertIn("Modes.quick(full: false)", self.engine)
        self.assertIn("PHPhotoLibrary.authorizationStatus", self.engine)
        self.assertNotIn("PHAsset.fetchAssets", self.engine)
        for dangerous in ("removeItem(", "moveItem(", "startDownloadingUbiquitousItem(", "terminate("):
            self.assertNotIn(dangerous, self.engine)

    def test_recommendations_use_supported_actions(self):
        supported = {"quick", "full", "storage", "startup", "duplicates", "cloud"}
        actual = set(re.findall(r'action:\s*"([^"]+)"', self.engine))
        self.assertTrue(actual)
        self.assertTrue(actual.issubset(supported))
        for key in actual:
            self.assertIn('case "' + key + '"', self.shell)

    def test_unmeasured_areas_not_reported_as_passed(self):
        self.assertIn('case unchecked = "Not fully checked"', self.engine)
        self.assertIn('case attention = "Attention"', self.engine)
        self.assertIn("residency", self.engine.lower())
        self.assertIn("not run", self.engine.lower())

    def test_no_automatic_background_system_check(self):
        self.assertIn("func runSystemCheck()", self.model)
        self.assertIn('Button("Run system check")', self.shell)
        self.assertNotIn(".onAppear { run(\"system\")", self.shell)

    def test_live_developer_disclosure_matches_mode(self):
        self.assertIn('case .developer: return .advanced', self.model)
        self.assertIn('SidebarTools(name: "Developer"', self.shell)

    def test_quarantine_checks_provider_before_creating_root(self):
        q = (SRC / "Quarantine.swift").read_text()
        self.assertIn('existingAncestor', q)
        self.assertIn('proposedClass != .fileProvider', q)
        self.assertLess(q.index('proposedClass != .fileProvider'),
                        q.index('try fm.createDirectory(at: root'))

    def test_package_version_follows_signed_bundle(self):
        core = (SRC / "Core.swift").read_text()
        self.assertIn('Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")', core)

    def test_native_builder_reuses_authoritative_source(self):
        builder = SRC.parents[2] / "builders" / "macos" / "JANITOR_macOS_Build.command"
        content = builder.read_text()
        self.assertIn('ditto "$NATIVE" "$STAGE/src"', content)
        self.assertNotIn('struct ContentView: View', content)
        self.assertIn('Refusing to replace existing release', content)

    def test_level_switch_keeps_current_results(self):
        self.assertIn("Interface complexity never invalidates", self.model)


if __name__ == "__main__":
    unittest.main()
