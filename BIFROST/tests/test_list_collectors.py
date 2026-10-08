import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from bifrost import list_collectors as lc


class ListCollectorTests(unittest.TestCase):
    def test_codex_parsing_and_failures(self):
        tid = "task_e_" + "a" * 32
        with mock.patch.object(lc, "_run", return_value=(0, f"{tid}  Title  env  RUNNING  2m")):
            item = lc.codex_tasks()["items"][0]
        self.assertEqual(item["task_id"], tid)
        with mock.patch.object(lc, "_run", return_value=(124, "timeout")):
            self.assertEqual(lc.codex_tasks()["status"], "UNKNOWN")
        with mock.patch.object(lc, "_run", return_value=(1, "429 rate limit")):
            self.assertEqual(lc.codex_tasks()["status"], "ERROR")

    def test_claude_reads_metadata_only_and_bounds(self):
        home = Path(tempfile.mkdtemp())
        project = home / ".claude/projects/project-a"
        project.mkdir(parents=True)
        for n in range(55):
            (project / f"session-{n}.jsonl").write_text("SECRET CONVERSATION")
        cap = lc.claude_sessions(home)
        self.assertEqual(len(cap["items"]), 50)
        self.assertNotIn("SECRET", json.dumps(cap))

    def test_chatgpt_export_omits_messages_and_limits_size(self):
        home = Path(tempfile.mkdtemp())
        path = home / "edenOS/Imports/chatgpt-export/conversations.json"
        path.parent.mkdir(parents=True)
        path.write_text(json.dumps([{"title": "Visible", "create_time": 2, "mapping": "SECRET"}]))
        cap = lc.chatgpt_chats(home, False)
        self.assertEqual(cap["items"], [{"title": "Visible", "create_time": 2}])
        with mock.patch.object(lc, "CHATGPT_MAX_BYTES", 1):
            self.assertEqual(lc.chatgpt_chats(home, False)["status"], "ERROR")

    def test_chatgpt_not_configured_and_accessibility_permission(self):
        self.assertEqual(lc.chatgpt_chats(Path(tempfile.mkdtemp()), False)["status"], "NOT_CONFIGURED")
        with mock.patch.object(lc, "_run", return_value=(1, "not authorized permission")) as run:
            cap = lc.chatgpt_chats(app_enabled=True)
        self.assertEqual(cap["status"], "PERMISSION_REQUIRED")
        self.assertEqual(run.call_args.args[0][0], "/usr/bin/osascript")


if __name__ == "__main__":
    unittest.main()
