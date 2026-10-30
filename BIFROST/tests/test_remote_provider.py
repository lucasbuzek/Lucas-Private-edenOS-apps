import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

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
        self.assertEqual(self.p.status()["remote"], "stopped")
        self.assertEqual(self.p.status()["keep_awake"], "running")

    def test_keep_awake_is_independent(self):
        self.p.start_keep_awake()
        self.assertEqual(self.p.status()["keep_awake"], "running")
        self.p.stop_keep_awake()
        self.assertEqual(self.p.status()["keep_awake"], "stopped")

    def test_stopped_state_survives_reload_and_provider_availability_changes(self):
        self.p.start_remote()
        self.p.stop_remote()
        reloaded = RemoteProvider(state_dir=self.state_dir, dry_run=True)
        for available in (True, False):
            with mock.patch.object(reloaded, "provider_available", return_value=available):
                self.assertEqual(reloaded.status()["remote"], "stopped")
        reloaded.start_remote()
        self.assertEqual(reloaded.status()["remote"], "running")
        self.assertNotIn("remote_stopped", reloaded._load())

    def test_stale_pid_is_not_hidden_by_stopped_marker(self):
        self.p._save({"remote_pid": 123, "remote_stopped": True})
        with mock.patch.object(self.p, "_alive", return_value=False):
            self.assertEqual(self.p.status()["remote"], "stale")


if __name__ == "__main__":
    unittest.main()
