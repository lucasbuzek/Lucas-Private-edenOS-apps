"""Offline, isolated BIFROST Headless tests; no real Caffeinate or cloud calls."""
import http.client
import importlib.util
import json
import plistlib
import pathlib
import tempfile
import threading
import unittest
import sys
from unittest import mock
from http.server import ThreadingHTTPServer
from socketserver import TCPServer


class LocalThreadingHTTPServer(ThreadingHTTPServer):
    """Avoid reverse-DNS lookup when binding an isolated loopback test server."""
    def server_bind(self):
        TCPServer.server_bind(self)
        self.server_name = "localhost"
        self.server_port = self.server_address[1]


SCRIPT = pathlib.Path(__file__).resolve().parents[1] / "headless" / "server.py"
sys.path.insert(0, str(SCRIPT.parent))
spec = importlib.util.spec_from_file_location("bifrost_headless", SCRIPT)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


class PreferenceTests(unittest.TestCase):
    def test_defaults(self):
        defaults = mod.normalize({})
        self.assertEqual(defaults["statusIndicators"], ["headless"])
        self.assertNotIn("aiRouting", defaults)
        self.assertEqual(defaults["caffeinateMinutes"], 60)

    def test_settings_are_restricted(self):
        value = mod.normalize({"caffeinateMinutes": -40, "aiRouting": "execute",
                               "statusIndicators": ["headless", "fake", "headless", "activeTasks"],
                               "dashboardSections": ["ai", "unsafe", "headless", "headless"]})
        self.assertEqual(value["caffeinateMinutes"], 60)
        self.assertNotIn("aiRouting", value)
        self.assertEqual(value["statusIndicators"], ["headless"])
        self.assertEqual(value["dashboardSections"], ["headless"])

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
        cls.server = LocalThreadingHTTPServer(("127.0.0.1", 0), mod.Handler)
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
        self.assertEqual(status["connectionScope"], "local-only")
        self.assertNotIn("ai", status)
        self.assertNotIn("raven", status)
        self.assertNotIn("tasks", status)

    def test_typed_status_is_read_only_and_requires_local_session(self):
        code, _ = self.api("GET", "/api/status/v1")
        self.assertEqual(code, 403)
        code, token = self.api("GET", "/api/session")
        self.assertEqual(code, 200)
        code, status = self.api("GET", "/api/status/v1",
                                headers={"X-Bifrost-Token": token["token"]})
        self.assertEqual(code, 200)
        self.assertEqual(status["schema"], "bifrost.status.v1")
        self.assertEqual(status["kind"], "node.status")
        self.assertEqual(status["taskState"], "not-submitted")
        self.assertIsNone(status["taskId"])
        self.assertEqual(status["connectionScope"], "local-only")
        self.assertEqual(status["authority"], "local-headless")
        self.assertEqual(status["headless"]["status"], "running")
        code, _ = self.api("GET", "/api/status/v1",
                           headers={"Host": "remote.example",
                                    "X-Bifrost-Token": token["token"]})
        self.assertEqual(code, 403)

    def test_pwa_adapter_storage_routes_are_read_only_private_source_catalog(self):
        code, value = self.api("GET", "/api/pwa/adapter")
        self.assertEqual(code, 200)
        registrations = {entry["id"]: entry for entry in value["capabilities"]}
        self.assertEqual(registrations["bifrost.storage.catalog.read"]["method"], "GET")
        self.assertEqual(registrations["bifrost.storage.catalog.read"]["route"],
                         "/api/storage/v1")
        self.assertEqual(registrations["bifrost.storage.accounts.metadata.read"]["route"],
                         "/api/storage/v1/accounts")
        self.assertEqual(registrations["bifrost.storage.profile.preview"]["method"], "POST")
        self.assertEqual(registrations["bifrost.storage.profile.preview"]["route"],
                         "/api/storage/v1/preview")
        for ident in ("bifrost.storage.catalog.read",
                      "bifrost.storage.accounts.metadata.read",
                      "bifrost.storage.profile.preview"):
            self.assertEqual(registrations[ident]["requires"], "local-session")
            self.assertNotIn("write", registrations[ident]["effect"])
        self.assertFalse(value["crossOriginApiEnabled"])
        self.assertEqual(value["externalPlugins"], "independently-installed")

    def test_real_headless_preview_integration_uses_selected_fixture_profile(self):
        # Exercises real storage core and adapter through isolated HTTP.
        # No real Rclone, Apple Drive or user home is contacted.
        home = (self.root / "storage-preview-fixture").resolve()
        root = home / "Documents" / "Selected"
        root.mkdir(parents=True, exist_ok=True)
        (root / "visible.txt").write_text("safe synthetic file")
        nested = root / "one-level"
        nested.mkdir()
        (nested / "child.txt").write_text("nested fixture")
        config = home / ".config" / "rclone" / "rclone.conf"
        config.parent.mkdir(parents=True, exist_ok=True)
        config.write_text("[personal]\ntype = drive\n")
        config.chmod(0o600)
        core = mod.storage_metadata._core()
        core.configure_profile("LocalDocs", "local", "native-local", "",
                               str(root), home=home, apply=True)
        core.configure_profile("GoogleDocs", "drive", "system", "personal",
                               str(root), home=home, apply=True,
                               remote_root="Chosen")
        token = self.api("GET", "/api/session")[1]["token"]
        headers = {"X-Bifrost-Token": token}
        with mock.patch("pathlib.Path.home", return_value=home):
            code, local = self.api("POST", "/api/storage/v1/preview",
                                   {"profile":"LocalDocs"}, headers=headers)
            self.assertEqual(code, 200)
            self.assertEqual(local["status"], "LOCAL_READ_ONLY")
            self.assertEqual({x["name"] for x in local["entries"]},
                             {"visible.txt", "one-level"})
            code, cloud = self.api("POST", "/api/storage/v1/preview",
                                   {"profile":"GoogleDocs","folder":"2026"},
                                   headers=headers)
            self.assertEqual(code, 200)
            self.assertEqual(cloud["account_id"], "system:personal")
            self.assertEqual(cloud["folder"], "Chosen/2026")
            self.assertFalse(cloud["remote_read_executed"])
            code, _ = self.api("POST", "/api/storage/v1/preview",
                               {"profile":"Unknown"}, headers=headers)
            self.assertEqual(code, 422)

    def test_storage_profile_preview_requires_local_session_and_explicit_scope(self):
        token = self.api("GET", "/api/session")[1]["token"]
        request = {"profile": "Google", "folder": "Chosen", "readRemote": False}
        receipt = {"schema": "bifrost.storage.v1",
                   "profile": "Google", "account_id": "system:personal",
                   "folder": "Chosen", "status": "REMOTE_READ_NOT_REQUESTED",
                   "remote_read_executed": False, "entries": []}
        with mock.patch.object(mod.storage_metadata, "preview",
                               return_value=receipt) as reader:
            code, _ = self.api("POST", "/api/storage/v1/preview", request)
            self.assertEqual(code, 403)
            code, _ = self.api("POST", "/api/storage/v1/preview", request,
                               headers={"X-Bifrost-Token": token,
                                        "Origin": "https://outside.example"})
            self.assertEqual(code, 403)
            code, _ = self.api("POST", "/api/storage/v1/preview?all=1",
                               request, headers={"X-Bifrost-Token": token})
            self.assertEqual(code, 400)
            code, _ = self.api("POST", "/api/storage/v1/preview",
                               {**request, "other": "forbidden"},
                               headers={"X-Bifrost-Token": token})
            self.assertEqual(code, 400)
            reader.assert_not_called()
            code, answer = self.api("POST", "/api/storage/v1/preview", request,
                                    headers={"X-Bifrost-Token": token})
            self.assertEqual(code, 200)
            self.assertEqual(answer, receipt)
            reader.assert_called_once_with("Google", folder="Chosen", read_remote=False)

    def test_storage_profile_remote_read_flag_must_be_boolean_and_explicit(self):
        token = self.api("GET", "/api/session")[1]["token"]
        headers = {"X-Bifrost-Token": token}
        with mock.patch.object(mod.storage_metadata, "preview",
                               return_value={"status": "REMOTE_READ_ONLY"}) as reader:
            for item in ({"profile": "Google", "readRemote": "yes"},
                         {"profile": "Google", "readRemote": 1},
                         {"profile": "Google", "folder": []},
                         {"profile": 17}):
                code, _ = self.api("POST", "/api/storage/v1/preview",
                                   item, headers=headers)
                self.assertEqual(code, 400)
            reader.assert_not_called()
            code, answer = self.api("POST", "/api/storage/v1/preview",
                                    {"profile": "Google", "folder": "Photos",
                                     "readRemote": True}, headers=headers)
            self.assertEqual(code, 200)
            self.assertEqual(answer["status"], "REMOTE_READ_ONLY")
            reader.assert_called_once_with("Google", folder="Photos", read_remote=True)

    def test_storage_preview_scope_denial_or_missing_core_never_claims_success(self):
        token = self.api("GET", "/api/session")[1]["token"]
        headers = {"X-Bifrost-Token": token}
        with mock.patch.object(mod.storage_metadata, "preview",
                               side_effect=ValueError("specific private location")):
            code, answer = self.api("POST", "/api/storage/v1/preview",
                                    {"profile":"Wrong"}, headers=headers)
            self.assertEqual(code, 422)
            self.assertNotIn("specific private location", json.dumps(answer))
        with mock.patch.object(mod.storage_metadata, "preview",
                               side_effect=RuntimeError("backend unavailable")):
            code, answer = self.api("POST", "/api/storage/v1/preview",
                                    {"profile":"Google"}, headers=headers)
            self.assertEqual(code, 503)
            self.assertNotIn("backend unavailable", json.dumps(answer))

    def test_storage_catalog_is_authenticated_metadata_only_and_disabled_for_writes(self):
        token = self.api("GET", "/api/session")[1]["token"]
        with mock.patch.object(mod.storage_metadata, "accounts",
                               side_effect=AssertionError("must not scan accounts")):
            code, _ = self.api("GET", "/api/storage/v1")
            self.assertEqual(code, 403)
            code, result = self.api("GET", "/api/storage/v1", headers={
                "X-Bifrost-Token": token})
            self.assertEqual(code, 200)
            self.assertEqual(result["schema"], "bifrost.storage.v1")
            self.assertEqual(result["authority"], "BIFROSTcore")
            self.assertFalse(result["capability"]["auto_sync"])
            self.assertFalse(result["capability"]["chatgpt_action_bridge_verified"])
            self.assertGreaterEqual(len(result["providers"]), 9)
            self.assertNotIn("accounts", result)
            code, _ = self.api("GET", "/api/storage/v1?path=/etc", headers={
                "X-Bifrost-Token": token})
            self.assertEqual(code, 400)
            code, _ = self.api("GET", "/api/storage/v1", headers={
                "X-Bifrost-Token": token, "Origin": "https://unknown.example"})
            self.assertEqual(code, 403)
            code, _ = self.api("GET", "/api/storage/v1", headers={
                "X-Bifrost-Token": token, "Host": "remote.example"})
            self.assertEqual(code, 403)
            code, _ = self.api("POST", "/api/storage/v1",
                               {"operation": "sync-all"}, headers={
                                   "X-Bifrost-Token": token})
            self.assertEqual(code, 404)

    def test_storage_profiles_require_session_and_exclude_private_fields(self):
        token = self.api("GET", "/api/session")[1]["token"]
        core = mock.Mock()
        core.profiles.return_value = [{"name":"saved", "provider":"drive", "account_binding":"secret", "local_root":"private"}]
        with mock.patch.object(mod.storage_metadata, "_core", return_value=core):
            code, _ = self.api("GET", "/api/storage/v1/profiles")
            self.assertEqual(code, 403)
            core.profiles.assert_not_called()
            code, result = self.api("GET", "/api/storage/v1/profiles", headers={"X-Bifrost-Token":token})
            self.assertEqual(code, 200)
            self.assertEqual(result["profiles"], [{"name":"saved", "provider":"drive"}])

    def test_storage_account_metadata_is_private_and_not_called_without_auth(self):
        token = self.api("GET", "/api/session")[1]["token"]
        fixture = {"schema": "bifrost.storage.v1", "accounts": [
            {"name": "private1", "provider": "onedrive", "source": "system",
             "authorizedByStorageCore": False}],
            "authorizedByThisModule": False}
        with mock.patch.object(mod.storage_metadata, "accounts",
                               return_value=fixture) as reader:
            code, _ = self.api("GET", "/api/storage/v1/accounts")
            self.assertEqual(code, 403)
            reader.assert_not_called()
            code, _ = self.api("GET", "/api/storage/v1/accounts?all=true", headers={
                "X-Bifrost-Token": token})
            self.assertEqual(code, 400)
            reader.assert_not_called()
            code, reply = self.api("GET", "/api/storage/v1/accounts", headers={
                "X-Bifrost-Token": token})
            self.assertEqual(code, 200)
            self.assertEqual(reply, fixture)
            reader.assert_called_once_with()
            code, _ = self.api("GET", "/api/storage/v1/accounts", headers={
                "X-Bifrost-Token": token, "Origin": "https://not-local.example"})
            self.assertEqual(code, 403)
            self.assertEqual(reader.call_count, 1)
            code, _ = self.api("POST", "/api/storage/v1/accounts", {},
                               headers={"X-Bifrost-Token": token})
            self.assertEqual(code, 404)
            self.assertEqual(reader.call_count, 1)

    def test_storage_adapter_missing_module_is_unavailable_not_fake(self):
        with mock.patch.object(mod.storage_metadata, "CORE_CANDIDATES",
                               (pathlib.Path("/nonexistent/bifrost/storage.py"),)):
            token = self.api("GET", "/api/session")[1]["token"]
            code, answer = self.api("GET", "/api/storage/v1", headers={
                "X-Bifrost-Token": token})
            self.assertEqual(code, 503)
            self.assertEqual(answer, {"error": "storage metadata unavailable"})

    def test_core_runtime_endpoint_requires_auth_and_is_observation_only(self):
        evidence = {
            "schema": "bifrost.core.runtime-state.v1",
            "runtime": "BIFROSTcore",
            "mode": "read-only-federation",
            "stateOwnership": {"unifiedDatabase": False},
            "operations": {"remoteExecutionVerified": False,
                           "sharedDispatcherVerified": False},
        }
        with mock.patch.object(mod.runtime_inventory, "snapshot", return_value=evidence) as inspect:
            code, _ = self.api("GET", "/api/core/v1")
            self.assertEqual(code, 403)
            inspect.assert_not_called()
            token = self.api("GET", "/api/session")[1]["token"]
            headers = {"X-Bifrost-Token": token}
            code, answer = self.api("GET", "/api/core/v1", headers=headers)
            self.assertEqual(code, 200)
            self.assertEqual(answer, evidence)
            inspect.assert_called_once_with(
                headless_identity=mod.RUNTIME_IDENTITY,
                headless_runtime=mod.WEBROOT)
            code, _ = self.api("GET", "/api/core/v1", headers={
                **headers, "Origin": "https://untrusted.example"})
            self.assertEqual(code, 403)
            self.assertEqual(inspect.call_count, 1)
            code, _ = self.api("POST", "/api/core/v1", {"action": "core.start"}, headers)
            self.assertEqual(code, 404)
            self.assertEqual(inspect.call_count, 1)

    def test_core_runtime_live_module_uses_exact_server_source_identity(self):
        token = self.api("GET", "/api/session")[1]["token"]
        fake_legacy = {"state": "configured-only", "health": "unknown",
                       "registration": "not-registered"}
        # Execute the actual Core observer against this isolated Headless
        # handler; the old Core source/config is replaced with a fixture.
        with mock.patch.object(mod.runtime_inventory, "legacy_core_state",
                               return_value=fake_legacy) as legacy:
            code, observed = self.api("GET", "/api/core/v1", headers={
                "X-Bifrost-Token": token})
        self.assertEqual(code, 200)
        self.assertEqual(observed["schema"], "bifrost.core.runtime-state.v1")
        self.assertEqual(observed["headless"]["state"], "identity-verified")
        self.assertEqual(observed["headless"]["health"], "serving-request")
        self.assertEqual(observed["legacyCore"], fake_legacy)
        self.assertFalse(observed["stateOwnership"]["unifiedDatabase"])
        self.assertFalse(observed["operations"]["remoteExecutionVerified"])
        legacy.assert_called_once()

    def test_native_app_open_is_user_approved_fixed_bundle_only(self):
        token = self.api("GET", "/api/session")[1]["token"]
        payload = {"accepted": True, "action": "app.open",
                   "execution": "macos-launchservices-request",
                   "uiVisibleVerified": False}
        headers = {"X-Bifrost-Token": token}
        # Without a valid token, a launch request cannot reach the backend.
        with mock.patch.object(mod, "open_native_bifrost", return_value=payload) as opener:
            code, _ = self.api("POST", "/api/control", {"action": "app.open"})
            self.assertEqual(code, 403)
            opener.assert_not_called()
            code, value = self.api("POST", "/api/control", {"action": "app.open"}, headers)
            self.assertEqual(code, 200)
            self.assertEqual(value, payload)
            self.assertFalse(value["uiVisibleVerified"])
            opener.assert_called_once_with()
            code, _ = self.api("POST", "/api/control",
                               {"action": "app.open", "path": "/bin/sh"}, headers)
            self.assertEqual(code, 400)
            self.assertEqual(opener.call_count, 1)
            code, _ = self.api("POST", "/api/control", {"action": "app.open"},
                               {**headers, "Origin": "https://evil.example"})
            self.assertEqual(code, 403)
            self.assertEqual(opener.call_count, 1)

    def test_native_app_unavailable_is_truthful(self):
        token = self.api("GET", "/api/session")[1]["token"]
        with mock.patch.object(mod, "open_native_bifrost", side_effect=OSError("missing")):
            code, value = self.api("POST", "/api/control", {"action": "app.open"},
                                   {"X-Bifrost-Token": token})
        self.assertEqual(code, 409)
        self.assertIn("unavailable", value["error"])

    @mock.patch.object(mod.sys, "platform", "darwin")
    def test_macos_native_launch_only_uses_exact_approved_bundle(self):
        app = self.root / "TestNativeBIFROST.app"
        (app / "Contents").mkdir(parents=True, exist_ok=True)
        (app / "Contents" / "Info.plist").write_bytes(
            plistlib.dumps({"CFBundleIdentifier": "eden.private.bifrost"}))
        record = self.root / "native-app.json"
        record.write_text(json.dumps({
            "schema": "bifrost.native-app.v1",
            "bundleIdentifier": "eden.private.bifrost",
            "path": str(app)
        }))
        record.chmod(0o600)
        class Result:
            returncode = 0
        with mock.patch.object(mod.subprocess, "run", return_value=Result()) as run:
            status = mod.open_native_bifrost()
        self.assertTrue(status["accepted"])
        args, kwargs = run.call_args
        self.assertEqual(args[0], ["/usr/bin/open", "-a", str(app)])
        self.assertFalse(kwargs.get("shell", False))
        self.assertEqual(kwargs["timeout"], 6)
        # An invalid identity never reaches LaunchServices.
        (app / "Contents" / "Info.plist").write_bytes(
            plistlib.dumps({"CFBundleIdentifier": "com.other.app"}))
        with mock.patch.object(mod.subprocess, "run") as run:
            with self.assertRaises(OSError):
                mod.open_native_bifrost()
            run.assert_not_called()
        record.unlink()

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
        code, _ = self.api("POST", "/api/control", {"action": "caffeinate.stop"},
                           {"X-Bifrost-Token": token, "Origin": "https://malicious.example"})
        self.assertEqual(code, 403)

    def test_local_task_receipts_are_authenticated_durable_and_readonly(self):
        key = "test-once-abcdef0987654321"
        body = {"kind": "local.status.snapshot", "idempotencyKey": key}
        code, _ = self.api("GET", "/api/tasks/v1")
        self.assertEqual(code, 403)
        code, _ = self.api("POST", "/api/tasks/v1", body)
        self.assertEqual(code, 403)
        token = self.api("GET", "/api/session")[1]["token"]
        headers = {"X-Bifrost-Token": token}
        code, receipt = self.api("POST", "/api/tasks/v1", body, headers)
        self.assertEqual(code, 201)
        self.assertEqual(receipt["kind"], "local.status.snapshot")
        self.assertEqual(receipt["state"], "completed")
        self.assertEqual(receipt["execution"], "local-readonly-observation")
        self.assertFalse(receipt["remoteExecutionVerified"])
        self.assertIsNone(receipt["result"]["remoteTaskId"])
        code, repeated = self.api("POST", "/api/tasks/v1", body, headers)
        self.assertEqual(code, 200)
        self.assertEqual(receipt, repeated)
        code, listed = self.api("GET", "/api/tasks/v1?limit=1", headers=headers)
        self.assertEqual(code, 200)
        self.assertEqual(listed["count"], 1)
        self.assertEqual(listed["tasks"][0]["taskId"], receipt["taskId"])
        code, fetched = self.api("GET", "/api/tasks/v1/" + receipt["taskId"],
                                 headers=headers)
        self.assertEqual(code, 200)
        self.assertEqual(receipt, fetched)
        self.assertEqual((self.root / "local_tasks.sqlite3").stat().st_mode & 0o777, 0o600)

    def test_local_task_rejects_external_execution_and_query_misuse(self):
        token = self.api("GET", "/api/session")[1]["token"]
        headers = {"X-Bifrost-Token": token}
        for payload in ({"kind": "shell.exec"},
                        {"kind": "local.status.snapshot", "command": "date"},
                        {"kind": "remote.provider.submit"}):
            with self.subTest(payload=payload):
                code, _ = self.api("POST", "/api/tasks/v1", payload, headers)
                self.assertEqual(code, 400)
        for url in ("/api/tasks/v1?limit=1000",
                    "/api/tasks/v1?unknown=value",
                    "/api/tasks/v1?limit=1&limit=2",
                    "/api/tasks/v1/../../private",
                    "/api/tasks/v1/local_invalid"):
            with self.subTest(url=url):
                code, _ = self.api("GET", url, headers=headers)
                self.assertIn(code, (400, 404))
        code, _ = self.api("POST", "/api/tasks/v1",
                           {"kind": "local.status.snapshot"}, {
                               "X-Bifrost-Token": token,
                               "Origin": "https://remote.example"})
        self.assertEqual(code, 403)
        code, _ = self.api("GET", "/api/tasks/v1", headers={
            "X-Bifrost-Token": token, "Host": "remote.example"})
        self.assertEqual(code, 403)

    def test_preference_roundtrip(self):
        token = self.api("GET", "/api/session")[1]["token"]
        code, obj = self.api("POST", "/api/preferences",
                             {"statusIndicators": ["headless"], "caffeinateMinutes": 60},
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

    def test_online_bridge_is_not_bundled(self):
        code, _ = self.api("GET", "/api/mobile/bridge")
        self.assertEqual(code, 404)
        code, _ = self.api("POST", "/api/control", {"action": "tasks.refresh"})
        self.assertEqual(code, 403)

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
        self.assertEqual(descriptor["onlineExecution"], "not-bundled")
        self.assertEqual(descriptor["externalPlugins"], "independently-installed")
        self.assertNotIn("optionalRemoteProvider", descriptor)
        ids = {cap["id"]: cap for cap in descriptor["capabilities"]}
        self.assertNotIn("remote.setup.execute", ids)
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
