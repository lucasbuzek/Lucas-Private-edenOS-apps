import json
from pathlib import Path
import subprocess
import sys
import unittest
ROOT=Path(__file__).resolve().parents[1]
class BridgeTests(unittest.TestCase):
 def test_real_stdio_lifecycle_and_platform_call(self):
  messages=[{'jsonrpc':'2.0','id':1,'method':'tools/list'},
   {'jsonrpc':'2.0','id':2,'method':'initialize','params':{'protocolVersion':'2025-06-18','capabilities':{},'clientInfo':{'name':'test','version':'1'}}},
   {'jsonrpc':'2.0','method':'notifications/initialized'},
   {'jsonrpc':'2.0','id':3,'method':'tools/list'},
   {'jsonrpc':'2.0','id':4,'method':'tools/call','params':{'name':'bifrost.system.platform.read','arguments':{}}},
   {'jsonrpc':'2.0','id':5,'method':'tools/call','params':{'name':'shell','arguments':{}}},
   {'jsonrpc':'2.0','id':6,'method':'tools/call','params':{'name':'bifrost.system.platform.read','arguments':{'command':'bad'}}}]
  p=subprocess.run([sys.executable,'-B',str(ROOT/'headless/mcp_bridge.py')],input='\n'.join(map(json.dumps,messages))+'\n',capture_output=True,text=True,timeout=15)
  self.assertEqual(p.returncode,0,p.stderr)
  rows=[json.loads(x) for x in p.stdout.splitlines()];self.assertEqual(len(rows),6)
  self.assertIn('error',rows[0]);self.assertEqual(rows[1]['result']['protocolVersion'],'2025-06-18')
  self.assertIn('bifrost.system.platform.read',[t['name'] for t in rows[2]['result']['tools']])
  self.assertTrue(json.loads(rows[3]['result']['content'][0]['text'])['effectsVerified'])
  self.assertIn('error',rows[4]);self.assertIn('error',rows[5])
