import sys
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'core'))
from bridge_contract import TARGETS, platform_matrix
from mcp_server import TOOLS, Server
from standalone_backup import DeLorean
import tempfile

class MultiPlatformContract(unittest.TestCase):
    def test_01_platforms_cover_all_target_families(self):
        self.assertEqual(set(TARGETS),{'macos','windows','linux','ios','ipados','android','web'})
    def test_02_cross_vendor_not_chatgpt_only(self):
        c=platform_matrix()
        self.assertTrue({'chatgpt','claude','codex','gemini','other-mcp-agent'}<=set(c['agent_surfaces_targets']))
        self.assertFalse(c['exclusive_chatgpt_dependency'])
        self.assertFalse(c['exclusive_macos_dependency'])
    def test_03_no_unverified_client_installed_claim(self):
        c=platform_matrix()
        self.assertTrue(all(not v['installed_verified'] for v in c['native_platforms'].values()))
        self.assertEqual(c['connected_connector_instances_verified_here'],[])
        self.assertFalse(c['remote_mcp_host_connected_verified'])
    def test_04_optional_support(self):
        c=platform_matrix()
        self.assertFalse(c['penelope_mandatory'])
        self.assertFalse(c['cloud_mandatory'])
    def test_05_portability_status_tool_read_only(self):
        t=[x for x in TOOLS if x['name']=='delorean_platform_matrix']
        self.assertEqual(len(t),1)
        self.assertTrue(t[0]['annotations']['readOnlyHint'])
        self.assertEqual(len(TOOLS),29)
    def test_06_status_readable_with_no_device_and_no_cloud(self):
        with tempfile.TemporaryDirectory() as d:
            core=DeLorean(str(Path(d)/'home'),[],[],owner='TestOwner')
            srv=Server(core,allow_writes=False)
            x=srv.handle({'jsonrpc':'2.0','method':'tools/call','id':1,'params':{'name':'delorean_platform_matrix','arguments':{}}})
            self.assertFalse(x['result']['isError'])
            c=x['result']['structuredContent']['result']
            self.assertEqual(c['product'],'DeLorean TimeMachine')
            names={x['name'] for x in srv.visible_tools()}
            self.assertIn('delorean_platform_matrix',names)
            self.assertNotIn('delorean_stage_restore',names)
    def test_07_host_does_not_claim_mobile_native_restore(self):
        c=platform_matrix()
        self.assertEqual(c['native_platforms']['android']['evidence'],'not-built')
        self.assertEqual(c['native_platforms']['ios']['evidence'],'swiftui-read-only-source-only')
    def test_08_no_connector_auth_faked(self):
        c=platform_matrix()
        self.assertNotIn('token',str(c).lower())
        self.assertNotIn('password',str(c).lower())

if __name__=='__main__':unittest.main()
