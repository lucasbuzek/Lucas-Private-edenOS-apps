"""Guard the BIFROST OCI packaging contract without a cloud credential or Docker daemon.

This does not prove deployment, OAuth acceptance or a ChatGPT MCP handshake.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class OCIContractTests(unittest.TestCase):
    def setUp(self):
        self.docker = (ROOT / "deploy/oci/Dockerfile").read_text()
        self.compose = (ROOT / "deploy/oci/compose.yaml").read_text()
        self.remote = (ROOT / "headless/mcp_remote.py").read_text()
        self.auth = (ROOT / "headless/mcp_remote_auth.py").read_text()

    def test_original_sdk_adapter_not_npm_placeholder(self):
        self.assertIn("mcp==2.3.0", self.docker)
        self.assertIn("headless/mcp_remote.py", self.docker)
        self.assertIn("shortcalls.v1.json", self.docker)
        self.assertNotIn("@modelcontextprotocol/server-sse", self.docker)

    def test_container_not_public_by_default(self):
        self.assertIn("network_mode: host", self.compose)
        self.assertIn('BIFROST_MCP_BIND_HOST: "127.0.0.1"', self.compose)
        self.assertIn('restart: "no"', self.compose)
        self.assertIn("cap_drop:", self.compose)
        self.assertIn("no-new-privileges:true", self.compose)
        self.assertNotIn("ports:", self.compose)

    def test_real_oauth_is_mandatory(self):
        for key in (
            "BIFROST_MCP_ISSUER_URL",
            "BIFROST_MCP_RESOURCE_URL",
            "BIFROST_MCP_INTROSPECTION_URL",
            "BIFROST_MCP_OAUTH_CLIENT_ID",
            "BIFROST_MCP_ALLOWED_SUBJECTS",
            "BIFROST_MCP_SECRET_FILE_HOST",
        ):
            self.assertIn("${" + key + ":?", self.compose)
        self.assertIn("BIFROST_MCP_SECRET_FILE: \"/run/secrets/issuer-client\"", self.compose)
        self.assertIn("from_environment()", self.remote)
        self.assertIn("stateless_http=True", self.remote)
        self.assertIn("allowed_subjects", self.auth)
        self.assertIn("subject not in config.allowed_subjects", self.auth)
        self.assertIn("BIFROST_MCP_TRUSTED_REVERSE_PROXY", self.remote)


if __name__ == "__main__":
    unittest.main()
