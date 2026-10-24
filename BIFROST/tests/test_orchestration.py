"""BIFROST orchestration tests: no real Shortcuts, Automator or personal files run."""
import http.client
import json
import os
from pathlib import Path
import sys
import tempfile
import threading
import unittest
from unittest import mock
from http.server import ThreadingHTTPServer

BASE = Path(__file__).resolve().parents[1] / "headless"
sys.path.insert(0, str(BASE))
import orchestration as orch
import server


class OrchestrationRules(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.home = Path(self.tmp.name).resolve()
        self.support = self.home / "Library/Application Support/BIFROST"
        self.support.mkdir(parents=True)
        self.folder = self.home / "Approved Folder"
        self.folder.mkdir()
        self.record = self.support / "orchestration-rule.json"

    def tearDown(self):
        self.tmp.cleanup()

    def save(self, enabled=False):
        self.record.write_text(json.dumps({
            "schema":orch.SCHEMA, "enabled":enabled,
            "folder":str(self.folder), "shortcut":"Reviewed Sample"
        }))
        self.record.chmod(0o600)

    def test_no_default_folder_or_execution(self):
        engine = orch.Orchestrator(self.support)
        self.assertIsNone(engine.status()["rule"])
        self.assertFalse(engine.status()["serviceActive"])
        with mock.patch.object(orch, "discover_shortcuts", return_value=[]):
            with mock.patch.object(orch.subprocess, "run") as process:
                with self.assertRaises(ValueError):
                    engine.run("shortcut", "unlisted")
                with self.assertRaises(ValueError):
                    engine.run("shell", "/bin/sh")
                process.assert_not_called()

    def test_approved_folder_private_record_and_symlink_defenses(self):
        self.save(enabled=True)
        with mock.patch.object(orch, "discover_shortcuts", return_value=["Reviewed Sample"]):
            rule, error = orch.load_rule(self.support, self.home)
            self.assertIsNone(error)
            self.assertTrue(rule["enabled"])
            self.record.chmod(0o644)
            rule, error = orch.load_rule(self.support, self.home)
            self.assertIsNone(rule)
            self.assertIn("private", error)
            self.record.chmod(0o600)
            self.folder.rename(self.home / "Moved Folder")
            self.folder.symlink_to(self.home / "Moved Folder")
            rule, error = orch.load_rule(self.support, self.home)
            self.assertIsNone(rule)
            self.assertIn("Folder", error)

    def test_idle_rule_check_does_not_launch_shortcuts_catalog(self):
        self.save(enabled=True)
        with mock.patch.object(orch, "_safe_folder", return_value=self.folder), \
             mock.patch.object(orch, "discover_shortcuts") as discovered:
            rule, error = orch.load_rule(self.support, check_catalog=False)
            self.assertIsNone(error)
            self.assertTrue(rule["enabled"])
            discovered.assert_not_called()
        # Execution still refuses a missing installed Shortcut.
        engine = orch.Orchestrator(self.support)
        with mock.patch.object(orch, "discover_shortcuts", return_value=[]), \
             mock.patch.object(orch.subprocess, "run") as process:
            with self.assertRaises(ValueError):
                engine.run("shortcut", "Reviewed Sample", source="native-folder")
            process.assert_not_called()

    def test_shallow_watch_metadata_not_file_contents(self):
        (self.folder / "new.txt").write_text("private contents")
        (self.folder / ".hidden").write_text("secret")
        (self.folder / "alias").symlink_to(self.folder / "new.txt")
        (self.folder / "nested").mkdir()
        snapshot = orch._snapshot(self.folder)
        self.assertEqual(set(snapshot), {"new.txt"})

    def test_bounded_exact_saved_shortcut_and_receipt(self):
        engine = orch.Orchestrator(self.support)
        successful = mock.Mock(returncode=0)
        with mock.patch.object(orch.sys, "platform", "darwin"), \
             mock.patch.object(orch, "discover_shortcuts", return_value=["Reviewed Sample"]), \
             mock.patch.object(orch.subprocess, "run", return_value=successful) as process:
            receipt = engine.run("shortcut", "Reviewed Sample")
            args, kwargs = process.call_args
            self.assertEqual(args[0], ["/usr/bin/shortcuts", "run", "Reviewed Sample"])
            self.assertEqual(kwargs["timeout"], 60)
            self.assertIs(kwargs["stdout"], orch.subprocess.DEVNULL)
            self.assertFalse(receipt["effectsVerified"])
            self.assertEqual(receipt["source"], "browser")
            with self.assertRaises(ValueError):
                engine.run("shortcut", "Other Shortcut")
        ledger = self.support / "orchestration-runs.jsonl"
        self.assertTrue(ledger.is_file())
        self.assertEqual(ledger.stat().st_mode & 0o077, 0)

    def test_opt_in_watcher_baselines_before_trigger(self):
        engine = orch.Orchestrator(self.support)
        self.save(enabled=True)
        calls = iter([{}, {"new.txt": (1, 9, 5)}, {"new.txt": (1, 9, 5)}])
        count = 0
        def wait(_seconds):
            nonlocal count
            count += 1
            return count > 3
        engine.stop_event = mock.Mock(wait=wait)
        with mock.patch.object(orch, "load_rule", return_value=({
            "folder":str(self.folder), "shortcut":"Reviewed Sample", "enabled":True
        }, None)), mock.patch.object(orch, "_snapshot", side_effect=lambda _: next(calls)), \
             mock.patch.object(engine, "run") as run:
            engine._loop()
            run.assert_called_once_with("shortcut", "Reviewed Sample", source="native-folder")
        self.assertFalse(engine.active)


class OrchestrationHTTP(unittest.TestCase):
    def test_local_browser_needs_session_and_exact_confirmation(self):
        with tempfile.TemporaryDirectory() as temp:
            previous = (server.PORT, server.SUPPORT, server.KEYFILE, server.ORCHESTRATOR)
            server.SUPPORT = Path(temp)
            server.KEYFILE = Path(temp) / "headless.token"
            server.ORCHESTRATOR = orch.Orchestrator(Path(temp))
            listener = ThreadingHTTPServer(("127.0.0.1", 0), server.Handler)
            server.PORT = listener.server_port
            thread = threading.Thread(target=listener.serve_forever, daemon=True)
            thread.start()
            def call(method, path, value=None, headers=None):
                conn = http.client.HTTPConnection("127.0.0.1", server.PORT, timeout=3)
                payload = json.dumps(value) if value is not None else None
                conn.request(method, path, body=payload, headers=headers or {})
                response = conn.getresponse()
                data = json.loads(response.read())
                conn.close()
                return response.status, data
            try:
                self.assertEqual(call("GET", "/api/orchestration/v1")[0], 403)
                token = call("GET", "/api/session")[1]["token"]
                auth = {"X-Bifrost-Token":token}
                with mock.patch.object(orch, "catalog", return_value={"shortcuts":[]}):
                    code, data = call("GET", "/api/orchestration/v1", headers=auth)
                self.assertEqual(code, 200)
                self.assertFalse(data["status"]["serviceActive"])
                attempted = {"action":"workflow.run", "kind":"shortcut",
                             "id":"Reviewed Sample", "confirmed":True}
                self.assertEqual(call("POST", "/api/orchestration/v1", attempted)[0], 403)
                self.assertEqual(call("POST", "/api/orchestration/v1",
                                      {**attempted, "confirmed":False}, auth)[0], 400)
                with mock.patch.object(server.ORCHESTRATOR, "run",
                                       return_value={"exitStatus":0,"effectsVerified":False}) as run:
                    code, data = call("POST", "/api/orchestration/v1", attempted, auth)
                    self.assertEqual(code, 200)
                    self.assertFalse(data["receipt"]["effectsVerified"])
                    run.assert_called_once_with("shortcut", "Reviewed Sample")
                    code, _ = call("POST", "/api/orchestration/v1", attempted,
                                   {**auth,"Origin":"https://bad.example"})
                    self.assertEqual(code, 403)
                    self.assertEqual(run.call_count, 1)
            finally:
                listener.shutdown()
                listener.server_close()
                thread.join(timeout=2)
                server.PORT, server.SUPPORT, server.KEYFILE, server.ORCHESTRATOR = previous


if __name__ == "__main__":
    unittest.main()

