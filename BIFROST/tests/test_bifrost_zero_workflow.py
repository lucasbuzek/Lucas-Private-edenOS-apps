"""ZERO local candidate tests; no Apple account, vendor or system app is called."""
from pathlib import Path
import os
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import bifrost_zero_workflow as zero


class ZeroWorkflowTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.path = Path(self.tmp.name) / 'subfolder' / 'workflow.json'
        self.state = zero.blank()

    def tearDown(self):
        self.tmp.cleanup()

    def test_read_only_empty_state_without_file_creation(self):
        self.assertEqual(zero.load(self.path), zero.blank())
        self.assertFalse(self.path.exists())
        self.assertEqual(zero.plan(self.state)['vendor'], 'UNKNOWN')
        self.assertFalse(zero.plan(self.state)['storesCredentials'])

    def test_local_private_state_persists_and_permissions(self):
        self.assertTrue(zero.decide(self.state, 'apple-guide', ask=lambda _: 'a', path=self.path))
        self.assertEqual(zero.load(self.path)['grants']['apple-guide'], 'allow-all')
        self.assertEqual(stat.S_IMODE(self.path.stat().st_mode), 0o600)
        self.assertEqual(stat.S_IMODE(self.path.parent.stat().st_mode), 0o700)
        self.assertEqual(len(zero.load(self.path)['journal']), 1)

    def test_deny_persists_and_fails_closed(self):
        self.assertFalse(zero.decide(self.state, 'vendor-guide', ask=lambda _: 'd', path=self.path))
        with self.assertRaises(zero.ZeroError):
            zero.decide(self.state, 'vendor-guide', ask=lambda _: '1', path=self.path)
        self.assertEqual(zero.load(self.path)['grants']['vendor-guide'], 'deny')

    def test_allow_once_has_no_persistent_grant(self):
        self.assertTrue(zero.decide(self.state, 'settings', ask=lambda _: '1', path=self.path))
        self.assertFalse(self.path.exists())
        self.assertEqual(self.state['grants'], {})

    def test_denied_action_never_launches_provider(self):
        with mock.patch.object(zero, '_existing_python') as launched:
            self.assertIsNone(zero.permitted_action(self.state, 'vendor', ask=lambda _: 'd', path=self.path))
        launched.assert_not_called()

    def test_native_provider_action_uses_exact_existing_launcher(self):
        with mock.patch.object(zero, '_existing_python', return_value='opened') as launched:
            self.assertEqual(zero.permitted_action(self.state, 'vendor', ask=lambda _: '1', path=self.path), 'opened')
        launched.assert_called_once_with(zero.RDC, ['provider'])
        self.assertEqual(zero.load(self.path)['journal'][-1]['outcome'],
                         'NATIVE_ACTION_COMPLETED_NOT_ACCOUNT_CREATED')

    def test_user_attestation_is_not_provider_verification(self):
        self.assertTrue(zero.attest(self.state, 'apple', ask=lambda _: 'YES', path=self.path))
        self.assertEqual(zero.plan(self.state)['apple'], 'USER_CLAIM_ONLY')
        self.assertEqual(zero.plan(zero.load(self.path))['vendor'], 'UNKNOWN')
        self.assertFalse(zero.load(self.path)['journal'][0]['verifiedProviderAccount'])

    def test_vendor_claim_requires_apple_stage(self):
        with self.assertRaises(zero.ZeroError):
            zero.attest(self.state, 'vendor', ask=lambda _: 'YES', path=self.path)
        self.assertFalse(self.path.exists())

    def test_vendor_decline_creates_no_attestation(self):
        zero.attest(self.state, 'apple', ask=lambda _: 'NO', path=self.path)
        self.assertFalse(self.state['userClaims'])

    def test_unapproved_pairing_never_calls_vendor(self):
        with mock.patch.object(zero, '_existing_python') as vendor:
            with self.assertRaises(zero.ZeroError):
                zero.pair(self.state, ask=lambda _: 'START', path=self.path)
        vendor.assert_not_called()

    def test_pairing_requires_individual_current_start_confirmation(self):
        self.state['userClaims'] = {'apple': {'verification': 'USER_ATTESTED_ONLY'},
                                    'vendor': {'verification': 'USER_ATTESTED_ONLY'}}
        answers = iter(['1', 'CANCEL'])
        with mock.patch.object(zero, '_existing_python') as vendor:
            self.assertFalse(zero.pair(self.state, ask=lambda _: next(answers), path=self.path))
        vendor.assert_not_called()

    def test_explicit_pairing_uses_real_existing_rdc_flow_without_secrets(self):
        self.state['userClaims'] = {'apple': {'verification': 'USER_ATTESTED_ONLY'},
                                    'vendor': {'verification': 'USER_ATTESTED_ONLY'}}
        responses = iter(['1', 'START'])
        with mock.patch.object(zero, '_existing_python', return_value='') as vendor:
            self.assertTrue(zero.pair(self.state, ask=lambda _: next(responses), path=self.path))
        vendor.assert_called_once_with(zero.RDC,
                ['login', '--apple-relay-created', '--rdc-account-created'],
                capture=False, timeout=14400)
        self.assertIn('VERIFICATION_STILL_REQUIRED', zero.load(self.path)['journal'][-1]['outcome'])

    def test_refuses_linked_private_state(self):
        target = Path(self.tmp.name) / 'original.json'
        target.write_text('{}')
        self.path.parent.mkdir(parents=True)
        self.path.symlink_to(target)
        with self.assertRaises(zero.ZeroError):
            zero.load(self.path)
        with self.assertRaises(zero.ZeroError):
            zero.save(self.state, self.path)

    def test_refuses_corrupt_or_unknown_state(self):
        self.path.parent.mkdir(parents=True)
        self.path.write_text('{bad json')
        self.path.chmod(0o600)
        with self.assertRaises(zero.ZeroError):
            zero.load(self.path)
        self.assertEqual(self.path.read_text(), '{bad json')

    def test_refuses_insecure_state_permissions(self):
        zero.save(self.state, self.path)
        self.path.chmod(0o644)
        with self.assertRaises(zero.ZeroError):
            zero.load(self.path)

    def test_existing_python_refuses_missing_or_linked_executables(self):
        with self.assertRaises(zero.ZeroError):
            zero._existing_python(Path(self.tmp.name) / 'absent.py', ['status'])
        file = Path(self.tmp.name) / 'valid.py'
        file.write_text('print("hello")\n')
        alias = Path(self.tmp.name) / 'alias.py'
        alias.symlink_to(file)
        with self.assertRaises(zero.ZeroError):
            zero._existing_python(alias, [])

    def test_private_state_cannot_replace_existing_unsafe_permissions(self):
        zero.save(self.state, self.path)
        self.path.chmod(0o644)
        original = self.path.read_bytes()
        with self.assertRaises(zero.ZeroError):
            zero.save(self.state, self.path)
        self.assertEqual(original, self.path.read_bytes())

    def test_shortcuts_listing_is_ephemeral_and_permissioned(self):
        with mock.patch.object(zero, '_native', return_value='Private Shortcut\n') as native:
            result = zero.permitted_action(self.state, 'shortcuts-list', ask=lambda _: '1', path=self.path)
        self.assertIn('Private Shortcut', result)
        native.assert_called_once_with(['/usr/bin/shortcuts', 'list'])
        self.assertNotIn('Private Shortcut', self.path.read_text())

    def test_core_identity_is_validated(self):
        with mock.patch.object(zero, '_existing_python', return_value='{"schema":"untrusted"}'):
            with self.assertRaises(zero.ZeroError):
                zero.observed()
        with mock.patch.object(zero, '_existing_python', return_value='{"schema":"bifrost.core.runtime-state.v1","headless":{"state":"identity-verified"}}'):
            self.assertEqual(zero.observed()['headless']['state'], 'identity-verified')

    def test_real_local_subprocess_contract_uses_existing_source_path(self):
        local = Path(self.tmp.name) / 'core-fake.py'
        local.write_text('import json; print(json.dumps({"schema": "bifrost.core.runtime-state.v1", "headless": {"state": "identity-verified"}}))\n')
        with mock.patch.object(zero, 'CORE', local):
            status = zero.observed()
        self.assertEqual(status['headless']['state'], 'identity-verified')

    def test_macos_root_owned_var_redirect_is_accepted(self):
        if sys.platform != 'darwin':
            self.skipTest('Only macOS maps /var to /private/var')
        self.assertTrue(Path('/var').is_symlink())
        self.assertEqual(Path('/var').resolve(), Path('/private/var'))
        # The trusted OS redirect must not allow user-managed symlinks.
        zero._safe_path(self.path)
        unsafe = self.path.parent / 'user-link.json'
        unsafe.parent.mkdir(parents=True, exist_ok=True)
        unsafe.symlink_to(Path(self.tmp.name) / 'target.json')
        with self.assertRaises(zero.ZeroError):
            zero._safe_path(unsafe)

    def test_menu_quit_never_calls_external_tool(self):
        with mock.patch.object(zero, '_native') as n, mock.patch.object(zero, '_existing_python') as e:
            self.assertEqual(zero.menu(ask=lambda _: 'q', path=self.path), 0)
        n.assert_not_called()
        e.assert_not_called()


if __name__ == '__main__':
    unittest.main()
