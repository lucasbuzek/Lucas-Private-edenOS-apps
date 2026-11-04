"""BIFROSTbridge registry boundaries: passive discovery and tenant isolation."""
import os
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "headless"))
from bridge_registry import RegistryError, connections_for_subject, visible_connections


def fixture():
    return {"schema": "bifrost.bridge.connections.v1", "connections": [
        {"id": "agent-alpha", "kind": "a2a", "protocol": "a2a-jsonrpc",
         "owner": "lucas", "tenant": "lucas-private",
         "allowedSubjects": ["lucas-subject"],
         "endpoint": "https://agents.example.test/.well-known/agent-card.json",
         "capabilities": ["tasks"]},
        {"id": "cloud-beta", "kind": "mcp", "protocol": "mcp-streamable-http",
         "owner": "lucas", "tenant": "business",
         "allowedSubjects": ["business-subject"],
         "endpoint": "https://tools.example.test/mcp",
         "capabilities": ["tools/list"]},
    ]}


class BridgeRegistryTest(unittest.TestCase):
    def test_explicit_subject_filter_does_not_cross_tenants(self):
        result = visible_connections("lucas-subject", fixture())
        self.assertEqual([x["id"] for x in result], ["agent-alpha"])
        self.assertEqual(result[0]["state"], "configured-unverified")
        self.assertNotIn("allowedSubjects", result[0])
        self.assertEqual([x["id"] for x in visible_connections("business-subject", fixture())], ["cloud-beta"])

    def test_unknown_subject_gets_no_connectors(self):
        self.assertEqual(visible_connections("stranger", fixture()), [])

    def test_empty_config_is_not_a_fabricated_connection(self):
        self.assertEqual(connections_for_subject("lucas-subject", path=""), [])

    def test_wildcard_and_unlisted_fields_are_denied(self):
        for field, value in (("allowedSubjects", ["*"]), ("secret", "do-not-expose")):
            with self.subTest(field=field):
                sample = fixture()
                sample["connections"][0][field] = value
                with self.assertRaises(RegistryError):
                    visible_connections("lucas-subject", sample)

    def test_non_https_and_embedded_credentials_are_denied(self):
        for endpoint in ("http://localhost:8799", "https://u:p@example.test/mcp",
                         "https://example.test/mcp#fragment"):
            with self.subTest(endpoint=endpoint):
                sample = fixture()
                sample["connections"][0]["endpoint"] = endpoint
                with self.assertRaises(RegistryError):
                    visible_connections("lucas-subject", sample)

    def test_duplicate_ids_are_denied(self):
        sample = fixture()
        sample["connections"][1]["id"] = "agent-alpha"
        with self.assertRaises(RegistryError):
            visible_connections("lucas-subject", sample)


if __name__ == "__main__":
    unittest.main()
