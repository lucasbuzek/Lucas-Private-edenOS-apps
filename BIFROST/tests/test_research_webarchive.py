import pathlib
import plistlib
import tempfile
import unittest
import sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / 'tools'))
from research_webarchive import scan, extract

class WebarchiveTest(unittest.TestCase):
    def build(self, target, kind='text/html', payload=b'<h1>Hello</h1><script>malicious()</script><p>Saved!</p><a href="https://github.com/example/demo/issues/1">Code</a>'):
        target.write_bytes(plistlib.dumps({'WebMainResource': {'WebResourceData': payload,
            'WebResourceURL': 'https://example.invalid/reference', 'WebResourceMIMEType': kind,
            'WebResourceTextEncodingName': 'utf-8'}, 'WebSubresources': []}, fmt=plistlib.FMT_BINARY))

    def test_extract_without_execution(self):
        with tempfile.TemporaryDirectory() as t:
            f = pathlib.Path(t) / 'test.webarchive'; self.build(f)
            meta, text = extract(f)
            self.assertIn('Hello', text); self.assertIn('Saved!', text)
            self.assertNotIn('malicious()', text)
            self.assertEqual(meta['source_url'], 'https://example.invalid/reference')
            self.assertEqual(meta['github_repositories'], ['https://github.com/example/demo'])

    def test_bad_plist_does_not_stop_scan(self):
        with tempfile.TemporaryDirectory() as t:
            d=pathlib.Path(t); (d/'bad.webarchive').write_bytes(b'not a plist');self.build(d/'good.webarchive')
            items=list(scan(d));self.assertEqual(len(items),2)
            self.assertEqual({x['archive_state'] for x in items}, {'extracted_offline','unreadable'})

    def test_no_source_tree_output(self):
        with tempfile.TemporaryDirectory() as t:
            d=pathlib.Path(t); self.build(d/'good.webarchive')
            with self.assertRaises(ValueError):list(scan(d,d/'output'))

    def test_explicit_export_idempotent_no_clobber(self):
        with tempfile.TemporaryDirectory() as s, tempfile.TemporaryDirectory() as o:
            d=pathlib.Path(s);self.build(d/'good.webarchive')
            once=list(scan(d,o));twice=list(scan(d,o))
            self.assertEqual(once[0]['local_export'], twice[0]['local_export'])
            self.assertEqual(len(list(pathlib.Path(o).iterdir())),1)

    def test_recursive_archive_inventory_keeps_source_provenance(self):
        with tempfile.TemporaryDirectory() as t, tempfile.TemporaryDirectory() as outside:
            root = pathlib.Path(t)
            nested = root / '#webMCP' / 'examples'
            nested.mkdir(parents=True)
            self.build(root / 'root.webarchive')
            self.build(nested / 'webmcp.webarchive')
            elsewhere = pathlib.Path(outside)
            self.build(elsewhere / 'private.webarchive')
            (root / 'linked-folder').symlink_to(elsewhere, target_is_directory=True)
            direct = list(scan(root))
            self.assertEqual([x['relative_path'] for x in direct], ['root.webarchive'])
            recursive = list(scan(root, recursive=True))
            self.assertEqual([x['relative_path'] for x in recursive],
                ['#webMCP/examples/webmcp.webarchive', 'root.webarchive'])
            self.assertEqual({x['archive_state'] for x in recursive},
                {'extracted_offline'})
            self.assertNotIn('linked-folder/private.webarchive',
                [x['relative_path'] for x in recursive])

    def test_symlink_refused(self):
        with tempfile.TemporaryDirectory() as t:
            d=pathlib.Path(t);self.build(d/'good.webarchive'); (d/'link.webarchive').symlink_to(d/'good.webarchive')
            x={i['filename']:i for i in scan(d)}
            self.assertEqual(x['link.webarchive']['archive_state'],'unreadable')

if __name__=='__main__': unittest.main()
