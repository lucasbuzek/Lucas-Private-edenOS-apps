"""Cross-agent provider metadata bridge: real stdio protocol + restrictive local catalog tests."""
import json
from pathlib import Path
import os
import stat
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'core'))
from connector_evidence import SCHEMA, canonical_records, EVIDENCE, _folder
from standalone_backup import DeLorean, Denied, history
from mcp_server import Server, TOOLS


def bundle(owner='OwnerA',entries=None):
    return {'schema':SCHEMA,'owner':owner,'entries':entries or [
        {'provider':'github','project':'DeLorean','account_alias':'private-github','kind':'commit',
         'ref':'a'*40,'occurred_at':'2026-10-29T12:30:00Z'},
        {'provider':'google-drive','project':'DeLorean','account_alias':'raven-drive','kind':'file-revision',
         'ref':'rev_009-ABC','occurred_at':'2026-10-29T12:31:00+00:00'},
        {'provider':'dropbox','project':'Research','account_alias':'raven-dropbox','kind':'file-revision',
         'ref':'dbid-0003','occurred_at':'2026-10-29T12:32:00Z'}
    ]}

class ConnectorBridgeTests(unittest.TestCase):
    def setUp(self):
        self.t=tempfile.TemporaryDirectory();self.addCleanup(self.t.cleanup)
        self.root=Path(self.t.name)
        self.core=DeLorean(self.root/'state',[],[],owner='OwnerA')
        self.ro=Server(self.core)
        self.rw=Server(self.core,allow_writes=True)
    def query(self,s,name,args=None):
        return s.handle({'jsonrpc':'2.0','id':4,'method':'tools/call',
            'params':{'name':name,'arguments':args or {}}})
    def test_01_preview_read_only_does_not_create_home(self):
        q=self.query(self.ro,'delorean_connector_preview',{'bundle':bundle()})
        self.assertFalse(q['result']['isError'],q)
        self.assertEqual(q['result']['structuredContent']['result']['unique_events'],3)
        self.assertFalse(self.core.home.exists())
    def test_02_import_not_visible_without_local_write_grant(self):
        self.assertNotIn('delorean_connector_import',{x['name'] for x in self.ro.visible_tools()})
        q=self.query(self.ro,'delorean_connector_import',{'bundle':bundle(),'confirmation':'IMPORT CONNECTOR REFERENCES'})
        self.assertTrue(q['result']['isError'])
        self.assertFalse(self.core.home.exists())
    def test_03_import_readback_timeline_dashboard(self):
        q=self.query(self.rw,'delorean_connector_import',{'bundle':bundle(),'confirmation':'IMPORT CONNECTOR REFERENCES'})
        self.assertFalse(q['result']['isError'],q)
        self.assertEqual(q['result']['structuredContent']['result']['created'],3)
        events=self.core.timeline()
        self.assertEqual(len(events),3)
        self.assertTrue(all(e['evidence']==EVIDENCE for e in events))
        self.assertTrue(all(e['recoverability']=='UNKNOWN_SOURCE_REFERENCE_ONLY' for e in events))
        self.assertEqual(len(self.core.dashboard_catalog()['events']),3)
    def test_04_idempotent_import(self):
        self.core.connector_import(bundle(),'IMPORT CONNECTOR REFERENCES')
        x=self.core.connector_import(bundle(),'IMPORT CONNECTOR REFERENCES')
        self.assertEqual(x['created'],0)
        self.assertEqual(x['reused'],3)
        self.assertEqual(len(self.core.timeline()),3)
    def test_05_project_scope(self):
        self.core.connector_import(bundle(),'IMPORT CONNECTOR REFERENCES')
        self.assertEqual(len(self.core.connector_events('DeLorean')),2)
        self.assertEqual(len(self.core.timeline('Research')),1)
    def test_06_cross_owner_refused_before_write(self):
        with self.assertRaises(history.RecoveryError):self.core.connector_import(bundle('AnotherCouncil'),'IMPORT CONNECTOR REFERENCES')
        self.assertFalse(self.core.home.exists())
    def test_07_model_confirmation_not_equal_host_consent(self):
        q=self.query(self.ro,'delorean_connector_import',{'bundle':bundle(),'confirmation':'IMPORT CONNECTOR REFERENCES'})
        self.assertTrue(q['result']['isError'])
        with self.assertRaises(Denied):self.core.connector_import(bundle(),'not authorized')
    def test_08_entire_batch_validated_before_mutation(self):
        b=bundle();b['entries'][2]['provider']='unknown-provider'
        with self.assertRaises(history.RecoveryError):self.core.connector_import(b,'IMPORT CONNECTOR REFERENCES')
        self.assertFalse(self.core.catalog.exists())
    def test_09_secret_or_extraneous_key_refused(self):
        b=bundle();b['entries'][0]['oauth_token']='secret'
        with self.assertRaises(history.RecoveryError):canonical_records(b,'OwnerA')
        self.assertNotIn('token',json.dumps(self.core.connector_events()).lower())
    def test_10_url_ref_disallowed(self):
        for ref in ['https://example.com/share','file:///etc/passwd','user@host','abc?token=123','x y','..//something']:
            with self.subTest(ref=ref):
                b=bundle();b['entries'][0]['ref']=ref
                with self.assertRaises(history.RecoveryError):canonical_records(b,'OwnerA')
    def test_11_timezone_required(self):
        b=bundle();b['entries'][0]['occurred_at']='2026-10-29T12:30:00'
        with self.assertRaises(history.RecoveryError):canonical_records(b,'OwnerA')
    def test_12_future_no_backup_claim(self):
        q=self.core.connector_preview(bundle())
        self.assertEqual(q['recoverability'],'NOT_VERIFIED')
        self.assertNotIn('HASH_VERIFIED',q['evidence'])
    def test_13_no_provider_login_performed(self):
        x=self.core.connector_import(bundle(),'IMPORT CONNECTOR REFERENCES')
        self.assertFalse(x['source_provider_was_called_by_delorean'])
        self.assertFalse(x['backup_or_restore_verified'])
    def test_14_stored_event_fingerprint_protects_timeline(self):
        self.core.connector_import(bundle(),'IMPORT CONNECTOR REFERENCES')
        f=next((self.core.catalog/'connector-events').glob('*.json'))
        record=json.loads(f.read_text());record['provider_ref']='forged'
        f.write_text(json.dumps(record))
        with self.assertRaises(history.RecoveryError):self.core.connector_events()
    def test_15_symlinked_catalog_events_denied(self):
        other=self.root/'external';other.mkdir()
        self.core.catalog.mkdir(parents=True)
        (self.core.catalog/'connector-events').symlink_to(other,target_is_directory=True)
        with self.assertRaises(history.RecoveryError):self.core.connector_import(bundle(),'IMPORT CONNECTOR REFERENCES')
    def test_16_batch_cap(self):
        b=bundle();b['entries']=b['entries']*34
        with self.assertRaises(history.RecoveryError):canonical_records(b,'OwnerA')
    def test_17_no_hidden_api_secrets_in_results(self):
        self.core.connector_import(bundle(),'IMPORT CONNECTOR REFERENCES')
        r=json.dumps(self.core.connector_events())
        self.assertNotIn('password',r.lower())
        self.assertNotIn('oauth',r.lower())
        self.assertNotIn('https://',r)
    def test_18_invalid_entry_provider_type_rejected(self):
        b=bundle();b['entries'][0]['provider']=['github']
        with self.assertRaises(history.RecoveryError):canonical_records(b,'OwnerA')
    def test_19_readonly_mcp_event_query(self):
        reply=self.query(self.ro,'delorean_connector_events',{'project':'DeLorean'})
        self.assertFalse(reply['result']['isError'])
        self.assertEqual(reply['result']['structuredContent']['result'],[])
    def test_20_subprocess_actual_mcp_cross_host_handoff(self):
        cmd=[sys.executable,str(ROOT/'core/mcp_server.py'),'--home',str(self.core.home),'--owner','OwnerA','--enable-writes']
        arr=[
            {'jsonrpc':'2.0','id':1,'method':'initialize','params':{'protocolVersion':'2025-06-18','clientInfo':{'name':'portable-client','version':'1'},'capabilities':{}}},
            {'jsonrpc':'2.0','method':'notifications/initialized'},
            {'jsonrpc':'2.0','id':2,'method':'tools/list'},
            {'jsonrpc':'2.0','id':3,'method':'tools/call','params':{'name':'delorean_connector_preview','arguments':{'bundle':bundle()}}},
            {'jsonrpc':'2.0','id':4,'method':'tools/call','params':{'name':'delorean_connector_import','arguments':{'bundle':bundle(),'confirmation':'IMPORT CONNECTOR REFERENCES'}}},
            {'jsonrpc':'2.0','id':5,'method':'tools/call','params':{'name':'delorean_timeline','arguments':{'project':'DeLorean'}}}
        ]
        p=subprocess.run(cmd,input='\n'.join(json.dumps(i) for i in arr)+'\n',text=True,capture_output=True,timeout=10)
        self.assertEqual(p.returncode,0,p.stderr)
        replies=[json.loads(s) for s in p.stdout.splitlines()]
        self.assertEqual(len(replies),5)
        names={t['name'] for t in replies[1]['result']['tools']}
        self.assertIn('delorean_connector_import',names)
        self.assertEqual(replies[3]['result']['structuredContent']['result']['created'],3)
        self.assertEqual(len(replies[4]['result']['structuredContent']['result']),2)
    def test_21_duplicate_entries_dedupe(self):
        b=bundle();b['entries'].append(dict(b['entries'][0]))
        self.assertEqual(self.core.connector_preview(b)['unique_events'],3)
    def test_22_unapproved_project_separation(self):
        self.core.connector_import(bundle(),'IMPORT CONNECTOR REFERENCES')
        other=DeLorean(self.root/'state',[],[],owner='OtherCouncil')
        self.assertEqual(other.connector_events(),[])
        self.assertEqual(other.timeline(),[])

    def test_23_imported_event_is_private_to_owner_on_posix(self):
        self.core.connector_import(bundle(),'IMPORT CONNECTOR REFERENCES')
        if os.name == 'posix':
            p=next((self.core.catalog/'connector-events').glob('*.json'))
            self.assertEqual(stat.S_IMODE(p.stat().st_mode),0o600)
    def test_24_default_mcp_rejects_write_after_preview(self):
        preview=self.query(self.ro,'delorean_connector_preview',{'bundle':bundle()})
        self.assertFalse(preview['result']['isError'])
        write=self.query(self.ro,'delorean_connector_import',{'bundle':bundle(),'confirmation':'IMPORT CONNECTOR REFERENCES'})
        self.assertTrue(write['result']['isError'])
        self.assertFalse(self.core.home.exists())

if __name__=='__main__':unittest.main()
