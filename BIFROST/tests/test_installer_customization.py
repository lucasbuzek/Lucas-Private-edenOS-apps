"""One-click BIFROST installer customization and no-clobber regression."""
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('bifrost_install', ROOT/'tools'/'install_headless.py')
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class InstallerCustomizationTests(unittest.TestCase):
    def test_safe_default_no_automatic_login_start(self):
        value = installer.validate_install_options({})
        self.assertEqual(value, {'port': 8798, 'startAtLogin': False, 'openDashboard': True})

    def test_custom_port_and_user_preferences(self):
        self.assertEqual(installer.validate_install_options(
            {'port': 8974, 'startAtLogin': True, 'openDashboard': False})['port'], 8974)

    def test_reject_invalid_ports_including_bool(self):
        for value in (True, '8798', 0, 80, 1023, 65536, -1, 99999):
            with self.subTest(value=value), self.assertRaisesRegex(RuntimeError, 'port'):
                installer.validate_install_options({'port': value})

    def test_reject_unknown_options_and_password_material(self):
        for value in ({'providerPassword': 'secret'}, {'oauthToken': 'secret'},
                      {'launchShell': True}, {'remoteSync': True}):
            with self.subTest(value=value), self.assertRaisesRegex(RuntimeError, 'Unrecognized'):
                installer.validate_install_options(value)

    def test_reject_non_boolean_flags(self):
        for value in ('false', 0, 1, None):
            with self.subTest(value=value), self.assertRaises(RuntimeError):
                installer.validate_install_options({'startAtLogin': value})
                installer.validate_install_options({'openDashboard': value})

    def test_manifest_covers_options_and_detects_tampering(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d)
            options = {'port': 8999, 'startAtLogin': False, 'openDashboard': False}
            raw = (json.dumps(options, indent=2, sort_keys=True)+'\n').encode()
            (p/'INSTALL-OPTIONS.json').write_bytes(raw)
            (p/'INSTALL-MANIFEST.json').write_text(json.dumps({
                'INSTALL-OPTIONS.json': hashlib.sha256(raw).hexdigest()
            }))
            signed = installer.verify(p)
            self.assertEqual(installer.read_install_options(p, signed), options)
            (p/'INSTALL-OPTIONS.json').write_bytes(raw+b'corrupt')
            with self.assertRaisesRegex(RuntimeError, 'integrity failed'):
                installer.verify(p)

    def test_options_without_manifest_are_not_trusted(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d)
            (p/'INSTALL-OPTIONS.json').write_text('{}')
            self.assertRaisesRegex(RuntimeError, 'manifest',
                                   installer.read_install_options, p, {})

    def test_legacy_installer_defaults_non_destructively(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertEqual(installer.read_install_options(Path(d), {}),
                             installer.DEFAULT_INSTALL_OPTIONS)

    def test_nonmac_still_refuses_before_source_inspection(self):
        from unittest import mock
        with mock.patch.object(installer.sys, 'platform', 'linux'):
            with self.assertRaisesRegex(RuntimeError, 'macOS only'):
                installer.install(Path('/nonexistent/no-side-effects'))


if __name__ == '__main__':
    unittest.main()
