"""Offline, isolated BIFROST Headless tests; no real Caffeinate or cloud calls."""
import http.client
import importlib.util
import json
import pathlib
import tempfile
import threading
import unittest
import sys
from http.server import ThreadingHTTPServer

SCRIPT = pathlib.Path(__file__).resolve().parents[1] / "headless" / "server.py"
sys.path.insert(0, str(SCRIPT.parent))
spec = importlib.util.spec_from_file_location("bifrost_headless", SCRIPT)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


class PreferenceTests(unittest.TestCase):
    def test_defaults(self):
        defaults = mod.normalize({})
        self.assertEqual(defaults["statusIndicators"], ["headless", "activeTasks"])
        self.assertEqual(defaults["aiRouting"], "auto")
        self.assertEqual(defaults["caffeinateMinutes"], 60)

    def test_settings_are_restricted(self):
        value = mod.normalize({"caffeinateMinutes": -40, "aiRouting": "execute",
                               "statusIndicators": ["headless", "fake", "headless", "activeTasks"],
                               "dashboardSections": ["ai", "unsafe", "headless", "headless"]})
        self.assertEqual(value["caffeinateMinutes"], 60)
        self.assertEqual(value["aiRouting"], "auto")
        self.assertEqual(value["statusIndicators"], ["headless", "activeTasks"])
        self.assertEqual(value["dashboardSections"], ["ai", "headless"])

    def test_invalid_caffeinate_cannot_spawn_process(self):
        rt = mod.Runtime()
        with self.assertRaises(ValueError):
            rt.start_awake(999)
        with self.assertRaises(ValueError):
            rt.start_awake("60")
        with self.assertRaises(ValueError):
            rt.start_awake(True)


