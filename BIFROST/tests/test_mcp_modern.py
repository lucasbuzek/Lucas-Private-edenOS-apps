"""MCP 2026-07-28 dual-era regression for the existing BIFROST Headless MCP."""
import importlib.util
import io
import json
import pathlib
import sys
import types
import unittest
from unittest import mock

SOURCE = pathlib.Path(__file__).resolve().parents[1] / "headless/mcp_stdio.py"
spec = importlib.util.spec_from_file_location("bifrost_mcp_modern", SOURCE)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


def request(method, params=None, request_id=1):
    return {"jsonrpc": "2.0", "id": request_id, "method": method,
            "params": params if params is not None else {}}


def modern(extra=None):
    d = {"io.modelcontextprotocol/protocolVersion": "2026-07-28",
         "io.modelcontextprotocol/clientCapabilities": {},
         "io.modelcontextprotocol/clientInfo": {"name": "isolated-test",
                                                 "version": "1"}}
    d.update(extra or {})
    return {"_meta": d}


class ModernMCPTests(unittest.TestCase):
    def test_discovery_uses_modern_stateless_response(self):
        data = m.rpc(request("server/discover", modern()))["result"]
        self.assertEqual(data["resultType"], "complete")
        self.assertIn("2026-07-28", data["supportedVersions"])
        self.assertEqual(data["cacheScope"], "private")
        self.assertEqual(data["ttlMs"], 0)
        self.assertEqual(data["_meta"]["io.modelcontextprotocol/serverInfo"]["name"],
                         "BIFROSTcore MCP")

    def test_modern_tool_list(self):
        data = m.rpc(request("tools/list", modern()))["result"]
        self.assertEqual(data["resultType"], "complete")
        self.assertEqual(len(data["tools"]), 8)

    def test_modern_read_only_adapter(self):
        with mock.patch.dict(sys.modules, {"storage_adapter": types.SimpleNamespace(
                catalog=lambda: {"authority": "BIFROSTcore"})}):
            result = m.rpc(request("tools/call",
                                   {**modern(), "name": "bifrost_storage_providers"}))
        self.assertEqual(result["result"]["resultType"], "complete")
        self.assertEqual(result["result"]["structuredContent"]["authority"], "BIFROSTcore")

    def test_client_capability_required(self):
        data = modern()
        del data["_meta"]["io.modelcontextprotocol/clientCapabilities"]
        self.assertEqual(m.rpc(request("tools/list", data))["error"]["code"], -32602)

    def test_unrecognized_version_returns_protocol_negotiation_info(self):
        data = modern({"io.modelcontextprotocol/protocolVersion": "9999-99-99"})
        error = m.rpc(request("tools/list", data))["error"]
        self.assertEqual(error["code"], -32022)
        self.assertEqual(error["data"]["requested"], "9999-99-99")
        self.assertIn("2026-07-28", error["data"]["supported"])

    def test_modern_invalid_identity_rejected(self):
        data = modern({"io.modelcontextprotocol/clientInfo": "bad"})
        self.assertEqual(m.rpc(request("tools/list", data))["error"]["code"], -32602)

    def test_legacy_initialize_unchanged(self):
        r = m.rpc(request("initialize", {"protocolVersion": "2025-11-25"}))
        self.assertEqual(r["result"]["protocolVersion"], "2025-11-25")
        self.assertNotIn("resultType", r["result"])

    def test_legacy_tool_list_unchanged(self):
        self.assertNotIn("resultType", m.rpc(request("tools/list"))["result"])

    def test_modern_stdio_discover_and_list(self):
        source = io.StringIO(json.dumps(request("server/discover", modern())) + "\n" +
                             json.dumps(request("tools/list", modern(), 2)) + "\n")
        destination = io.StringIO()
        m.serve_stdin(source, destination)
        results = [json.loads(x) for x in destination.getvalue().splitlines()]
        self.assertEqual(len(results), 2)
        self.assertTrue(all(x["result"]["resultType"] == "complete" for x in results))

    def test_no_unauthorized_tool_notifications(self):
        self.assertIsNone(m.rpc({"jsonrpc": "2.0", "method": "tools/call",
                                 "params": {**modern(), "name": "bifrost_status"}}))


if __name__ == "__main__":
    unittest.main()
