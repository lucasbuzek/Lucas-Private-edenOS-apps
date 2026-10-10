"""A RavenNest Mac bridge is never a hidden persistent background service.

Only a live BIFROST GUI process may own a manually activated bridge.
Cloudflare's independent Worker is unaffected by this local safeguard.
"""
from __future__ import annotations

from types import SimpleNamespace
from unittest import TestCase
from unittest.mock import patch
import os

from bifrost import raven_bridge


class ManualSessionGuardTests(TestCase):
    def test_missing_or_malformed_owner_fails_before_process_lock(self):
        for value in ("", "0", "-1", "abc", " 123 ", "1" * 20):
            with self.subTest(value=value), patch.dict(
                os.environ, {"BIFROST_RAVEN_SESSION_OWNER_PID": value}
            ):
                with self.assertRaises(RuntimeError):
                    raven_bridge.manual_session_owner()

    def test_running_bifrost_binary_required_not_any_pid(self):
        with patch.dict(os.environ, {"BIFROST_RAVEN_SESSION_OWNER_PID": "22550"}):
            with patch.object(raven_bridge, "owner_alive", return_value=True), patch.object(
                raven_bridge.subprocess, "run",
                return_value=SimpleNamespace(
                    returncode=0,
                    stdout="/private/tmp/BIFROST.app/Contents/MacOS/BIFROST\n",
                ),
            ):
                self.assertEqual(raven_bridge.manual_session_owner(), 22550)
            with patch.object(raven_bridge, "owner_alive", return_value=True), patch.object(
                raven_bridge.subprocess, "run",
                return_value=SimpleNamespace(returncode=0, stdout="/bin/zsh\n"),
            ):
                with self.assertRaisesRegex(RuntimeError, "not the BIFROST"):
                    raven_bridge.manual_session_owner()

    def test_dead_owner_aborts_before_bridge_launch(self):
        with patch.dict(os.environ, {"BIFROST_RAVEN_SESSION_OWNER_PID": "22550"}):
            with patch.object(raven_bridge, "owner_alive", return_value=False):
                with self.assertRaisesRegex(RuntimeError, "not running"):
                    raven_bridge.run_forever()

    def test_sleep_loop_stops_with_owner_disappearance(self):
        with patch.object(
            raven_bridge, "owner_alive", side_effect=[True, False]
        ), patch("time.sleep") as sleep:
            self.assertFalse(raven_bridge.wait_while_owned(9, 22550))
            sleep.assert_called_once_with(3.0)

    def test_live_owner_requires_no_extra_background_watcher(self):
        with patch.object(raven_bridge, "owner_alive", return_value=True), patch(
            "time.sleep"
        ) as sleep:
            self.assertTrue(raven_bridge.wait_while_owned(7, 22550))
            self.assertEqual([c.args[0] for c in sleep.call_args_list], [3.0, 3.0, 1.0])
