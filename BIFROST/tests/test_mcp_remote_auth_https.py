"""Real loopback TLS tests for introspection; not a live OAuth issuer/MCP host."""
import base64
import json
import shutil
import ssl
import subprocess
import sys
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs
from urllib.request import HTTPSHandler, ProxyHandler, build_opener
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "headless"))
import mcp_remote_auth as auth


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", "0")))
        self.server.requests.append((self.path, dict(self.headers), body))
        self.send_response(self.server.response_status)
        self.send_header("Content-Type", "application/json")
        if self.server.response_status in (301, 302, 303, 307, 308):
            self.send_header("Location", self.server.base_url + "/redirect-target")
        self.send_header("Content-Length", str(len(self.server.response_body)))
        self.end_headers()
        self.wfile.write(self.server.response_body)


@unittest.skipUnless(shutil.which("openssl"), "OpenSSL required for ephemeral TLS fixture")
class IntrospectionHTTPSTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        cls.addClassCleanup(cls.temp.cleanup)
        root = Path(cls.temp.name)
        key, cert = root / "key.pem", root / "cert.pem"
        subprocess.run([
            shutil.which("openssl"), "req", "-x509", "-newkey", "rsa:2048",
            "-nodes", "-keyout", str(key), "-out", str(cert), "-days", "1",
            "-subj", "/CN=localhost", "-addext", "subjectAltName=IP:127.0.0.1",
        ], check=True, capture_output=True, timeout=15)
        key.chmod(0o600)
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        cls.addClassCleanup(cls.server.server_close)
        tls = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        tls.load_cert_chain(cert, key)
        cls.server.socket = tls.wrap_socket(cls.server.socket, server_side=True)
        cls.server.base_url = "https://127.0.0.1:" + str(cls.server.server_port)
        cls.context = ssl.create_default_context(cafile=str(cert))
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.addClassCleanup(cls.thread.join, 5)
        cls.addClassCleanup(cls.server.shutdown)

    def setUp(self):
        self.config = auth.Settings(
            self.server.base_url, "https://bifrost.example/mcp",
            self.server.base_url + "/introspect", "fixture-client", "fixture-secret", ("fixture-owner",))
        self.payload = {"active": True, "iss": self.config.issuer,
                        "aud": self.config.resource, "scope": "bifrost:read",
                        "sub": "fixture-owner", "client_id": "fixture-app", "exp": 2000}
        self.server.requests = []
        self.respond(self.payload)

    def respond(self, payload, status=200):
        self.server.response_status = status
        self.server.response_body = payload if isinstance(payload, bytes) else json.dumps(payload).encode()

    def inspect(self, token="fixture-token"):
        # Exercise production opener construction and redirect handler; add only
        # the temporary CA and disable environment proxy use for loopback.
        def trusted_builder(*handlers):
            return build_opener(ProxyHandler({}), HTTPSHandler(context=self.context), *handlers)
        with patch.object(auth, "build_opener", side_effect=trusted_builder):
            return auth.inspect_token(self.config, token, now=1000)

    def test_real_tls_post_and_minimal_identity(self):
        result = self.inspect()
        self.assertEqual(result["subject"], "fixture-owner")
        self.assertNotIn("token", result)
        path, headers, body = self.server.requests[0]
        self.assertEqual(path, "/introspect")
        self.assertEqual(headers["Authorization"], "Basic " + base64.b64encode(b"fixture-client:fixture-secret").decode())
        self.assertEqual(parse_qs(body.decode()), {"token": ["fixture-token"], "token_type_hint": ["access_token"]})

    def test_revocation_is_observed_on_next_request(self):
        self.assertIsNotNone(self.inspect())
        self.respond({"active": False})
        self.assertIsNone(self.inspect())
        self.assertEqual(len(self.server.requests), 2)

    def test_another_valid_subject_is_denied_over_tls(self):
        self.respond({**self.payload, "sub": "uninvited-user"})
        self.assertIsNone(self.inspect())
        self.assertEqual(len(self.server.requests), 1)

    def test_redirects_never_forward_credentials(self):
        for status in (301, 302, 303, 307, 308):
            with self.subTest(status=status):
                self.server.requests = []
                self.respond(b"", status)
                self.assertIsNone(self.inspect())
                self.assertEqual([r[0] for r in self.server.requests], ["/introspect"])

    def test_http_errors_deny(self):
        for status in (401, 403, 429, 500, 503):
            with self.subTest(status=status):
                self.respond({"error": "fixture-provider-error"}, status)
                self.assertIsNone(self.inspect())

    def test_invalid_json_and_oversized_responses_deny(self):
        for body in (b"not json", b"\xff", b"x" * (auth.MAX_RESPONSE + 1)):
            with self.subTest(length=len(body)):
                self.respond(body)
                self.assertIsNone(self.inspect())

    def test_deeply_nested_response_denies_without_crashing(self):
        self.respond(b"[" * 2000 + b"0" + b"]" * 2000)
        self.assertIsNone(self.inspect())

    def test_wrong_issuer_audience_scope_and_expiry_deny(self):
        for change in ({"iss": "https://wrong.example"}, {"aud": "https://wrong.example/mcp"},
                       {"scope": "other:read"}, {"exp": 999}, {"exp": float("nan")}):
            with self.subTest(change=change):
                self.respond({**self.payload, **change})
                self.assertIsNone(self.inspect())

    def test_malformed_token_never_reaches_network(self):
        self.assertIsNone(self.inspect("bad\nheader"))
        self.assertEqual(self.server.requests, [])

    def test_default_trust_rejects_fixture_certificate(self):
        # No test CA injection: the real production default must reject it.
        self.assertIsNone(auth.inspect_token(self.config, "fixture-token", now=1000))
        self.assertEqual(self.server.requests, [])


if __name__ == "__main__":
    unittest.main()
