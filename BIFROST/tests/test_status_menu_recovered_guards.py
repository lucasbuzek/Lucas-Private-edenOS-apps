"""Recovered pre-refactor BIFROST guards; adjusted for separate Menu process.

Derived from the verified 2026-10-19 pre-change source archive.
Static contracts do not prove physical interaction.
"""
from pathlib import Path
import unittest
import json
import re

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Sources"
MENU = ROOT / "MenuController"


class PreservedNativeMenuAndHeadlessGuards(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.menu = (MENU / "BIFROSTMenuControllerView.swift").read_text()
        cls.agent = (MENU / "BIFROSTMenuControllerApp.swift").read_text()
        cls.native = (SOURCE / "BIFROSTApp.swift").read_text()
        cls.client = (SOURCE / "HeadlessClient.swift").read_text()

    def test_native_system_menu_contrast(self):
        self.assertIn("Group {", self.menu)
        self.assertNotIn(".background(BifrostUI.sidebar)", self.menu)
        self.assertNotIn(".preferredColorScheme(.dark)", self.agent)
        self.assertIn('Text("BIFROST · CONNECT · KEEP · RESOLVE")', self.menu)
        self.assertNotIn('systemImage: "network"', self.agent)

    def test_original_native_destinations_still_exist(self):
        root = (SOURCE / "RootView.swift").read_text()
        for section in ("Overview", "Headless", "Devices", "Connections",
                        "Capabilities", "JANITOR", "Settings"):
            self.assertIn('case "' + section + '":', root)
        self.assertIn('Label("Open BIFROST App"', self.menu)
        self.assertIn("HeadlessServiceView()", root)

    def test_quit_menu_is_separate_from_explicit_headless_stop(self):
        self.assertIn("Quit Menu Controller · Keep Headless", self.menu)
        self.assertIn("NSApplication.shared.terminate(nil)", self.menu)
        self.assertIn("confirmStop()", self.menu)
        self.assertIn("headless.stop()", self.menu)
        self.assertNotIn("Stop Headless & Quit Interface", self.menu)

    def test_stop_uses_verified_launchd_result(self):
        for expected in ("func stop() -> Bool", "guard code == 0 else {",
                         'launchctl(["bootout"', 'launchctl(["print"',
                         "return false", "return true"):
            self.assertIn(expected, self.client)

    def test_start_does_not_overwrite_registered_headless(self):
        self.assertIn('if launchctl(["print"', self.client)
        self.assertIn("already registered with launchd", self.client)
        self.assertIn("runtime.staging.", self.client)
        self.assertIn("runtime.recovery.", self.client)
        self.assertIn("fm.moveItem(at: runtimeURL, to: previous)", self.client)
        self.assertNotIn("fm.removeItem(at: runtimeURL)", self.client)

    def test_portable_kernel_is_bundled_and_recoverable(self):
        for expected in ('appendingPathComponent("core/portable_kernel.py")',
                         'appendingPathComponent("kernel_adapter.py")',
                         'appendingPathComponent("portable_kernel.py")'):
            self.assertIn(expected, self.client)
        self.assertTrue((ROOT / "core/portable_kernel.py").is_file())
        self.assertTrue((ROOT / "headless/kernel_adapter.py").is_file())
        project = (ROOT / "project.yml").read_text()
        self.assertIn("path: core", project)
        self.assertIn("path: headless", project)

    def test_identity_rejects_unknown_loopback_service(self):
        self.assertIn("import CryptoKit", self.client)
        self.assertIn('identity["runtimeId"] as? String == expectedRuntimeId', self.client)
        self.assertIn('identity["sourceSha256"] as? String', self.client)
        self.assertIn("Unverified Headless identity on localhost", self.client)
        self.assertIn("Refusing to replace an unknown process", self.client)

    def test_external_caffeinate_and_online_plugins_are_not_owned(self):
        self.assertIn("External Caffeinate · Not controlled", self.menu)
        self.assertIn("headless.systemCaffeinateObserved != true", self.menu)
        for forbidden in ("RavenNest", "Cloudflare", "Codex Cloud",
                          "killall caffeinate", "system.remote"):
            self.assertNotIn(forbidden, self.menu)
            self.assertNotIn(forbidden, self.client)
        self.assertFalse((SOURCE / "RavenAgentController.swift").exists())
        self.assertFalse((SOURCE / "RemoteDesktopProvider.swift").exists())

    def test_unreachable_registered_service_remains_stoppable(self):
        self.assertIn("headless.isRegisteredWithLaunchd == true", self.menu)
        self.assertIn("Registered but unreachable", self.menu)
        self.assertIn("observeHeadlessLaunchdRegistration()", self.client)
        self.assertIn('launchctl(["print",', self.client)

    def test_headless_and_web_remain_loopback_and_offline(self):
        server = (ROOT / "headless/server.py").read_text()
        html = (ROOT / "headless/index.html").read_text()
        script = (ROOT / "headless/dashboard.js").read_text()
        self.assertIn('HOST = "127.0.0.1"', server)
        self.assertIn('"connectionScope": "local-only"', server)
        self.assertIn('"onlineExecution": "not-bundled"', server)
        for forbidden in ("remote.setup.execute", "api/mobile/bridge",
                          "RavenNest", "Cloudflare", "Codex"):
            self.assertNotIn(forbidden, server + html + script)
        self.assertIn('"/api/kernel/search"', server)
        self.assertIn('"/api/setup/stage"', server)

    def test_pwa_dom_has_no_unresolved_ids(self):
        html = (ROOT / "headless/index.html").read_text()
        js = (ROOT / "headless/dashboard.js").read_text()
        ids = set(re.findall(r'\bid="([^"]+)"', html))
        refs = set(re.findall(r'\$\("([^"]+)"\)', js))
        # The responsive Menu control is created by shellInstallRoutes at runtime.
        # Treat explicitly assigned element IDs as defined, without weakening
        # the guard for genuinely missing DOM references.
        runtime_ids = set(re.findall(r'\b\w+\.id\s*=\s*"([^"]+)"', js))
        available = ids | runtime_ids
        self.assertTrue(refs.issubset(available), sorted(refs - available))
        self.assertIn('id="openNativeApp"', html)
        self.assertNotIn('href="https://', html)

    def test_janitor_target_is_canonical(self):
        code = (SOURCE / "JanitorProvider.swift").read_text()
        self.assertIn("edenOS/Software Development/JANITOR/JANITOR.command", code)
        self.assertNotIn("Downloads/JANITOR", code)
        self.assertIn("isExecutableFile", code)

    def test_frozen_six_platform_targets_preserved(self):
        data = json.loads((ROOT / "docs/architecture/bifrost.platform-targets.json").read_text())
        self.assertEqual({item["id"] for item in data["deployment_targets"]},
                         {"macos-native", "macos-headless", "windows-native",
                          "windows-headless", "linux-native", "linux-headless"})
        self.assertTrue(data["core"]["offline_first"])
        self.assertTrue(data["core"]["cloud_optional"])


if __name__ == "__main__":
    unittest.main()
