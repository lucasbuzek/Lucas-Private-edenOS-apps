"""Standalone AppleRAVEN local MCP and permission regression."""
import json,subprocess,sys,tempfile,types,unittest
from pathlib import Path
from appleraven.core import AppleRaven,AccessDenied,default_config,init_config
from appleraven.server import Session
class AppleRavenTests(unittest.TestCase):
    def setUp(self):
        self.bridge=AppleRaven(default_config(),'lucascouncil',which=lambda n:'/usr/bin/'+n,mac=True)
        self.s=Session(self.bridge);self.init()
    def req(self,method,params=None):
        return self.s.handle({'jsonrpc':'2.0','id':1,'method':method,'params':params or {}})
    def init(self):
        self.assertEqual(self.req('initialize',{'protocolVersion':'2025-06-18','capabilities':{},'clientInfo':{'name':'test','version':'1'}})['result']['protocolVersion'],'2025-06-18')
        self.s.handle({'jsonrpc':'2.0','method':'notifications/initialized'})
    def call(self,name,args=None):
        return self.req('tools/call',{'name':name,'arguments':args or {}})['result']
    def test_catalog(self):
        self.assertEqual(len(self.req('tools/list')['result']['tools']),6)
    def test_unknown_tool_refused(self):
        self.assertEqual(self.req('tools/call',{'name':'shell','arguments':{}})['error']['code'],-32602)
    def test_extra_arguments_refused(self):
        self.assertEqual(self.req('tools/call',{'name':'appleraven.status','arguments':{'shell':'ls'}})['error']['code'],-32602)
    def test_unauthorized_shortcut(self):
        self.assertTrue(self.call('appleraven.shortcuts.run',{'name':'Unapproved'})['isError'])
    def test_allowlisted_shortcut_exact_argv(self):
        calls=[]
        def fake(args,**kwargs):
            calls.append((args,kwargs))
            return types.SimpleNamespace(returncode=0,stdout='ok',stderr='')
        c=default_config();c['profiles']['lucascouncil']['allow_shortcuts']=['HEIMDALL Status']
        self.s=Session(AppleRaven(c,'lucascouncil',run=fake,which=lambda n:'/usr/bin/'+n,mac=True));self.init()
        self.assertFalse(self.call('appleraven.shortcuts.run',{'name':'HEIMDALL Status'})['isError'])
        self.assertEqual(calls[0][0],['shortcuts','run','HEIMDALL Status'])
        self.assertNotIn('shell',calls[0][1])
    def test_bound_profile(self):
        with self.assertRaises(AccessDenied):AppleRaven(default_config(),'lucaspro')
    def test_icloud_scopes(self):
        with tempfile.TemporaryDirectory() as t, tempfile.TemporaryDirectory() as outside:
            r=Path(t);(r/'hello.txt').write_text('hello')
            (Path(outside)/'secret.txt').write_text('secret')
            (r/'secret.txt').symlink_to(Path(outside)/'secret.txt')
            c=default_config();c['profiles']['lucascouncil']['allow_roots']={'docs':str(r)}
            c['profiles']['lucascouncil']['allow_file_read']=True
            self.s=Session(AppleRaven(c,'lucascouncil',mac=False));self.init()
            self.assertFalse(self.call('appleraven.icloud.read_text',{'root':'docs','path':'hello.txt'})['isError'])
            self.assertTrue(self.call('appleraven.icloud.read_text',{'root':'docs','path':'../secret.txt'})['isError'])
            self.assertTrue(self.call('appleraven.icloud.read_text',{'root':'docs','path':'secret.txt'})['isError'])
    def test_config_private_no_clobber(self):
        with tempfile.TemporaryDirectory() as t:
            p=Path(t)/'config.json';init_config(p)
            self.assertEqual(p.stat().st_mode & 0o777,0o600)
            with self.assertRaises(FileExistsError):init_config(p)
    def test_stdio_subprocess(self):
        with tempfile.TemporaryDirectory() as t:
            p=Path(t)/'config.json';init_config(p)
            msgs=[{'jsonrpc':'2.0','id':1,'method':'initialize','params':{'protocolVersion':'2025-06-18','capabilities':{},'clientInfo':{'name':'probe','version':'1'}}},
            {'jsonrpc':'2.0','method':'notifications/initialized'},
            {'jsonrpc':'2.0','id':2,'method':'tools/list'},
            {'jsonrpc':'2.0','id':3,'method':'tools/call','params':{'name':'appleraven.status','arguments':{}}}]
            result=subprocess.run([sys.executable,'-m','appleraven.server','--config',str(p)],input=''.join(json.dumps(x)+'\n' for x in msgs),text=True,capture_output=True,timeout=12)
            self.assertEqual(result.returncode,0,result.stderr)
            out=[json.loads(x) for x in result.stdout.splitlines()]
            self.assertEqual([x['id'] for x in out],[1,2,3])
            self.assertEqual(len(out[1]['result']['tools']),6)
if __name__=='__main__':unittest.main()
