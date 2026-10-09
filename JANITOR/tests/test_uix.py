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

    def test_developer_owns_homebrew_and_simulators(self):
        maintenance = self.shell.split("private let maintenance: [SidebarCommand] = [", 1)[1].split("    ]", 1)[0]
        developer = self.shell.split("private let developer: [SidebarCommand] = [", 1)[1].split("    ]", 1)[0]
        for key in ("brew-preview", "brew-run", "sim-preview", "sim-run"):
            self.assertNotIn('"' + key + '"', maintenance)
            self.assertIn('"' + key + '"', developer)
        self.assertIn('case "brew-preview", "brew-run", "sim-preview", "sim-run": group = .developer', self.shell)
        self.assertIn('case "brew-run": confirmBrew = true', self.shell)
        self.assertIn('case "sim-run": confirmSim = true', self.shell)
        self.assertIn('"sim-run", "Remove unavailable simulators…", "trash", .expert', developer)

    def test_branded_sidebar_retains_native_settings_and_cues(self):
        self.assertIn('Text("JANITOR")', self.shell)
        self.assertIn('Text("INSPECT · TIDY · RECOVER")', self.shell)
        self.assertIn('Image(systemName: "paintbrush.pointed.fill")', self.shell)
        self.assertIn('.safeAreaInset(edge: .bottom)', self.shell)
        self.assertIn('No background service · Local-first', self.shell)
        self.assertIn('navigationSplitViewColumnWidth(min: 250, ideal: 290, max: 345)', self.shell)
        for required in ('case "system":', 'case "recovery":', 'case "settings":',
                         'SystemInspectorPanel(run: perform)', 'QuarantineView()', 'SettingsView()'):
            self.assertIn(required, self.shell)

    def test_dashboard_does_not_claim_unverified_health(self):
        self.assertIn('Text("Read-only until you explicitly review and confirm an action")', self.shell)
        self.assertIn('No system check has been run in this session.', self.shell)
        self.assertNotIn('Text("System Health Good")', self.shell)
        self.assertIn('m.systemReport == nil', self.shell)

    def test_legacy_clean_and_developer_classification(self):
        legacy = (SRC / "Levels.swift").read_text()
        clean = legacy.split('struct CleanView: View {', 1)[1].split('// MARK: - Organize', 1)[0]
        developer = legacy.split('struct DeveloperView: View {', 1)[1]
        self.assertNotIn('Maint.brew(', clean)
        self.assertNotIn('Maint.simulators(', clean)
        self.assertIn('Maint.brew(dryRun: true)', developer)
        self.assertIn('Maint.simulators(dryRun: true)', developer)

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
