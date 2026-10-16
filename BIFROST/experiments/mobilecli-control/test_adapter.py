import unittest
from adapter import summarize_devices


class MobileCLITests(unittest.TestCase):
    def test_inventory_summary_redacts_identifiers(self):
        result = summarize_devices({"status": "ok", "data": {"devices": [
            {"id": "PRIVATE-UDID", "name": "Private iPhone", "platform": "ios", "state": "online"},
            {"platform": "android", "state": "offline"}]}})
        self.assertEqual(result["counts"], {"ios": 1, "android": 1, "online": 1, "offline": 1})
        self.assertNotIn("PRIVATE-UDID", repr(result))
        self.assertFalse(result["enabled"])

    def test_error_response_rejected(self):
        with self.assertRaises(ValueError):
            summarize_devices({"status": "error", "error": "offline"})

    def test_invalid_device_rejected(self):
        with self.assertRaises(ValueError):
            summarize_devices({"status": "ok", "data": {"devices": ["bad"]}})

    def test_unsupported_platform_rejected(self):
        with self.assertRaises(ValueError):
            summarize_devices({"status": "ok", "data": {"devices": [{"platform": "remote", "state": "online"}]}})

    def test_inventory_bounded(self):
        with self.assertRaises(ValueError):
            summarize_devices({"status": "ok", "data": {"devices": [{}] * 101}})
