"""Regression for original WebMCP adapter. Requires no WebMCP-capable browser."""
import pathlib
import sys
import unittest

sys.path.insert(0,str(pathlib.Path(__file__).resolve().parents[1]/'headless'))
import webmcp_bridge

class WebMCPBridgeTests(unittest.TestCase):
    def test_tools_are_read_only_and_owned_by_original_bridge(self):
        tools=webmcp_bridge.tools()
        self.assertLessEqual(len(tools),64)
        self.assertTrue(all(x['annotations']['readOnlyHint'] for x in tools))
        self.assertTrue(all(x['name'] in {i['name'] for i in __import__('mcp_bridge').tools()} for x in tools))
    def test_unregistered_or_arguments_denied(self):
        for name,args in [('shell.exec',{}),('bifrost.storage.profiles',{'remote':True}),([], {})]:
            with self.assertRaises(ValueError):
                webmcp_bridge.call(name,args)
    def test_original_authority_handles_call(self):
        tools=webmcp_bridge.tools()
        if not tools:return
        result=webmcp_bridge.call(tools[0]['name'],{})
        self.assertIn('content',result)
        self.assertIn('isError',result)

if __name__=='__main__':unittest.main()
