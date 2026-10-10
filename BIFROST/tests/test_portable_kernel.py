"""BIFROST DP0.1 portable core regression on temporary user-owned data."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

SOURCE=Path(__file__).resolve().parents[1]/'core'/'portable_kernel.py'
spec=importlib.util.spec_from_file_location('bifrost_dp01',SOURCE)
kernel=importlib.util.module_from_spec(spec)
spec.loader.exec_module(kernel)

class KernelTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='bifrost-core-test-')
        self.root=Path(self.temp.name)/'source'
        self.root.mkdir()
        self.db=Path(self.temp.name)/'index'/'bifrost.db'

    def tearDown(self):
        self.temp.cleanup()

    def add(self,relative,body):
        path=self.root/relative
        path.parent.mkdir(parents=True,exist_ok=True)
        path.write_bytes(body)
        return path

    def test_dp01_scans_classifies_indexed_and_persists(self):
        image=self.add('Photos/memory.jpg',b'image test bytes')
        self.add('Docs/readme.md',b'Hello BIFROST users\n')
        before=image.read_bytes()
        with kernel.Kernel(self.db) as idx:
            result=idx.scan(self.root)
            self.assertEqual(result['state'],'COMPLETE')
            self.assertEqual(result['indexed_files'],2)
            status=idx.status()
            self.assertEqual(status['sources'],1)
            self.assertEqual(status['relationships'],4)
            self.assertEqual(status['provenance'],5)
            self.assertEqual(len(idx.search('readme')),1)
            self.assertEqual(idx.search('readme')[0]['mime'],'text/markdown')
            image_result=idx.search('memory')[0]
            self.assertEqual(image_result['classification'],'image')
            self.assertEqual(image_result['mime'],'image/jpeg')
            detail=idx.detail(image_result['object_id'])
            self.assertEqual(detail['locations'][0]['relative'],'Photos/memory.jpg')
            self.assertTrue(any(p['event']=='observed' for p in detail['provenance']))
            self.assertEqual(len(detail['relations']),1)
        with kernel.Kernel(self.db) as reopened:
            self.assertEqual(reopened.status()['objects'],5)
            self.assertEqual(len(reopened.search('readme')),1)
        self.assertEqual(before,image.read_bytes())

    def test_repeat_scan_is_idempotent_without_duplicate_provenance(self):
        self.add('notes.txt',b'hello')
        with kernel.Kernel(self.db) as idx:
            idx.scan(self.root)
            original=idx.status()
            idx.scan(self.root)
            current=idx.status()
            self.assertEqual(original['objects'],current['objects'])
            self.assertEqual(original['relationships'],current['relationships'])
            self.assertEqual(original['provenance'],current['provenance'])

    def test_move_file_keeps_object_identity_and_marks_old_location_inactive(self):
        first=self.add('One/name.txt',b'the same thing forever')
        (self.root/'Two').mkdir()
        with kernel.Kernel(self.db) as idx:
            idx.scan(self.root)
            old=idx.search('name')[0]
            first.rename(self.root/'Two'/'renamed.txt')
            newscan=idx.scan(self.root)
            self.assertEqual(newscan['state'],'COMPLETE')
            fresh=idx.search('renamed')[0]
            self.assertEqual(old['object_id'],fresh['object_id'])
            self.assertEqual(idx.search('One/name'),[])
            details=idx.detail(fresh['object_id'])
            self.assertEqual(len(details['locations']),2)
            self.assertEqual(sum(x['active'] for x in details['locations']),1)
            self.assertIn('location_missing', [p['event'] for p in details['provenance']])
            self.assertEqual(len(details['relations']),1)

    def test_changed_content_creates_new_object_not_overwrites_evidence(self):
        doc=self.add('report.md',b'old')
        with kernel.Kernel(self.db) as idx:
            idx.scan(self.root)
            old=idx.search('report')[0]['object_id']
            doc.write_bytes(b'changed data')
            idx.scan(self.root)
            new=idx.search('report')[0]['object_id']
            self.assertNotEqual(old,new)
            self.assertIsNotNone(idx.detail(old))
            self.assertEqual(idx.detail(new)['locations'][0]['active'],1)
            self.assertTrue(any(p['event']=='changed' for p in idx.detail(new)['provenance']))

    def test_duplicates_are_two_locations_of_one_content_identity(self):
        self.add('A.txt',b'same')
        self.add('B.txt',b'same')
        with kernel.Kernel(self.db) as idx:
            idx.scan(self.root)
            found=idx.search('.txt')
            self.assertEqual(len(found),2)
            self.assertEqual(found[0]['object_id'],found[1]['object_id'])
            self.assertEqual(len(idx.detail(found[0]['object_id'])['locations']),2)

    def test_filesystem_provider_skips_secrets_hidden_and_symlink_escape(self):
        self.add('public.md',b'public')
        self.add('.env',b'UNSAFE SECRET')
        self.add('.ssh/id_rsa',b'UNSAFE SECRET')
        outside=Path(self.temp.name)/'outside_secret'
        outside.write_text('outside')
        try:
            (self.root/'outside_link').symlink_to(outside)
        except (OSError,NotImplementedError):
            pass
        with kernel.Kernel(self.db) as idx:
            result=idx.scan(self.root)
            self.assertEqual(result['state'],'COMPLETE')
            self.assertEqual(result['indexed_files'],1)
            self.assertEqual(idx.search('env'),[])
            self.assertEqual(idx.search('secret'),[])
            self.assertEqual(idx.search('outside_link'),[])

    def test_partial_scan_never_prunes_unobserved_locations(self):
        self.add('1.txt',b'one')
        self.add('2.txt',b'two')
        with kernel.Kernel(self.db) as idx:
            idx.scan(self.root)
            self.assertEqual(len(idx.search('.txt')),2)
            result=idx.scan(self.root,max_files=1)
            self.assertEqual(result['state'],'PARTIAL')
            self.assertEqual(len(idx.search('.txt')),2)
            self.assertTrue(any(a['active'] for a in idx.detail(idx.search('2')[0]['object_id'])['locations']))

    def test_oversize_partial_avoids_stale_deletions(self):
        self.add('fine.txt',b'safe')
        with kernel.Kernel(self.db) as idx:
            idx.scan(self.root)
            self.add('large.txt',b'x'*1025)
            outcome=idx.scan(self.root,max_bytes=8)
            self.assertEqual(outcome['state'],'PARTIAL')
            self.assertIn('fine.txt',[x['relative'] for x in idx.search('fine')])
            self.assertEqual(idx.search('large'),[])

    def test_database_inside_root_rejected(self):
        db=self.root/'local.sqlite'
        with kernel.Kernel(db) as idx:
            with self.assertRaises(kernel.KernelError):
                idx.scan(self.root)

    def test_symlink_source_rejected(self):
        alias=Path(self.temp.name)/'alias'
        try:
            alias.symlink_to(self.root,target_is_directory=True)
        except (OSError,NotImplementedError):
            self.skipTest('symlinks unavailable')
        with kernel.Kernel(self.db) as idx:
            with self.assertRaises(kernel.KernelError):
                idx.scan(alias)

    def test_newer_schema_rejected_without_downgrade(self):
        import sqlite3
        self.db.parent.mkdir(parents=True,exist_ok=True)
        connection=sqlite3.connect(str(self.db))
        connection.execute('PRAGMA user_version=999')
        connection.close()
        with self.assertRaises(kernel.KernelError):
            kernel.Kernel(self.db)

    def test_search_wildcards_are_escaped_and_limit_checked(self):
        self.add('100%_special.txt',b'a')
        self.add('regular.txt',b'b')
        with kernel.Kernel(self.db) as idx:
            idx.scan(self.root)
            self.assertEqual(len(idx.search('%_')),1)
            self.assertEqual(len(idx.search('.txt',limit=1)),1)
            for item in ['', ' ' * 129, '%'*129]:
                with self.assertRaises(kernel.KernelError): idx.search(item)
            with self.assertRaises(kernel.KernelError): idx.search('txt',limit=1000)

    def test_content_revision_has_explicit_supersedes_relation(self):
        item=self.add('data.txt',b'v1')
        with kernel.Kernel(self.db) as idx:
            idx.scan(self.root)
            old=idx.search('data.txt')[0]['object_id']
            item.write_bytes(b'v2')
            idx.scan(self.root)
            newest=idx.search('data.txt')[0]['object_id']
            records=idx.detail(newest)['relations']
            self.assertTrue(any(x['type']=='supersedes' and
                                x['parent']==newest and x['child']==old for x in records))
            idx.scan(self.root)
            self.assertTrue(any(x['type']=='supersedes' and x['child']==old
                                for x in idx.detail(newest)['relations']))

    def test_prunes_multiple_stale_locations_on_completed_scan(self):
        self.add('A/f1.txt',b'one')
        self.add('A/f2.txt',b'two')
        self.add('A/f3.txt',b'three')
        with kernel.Kernel(self.db) as idx:
            idx.scan(self.root)
            self.assertEqual(len(idx.search('.txt')),3)
            (self.root/'A/f1.txt').unlink()
            (self.root/'A/f2.txt').unlink()
            (self.root/'A/f3.txt').unlink()
            (self.root/'A').rmdir()
            result=idx.scan(self.root)
            self.assertEqual(result['state'],'COMPLETE')
            self.assertEqual(len(idx.search('.txt')),0)
            self.assertEqual(idx.status()['relationships'],0)
            self.assertGreaterEqual(idx.status()['provenance'],8)

    def test_total_byte_budget_marks_partial_and_preserves_old_state(self):
        self.add('a.txt', b'aaa')
        self.add('b.txt', b'bbbb')
        with kernel.Kernel(self.db) as idx:
            idx.scan(self.root)
            self.assertEqual(len(idx.search('.txt')),2)
            result=idx.scan(self.root,max_total_bytes=3)
            self.assertEqual(result['state'],'PARTIAL')
            self.assertEqual(result['bytes_hashed'],3)
            self.assertEqual(len(idx.search('.txt')),2)
        with kernel.Kernel(self.db) as reopened:
            self.assertEqual(len(reopened.search('.txt')),2)

    def test_wal_allows_parallel_read_during_pending_writer(self):
        import sqlite3
        self.add('example.txt',b'original')
        with kernel.Kernel(self.db) as idx:
            idx.scan(self.root)
            idx.db.execute('BEGIN IMMEDIATE')
            try:
                read=sqlite3.connect(str(self.db),timeout=1)
                self.assertEqual(read.execute('SELECT count(*) FROM objects').fetchone()[0],2)
                read.close()
            finally:
                idx.db.rollback()

    def test_separate_roots_preserve_content_based_identity(self):
        first=self.add('something.md',b'provider migration')
        second=Path(self.temp.name)/'another-source'
        second.mkdir()
        shutil.copyfile(first,second/'moved.md')
        with kernel.Kernel(self.db) as idx:
            idx.scan(self.root)
            idx.scan(second)
            self.assertEqual(idx.status()['sources'],2)
            old=idx.search('something.md')[0]
            new=idx.search('moved.md')[0]
            self.assertEqual(old['object_id'],new['object_id'])
            self.assertEqual(len(idx.detail(old['object_id'])['locations']),2)

    def test_cli_status_search_scan_are_cross_process(self):
        self.add('test.md',b'CLI smoke')
        python=sys.executable
        base=[python,'-B',str(SOURCE),'--db',str(self.db)]
        def invoke(parts):
            return subprocess.run(base+parts,stdout=subprocess.PIPE,stderr=subprocess.PIPE,
                                  text=True,timeout=12)
        scan=invoke(['scan',str(self.root)])
        self.assertEqual(scan.returncode,0,scan.stderr)
        self.assertEqual(json.loads(scan.stdout)['indexed_files'],1)
        status=invoke(['status'])
        self.assertEqual(status.returncode,0,status.stderr)
        self.assertEqual(json.loads(status.stdout)['version'],1)
        query=invoke(['search','test.md'])
        self.assertEqual(len(json.loads(query.stdout)),1)

    def test_empty_folder_index_and_directory_relation(self):
        (self.root/'Empty').mkdir()
        with kernel.Kernel(self.db) as idx:
            result=idx.scan(self.root)
            self.assertEqual(result['state'],'COMPLETE')
            self.assertEqual(result['indexed_files'],0)
            self.assertEqual(idx.status()['objects'],2)
            self.assertEqual(idx.status()['relationships'],1)

if __name__=='__main__':
    unittest.main()
