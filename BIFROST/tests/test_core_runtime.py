"""BIFROSTcore read-only reconciliation contracts, synthetic isolated test homes."""
import contextlib
import hashlib
import io
import json
import pathlib
import plistlib
import sys
import tempfile
import unittest
from unittest import mock

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "headless"))
import core_runtime as core


class RuntimeInventoryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = pathlib.Path(self.temp.name)
        self.runtime = (self.home /
                        "Library/Application Support/BIFROST/runtime")
        self.runtime.mkdir(parents=True)
        self.source = self.runtime / "server.py"
        self.source.write_bytes(b"# verified isolated BIFROST Headless fixture\n")
        self.legacy_source = (
            self.home / "Library/Application Support/EDEN/BIFROST/Core/app.py")
        self.legacy_source.parent.mkdir(parents=True)
        self.legacy_source.write_bytes(
            b"VERSION='0.11.0'; SCHEMA_VERSION=1\n# no execution\n")
        self.plist = (
            self.home / "Library/LaunchAgents/org.eden.bifrost.core.plist")
        self.plist.parent.mkdir(parents=True)
        self.plist.write_bytes(plistlib.dumps({
            "Label": core.LEGACY_LABEL,
            "ProgramArguments": ["/opt/homebrew/bin/python3",
                                 str(self.legacy_source)],
            "RunAtLoad": False,
        }))

    def expected(self):
        return {
            "schema": "bifrost.headless.identity.v1",
            "productId": core.HEADLESS_PRODUCT,
            "runtimeId": hashlib.sha256(str(self.runtime).encode()).hexdigest()[:16],
            "sourceSha256": hashlib.sha256(self.source.read_bytes()).hexdigest(),
        }

    def test_typed_contract_with_distinct_owners_and_no_remote_claims(self):
        state = core.snapshot(
            self.home, headless_identity=self.expected(),
            headless_runtime=self.runtime, launchctl_status=lambda _: "not-registered")
        self.assertEqual(state["schema"], "bifrost.core.runtime-state.v1")
        self.assertEqual(state["runtime"], "BIFROSTcore")
        self.assertEqual(state["mode"], "read-only-federation")
        self.assertEqual(state["headless"]["state"], "identity-verified")
        self.assertEqual(state["legacyCore"]["state"], "configured-only")
        self.assertEqual(state["legacyCore"]["registration"], "not-registered")
        self.assertEqual(state["legacyCore"]["health"], "unknown")
        self.assertEqual(state["legacyCore"]["sourceVersion"], "0.11.0")
        self.assertFalse(state["stateOwnership"]["unifiedDatabase"])
        self.assertFalse(state["stateOwnership"]["migrationPerformed"])
        self.assertTrue(all(value is False for value in state["operations"].values()))

    def test_real_health_fixture_uses_exact_local_identity(self):
        def response(_timeout):
            return {"ok": True, "identity": self.expected()}
        observed = core.snapshot(
            self.home, request_health=response,
            launchctl_status=lambda _: "not-registered")
        self.assertEqual(observed["headless"]["state"], "identity-verified")
        self.assertEqual(observed["headless"]["health"], "responsive")
        self.assertEqual(observed["headless"]["provenance"], "bounded-local-health")

    def test_wrong_port_or_source_cannot_become_verified(self):
        wrong = dict(self.expected(), runtimeId="0" * 16)
        bad = core.headless_state(self.home, identity=wrong,
                                  runtime_path=self.runtime)
        self.assertEqual(bad["state"], "unverified")
        wrong = dict(self.expected(), sourceSha256="0" * 64)
        self.assertEqual(core.headless_state(
            self.home, identity=wrong,
            runtime_path=self.runtime)["state"], "unverified")
        wrong = dict(self.expected(), productId="other")
        self.assertEqual(core.headless_state(
            self.home, identity=wrong,
            runtime_path=self.runtime)["state"], "unverified")

    def test_unavailable_or_unrecognized_remote_response_is_not_a_pass(self):
        for payload in [{"ok": True, "identity": {"service": "other"}},
                        {"error": "provider unavailable"},
                        {"ok": False, "identity": self.expected()}]:
            self.assertNotEqual(core.headless_state(
                self.home, request_health=lambda _: payload)["state"],
                "identity-verified")
        self.assertEqual(core.headless_state(
            self.home, request_health=lambda _: (
                (_ for _ in ()).throw(OSError("offline"))))["state"],
                "not-observed")

    def test_legacy_source_and_plist_are_observed_only(self):
        cfg = self.legacy_source.parent.parent / "config/providers.json"
        cfg.parent.mkdir(parents=True)
        cfg.write_text('{"password":"do-not-read","api_key":"do-not-read"}')
        database = self.legacy_source.parent.parent / "data/bifrost.db"
        database.parent.mkdir()
        database.write_bytes(b"private user data")
        originals = {p: hashlib.sha256(p.read_bytes()).hexdigest() for p in (
            self.plist, self.legacy_source, cfg, database)}
        result = core.legacy_core_state(
            self.home, launchctl_status=lambda _: "registered")
        self.assertEqual(result["state"], "configured-only")
        self.assertEqual(result["registration"], "registered")
        self.assertEqual(result["health"], "unknown")
        self.assertNotIn("password", json.dumps(result))
        self.assertNotIn("api_key", json.dumps(result))
        self.assertNotIn("private user data", json.dumps(result))
        self.assertEqual(originals, {
            p: hashlib.sha256(p.read_bytes()).hexdigest() for p in originals})

    def test_bad_legacy_target_is_not_a_registered_core(self):
        data = plistlib.loads(self.plist.read_bytes())
        data["ProgramArguments"][-1] = "/tmp/unapproved.py"
        self.plist.write_bytes(plistlib.dumps(data))
        with mock.patch.object(core, "_launchctl_registration") as launcher:
            observed = core.legacy_core_state(self.home)
        self.assertEqual(observed["state"], "unexpected-launch-configuration")
        launcher.assert_not_called()

    def test_symlinked_core_plist_rejected_without_following(self):
        real = self.home / "reparse.plist"
        self.plist.rename(real)
        self.plist.symlink_to(real)
        observed = core.legacy_core_state(self.home)
        self.assertEqual(observed["state"], "launch-configuration-unavailable")

    def test_oversize_script_and_missing_runtime_fail_closed(self):
        self.legacy_source.write_bytes(b"x" * (core.MAX_SOURCE + 1))
        self.assertEqual(core.legacy_core_state(self.home)["state"],
                         "source-unavailable")
        identity = self.expected()
        self.source.unlink()
        self.assertEqual(core.headless_state(
            self.home, identity=identity,
            runtime_path=self.runtime)["state"], "unverified")

    def test_terminal_config_show_and_preview_are_never_writes(self):
        prefs = self.home / "Library/Application Support/BIFROST/settings.json"
        prefs.parent.mkdir(parents=True, exist_ok=True)
        prefs.write_text(json.dumps({"caffeinateMinutes": 30,
                                     "credentials": "should-not-be-exposed",
                                     "statusIndicators": ["headless", "unapproved"],
                                     "dashboardSections": ["headless", "caffeinate"]}))
        self.assertEqual(core.read_headless_preferences(
            self.home)["statusIndicators"], ["headless"])
        stdout = io.StringIO()
        with contextlib.ExitStack() as stack:
            stack.enter_context(mock.patch.object(core.Path, "home", return_value=self.home))
            writer = stack.enter_context(mock.patch.object(core, "apply_headless_preference"))
            stack.enter_context(contextlib.redirect_stdout(stdout))
            self.assertEqual(core.main(["config", "show", "--json"]), 0)
            self.assertEqual(core.main([
                "config", "set", "caffeinateMinutes", "120", "--json"]), 0)
        content = stdout.getvalue()
        self.assertNotIn("credentials", content)
        self.assertNotIn("should-not-be-exposed", content)
        self.assertIn('"written": false', content)
        writer.assert_not_called()
        self.assertEqual(core.read_headless_preferences(
            self.home)["caffeinateMinutes"], 30)

    def test_terminal_config_requires_explicit_approved_supported_value(self):
        with contextlib.ExitStack() as stack:
            stack.enter_context(mock.patch.object(core.Path, "home", return_value=self.home))
            writer = stack.enter_context(mock.patch.object(core, "apply_headless_preference"))
            stack.enter_context(contextlib.redirect_stdout(io.StringIO()))
            with self.assertRaises(SystemExit) as bad:
                core.main(["config", "set", "caffeinateMinutes", "999", "--apply"])
            self.assertEqual(bad.exception.code, 2)
            with self.assertRaises(SystemExit) as unknown:
                core.main(["config", "set", "providerToken", "fake", "--apply"])
            self.assertEqual(unknown.exception.code, 2)
            self.assertEqual(core.main(["config", "set", "caffeinateMinutes",
                                        "120", "--apply"]), 0)
        writer.assert_called_once_with(self.home, 120)

    def test_explicit_local_config_uses_existing_headless_auth_and_readback(self):
        token_file = self.home / "Library/Application Support/BIFROST/headless.token"
        token_file.parent.mkdir(parents=True, exist_ok=True)
        token_file.write_text("synthetic-test-token\n")
        token_file.chmod(0o600)
        settings = token_file.parent / "settings.json"
        settings.write_text('{"caffeinateMinutes":30}')
        captured = []

        class Response:
            status = 200
            def __enter__(self):
                return self
            def __exit__(self, *_):
                return None
            def read(self, _max_bytes):
                return json.dumps({"preferences": {"caffeinateMinutes": 60}}).encode()

        class Opener:
            def open(self, request, timeout):
                captured.append((request.full_url, request.get_method(),
                                 json.loads(request.data), timeout))
                settings.write_text('{"caffeinateMinutes":60}')
                return Response()

        with mock.patch.object(core, "headless_state", return_value={
                "state": "identity-verified"}), (
             mock.patch.object(core.urllib.request, "build_opener", return_value=Opener())):
            receipt = core.apply_headless_preference(self.home, 60)
        self.assertTrue(receipt["saved"])
        self.assertFalse(receipt["serviceRestarted"])
        self.assertEqual(core.read_headless_preferences(
            self.home)["caffeinateMinutes"], 60)
        self.assertEqual(captured, [(
            "http://127.0.0.1:8798/api/preferences", "POST",
            {"caffeinateMinutes": 60}, 1.5)])
        self.assertEqual(token_file.read_text(), "synthetic-test-token\n")

    def test_local_config_rejects_insecure_auth_file(self):
        token_file = self.home / "Library/Application Support/BIFROST/headless.token"
        token_file.parent.mkdir(parents=True, exist_ok=True)
        token_file.write_text("synthetic-test-token")
        token_file.chmod(0o644)
        with contextlib.ExitStack() as stack:
            stack.enter_context(mock.patch.object(core, "headless_state", return_value={
                "state": "identity-verified"}))
            http_opener = stack.enter_context(mock.patch.object(
                core.urllib.request, "build_opener"))
            with self.assertRaises(RuntimeError):
                core.apply_headless_preference(self.home, 30)
        http_opener.assert_not_called()

    def test_cli_never_creates_an_account_or_changes_service(self):
        recorded = core.snapshot(
            self.home, headless_identity=self.expected(),
            headless_runtime=self.runtime, launchctl_status=lambda _: "not-registered")
        stdout = io.StringIO()
        with mock.patch.object(core, "snapshot", return_value=recorded), (
                contextlib.redirect_stdout(stdout)):
            self.assertEqual(core.main(["status", "--json"]), 0)
        result = json.loads(stdout.getvalue())
        self.assertEqual(result["schema"], core.SCHEMA)
        self.assertEqual(result["legacyCore"]["health"], "unknown")
        self.assertFalse(result["operations"]["serviceChanges"])


if __name__ == "__main__":
    unittest.main()
