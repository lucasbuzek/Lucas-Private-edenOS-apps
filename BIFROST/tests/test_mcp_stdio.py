"""BIFROST native Headless MCP stdio integration/denial regressions."""
import importlib.util
import io
import json
import pathlib
import sys
import types
import unittest
from unittest import mock

SOURCE = pathlib.Path(__file__).resolve().parents[1] / "headless/mcp_stdio.py"
spec = importlib.util.spec_from_file_location("bifrost_existing_mcp", SOURCE)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class MCPTests(unittest.TestCase):
    def test_initialize(self):
        r = m.rpc({"jsonrpc":"2.0","id":1,"method":"initialize",
                   "params":{"protocolVersion":"2025-11-25"}})
        self.assertEqual(r["result"]["serverInfo"]["name"], "BIFROSTcore MCP")

    def test_no_rdc_dependency(self):
        self.assertNotIn("remote_desktop_commander", SOURCE.read_text().lower())
        self.assertNotIn("subprocess", SOURCE.read_text())

    def test_tools_readonly(self):
        x = m.descriptors()
        self.assertEqual(len(x), 8)
        self.assertTrue(all(t["annotations"]["readOnlyHint"] for t in x))
        self.assertTrue(all(not t["annotations"]["openWorldHint"] for t in x))

    def test_unknown_tool_refused(self):
        r = m.rpc({"jsonrpc":"2.0","id":2,"method":"tools/call",
                   "params":{"name":"shell_exec"}})
        self.assertEqual(r["error"]["code"],-32602)

    def test_status_uses_existing_core(self):
        with mock.patch.dict(sys.modules,{
          "core_runtime":types.SimpleNamespace(snapshot=lambda:{"headless":{"state":"unverified"}})
        }):
            s=m.run("bifrost_status")
            self.assertEqual(s["connectionAcceptance"], "NOT_ATTESTED_BY_LOCAL_PROCESS")

    def test_provider_uses_existing_adapter(self):
        with mock.patch.dict(sys.modules,{
          "storage_adapter":types.SimpleNamespace(catalog=lambda:{"authority":"BIFROSTcore"})
        }):
            self.assertEqual(m.run("bifrost_storage_providers")["authority"],"BIFROSTcore")

    def test_accounts_existing_adapter(self):
        with mock.patch.dict(sys.modules,{
          "storage_adapter":types.SimpleNamespace(accounts=lambda:{"accounts":[{"name":"remote","provider":"drive"}]})
        }):
            self.assertEqual(m.run("bifrost_storage_accounts")["accounts"][0]["name"],"remote")

    def test_preview_offline_only(self):
        calls=[]
        def preview(name,*,folder,read_remote):
            calls.append((name,folder,read_remote))
            return {"count":0}
        with mock.patch.dict(sys.modules,{
          "storage_adapter":types.SimpleNamespace(preview=preview)
        }):
            self.assertEqual(m.run("bifrost_storage_preview",{"profile":"a","folder":"docs"})["count"],0)
        self.assertEqual(calls,[("a","docs",False)])

    def test_reject_extra_arguments(self):
        with self.assertRaises(ValueError):
            m.run("bifrost_storage_accounts",{"command":"rm -rf"})

    def test_reject_non_object(self):
        with self.assertRaises(ValueError):
            m.run("bifrost_storage_accounts","x")

    def test_reject_preview_additional_parameters(self):
        with self.assertRaises(ValueError):
            m.run("bifrost_storage_preview",{"profile":"a","command":"rm"})

    def test_reject_preview_missing_profile(self):
        with self.assertRaises(ValueError):
            m.run("bifrost_storage_preview",{})

    def test_no_tool_notifications(self):
        self.assertIsNone(m.rpc({"jsonrpc":"2.0","method":"tools/call",
                                 "params":{"name":"bifrost_status"}}))

    def test_bad_json(self):
        i=io.StringIO("{invalid}\n")
        o=io.StringIO()
        m.serve_stdin(i,o)
        self.assertEqual(json.loads(o.getvalue())["error"]["code"],-32700)

    def test_stdio_sequence(self):
        i=io.StringIO(json.dumps({"jsonrpc":"2.0","id":1,"method":"tools/list"})+"\n"+
                      json.dumps({"jsonrpc":"2.0","method":"notifications/initialized"})+"\n")
        o=io.StringIO()
        m.serve_stdin(i,o)
        self.assertEqual(len(o.getvalue().splitlines()),1)

    def test_specialist_handoff_no_execution(self):
        x=m.run("bifrost_specialists")
        self.assertFalse(x["delegationPerformed"])
        self.assertFalse(x["handoffs"][0]["executionReady"])

    def test_installer_never_runs(self):
        with mock.patch.dict(sys.modules,{
          "setup_manager":types.SimpleNamespace(catalog=lambda:{"packages":[]})
        }):
            self.assertFalse(m.run("bifrost_installer")["installerExecuted"])

    def test_error_redaction(self):
        with mock.patch.dict(sys.modules,{
          "core_runtime":types.SimpleNamespace(snapshot=lambda:(_ for _ in ()).throw(OSError("SECRET TOKENS")))
        }):
            r=m.rpc({"jsonrpc":"2.0","id":3,"method":"tools/call",
                     "params":{"name":"bifrost_status"}})
            self.assertNotIn("SECRET",json.dumps(r))


if __name__ == "__main__":
    unittest.main()
