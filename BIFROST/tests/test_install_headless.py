import importlib.util
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock
spec=importlib.util.spec_from_file_location('installer',Path(__file__).resolve().parents[1]/'tools/install_headless.py')
installer=importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)
class InstallerTests(unittest.TestCase):
    def test_non_mac_refused_before_any_file_access(self):
        with mock.patch.object(installer.sys,'platform','linux'):
            with self.assertRaisesRegex(RuntimeError,'macOS only'):
                installer.install(Path('/does-not-exist'))
    def test_manifest_accepts_original_and_rejects_tamper(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);(root/'file').write_bytes(b'original')
            (root/'INSTALL-MANIFEST.json').write_text(json.dumps({'file':hashlib.sha256(b'original').hexdigest()}))
            self.assertIn('file',installer.verify(root))
            (root/'file').write_bytes(b'changed')
            with self.assertRaisesRegex(RuntimeError,'integrity failed'):installer.verify(root)
    def test_manifest_rejects_escape(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);(root/'INSTALL-MANIFEST.json').write_text(json.dumps({'../escape':'bad'}))
            with self.assertRaisesRegex(RuntimeError,'Unsafe'):installer.verify(root)
    def test_symlink_refused(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);(root/'link').symlink_to('/tmp')
            (root/'INSTALL-MANIFEST.json').write_text(json.dumps({'link':'bad'}))
            with self.assertRaisesRegex(RuntimeError,'Unsafe'):installer.verify(root)
