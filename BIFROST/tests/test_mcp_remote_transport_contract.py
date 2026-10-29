"""Source contract for optional BIFROST remote MCP's stateless cloud transport.

These tests intentionally require only Python stdlib so they run without OAuth
secrets or installing an MCP server. They do NOT replace HTTP/client E2E tests.
"""
import ast
import unittest
from pathlib import Path


SOURCE = Path(__file__).resolve().parents[1] / "headless" / "mcp_remote.py"


def transport_keywords(source):
    tree = ast.parse(source)
    functions = [node for node in tree.body if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name == "run"]
    if len(functions) != 1:
        raise AssertionError("Expected one remote MCP run() entrypoint")
    calls = [
        node for node in ast.walk(functions[0])
        if isinstance(node, ast.Call)
        and isinstance(node.func, ast.Attribute)
        and node.func.attr == "run"
        and any(k.arg == "transport" and isinstance(k.value, ast.Constant) and
                k.value.value == "streamable-http" for k in node.keywords)
    ]
    if len(calls) != 1:
        raise AssertionError("Expected exactly one Streamable HTTP run() invocation")
    return {key.arg: key.value for key in calls[0].keywords}


class RemoteTransportContractTests(unittest.TestCase):
    def test_stateless_http_explicit_for_independent_cloud_mcp(self):
        kwargs = transport_keywords(SOURCE.read_text(encoding="utf-8"))
        stateless = kwargs.get("stateless_http")
        self.assertIsInstance(stateless, ast.Constant,
                              "MCP SDK's default is stateful; explicitly request stateless HTTP")
        self.assertIs(stateless.value, True)

    def test_transport_preserves_bounded_body_and_security(self):
        kwargs = transport_keywords(SOURCE.read_text(encoding="utf-8"))
        self.assertIsInstance(kwargs.get("json_response"), ast.Constant)
        self.assertIs(kwargs["json_response"].value, True)
        self.assertIsInstance(kwargs.get("max_request_body_size"), ast.Constant)
        self.assertEqual(kwargs["max_request_body_size"].value, 65536)
        self.assertIsInstance(kwargs.get("transport_security"), ast.Name)

    def test_missing_stateless_flag_regression_is_detected(self):
        old = 'def run():\n    server.run(transport="streamable-http", json_response=True)\n'
        self.assertNotIn("stateless_http", transport_keywords(old))


if __name__ == "__main__":
    unittest.main()
