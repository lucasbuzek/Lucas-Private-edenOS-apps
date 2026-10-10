import os
import tempfile
import unittest
from pathlib import Path

from bifrost.remote_provider import RemoteProvider


class RemoteProviderTests(unittest.TestCase):
    def setUp(self):
        self.state_dir = Path(tempfile.mkdtemp())
        self.p = RemoteProvider(state_dir=self.state_dir, dry_run=True)

    def test_status_is_truthful_when_not_managed(self):
        status = self.p.status()
        self.assertIn(status["remote"], {"available", "unavailable", "stopped"})
        self.assertEqual(status["keep_awake"], "stopped")

    def test_remote_start_is_idempotent(self):
        first = self.p.start_remote()
        second = self.p.start_remote()
        self.assertEqual(first["pid"], second["pid"])
        self.assertEqual(self.p.status()["remote"], "running")

    def test_remote_stop_does_not_stop_keep_awake(self):
        self.p.start_keep_awake()
        self.p.start_remote()
        self.p.stop_remote()
        # After stop, status reports the provider as not running: "available"
        # (provider present, nothing managed) per RemoteProvider.status().
        self.assertIn(self.p.status()["remote"], {"available", "unavailable"})
        self.assertEqual(self.p.status()["keep_awake"], "running")

    def test_keep_awake_is_independent(self):
        self.p.start_keep_awake()
        self.assertEqual(self.p.status()["keep_awake"], "running")
        self.p.stop_keep_awake()
        self.assertEqual(self.p.status()["keep_awake"], "stopped")


if __name__ == "__main__":
    unittest.main()
