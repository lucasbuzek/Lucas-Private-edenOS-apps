import unittest
from adapter import inspect_endpoint


class OpenHandsTests(unittest.TestCase):
    def test_explicit_loopback(self):
        x = inspect_endpoint("http://127.0.0.1:8000")
        self.assertEqual(x["endpoint"], "http://127.0.0.1:8000")
        self.assertFalse(x["enabled"])
        self.assertEqual(x["sandbox"], "unverified")

    def test_public_host_blocked(self):
        with self.assertRaises(ValueError):
            inspect_endpoint("http://0.0.0.0:8000")

    def test_remote_host_blocked(self):
        with self.assertRaises(ValueError):
            inspect_endpoint("https://agents.example.com:443")

    def test_embedded_credentials_blocked(self):
        with self.assertRaises(ValueError):
            inspect_endpoint("http://user:password@127.0.0.1:8000")

    def test_unexpected_path_blocked(self):
        with self.assertRaises(ValueError):
            inspect_endpoint("http://127.0.0.1:8000/api/commands")
