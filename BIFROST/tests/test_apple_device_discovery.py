"""Apple CoreDevice discovery must not pretend device observation is pairing."""
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'headless'))
import apple_device_discovery as adapter


class CoreDeviceTests(unittest.TestCase):
    def test_foreign_host_cannot_invoke_xcrun(self):
        with mock.patch.object(adapter.subprocess, 'run') as run:
            r = adapter.inspect(system='Linux')
        self.assertEqual(r['status'], 'unsupported-host')
        run.assert_not_called()

    def test_missing_cli_has_no_side_effects(self):
        with mock.patch.object(adapter.subprocess, 'run') as run:
            r = adapter.inspect(system='Darwin', xcrun='/nonexistent-BIFROST-xcrun')
        self.assertEqual(r['status'], 'xcode-command-line-tools-unavailable')
        run.assert_not_called()

    def test_current_apple_json_observation_redacts_identifiers(self):
        value = {"result": {"devices": [{
            "identifier": "SENSITIVE-UDID", "deviceProperties": {"name": "PRIVATE PHONE"},
            "properties": {"hardware": {"productType": "iPhone16,2"},
                           "connection": {"transportType": "usb", "serialNumber": "SECRET"}}
        }]}}
        def runner(args, **kwargs):
            self.assertEqual(args[1:5], ['devicectl','list','devices','--json-output'])
            Path(args[5]).write_text(json.dumps(value), encoding='utf-8')
            return type('Completed', (), {'returncode': 0})()
        with tempfile.TemporaryDirectory() as temp:
            cli = Path(temp) / 'xcrun'; cli.write_text('test', encoding='utf-8')
            r = adapter.inspect(system='Darwin', xcrun=cli, run=runner)
        self.assertEqual(r['deviceCount'], 1)
        self.assertEqual(r['devices'][0]['kind'], 'iPhone16,2')
        self.assertEqual(r['devices'][0]['transport'], 'usb')
        self.assertEqual(r['devices'][0]['edenTrust'], 'not-established')
        self.assertNotIn('SENSITIVE-UDID', json.dumps(r))
        self.assertNotIn('PRIVATE PHONE', json.dumps(r))
        self.assertNotIn('SECRET', json.dumps(r))

    def test_invalid_json_or_malformed_device_list_fails_closed(self):
        for payload in ('{bad', json.dumps({'result': {'devices': {}}}),
                        json.dumps({'result': {'devices': [{}] * 65}})):
            def runner(args, **kwargs):
                Path(args[5]).write_text(payload, encoding='utf-8')
                return type('Completed', (), {'returncode': 0})()
            with tempfile.TemporaryDirectory() as temp:
                cli = Path(temp) / 'xcrun'; cli.write_text('test', encoding='utf-8')
                result = adapter.inspect(system='Darwin', xcrun=cli, run=runner)
            self.assertEqual(result['status'], 'discovery-unavailable')
            self.assertFalse(result['observed'])

    def test_failed_runner_does_not_claim_device_missing(self):
        with tempfile.TemporaryDirectory() as temp:
            cli = Path(temp) / 'xcrun'; cli.write_text('test', encoding='utf-8')
            r=adapter.inspect(system='Darwin',xcrun=cli,run=lambda *a,**k: type('Completed',(),{'returncode':5})())
        self.assertEqual(r['status'], 'devicectl-failed')
        self.assertEqual(r['connected'], 'unknown')
        self.assertFalse(r['observed'])

    def test_bounded_non_identifying_labels(self):
        value={"result":{"devices":[{"hardwareProperties":{"productType":"iPhone-escaped\nIdentifier"},"connectionProperties":{"transportType":"wifi;bad"}}]}}
        parsed=adapter._view(value)
        self.assertEqual(parsed['devices'][0]['kind'],'unknown')
        self.assertEqual(parsed['devices'][0]['transport'],'unknown')


if __name__ == '__main__': unittest.main()
