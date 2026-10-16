import unittest
from adapter import summarize_sessions, observe_wait_state


class MobileCLITests(unittest.TestCase):
    def test_sessions_redact_paths_commands_identifiers(self):
        x = summarize_sessions({"type": "sessions", "sessions": [
            {"session_id": "secret-session", "cli_type": "codex", "command": "sh private.sh",
             "project_path": "/private/home"},
            {"session_id": "other", "cli_type": "claude"}]})
        self.assertEqual(x["sessions"], 2)
        self.assertEqual(x["cli_counts"]["codex"], 1)
        self.assertFalse(x["enabled"])
        self.assertNotIn("secret-session", repr(x))
        self.assertNotIn("/private/home", repr(x))

    def test_wrong_event_rejected(self):
        with self.assertRaises(ValueError):
            summarize_sessions({"type": "spawn_result", "sessions": []})

    def test_invalid_cli_rejected(self):
        with self.assertRaises(ValueError):
            summarize_sessions({"type": "sessions", "sessions": [{"cli_type": "root_shell"}]})

    def test_session_count_bounded(self):
        with self.assertRaises(ValueError):
            summarize_sessions({"type": "sessions", "sessions": [{}] * 101})

    def test_wait_state_not_authorization(self):
        x = observe_wait_state({"type": "waiting_for_input", "cli_type": "codex",
                                "wait_type": "tool_approval", "session_id": "secret",
                                "prompt_content": "private credentials"})
        self.assertEqual(x["authorization"], "none")
        self.assertEqual(x["execution_status"], "unknown")
        self.assertNotIn("credentials", repr(x))

    def test_unknown_wait_rejected(self):
        with self.assertRaises(ValueError):
            observe_wait_state({"type": "waiting_for_input", "cli_type": "codex", "wait_type": "execute"})
