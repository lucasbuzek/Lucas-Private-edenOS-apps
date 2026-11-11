"""Tests exercising actual byte copies, isolated recovery, and JSON-RPC stdio transport."""
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'core'))
from standalone_backup import DeLorean,Denied,history
from mcp_server import Server,TOOLS

class StandaloneTests(unittest.TestCase):
    def setUp(self):
        t=tempfile.TemporaryDirectory();self.addCleanup(t.cleanup);self.base=Path(t.name)
        self.home=self.base/'home';self.inputs=self.base/'inputs';self.restore=self.base/'restore-granted'
        self.inputs.mkdir();self.restore.mkdir()
        self.src=self.inputs/'A';self.src.mkdir();(self.src/'file.txt').write_text('hello world')
        (self.src/'nested').mkdir();(self.src/'nested'/'x.swift').write_text('func hello() {}')
        self.server=DeLorean(self.home,[str(self.inputs)],[str(self.restore)],owner='LucasPRIVATE')
        self.mcp=Server(self.server,allow_writes=True)

    def make(self):return self.server.backup_create(str(self.src),'project','DeLorean','BACKUP NOW')

    def test_status_no_grants_leak(self):
        state=self.server.status()
        self.assertEqual(state['read_grants'],1)
        self.assertNotIn(str(self.inputs),json.dumps(state))
    def test_create_real_snapshot(self):
        b=self.make();self.assertEqual(b['files'],2)
        self.assertTrue(Path(b['snapshot_directory']).is_dir())
        self.assertTrue(self.server.verify_snapshot(b['snapshot_id'])['ok'])
        self.assertTrue((self.src/'file.txt').is_file())
    def test_restore_full_and_no_clobber(self):
        b=self.make();dst=self.restore/'out'
        plan=self.server.recovery_plan(b['snapshot_id'],str(dst))
        self.assertEqual(plan['files'],2)
        result=self.server.recovery_stage(b['snapshot_id'],str(dst),'RESTORE TO NEW DIRECTORY')
        self.assertEqual(result['status'],'ISOLATED_RESTORE_VERIFIED')
        self.assertEqual((dst/'nested'/'x.swift').read_text(),'func hello() {}')
        with self.assertRaises(history.RecoveryError):self.server.recovery_stage(b['snapshot_id'],str(dst),'RESTORE TO NEW DIRECTORY')
    def test_selective_restore_and_original_unchanged(self):
        b=self.make();dst=self.restore/'selected'
        self.server.recovery_stage(b['snapshot_id'],str(dst),'RESTORE TO NEW DIRECTORY',['nested/x.swift'])
        self.assertFalse((dst/'file.txt').exists())
        self.assertTrue((dst/'nested'/'x.swift').exists())
        self.assertTrue((self.src/'file.txt').exists())
    def test_explicit_backup_confirmation(self):
        with self.assertRaises(Denied):self.server.backup_create(str(self.src),'project','A','maybe')
        self.assertFalse(self.server.catalog.exists())
    def test_restore_confirmation(self):
        b=self.make()
        with self.assertRaises(Denied):self.server.recovery_stage(b['snapshot_id'],str(self.restore/'bad'),'yes')
    def test_scope_device_data_not_system_image(self):
        p=self.server.backup_plan(str(self.src),'device-data','MacA')
        self.assertEqual(p['kind'],'FILE_TREE_COPY_NOT_SYSTEM_IMAGE')
        with self.assertRaises(Denied):self.server.backup_plan(str(self.src),'disk-image','MacA')
    def test_denied_outside_read_and_restore(self):
        secret=self.base/'secret';secret.mkdir();(secret/'key').write_text('SECRET')
        with self.assertRaises(Denied):self.server.backup_plan(str(secret),'project','A')
        b=self.make()
        with self.assertRaises(Denied):self.server.recovery_plan(b['snapshot_id'],str(secret/'new'))
    def test_reject_symlink_source(self):
        (self.src/'leak').symlink_to(self.base/'secret')
        with self.assertRaises(history.RecoveryError):self.make()
    def test_tampering_source_backup_detected(self):
        b=self.make();snap=Path(b['snapshot_directory'])/'payload'/'file.txt';snap.write_text('evil')
        self.assertFalse(self.server.verify_snapshot(b['snapshot_id'])['ok'])
        with self.assertRaises(history.RecoveryError):self.server.recovery_plan(b['snapshot_id'],str(self.restore/'no'))
    def test_reject_cross_owner_snapshot(self):
        b=self.make();other=DeLorean(self.home,[str(self.inputs)],[str(self.restore)],owner='AnotherCouncil')
        with self.assertRaises(Denied):other.verify_snapshot(b['snapshot_id'])
        self.assertEqual(other.snapshots(),[])
    def test_file_backup(self):
        b=self.server.backup_create(str(self.src/'file.txt'),'file','OneFile','BACKUP NOW')
        out=self.restore/'file'
        self.server.recovery_stage(b['snapshot_id'],str(out),'RESTORE TO NEW DIRECTORY')
        self.assertEqual((out/'file.txt').read_text(),'hello world')
    def test_compare_snapshots(self):
        a=self.make();(self.src/'file.txt').write_text('v2');b=self.make()
        result=self.server.compare(a['snapshot_id'],b['snapshot_id']);self.assertEqual(result['modified'],['file.txt'])
    def test_persistent_reload(self):
        a=self.make();again=DeLorean(self.home,[str(self.inputs)],[str(self.restore)])
        self.assertEqual(again.snapshots()[0]['snapshot_id'],a['snapshot_id'])
    def test_optional_penelope(self):
        data={'schema':'eden.penelope.references.v1','owner':'LucasPRIVATE','items':[{'project':'DeLorean','reference':'doc:a','time':'2026-10-25T12:00:00Z'}]}
        exp=self.inputs/'penelope.json';exp.write_text(json.dumps(data));r=self.server.penelope_import(str(exp))
        self.assertEqual(r['imported_references'],1)
        self.assertEqual(self.server.timeline('DeLorean')[0]['provider'],'PENELOPE')
    def test_penelope_cross_owner_denied(self):
        exp=self.inputs/'penelope.json';exp.write_text(json.dumps({'schema':'eden.penelope.references.v1','owner':'OtherCouncil','items':[]}))
        with self.assertRaises(Denied):self.server.penelope_import(str(exp))
    def test_optional_cloud_does_not_require_restic(self):
        self.assertIn('configured',self.server.restic_status())
        with self.assertRaises(Denied):self.server.restic_backup(str(self.src),'DeLorean','NOT APPROVED')
    def test_time_machine_not_macos_on_linux(self):
        if sys.platform!='darwin':self.assertFalse(self.server.time_machine_status()['available'])
    def test_unchanged_backup_reuses_verified_snapshot(self):
        first=self.make();second=self.make()
        self.assertEqual(first['snapshot_id'],second['snapshot_id'])
        self.assertEqual(second['status'],'UNCHANGED_REUSED_VERIFIED')
        self.assertEqual(len(list(self.server.sets.glob('*/backup_info.json'))),1)
    def test_modified_source_creates_new_version(self):
        first=self.make();(self.src/'file.txt').write_text('changed')
        second=self.make();self.assertNotEqual(first['snapshot_id'],second['snapshot_id'])
        self.assertEqual(len(self.server.snapshots()),2)
    def test_unencrypted_copy_marked(self):
        result=self.make();self.assertFalse(result['encrypted'])
        self.assertIn('UNENCRYPTED',self.server.backup_plan(str(self.src),'project','DeLorean')['warning'])
    def test_restic_filters_owner_and_project(self):
        from unittest.mock import patch
        mock=[{"id":"abcdef1234567890","tags":["delorean:DeLorean","delorean-owner:LucasPRIVATE"],"time":"2026-10-26T00:00:00Z"}, {"id":"bbbbbbbb11111111","tags":["delorean:DeLorean","delorean-owner:OtherCouncil"]}]
        with patch('standalone_backup._restic_checked',return_value=json.dumps(mock)):
            matches=self.server.restic_snapshots('DeLorean')
        self.assertEqual([x['snapshot_id'] for x in matches],['abcdef1234567890'])
    def test_restic_restore_requires_authorized_id_and_new_dir(self):
        from unittest.mock import patch
        with patch('standalone_backup.restic_snapshots',return_value=[{'snapshot_id':'abcdef1234567890'}]):
            with self.assertRaises(Denied):
                self.server.restic_restore('A','bbbb1111',str(self.restore/'target'),'RESTORE CLOUD SNAPSHOT TO NEW DIRECTORY')
            with self.assertRaises(Denied):
                self.server.restic_restore('A','abcdef1234567890',str(self.restore/'target'),'please')
    def test_restic_restore_stages_then_renames(self):
        from unittest.mock import patch
        def fake_call(core,argv,timeout=300):
            if argv[0]=='snapshots':
                return '[{"id":"abcdef1234567890","tags":["delorean:DeLorean","delorean-owner:LucasPRIVATE"]}]'
            if argv[0]=='restore':
                Path(argv[argv.index('--target')+1],'file.txt').write_text('test recovered')
                return ''
            raise AssertionError(argv)
        with patch('standalone_backup._restic_checked',new=fake_call):
            dest=self.restore/'cloud-restored'
            result=self.server.restic_restore('DeLorean','abcdef1234567890',str(dest),'RESTORE CLOUD SNAPSHOT TO NEW DIRECTORY')
        self.assertEqual(result['files'],1)
        self.assertEqual((dest/'file.txt').read_text(),'test recovered')
    def test_restic_repository_check_not_full_restore(self):
        from unittest.mock import patch
        with patch('standalone_backup._restic_checked',return_value=''):
            result=self.server.restic_check()
        self.assertEqual(result['full_restoration'],'NOT_PROVEN')
    def test_mcp_tool_discovery(self):
        answer=self.mcp.handle({'jsonrpc':'2.0','id':1,'method':'tools/list'})
        names={x['name'] for x in answer['result']['tools']}
        self.assertIn('delorean_backup_create',names);self.assertIn('delorean_stage_restore',names)
        self.assertGreater(len(TOOLS),10)
    def test_mcp_positive_actual_operation(self):
        q={'jsonrpc':'2.0','id':3,'method':'tools/call','params':{'name':'delorean_backup_create','arguments':{'source':str(self.src),'scope':'project','project':'DeLorean','confirmation':'BACKUP NOW'}}}
        response=self.mcp.handle(q);self.assertFalse(response['result']['isError']);self.assertEqual(response['result']['structuredContent']['result']['files'],2)
    def test_mcp_deny_missing_confirmation(self):
        q={'jsonrpc':'2.0','id':3,'method':'tools/call','params':{'name':'delorean_backup_create','arguments':{'source':str(self.src),'scope':'project','project':'DeLorean'}}}
        self.assertTrue(self.mcp.handle(q)['result']['isError'])
    def test_mcp_deny_unknown_keys(self):
        q={'jsonrpc':'2.0','id':3,'method':'tools/call','params':{'name':'delorean_snapshots','arguments':{'extra':'secret'}}}
        self.assertTrue(self.mcp.handle(q)['result']['isError'])
    def test_mcp_notifications_silent(self):
        self.assertIsNone(self.mcp.handle({'jsonrpc':'2.0','method':'notifications/initialized'}))
    def test_mcp_stdio_wire_client(self):
        cmd=[sys.executable,str(ROOT/'core'/'mcp_server.py'),'--home',str(self.home),'--allow-source',str(self.inputs),'--allow-restore',str(self.restore)]
        inp='\n'.join(json.dumps(x) for x in [
            {'jsonrpc':'2.0','id':1,'method':'initialize','params':{'protocolVersion':'2025-06-18','capabilities':{},'clientInfo':{'name':'test','version':'1'}}},
            {'jsonrpc':'2.0','method':'notifications/initialized'},
            {'jsonrpc':'2.0','id':2,'method':'tools/list'},
            {'jsonrpc':'2.0','id':3,'method':'tools/call','params':{'name':'delorean_backup_plan','arguments':{'source':str(self.src),'project':'DeLorean','scope':'app'}}}
        ])+'\n'
        proc=subprocess.run(cmd,input=inp,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,timeout=10)
        self.assertEqual(proc.returncode,0,proc.stderr)
        reply=[json.loads(x) for x in proc.stdout.splitlines()];self.assertEqual(len(reply),3)
        self.assertEqual(reply[0]['result']['protocolVersion'],'2025-06-18')
        self.assertEqual(reply[-1]['result']['structuredContent']['result']['files'],2)
    def test_mcp_no_authorized_roots(self):
        cmd=[sys.executable,str(ROOT/'core'/'mcp_server.py'),'--home',str(self.home)]
        req=json.dumps({'jsonrpc':'2.0','id':1,'method':'tools/call','params':{'name':'delorean_backup_plan','arguments':{'source':str(self.src),'project':'A','scope':'app'}}})+'\n'
        p=subprocess.run(cmd,input=req,capture_output=True,text=True,timeout=10)
        self.assertTrue(json.loads(p.stdout)['result']['isError'])
    def test_dangerous_root_overlap_denied(self):
        with self.assertRaises(Denied):DeLorean(self.inputs/'backup_root',[str(self.inputs)],[str(self.restore)])

if __name__=='__main__':unittest.main()