class APITests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        cls.root = pathlib.Path(cls.temp.name)
        cls.restore = (mod.SUPPORT, mod.PREFS, mod.KEYFILE, mod.PORT, mod.RUNTIME)
        mod.SUPPORT = cls.root
        mod.PREFS = cls.root / "settings.json"
        mod.KEYFILE = cls.root / "headless.token"
        mod.RUNTIME = mod.Runtime()
        mod.RUNTIME.update_tasks_async = lambda force=False: None
        mod.RUNTIME.raven_status = lambda: "unknown"
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), mod.Handler)
        mod.PORT = cls.server.server_address[1]
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join(timeout=2)
        mod.SUPPORT, mod.PREFS, mod.KEYFILE, mod.PORT, mod.RUNTIME = cls.restore
        cls.temp.cleanup()

    def api(self, method, path, obj=None, headers=None):
        conn = http.client.HTTPConnection("127.0.0.1", mod.PORT, timeout=4)
        payload = json.dumps(obj).encode() if obj is not None else None
        all_headers = {"Content-Type": "application/json", **(headers or {})}
        conn.request(method, path, body=payload, headers=all_headers)
        response = conn.getresponse()
        content = response.read()
        status = response.status
        conn.close()
        try:
            return status, json.loads(content)
        except ValueError:
            return status, content

    def test_headless_health_and_state(self):
        code, health = self.api("GET", "/api/health")
        self.assertEqual(code, 200)
        self.assertTrue(health["ok"])
        self.assertEqual(health["identity"]["productId"], "eden.bifrost.headless")
        self.assertRegex(health["identity"]["runtimeId"], r"^[a-f0-9]{16}$")
        self.assertRegex(health["identity"]["sourceSha256"], r"^[a-f0-9]{64}$")
        code, status = self.api("GET", "/api/state")
        self.assertEqual(code, 200)
        self.assertEqual(status["headless"]["status"], "running")
        self.assertEqual(status["headless"]["identity"], health["identity"])
        self.assertEqual(status["preferences"]["caffeinateMinutes"], 60)
        self.assertEqual(status["ai"]["provider"], "not-configured")

    def test_mutation_requires_token(self):
        code, _ = self.api("POST", "/api/control", {"action": "caffeinate.stop"})
        self.assertEqual(code, 403)
        code, _ = self.api("POST", "/api/control", {"action": "caffeinate.stop"},
                           {"X-Bifrost-Token": "incorrect"})
        self.assertEqual(code, 403)

    def test_host_protection(self):
        code, _ = self.api("GET", "/api/state", headers={"Host": "external.example"})
        self.assertEqual(code, 403)

    def test_cross_site_origin_rejected(self):
        token = self.api("GET", "/api/session")[1]["token"]
        code, _ = self.api("POST", "/api/control", {"action": "tasks.refresh"},
                           {"X-Bifrost-Token": token, "Origin": "https://malicious.example"})
        self.assertEqual(code, 403)

    def test_preference_roundtrip(self):
        token = self.api("GET", "/api/session")[1]["token"]
        code, obj = self.api("POST", "/api/preferences",
                             {"statusIndicators": ["headless", "activeTasks"],
                              "aiRouting": "auto", "caffeinateMinutes": 60},
                             {"X-Bifrost-Token": token})
        self.assertEqual(code, 200)
        self.assertEqual(obj["preferences"]["caffeinateMinutes"], 60)
        self.assertTrue(mod.PREFS.exists())
        self.assertEqual(mod.PREFS.stat().st_mode & 0o777, 0o600)

    def test_setup_catalog_is_read_only(self):
        code, data = self.api("GET", "/api/setup/catalog")
        self.assertEqual(code, 200)
        self.assertFalse(data["executionsEnabled"])
        self.assertEqual({item["id"] for item in data["packages"]},
                         {"ai-toolkit", "project-workspace"})

    def test_unauthorized_setup_stage_is_rejected(self):
        code, _ = self.api("POST", "/api/setup/stage", {"id": "ai-toolkit"})
        self.assertEqual(code, 403)

    def test_unknown_setup_id_is_rejected(self):
        token = self.api("GET", "/api/session")[1]["token"]
        code, value = self.api("POST", "/api/setup/stage", {"id": "arbitrary"},
                               {"X-Bifrost-Token": token})
        self.assertEqual(code, 422)
        self.assertIn("unknown", value["error"])

    def test_mobile_bridge_is_not_declared_operational(self):
        code, value = self.api("GET", "/api/mobile/bridge")
        self.assertEqual(code, 200)
        self.assertEqual(value["headlessRemoteControl"], "not-enabled")
        self.assertFalse(value["mobilePairingVerified"])
        self.assertFalse(value["localAPIExposed"])

    def test_portable_kernel_status_search_and_local_permission(self):
        import kernel_adapter
        status, data = self.api("GET", "/api/kernel/status")
        self.assertEqual(status, 200)
        self.assertEqual(data["state"], "NOT_INDEXED")
        status, _ = self.api("GET", "/api/kernel/search?q=report")
        self.assertEqual(status, 403)
        token = self.api("GET", "/api/session")[1]["token"]
        headers = {"X-Bifrost-Token": token}
        status, data = self.api("GET", "/api/kernel/search?q=report", headers=headers)
        self.assertEqual(status, 200)
        self.assertEqual(data["state"], "NOT_INDEXED")
        folder = self.root / "selected-for-index"
        folder.mkdir()
        (folder / "report.md").write_text("Portable kernel DP0.1 example")
        portable = kernel_adapter.load_kernel()
        with portable.Kernel(kernel_adapter.storage_path(mod.SUPPORT)) as idx:
            result = idx.scan(folder)
        self.assertEqual(result["state"], "COMPLETE")
        status, data = self.api("GET", "/api/kernel/status")
        self.assertEqual(status, 200)
        self.assertEqual(data["source_count"], 1)
        self.assertGreater(data["relationship_count"], 0)
        status, data = self.api("GET", "/api/kernel/search?q=report", headers=headers)
        self.assertEqual(status, 200)
        self.assertEqual(data["state"], "INDEX_AVAILABLE")
        self.assertEqual(data["matches"][0]["relative"], "report.md")
        self.assertNotIn(str(folder), json.dumps(data))
        status, _ = self.api("GET", "/api/kernel/search?q=%25%25&limit=500",
                             headers=headers)
        self.assertEqual(status, 400)
        status, _ = self.api("POST", "/api/kernel/scan", {"path": str(folder)},
                             headers=headers)
        self.assertEqual(status, 404)

    def test_local_pwa_adapter_is_readonly_and_not_implicitly_remote(self):
        code, descriptor = self.api("GET", "/api/pwa/adapter")
        self.assertEqual(code, 200)
        self.assertEqual(descriptor["schema"], "bifrost.pwa.adapter.v1")
        self.assertEqual(descriptor["transport"], "same-origin-loopback")
        self.assertFalse(descriptor["offlineActionsEnabled"])
        self.assertFalse(descriptor["crossOriginApiEnabled"])
        self.assertFalse(descriptor["optionalRemoteProvider"]["mobilePairingVerified"])
        self.assertFalse(descriptor["optionalRemoteProvider"]["directApiProxy"])
        ids = {cap["id"]: cap for cap in descriptor["capabilities"]}
        self.assertFalse(ids["remote.setup.execute"]["enabled"])
        self.assertEqual(ids["setup.stage"]["requires"], "local-session-and-confirmation")

    def test_pwa_assets_are_served_locally_with_strict_headers(self):
        checks = (
            ("/manifest.webmanifest", "application/manifest+json"),
            ("/sw.js", "text/javascript"),
            ("/offline.html", "text/html"),
            ("/icons/icon-192.png", "image/png"),
            ("/icons/icon-512.png", "image/png"),
        )
        for route, mime in checks:
            with self.subTest(route=route):
                conn = http.client.HTTPConnection("127.0.0.1", mod.PORT, timeout=4)
                conn.request("GET", route)
                response = conn.getresponse()
                data = response.read()
                self.assertEqual(response.status, 200)
                self.assertIn(mime, response.getheader("Content-Type"))
                self.assertIn("worker-src 'self'",
                              response.getheader("Content-Security-Policy"))
                self.assertEqual(response.getheader("Cache-Control"), "no-store")
                self.assertGreater(len(data), 30)
                conn.close()
        self.assertEqual(self.api("GET", "/manifest.webmanifest")[1]["display"],
                         "standalone")
        self.assertEqual(self.api("GET", "/icons/icon-192.png")[1][:8],
                         bytes.fromhex("89504e470d0a1a0a"))

    def test_pwa_rejects_cross_host_and_non_allowlisted_files(self):
        code, _ = self.api("GET", "/manifest.webmanifest",
                           headers={"Host": "attacker.example"})
        self.assertEqual(code, 403)
        code, _ = self.api("GET", "/headless.token")
        self.assertEqual(code, 404)
        code, _ = self.api("GET", "/../settings.json")
        self.assertEqual(code, 404)

    def test_unknown_action_rejected(self):
        token = self.api("GET", "/api/session")[1]["token"]
        code, payload = self.api("POST", "/api/control",
                                 {"action": "shell.exec", "command": "echo no"},
                                 {"X-Bifrost-Token": token})
        self.assertEqual(code, 400)
        self.assertIn("unknown", payload["error"])

    def test_invalid_duration_rejected(self):
        token = self.api("GET", "/api/session")[1]["token"]
        code, _ = self.api("POST", "/api/control",
                           {"action": "caffeinate.start", "minutes": 999},
                           {"X-Bifrost-Token": token})
        self.assertEqual(code, 400)


if __name__ == "__main__":
    unittest.main()
