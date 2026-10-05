"""Protocol lifecycle tests using the official SDK client against a child stdio server."""
import asyncio
import base64
import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path

SDK_AVAILABLE = importlib.util.find_spec("mcp") is not None


@unittest.skipUnless(SDK_AVAILABLE, "Official MCP SDK is not installed in this environment")
class NativeProtocolTests(unittest.IsolatedAsyncioTestCase):
    async def test_initialize_discover_effects_and_structured_errors(self):
        from mcp import ClientSession, StdioServerParameters
        from mcp.client.stdio import stdio_client
        with tempfile.TemporaryDirectory() as tmp:
            params = StdioServerParameters(command=sys.executable,
                args=[str(Path(__file__).with_name("native_stdio_fixture.py")), tmp])
            async with stdio_client(params) as (read, write):
                async with ClientSession(read, write) as client:
                    initialized = await client.initialize()
                    self.assertIn(initialized.protocolVersion, {"2024-11-05", "2025-03-26", "2025-06-18", "2025-11-25"})
                    tools = await client.list_tools()
                    names = {tool.name for tool in tools.tools}
                    self.assertIn("filesystem_read", names)
                    self.assertIn("process_start", names)
                    self.assertIn("transfer_finish", names)
                    self.assertNotIn("enroll", names)
                    self.assertNotIn("approve_command", names)
                    status = await client.call_tool("host_status", {})
                    self.assertFalse(status.isError)
                    self.assertIsNotNone(status.structuredContent)
                    grant = status.structuredContent["grants"][0]["id"]
                    created = await client.call_tool("filesystem_write", {"grant_id":grant, "path":"mcp-effect", "data":"aGVsbG8="})
                    self.assertFalse(created.isError)
                    self.assertEqual((Path(tmp)/"share/mcp-effect").read_bytes(), b"hello")
                    readback = await client.call_tool("filesystem_read", {"grant_id":grant, "path":"mcp-effect"})
                    self.assertEqual(base64.b64decode(readback.structuredContent["data"]), b"hello")
                    denied = await client.call_tool("filesystem_read", {"grant_id":grant, "path":"../escape"})
                    self.assertTrue(denied.isError)
                    self.assertIn("invalid_path", denied.content[0].text)
                    invalid = await client.call_tool("filesystem_read", {"grant_id":grant, "path":"mcp-effect", "length":-2})
                    self.assertTrue(invalid.isError)
                    unknown = await client.call_tool("nonexistent_tool", {})
                    self.assertTrue(unknown.isError)
                    command = status.structuredContent["commands"][0]["id"]
                    started = await client.call_tool("process_start", {"command_id":command})
                    job = started.structuredContent["id"]
                    for _ in range(100):
                        result = await client.call_tool("process_output", {"job_id":job})
                        if result.structuredContent["state"] == "exited":
                            break
                        await asyncio.sleep(.02)
                    self.assertEqual(result.structuredContent["exit_code"], 3)
                    self.assertIn(b"protocol-out", base64.b64decode(result.structuredContent["stdout"]))
                    self.assertIn(b"protocol-err", base64.b64decode(result.structuredContent["stderr"]))

    async def test_reconnect_requires_initialize_but_preserves_host_identity(self):
        from mcp import ClientSession, StdioServerParameters
        from mcp.client.stdio import stdio_client
        identities = []
        with tempfile.TemporaryDirectory() as tmp:
            for _ in range(2):
                params = StdioServerParameters(command=sys.executable,
                    args=[str(Path(__file__).with_name("native_stdio_fixture.py")), tmp])
                async with stdio_client(params) as (read, write):
                    async with ClientSession(read, write) as client:
                        await client.initialize()
                        result = await client.call_tool("host_status", {})
                        identities.append(result.structuredContent["host_id"])
            self.assertEqual(identities[0], identities[1])
