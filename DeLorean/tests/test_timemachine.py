import json
import os
from pathlib import Path
import tempfile
import unittest
from importlib.util import spec_from_file_location, module_from_spec

MODULE = Path(__file__).resolve().parents[1] / 'core' / 'timemachine.py'
spec = spec_from_file_location('timemachine', MODULE)
d = module_from_spec(spec); spec.loader.exec_module(d)

class TimeMachineTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.src = self.root/'original-backup'
        self.src.mkdir()
        (self.src/'source').mkdir()
        (self.src/'source'/'app.swift').write_text('Original, known-good app content')
        (self.src/'README.md').write_text('Project Bible pointer')
        self.catalog = self.root/'catalog'
        self.one = d.register(self.catalog,'EDEN',str(self.src),ref='git:abc')
    def test_register_preserves_source_and_idempotent(self):
        first=self.one
        second=d.register(self.catalog,'EDEN',str(self.src),ref='git:abc')
        self.assertEqual(first,second)
        self.assertEqual(len(list(self.catalog.glob('*.json'))),1)
        self.assertEqual((self.src/'README.md').read_text(),'Project Bible pointer')
        self.assertFalse(first['backup_created_by_delorean'])
    def test_verify_positive(self):
        v=d.verify(self.one)
        self.assertTrue(v['ok'])
        self.assertEqual(v['files_checked'],2)
    def test_verify_modified_source_denied(self):
        (self.src/'README.md').write_text('Modified later')
        v=d.verify(self.one)
        self.assertFalse(v['ok'])
        self.assertIn('README.md',v['changed'])
        with self.assertRaises(d.RecoveryError):
            d.stage(self.one,str(self.root/'restore'))
    def test_compare_added_removed_modified(self):
        (self.src/'source'/'app.swift').write_text('Next version')
        (self.src/'new.txt').write_text('New')
        (self.src/'README.md').unlink()
        newer=d.register(self.catalog,'EDEN',str(self.src),ref='git:def')
        changes=d.compare(self.one,newer)
        self.assertEqual(changes['added'],['new.txt'])
        self.assertEqual(changes['removed'],['README.md'])
        self.assertEqual(changes['modified'],['source/app.swift'])
    def test_cross_tenant_negative(self):
        other=d.register(self.catalog,'EDEN',str(self.src),ref='other',owner='OtherCouncil')
        with self.assertRaises(d.RecoveryError):
            d.compare(self.one,other)
    def test_stage_restore_and_revalidate(self):
        target=self.root/'restored'
        info=d.stage(self.one,str(target))
        self.assertEqual(info['status'],'ISOLATED_RESTORE_VERIFIED')
        self.assertEqual((target/'README.md').read_text(),'Project Bible pointer')
        self.assertTrue(self.src.is_dir())
    def test_preview_refuses_nonempty_destination(self):
        target=self.root/'current-project'
        target.mkdir()
        (target/'unique.txt').write_text('KEEP')
        with self.assertRaises(d.RecoveryError):
            d.plan(self.one,str(target))
        self.assertEqual((target/'unique.txt').read_text(),'KEEP')
    def test_existing_empty_directory_also_preserved(self):
        target=self.root/'empty-current'
        target.mkdir()
        with self.assertRaises(d.RecoveryError):
            d.stage(self.one,str(target))
        self.assertTrue(target.is_dir())
    def test_manifest_changed_source_during_stage_fails_closed(self):
        # The outer integrity gate rejects a changed candidate before writing.
        (self.src/'source'/'app.swift').write_bytes(b'CORRUPTED')
        with self.assertRaises(d.RecoveryError):
            d.stage(self.one,str(self.root/'staged'))
        self.assertFalse((self.root/'staged').exists())
    def test_source_and_target_never_overlap(self):
        with self.assertRaises(d.RecoveryError):
            d.plan(self.one,str(self.src/'restore'))
        with self.assertRaises(d.RecoveryError):
            d.plan(self.one,str(self.root))
    def test_symlink_scan_rejected(self):
        outside=self.root/'secret'
        outside.write_text('private')
        (self.src/'secret').symlink_to(outside)
        with self.assertRaises(d.RecoveryError):
            d.scan(self.src)
    def test_traversal_and_duplicate_manifest_rejected(self):
        f=self.catalog/(self.one['snapshot_id']+'.json')
        m=json.loads(f.read_text())
        m['files'][0]['path']='../oops'
        f.write_text(json.dumps(m))
        with self.assertRaises(d.RecoveryError):
            d.load_manifest(f)
        m['files'][0]['path']='README.md'
        m['files'].append(m['files'][0].copy())
        f.write_text(json.dumps(m))
        with self.assertRaises(d.RecoveryError):
            d.load_manifest(f)
    def test_bad_manifest_rejected(self):
        f=self.catalog/(self.one['snapshot_id']+'.json')
        f.write_text('{bad')
        with self.assertRaises(d.RecoveryError):
            d.load_manifest(f)
    def test_export_private_paths_removed_and_noclobber(self):
        export=self.root/'phone-import.json'
        value=d.export(self.catalog,export)
        self.assertEqual(value['schema'],'eden.delorean.catalog.v1')
        self.assertNotIn('source_root',export.read_text())
        self.assertNotIn(str(self.src),export.read_text())
        with self.assertRaises(d.RecoveryError):
            d.export(self.catalog,export)
    def test_missing_and_extra_files(self):
        (self.src/'README.md').unlink()
        (self.src/'unregistered').write_text('extra')
        v=d.verify(self.one)
        self.assertEqual(v['missing'],['README.md'])
        self.assertEqual(v['extra'],['unregistered'])
    def test_empty_backup_snapshot_stage(self):
        empty=self.root/'empty'
        empty.mkdir()
        s=d.register(self.catalog,'EDEN',str(empty),ref='empty')
        target=self.root/'restoredempty'
        info=d.stage(s,str(target))
        self.assertTrue(target.exists())
        self.assertEqual(info['files'],0)
    def test_no_catalog_inside_backup(self):
        with self.assertRaises(d.RecoveryError):
            d.register(self.src/'catalog','EDEN',str(self.src))

if __name__=='__main__':
    unittest.main()
