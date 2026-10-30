"""Real SDK HTTP boundary tests with a fixture identity, never production OAuth.

Install mcp==2.3.0 for this optional suite. CI sets BIFROST_REQUIRE_MCP_SDK=1
so missing dependencies fail rather than silently turning acceptance into skips.
"""
import importlib.util
import json
import os
import platform
import socket
import sys
import threading
import time
import unittest
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, ProxyHandler, build_opener
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "headless"))
SDK_AVAILABLE = importlib.util.find_spec("mcp") is not None
if not SDK_AVAILABLE and os.environ.get("BIFROST_REQUIRE_MCP_SDK") == "1":
    raise RuntimeError("Required official MCP SDK unavailable; HTTP acceptance cannot run")
if SDK_AVAILABLE:
    import uvicorn
    import mcp_remote as remote
    from mcp_remote_auth import Settings, SCOPE
    from mcp.server.transport_security import TransportSecuritySettings


@unittest.skipUnless(SDK_AVAILABLE, "Official MCP SDK required; not HTTP acceptance")
class RemoteHTTPTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.resource = "https://bifrost.example/mcp"
        cls.revoked = False
        cls.calls = []

        def identity(config, bearer):
            cls.calls.append(bearer)
            if bearer != "fixture-token" or cls.revoked:
                return None
            return {"subject": "fixture-owner", "client_id": "fixture-client",
                    "scopes": [SCOPE], "resource": cls.resource,
                    "expires_at": int(time.time()) + 60}

        fixture = patch.object(remote, "inspect_token", side_effect=identity)
        fixture.start()
        cls.addClassCleanup(fixture.stop)
        sock = socket.socket()
        sock.bind(("127.0.0.1", 0))
        sock.listen()
        cls.addClassCleanup(sock.close)
        host = "127.0.0.1:" + str(sock.getsockname()[1])
        cls.base = "http://" + host
        config = Settings("https://issuer.example", cls.resource,
                          "https://issuer.example/introspect", "fixture", "unused", ("fixture-owner",))
        app = remote.create_server(config).streamable_http_app(
            json_response=True, stateless_http=True, max_request_body_size=65536,
            transport_security=TransportSecuritySettings(allowed_hosts=[host], allowed_origins=[]))
        cls.server = uvicorn.Server(uvicorn.Config(app, log_level="error", access_log=False))
        cls.thread = threading.Thread(target=cls.server.run, kwargs={"sockets": [sock]}, daemon=True)
        cls.thread.start()
        cls.addClassCleanup(cls.stop_server)
        deadline = time.monotonic() + 10
        while not cls.server.started and cls.thread.is_alive() and time.monotonic() < deadline:
            time.sleep(0.02)
        if not cls.server.started:
            raise RuntimeError("SDK HTTP listener did not start")

    @classmethod
    def stop_server(cls):
        cls.server.should_exit = True
        cls.thread.join(5)
        if cls.thread.is_alive():
            raise RuntimeError("SDK HTTP listener failed to stop")

    def setUp(self):
        type(self).revoked = False

    def request(self, method="tools/list", params=None, token="fixture-token", headers=None, path="/mcp", raw=None):
        hdr = {"Accept": "application/json, text/event-stream", "Content-Type": "application/json",
               "MCP-Protocol-Version": "2025-06-18"}
        if token is not None:
            hdr["Authorization"] = "Bearer " + token
        hdr.update(headers or {})
        payload = {"jsonrpc": "2.0", "id": 1, "method": method}
        if params is not None:
            payload["params"] = params
        body = raw if raw is not None else json.dumps(payload).encode()
        req = Request(self.base + path, data=body, headers=hdr, method="POST")
        try:
            response = build_opener(ProxyHandler({})).open(req, timeout=5)
        except HTTPError as exc:
            response = exc
        with response:
            return response.status, response.headers, response.read()

    def test_unauthenticated_and_invalid_tokens_are_challenged(self):
        for token in (None, "invalid-token"):
            with self.subTest(token=token):
                status, headers, _ = self.request(token=token)
                self.assertEqual(status, 401)
                self.assertIn("resource_metadata", headers.get("WWW-Authenticate", ""))

    def test_legacy_initialize_and_list_have_no_session(self):
        status, headers, body = self.request("initialize", {
            "protocolVersion": "2025-06-18", "capabilities": {},
            "clientInfo": {"name": "bifrost-test", "version": "1"}})
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body)["result"]["protocolVersion"], "2025-06-18")
        self.assertIsNone(headers.get("Mcp-Session-Id"))
        status, _, body = self.request()
        self.assertEqual(status, 200)
        self.assertEqual([t["name"] for t in json.loads(body)["result"]["tools"]],
                         ["bifrost.system.platform.read"])

    def test_authenticated_call_uses_real_platform_dispatcher(self):
        status, _, body = self.request("tools/call", {"name": "bifrost.system.platform.read", "arguments": {}})
        self.assertEqual(status, 200)
        result = json.loads(body)["result"]
        self.assertFalse(result.get("isError", False))
        data = result.get("structuredContent")
        if data is None:
            data = json.loads(result["content"][0]["text"])
        self.assertEqual(data["action"], "bifrost.system.platform.read")
        self.assertEqual(data["result"]["system"], platform.system())
        self.assertTrue(data["effectsVerified"])

    def test_revoked_fixture_identity_is_denied(self):
        self.assertEqual(self.request()[0], 200)
        type(self).revoked = True
        self.assertEqual(self.request()[0], 401)

    def test_host_and_origin_denied(self):
        self.assertEqual(self.request(headers={"Host": "evil.example"})[0], 421)
        self.assertEqual(self.request(headers={"Origin": "https://evil.example"})[0], 403)

    def test_oversized_request_denied(self):
        self.assertEqual(self.request(raw=b" " * 65537)[0], 413)


if __name__ == "__main__":
    unittest.main()
