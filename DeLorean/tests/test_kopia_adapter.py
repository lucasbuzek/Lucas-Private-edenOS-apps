"""Kopia adapter security + protocol tests against documented CLI contract.
Mocks a connected engine; these are NOT live cloud repository tests.
"""
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'core'))
import standalone_backup as b
import mcp_server as m

SID='a'*32
ROOT='k'+'b'*32
OWNER='LucasPRIVATE'
PROJECT='DemoApp'

class KopiaIntegration(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        root=Path(self.tmp.name)
        self.source=root/'src';self.source.mkdir()
        (self.source/'file.txt').write_text('actual source remains unchanged')
        self.out=root/'restore';self.out.mkdir()
        self.home=root/'backups'
        self.core=b.DeLorean(self.home,[str(self.source)],[str(self.out)])
        self.cli=patch.object(b,'_kopia_checked',side_effect=self.fake_cli)
        self.which=patch.object(b.shutil,'which',side_effect=lambda e:'/usr/local/bin/'+e if e=='kopia' else None)
        self.cli.start();self.which.start()
        self.addCleanup(self.cli.stop);self.addCleanup(self.which.stop)
        self.items=[{'id':SID,'rootID':ROOT,'tags':{'delorean-owner':OWNER,'delorean-project':PROJECT},'endTime':'2026-10-29T06:00:00Z'}]
        self.calls=[]

    def fake_cli(self,cmd,timeout=300):
        self.calls.append(list(cmd))
        if cmd[:2]==['repository','status']:
            return json.dumps({'storage':{'type':'filesystem'}})
        if cmd[:2]==['snapshot','list']:
            return json.dumps(self.items)
        if cmd[:2]==['snapshot','create']:
            return json.dumps({'id':SID,'rootID':ROOT,'incomplete':''})
        if cmd[:2]==['snapshot','verify']:
            return '{}'
        if cmd[:2]==['snapshot','restore']:
            # Model the Kopia CLI writing into the exact provided disposable dir.
            target=Path(cmd[3]);target.mkdir()
            (target/'restored.txt').write_text('verified-fresh-output')
            return '{}'
        raise AssertionError('Unexpected invocation '+repr(cmd))

    def test_01_read_only_status(self):
        status=self.core.kopia_status()
        self.assertTrue(status['connected']);self.assertFalse(status['credentials_exposed'])
    def test_02_source_scoped_owner_snapshot(self):
        x=self.core.kopia_snapshots(str(self.source),PROJECT)
        self.assertEqual([x[0]['snapshot_id'],x[0]['root_id']],[SID,ROOT])
        self.assertTrue(any('--tags' in c for c in self.calls))
    def test_03_other_owner_hidden(self):
        self.items[0]['tags']['delorean-owner']='OtherOwner'
        self.assertEqual(self.core.kopia_snapshots(str(self.source),PROJECT),[])
    def test_04_missing_tag_hidden(self):
        self.items[0].pop('tags')
        self.assertEqual(self.core.kopia_snapshots(str(self.source),PROJECT),[])
    def test_05_bad_snapshot_id_hidden(self):
        self.items[0]['id']='latest;rm -rf /'
        self.assertEqual(self.core.kopia_snapshots(str(self.source),PROJECT),[])
    def test_06_source_outside_grant_refused(self):
        with self.assertRaises(b.Denied):
            self.core.kopia_snapshots(str(self.home),PROJECT)
    def test_07_backup_requires_confirmation(self):
        with self.assertRaises(b.Denied):
            self.core.kopia_backup(str(self.source),PROJECT,'BACKUP NOW')
        self.assertFalse(any(c[:2]==['snapshot','create'] for c in self.calls))
    def test_08_backup_disables_hooks(self):
        r=self.core.kopia_backup(str(self.source),PROJECT,'ENCRYPTED KOPIA BACKUP')
        self.assertEqual(r['snapshot_id'],SID)
        command=next(c for c in self.calls if c[:2]==['snapshot','create'])
        self.assertIn('--force-disable-actions',command)
        self.assertIn('--no-send-snapshot-report',command)
        self.assertNotIn('init',command)
    def test_09_incomplete_backup_refused(self):
        old=self.fake_cli
        def failed(cmd,timeout=300):
            if cmd[:2]==['snapshot','create']:
                return json.dumps({'id':SID,'incomplete':'file missing'})
            return old(cmd,timeout)
        with patch.object(b,'_kopia_checked',side_effect=failed):
            with self.assertRaises(b.Denied):self.core.kopia_backup(str(self.source),PROJECT,'ENCRYPTED KOPIA BACKUP')
    def test_10_verify_is_not_claimed_full(self):
        result=self.core.kopia_verify(str(self.source),PROJECT,SID)
        self.assertFalse(result['full_restore_tested'])
    def test_11_restore_no_overwrite(self):
        target=self.out/'existing';target.mkdir()
        with self.assertRaises(b.Denied):
            self.core.kopia_restore(str(self.source),PROJECT,SID,str(target),'RESTORE KOPIA TO NEW DIRECTORY')
    def test_12_restore_refuses_other_owner(self):
        self.items[0]['tags']['delorean-owner']='OtherOwner'
        with self.assertRaises(b.Denied):
            self.core.kopia_restore(str(self.source),PROJECT,SID,str(self.out/'new'),'RESTORE KOPIA TO NEW DIRECTORY')
    def test_13_restore_requires_confirmation(self):
        with self.assertRaises(b.Denied):
            self.core.kopia_restore(str(self.source),PROJECT,SID,str(self.out/'new'),'YES')
    def test_14_isolated_restore(self):
        before=(self.source/'file.txt').read_text()
        result=self.core.kopia_restore(str(self.source),PROJECT,SID,str(self.out/'new'),'RESTORE KOPIA TO NEW DIRECTORY')
        self.assertEqual(result['restored_files'],1)
        self.assertEqual((self.out/'new'/'restored.txt').read_text(),'verified-fresh-output')
        self.assertEqual((self.source/'file.txt').read_text(),before)
        cmd=next(c for c in self.calls if c[:2]==['snapshot','restore'])
        self.assertIn('--no-overwrite-files',cmd)
        self.assertIn('--no-overwrite-symlinks',cmd)
    def test_15_read_only_mcp_cannot_backup(self):
        server=m.Server(self.core)
        self.assertEqual(len(server.visible_tools()),19)
        r=server.handle({'jsonrpc':'2.0','id':1,'method':'tools/call','params':{'name':'delorean_kopia_backup','arguments':{'source':str(self.source),'project':PROJECT,'confirmation':'ENCRYPTED KOPIA BACKUP'}}})
        self.assertTrue(r['result']['isError'])
    def test_16_write_enabled_mcp_backup(self):
        server=m.Server(self.core,allow_writes=True)
        self.assertEqual(len(server.visible_tools()),29)
        r=server.handle({'jsonrpc':'2.0','id':1,'method':'tools/call','params':{'name':'delorean_kopia_backup','arguments':{'source':str(self.source),'project':PROJECT,'confirmation':'ENCRYPTED KOPIA BACKUP'}}})
        self.assertFalse(r['result']['isError'])
    def test_17_write_denied_outside_grant(self):
        server=m.Server(self.core,allow_writes=True)
        r=server.handle({'jsonrpc':'2.0','id':1,'method':'tools/call','params':{'name':'delorean_kopia_backup','arguments':{'source':str(self.home),'project':PROJECT,'confirmation':'ENCRYPTED KOPIA BACKUP'}}})
        self.assertTrue(r['result']['isError'])
    def test_18_kopia_uninstalled_fails_closed(self):
        with patch.object(b.shutil,'which',return_value=None):
            self.assertFalse(self.core.kopia_status()['connected'])
            with self.assertRaises(b.Denied):self.core.kopia_snapshots(str(self.source),PROJECT)
    def test_19_raw_cli_no_shell(self):
        self.assertTrue(all(isinstance(c,list) for c in self.calls))
    def test_20_catalog_no_broad_listing(self):
        for c in self.calls:
            if c[:2]==['snapshot','list']:
                self.assertNotIn('--all',c)

if __name__=='__main__':unittest.main()
