import json
from pathlib import Path
import subprocess
import sys
import unittest
ROOT=Path(__file__).resolve().parents[1]
class BridgeTests(unittest.TestCase):
 def test_client_config_is_read_only_and_supports_codex_cli(self):
  import shlex
  import tempfile
  generator=str(ROOT/'tools/mcp_client_config.py')
  with tempfile.TemporaryDirectory() as temp:
   home=Path(temp)
   env={"HOME": str(home), "PATH": "/usr/bin:/bin"}
   import os
   env.update({key:val for key,val in os.environ.items() if key in ("SYSTEMROOT","WINDIR")})
   original=subprocess.run([sys.executable,'-B',generator],capture_output=True,text=True,timeout=8,env=env)
   self.assertEqual(original.returncode,0,original.stderr)
   payload=json.loads(original.stdout)['mcpServers']['BIFROSTbridge-local']
   self.assertEqual(payload['command'],sys.executable)
   self.assertEqual(payload['args'],['-B',str(ROOT/'headless/mcp_bridge.py')])
   cli=subprocess.run([sys.executable,'-B',generator,'--codex'],capture_output=True,text=True,timeout=8,env=env)
   self.assertEqual(cli.returncode,0,cli.stderr)
   self.assertEqual(shlex.split(cli.stdout.strip()),
                    ['codex','mcp','add','BIFROSTbridge-local','--',
                     sys.executable,'-B',str(ROOT/'headless/mcp_bridge.py')])
   self.assertEqual(list(home.iterdir()),[])
   denied=subprocess.run([sys.executable,'-B',generator,'--execute'],capture_output=True,text=True,timeout=8,env=env)
   self.assertNotEqual(denied.returncode,0)
   self.assertEqual(denied.stdout,'')

 def test_2026_stateless_stdio_discovery_and_denials(self):
  modern_meta={'io.modelcontextprotocol/protocolVersion':'2026-07-28',
               'io.modelcontextprotocol/clientCapabilities':{},
               'io.modelcontextprotocol/clientInfo':{'name':'isolated-test','version':'1'}}
  def req(i,method,params):return {'jsonrpc':'2.0','id':i,'method':method,'params':params}
  m=[
   req(1,'server/discover',{'_meta':modern_meta}),
   req(2,'tools/list',{'_meta':modern_meta}),
   req(3,'tools/call',{'name':'bifrost.system.platform.read','arguments':{},'_meta':modern_meta}),
   req(4,'tools/call',{'name':'shell','arguments':{},'_meta':modern_meta}),
   req(5,'tools/call',{'name':'bifrost.system.platform.read','arguments':{'command':'uname'},'_meta':modern_meta}),
   req(6,'tools/list',{'_meta':{**modern_meta,'io.modelcontextprotocol/protocolVersion':'1900-01-01'}}),
   req(7,'tools/list',{}),
   req(8,'server/discover',{'_meta':{'io.modelcontextprotocol/protocolVersion':'2026-07-28'}}),
   req(9,'tools/call',{'name':'bifrost.system.platform.read','arguments':{},'_meta':{**modern_meta,
      'io.modelcontextprotocol/clientCapabilities':None}})
  ]
  p=subprocess.run([sys.executable,'-B',str(ROOT/'headless/mcp_bridge.py')],
    input='\n'.join(map(json.dumps,m))+'\n',capture_output=True,text=True,timeout=15)
  self.assertEqual(p.returncode,0,p.stderr)
  rows=[json.loads(row) for row in p.stdout.splitlines()]
  self.assertEqual(len(rows),len(m),p.stdout)
  self.assertEqual(rows[0]['result']['supportedVersions'],['2026-07-28'])
  self.assertEqual(rows[0]['result']['cacheScope'],'private')
  self.assertEqual(rows[1]['result']['resultType'],'complete')
  self.assertIn('bifrost.system.platform.read',[t['name'] for t in rows[1]['result']['tools']])
  self.assertEqual(rows[2]['result']['resultType'],'complete')
  self.assertTrue(json.loads(rows[2]['result']['content'][0]['text'])['effectsVerified'])
  self.assertIn('error',rows[3])
  self.assertIn('error',rows[4])
  self.assertEqual(rows[5]['error']['code'],-32022)
  self.assertEqual(rows[5]['error']['data']['requested'],'1900-01-01')
  self.assertIn('error',rows[6])
  self.assertEqual(rows[7]['error']['code'],-32602)
  self.assertEqual(rows[8]['error']['code'],-32602)

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
