"""End-to-end local HTTP backing checks for the optional NOSTOS MCP adapter."""
import importlib.util
import os
import tempfile
import threading
import unittest
from pathlib import Path
from unittest.mock import patch
from urllib.error import HTTPError

ROOT=Path(__file__).resolve().parents[1]

def load(path,name):
    spec=importlib.util.spec_from_file_location(name,path)
    module=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

class NostosMcpTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        try:
            from mcp.server import MCPServer
        except ImportError as exc:
            raise unittest.SkipTest("Install the optional official MCP Python SDK v2") from exc
        cls.app=load(ROOT/'nostos.py','nostos_mcp_test_service')
        cls.temp=tempfile.TemporaryDirectory()
        cls.app.DATA_DIR=Path(cls.temp.name)
        cls.app.DB_PATH=cls.app.DATA_DIR/'nostos.sqlite3'
        cls.app.OWNER_TOKEN='mcp-test-owner-'+'a'*50
        cls.app.init_db()
        cls.server=cls.app.ThreadingHTTPServer(('127.0.0.1',0),cls.app.Handler)
        cls.thread=threading.Thread(target=cls.server.serve_forever,daemon=True)
        cls.thread.start()
        cls.base=f'http://127.0.0.1:{cls.server.server_address[1]}'
        cls.adapter=load(ROOT/'mcp_readonly.py','nostos_mcp_readonly_test')
        with cls.app.db() as c:
            t=cls.app.now()
            c.execute("""INSERT INTO items(kind,title,created_at,updated_at)
                VALUES('supplies','Pantry rice',?,?)""",(t,t))

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join(timeout=2)
        cls.temp.cleanup()

    def env(self,token=None,base=None):
        return patch.dict(os.environ,{
            'NOSTOS_OWNER_TOKEN': token if token is not None else self.app.OWNER_TOKEN,
            'NOSTOS_API_URL': base if base is not None else self.base
        })

    def test_mcp_summary_and_search_use_real_local_api(self):
        with self.env():
            s=self.adapter.household_summary()
            self.assertGreaterEqual(s['counts']['supplies'],1)
            found=self.adapter.search_household('supplies','rice',10)
            self.assertTrue(any(x['title']=='Pantry rice' for x in found['items']))

    def test_mcp_refuses_remote_origins(self):
        for target in ['https://example.org','http://192.168.0.4:8787','http://evil.local','http://127.0.0.1:8787/other']:
            with self.env(base=target):
                with self.assertRaises(ValueError):
                    self.adapter._settings()

    def test_mcp_stdio_protocol_discovery_and_real_tool_calls(self):
        """Run an actual SDK v2 MCP client over stdio to a child MCP server."""
        import sys
        import anyio
        from mcp import Client, StdioServerParameters
        from mcp.client.stdio import stdio_client

        async def exercise():
            params=StdioServerParameters(
                command=sys.executable,
                args=[str(ROOT/'mcp_readonly.py')],
                env={'NOSTOS_OWNER_TOKEN':self.app.OWNER_TOKEN,
                     'NOSTOS_API_URL':self.base},
            )
            async with Client(stdio_client(params)) as client:
                listed=await client.list_tools()
                names={t.name for t in listed.tools}
                self.assertEqual(names,{'household_summary','search_household'})
                summary=await client.call_tool('household_summary',{})
                self.assertFalse(summary.is_error)
                self.assertIn('supplies',str(summary.structured_content or summary.content))
                found=await client.call_tool('search_household',
                    {'kind':'supplies','query':'Pantry','limit':10})
                self.assertFalse(found.is_error)
                self.assertIn('Pantry rice',str(found.structured_content or found.content))
                forbidden=await client.call_tool('search_household',
                    {'kind':'not-a-category','query':''})
                self.assertTrue(forbidden.is_error)

        anyio.run(exercise)

    def test_mcp_no_bearer_or_invalid_kind_or_bad_limit(self):
        with self.env(token='wrong'+'x'*40):
            with self.assertRaises(HTTPError) as denied:
                self.adapter.household_summary()
            self.assertEqual(denied.exception.code,401)
        with self.env():
            with self.assertRaises(ValueError): self.adapter.search_household('business','',10)
            with self.assertRaises(ValueError): self.adapter.search_household('supplies','',500)
            with self.assertRaises(ValueError): self.adapter.search_household('supplies','a'*201,5)
