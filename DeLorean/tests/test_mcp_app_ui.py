import json, tempfile,unittest,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'core'))
from standalone_backup import DeLorean
from mcp_server import Server, TOOLS, UI_RESOURCE
class MCPAppUITests(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
  r=Path(self.temp.name);self.src=r/'src';self.src.mkdir();(self.src/'data.txt').write_text('hello')
  self.restore=r/'restore';self.restore.mkdir()
  self.core=DeLorean(r/'state',[str(self.src)],[str(self.restore)],owner='OwnerA')
  self.srv=Server(self.core)
 def call(self,i,method,params={}):return self.srv.handle({'jsonrpc':'2.0','id':i,'method':method,'params':params})
 def test_resource_discovery(self):
  x=self.call(1,'resources/list');self.assertEqual(x['result']['resources'][0]['uri'],UI_RESOURCE)
 def test_resource_html_and_identity(self):
  d=self.call(2,'resources/read',{'uri':UI_RESOURCE})['result']['contents'][0]
  self.assertIn('DeLorean TimeMachine',d['text']);self.assertIn('data:image/png;base64,',d['text'])
  self.assertEqual(d['mimeType'],'text/html;profile=mcp-app')
 def test_wrong_resource_denied(self):
  x=self.call(3,'resources/read',{'uri':'ui://other'});self.assertEqual(x['error']['code'],-32602)
 def test_dashboard_metadata_discovered(self):
  t={x['name']:x for x in TOOLS};self.assertIn('delorean_dashboard',t)
  self.assertEqual(t['delorean_dashboard']['_meta']['ui']['resourceUri'],UI_RESOURCE)
 def test_dashboard_owner_and_paths_redacted(self):
  self.core.backup_create(str(self.src),'project','Test','BACKUP NOW')
  out=self.call(4,'tools/call',{'name':'delorean_dashboard','arguments':{}})
  self.assertFalse(out['result']['isError'])
  catalog=out['result']['structuredContent']['result'];self.assertEqual(len(catalog['snapshots']),1)
  self.assertNotIn('source_root',catalog['snapshots'][0]);self.assertNotIn(str(self.src),json.dumps(catalog))
 def test_dashboard_empty_no_fake_data(self):
  catalog=self.call(5,'tools/call',{'name':'delorean_dashboard','arguments':{}})['result']['structuredContent']['result']
  self.assertEqual(catalog['snapshots'],[]);self.assertEqual(catalog['events'],[])
if __name__=='__main__':unittest.main()
