"""BIFROST ZERO: explicit health+HTML evidence for owned specialist Web UIs.

All network tests use a disposable loopback HTTP fixture. Never start an
existing user daemon, inspect credentials or access external service ports.
"""
import json
import pathlib
import sys
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from unittest import mock

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "headless"))
import connection_observer as obs

HEIMDALL = {"ok": True, "app": "HEIMDALL",
            "identity": "ORGANIZE & UNDERSTAND", "schema_version": 2,
            "build_id": "heimdall-private-exp-20260925.4"}
PENELOPE = {"status": "ready", "version": "0.2.0",
            "custody": "read-only", "legacy_reconcile": True}


class StubHandler(BaseHTTPRequestHandler):
    health = HEIMDALL
    html = "<!doctype html><title>HEIMDALL</title><h1>HEIMDALL</h1>"
    status = 200
    mime = None

    def log_message(self, *args):
        pass

    def do_GET(self):
        if self.status != 200:
            self.send_response(self.status)
            self.send_header("Location", "http://evil.example")
            self.send_header("Content-Length", "0")
            self.end_headers()
            return
        if self.path == "/api/health":
            body = json.dumps(self.health).encode()
            mime = "application/json"
        elif self.path == "/":
            body = self.html.encode()
            mime = "text/html; charset=utf-8"
        else:
            self.send_error(404)
            return
        if self.mime:
            mime = self.mime
        self.send_response(200)
        self.send_header("Content-Type", mime)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


class SpecialistWebRepresentationTests(unittest.TestCase):
    def setUp(self):
        StubHandler.health = HEIMDALL
        StubHandler.html = "<!doctype html><title>HEIMDALL</title><h1>HEIMDALL</h1>"
        StubHandler.status = 200
        StubHandler.mime = None
        self.http = ThreadingHTTPServer(("127.0.0.1", 0), StubHandler)
        self.http.daemon_threads = True
        self.thread = threading.Thread(target=self.http.serve_forever, daemon=True)
        self.thread.start()
        self.port = self.http.server_address[1]
        self.home = tempfile.TemporaryDirectory()
        # Cleanup runs in reverse order: stop, close, then join.
        self.addCleanup(self.home.cleanup)
        self.addCleanup(self.thread.join, 2)
        self.addCleanup(self.http.server_close)
        self.addCleanup(self.http.shutdown)

    def spec(self, name):
        return mock.patch.dict(obs.WEB_REPRESENTATIONS, {
            name: {**obs.WEB_REPRESENTATIONS[name], "port": self.port}
        })

    def test_heimdall_local_web_requires_matching_health_and_actual_html(self):
        with self.spec("HEIMDALL"):
            url = obs._verified_web("HEIMDALL")
            self.assertEqual(url, "http://127.0.0.1:{}/".format(self.port))
            apps = {app["id"]: app for app in obs._apps(pathlib.Path(self.home.name))}
            self.assertTrue(apps["heimdall"]["webVerified"])
            self.assertEqual(apps["heimdall"]["webURL"], url)
            self.assertEqual(apps["heimdall"]["webEvidence"], "exact-loopback-health-and-html")
            self.assertIsNone(apps["janitor"]["webURL"])
            self.assertFalse(apps["curator"]["webVerified"])

    def test_penelope_local_web_requires_its_own_exact_identity(self):
        StubHandler.health = PENELOPE
        StubHandler.html = "<!doctype html><title>PENELOPE — File Custody</title>"
        with self.spec("PENELOPE"):
            self.assertEqual(obs._verified_web("PENELOPE"),
                             "http://127.0.0.1:{}/".format(self.port))

    def test_heath_service_identity_mismatch_never_creates_a_launch_url(self):
        for health in ({"ok": True, "app": "HEIMDALL"},
                       {"ok": True, "app": "JANITOR", "identity": "ORGANIZE & UNDERSTAND"},
                       [], None, {}, {"status": "ready"}):
            with self.subTest(health=health):
                StubHandler.health = health
                with self.spec("HEIMDALL"):
                    self.assertIsNone(obs._verified_web("HEIMDALL"))

    def test_wrong_html_impostor_never_passes(self):
        StubHandler.html = "<title>Unknown Portal</title>"
        with self.spec("HEIMDALL"):
            self.assertIsNone(obs._verified_web("HEIMDALL"))

    def test_redirect_and_wrong_mime_do_not_pass(self):
        for status, mime in ((302, None), (200, "text/plain")):
            with self.subTest(status=status, mime=mime):
                StubHandler.status = status
                StubHandler.mime = mime
                with self.spec("HEIMDALL"):
                    self.assertIsNone(obs._verified_web("HEIMDALL"))

    def test_no_unlisted_arbitrary_service_can_be_probed(self):
        with mock.patch.object(obs, "_web_get") as getter:
            self.assertIsNone(obs._verified_web("JANITOR"))
            self.assertIsNone(obs._verified_web("evil"))
            self.assertIsNone(obs._verified_web("CURATOR"))
            getter.assert_not_called()

    def test_wrong_penelope_version_and_missing_custody_role_denied(self):
        StubHandler.html = "<title>PENELOPE — File Custody</title>"
        for health in ({"status": "ready", "version": "0.3.2"},
                       {"status": "ready", "version": "0.2.0"},
                       {"status": "ready", "version": "0.2.0",
                        "custody": "read-only", "legacy_reconcile": False}):
            with self.subTest(health=health):
                StubHandler.health = health
                with self.spec("PENELOPE"):
                    self.assertIsNone(obs._verified_web("PENELOPE"))

    def test_unavailable_loopback_port_fails_closed(self):
        self.http.shutdown()
        self.thread.join(timeout=2)
        self.http.server_close()
        with self.spec("HEIMDALL"):
            self.assertIsNone(obs._verified_web("HEIMDALL"))


if __name__ == "__main__":
    unittest.main()
