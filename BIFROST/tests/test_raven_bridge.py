import subprocess
import tempfile
import time
import unittest
from pathlib import Path

from bifrost.raven_bridge import ACTIONS, ActionError, execute, load_actions, acquire_lock
from bifrost.remote_provider import RemoteProvider


class BridgeAllowlistTests(unittest.TestCase):
    def setUp(self):
        self.p = RemoteProvider(state_dir=Path(tempfile.mkdtemp()), dry_run=True)
        self.ctx = {"provider": self.p, "force_slow": False}

    def test_only_allowlisted_actions(self):
        self.assertEqual(set(ACTIONS), {"power.keepawake.start", "power.keepawake.stop", "bifrost.state.refresh",
                                        "lists.refresh", "codex.cloud.status", "codex.cloud.submit"})
        for bad in ("shell.exec", "remote.provider.start", "", "power.keepawake.start;rm"):
            with self.assertRaises(ActionError):
                execute(self.ctx, bad, {})

    def test_minutes_bounds_and_types(self):
        for bad in (0, 481, -5, 1.5, "60", True, None):
            with self.assertRaises(ActionError):
                execute(self.ctx, "power.keepawake.start", {"minutes": bad})
        with self.assertRaises(ActionError):
            execute(self.ctx, "power.keepawake.start", {"minutes": 5, "cmd": "x"})
        r = execute(self.ctx, "power.keepawake.start", {"minutes": 5})
        self.assertEqual(r["status"], "running")
        self.assertAlmostEqual(r["until"], time.time() + 300, delta=5)

    def test_stop_and_refresh_take_no_params(self):
        with self.assertRaises(ActionError):
            execute(self.ctx, "power.keepawake.stop", {"x": 1})
        execute(self.ctx, "bifrost.state.refresh", {})
        self.assertTrue(self.ctx["force_slow"])

    def test_params_must_be_object(self):
        with self.assertRaises(ActionError):
            execute(self.ctx, "power.keepawake.stop", ["x"])

    def test_catalog_missing_fails_closed(self):
        actions = load_actions(Path(tempfile.mkdtemp()) / "missing.json")
        self.assertEqual(set(actions), {"power.keepawake.start", "power.keepawake.stop", "bifrost.state.refresh"})

    def test_single_instance_lock(self):
        path = Path(tempfile.mkdtemp()) / "bridge.lock"
        first = acquire_lock(path)
        self.addCleanup(first.close)
        with self.assertRaisesRegex(RuntimeError, "already running"):
            acquire_lock(path)


class RealProcessTests(unittest.TestCase):
    """Uses a harmless real child process to prove zombie reaping."""

    def test_exited_child_not_reported_running(self):
        p = RemoteProvider(state_dir=Path(tempfile.mkdtemp()))
        pid = subprocess.Popen(["/bin/sleep", "0.2"]).pid
        p._save({"keep_awake_pid": pid, "keep_awake_until": time.time() + 1})
        self.assertEqual(p.status()["keep_awake"], "running")
        time.sleep(0.6)
        self.assertEqual(p.status()["keep_awake"], "stopped")
        self.assertIsNone(p.status()["keep_awake_until"])


if __name__ == "__main__":
    unittest.main()
