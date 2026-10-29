import json
import os
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "headless"))
import mcp_remote_auth as a


class FakeResponse:
    status = 200
    def __init__(self, payload):
        self.data = json.dumps(payload).encode()
    def read(self, n):
        return self.data[:n]
    def __enter__(self):
        return self
    def __exit__(self, *args):
        pass


class Opener:
    def __init__(self, data):
        self.data = data
        self.requests = []
    def open(self, request, timeout=None):
        self.requests.append(request)
        return FakeResponse(self.data)


class RemoteAuthTests(unittest.TestCase):
    def setUp(self):
        self.config = a.Settings(
            "https://auth.example.com", "https://bifrost.example.com/mcp",
            "https://auth.example.com/introspect", "bifrost-service", "secret")
        self.payload = {"active": True, "iss": self.config.issuer,
            "aud": self.config.resource, "client_id": "client-1",
            "sub": "user-1", "scope": "bifrost:read", "exp": 1700001000}

    def inspect(self, data=None):
        return a.inspect_token(self.config, "token1", opener=Opener(data if data is not None else self.payload), now=1700000000)

    def test_valid_scope_identity_and_audience(self):
        self.assertEqual(self.inspect()["subject"], "user-1")
        self.assertEqual(self.inspect()["resource"], self.config.resource)

    def test_denies_invalid_grants(self):
        for changed in ({"active": False}, {"iss": "https://other.example.com"},
                        {"aud": "https://other.example.com/mcp"}, {"exp": 1699999999},
                        {"exp": True}, {"scope": "other"}, {"client_id": ""}, {"sub": ""}):
            with self.subTest(case=changed):
                self.assertIsNone(self.inspect({**self.payload, **changed}))

    def test_denies_malformed_bearer(self):
        for bearer in ("", "bad token", "bad\nheader", "a" * 4097, None):
            self.assertIsNone(a.inspect_token(self.config, bearer,
                opener=Opener(self.payload), now=1700000000))

    def test_oauth_introspection_is_post(self):
        opener = Opener(self.payload)
        result = a.inspect_token(self.config, "token1", opener=opener, now=1700000000)
        self.assertIsNotNone(result)
        self.assertEqual(opener.requests[0].get_method(), "POST")
        self.assertEqual(opener.requests[0].full_url, self.config.introspection)

    def test_missing_configuration_fails_closed(self):
        with self.assertRaises(a.ConfigurationError):
            a.from_environment({})

    def test_https_required_and_secret_file_private(self):
        with tempfile.TemporaryDirectory() as temp:
            secret = Path(temp) / "oauth.secret"
            secret.write_text("secret\n")
            env = {"BIFROST_MCP_ISSUER_URL": "https://auth.example.com",
                   "BIFROST_MCP_RESOURCE_URL": "https://bifrost.example.com/mcp",
                   "BIFROST_MCP_INTROSPECTION_URL": "https://auth.example.com/introspect",
                   "BIFROST_MCP_OAUTH_CLIENT_ID": "bifrost-service",
                   "BIFROST_MCP_SECRET_FILE": str(secret)}
            if os.name == "posix":
                secret.chmod(0o644)
                with self.assertRaises(a.ConfigurationError):
                    a.from_environment(env)
                secret.chmod(0o600)
            self.assertEqual(a.from_environment(env).client_secret, "secret")
            env["BIFROST_MCP_RESOURCE_URL"] = "http://bifrost.example.com/mcp"
            with self.assertRaises(a.ConfigurationError):
                a.from_environment(env)


if __name__ == "__main__":
    unittest.main()
