"""Regression cases for DeLorean TimeMachine product integrity and stdio write isolation."""
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'core'))
from standalone_backup import DeLorean
from mcp_server import Server, TOOLS

class SessionSafety(unittest.TestCase):
    def setUp(self):
        td = tempfile.TemporaryDirectory(); self.addCleanup(td.cleanup)
        r = Path(td.name)
        self.home = r/'state'; self.data = r/'input'; self.data.mkdir()
        self.destination = r/'restores'; self.destination.mkdir()
        (self.data/'example.txt').write_text('original')
        self.core = DeLorean(self.home,[str(self.data)],[str(self.destination)],owner='OwnerA')
    def query(self,server,name,args=None):
        return server.handle({'jsonrpc':'2.0','id':7,'method':'tools/call','params':{'name':name,'arguments':args or {}}})
    def test_readonly_default_excludes_every_mutating_tool(self):
        s = Server(self.core)
        available={x['name'] for x in s.handle({'jsonrpc':'2.0','id':1,'method':'tools/list'})['result']['tools']}
        forbidden={x['name'] for x in TOOLS if not x['annotations']['readOnlyHint']}
        self.assertTrue(forbidden)
        self.assertFalse(available & forbidden)
        self.assertIn('delorean_dashboard',available)
        self.assertIn('delorean_backup_plan',available)
    def test_even_exact_magic_confirmation_cannot_override_readonly_mode(self):
        res=self.query(Server(self.core),'delorean_backup_create', {'source':str(self.data),'scope':'project','project':'Test','confirmation':'BACKUP NOW'})
        self.assertTrue(res['result']['isError'])
        self.assertFalse(self.home.exists())
    def test_explicit_owner_started_write_mode_and_isolated_restore_still_work(self):
        s = Server(self.core,allow_writes=True)
        res=self.query(s,'delorean_backup_create',{'source':str(self.data),'scope':'project','project':'Test','confirmation':'BACKUP NOW'})
        self.assertFalse(res['result']['isError'])
        snap=res['result']['structuredContent']['result']['snapshot_id']
        target=self.destination/'staged'
        ans=self.query(s,'delorean_stage_restore',{'snapshot':snap,'target':str(target),'confirmation':'RESTORE TO NEW DIRECTORY'})
        self.assertFalse(ans['result']['isError'],ans)
        self.assertEqual((target/'example.txt').read_text(),'original')
    def test_stdio_default_readonly_and_flag_write(self):
        command=[sys.executable,str(ROOT/'core/mcp_server.py'),'--home',str(self.home),'--allow-source',str(self.data),'--allow-restore',str(self.destination)]
        req=json.dumps({'jsonrpc':'2.0','id':2,'method':'tools/list'})+'\n'
        for flag,should_appear in [(False,False),(True,True)]:
            cmd=command+(['--enable-writes'] if flag else [])
            out=subprocess.run(cmd,input=req,text=True,capture_output=True,timeout=8)
            self.assertEqual(out.returncode,0,out.stderr)
            result=json.loads(out.stdout)['result']['tools']
            self.assertEqual('delorean_backup_create' in {t['name'] for t in result},should_appear)
    def test_mcp_apps_resource_available_in_readonly(self):
        s=Server(self.core)
        reply=s.handle({'jsonrpc':'2.0','id':1,'method':'resources/list'})
        self.assertEqual(reply['result']['resources'][0]['uri'],'ui://edenos-delorean/timeline')
    def test_public_ui_uses_current_name(self):
        text=(ROOT/'platforms/web/index.html').read_text()
        self.assertIn('DeLorean TimeMachine',text)
        self.assertNotIn('<h1>TimeMachine — DeLorean</h1>',text)

if __name__=='__main__':unittest.main()
