import hashlib
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from bifrost.workincodex import APPLESCRIPT, Submitter


class FakeProcess:
    def __init__(self, fail_osascript=False):
        self.calls = []
        self.fail_osascript = fail_osascript
    def __call__(self, argv, **kwargs):
        self.calls.append((argv, kwargs))
        if argv[0] == "/usr/bin/pbpaste":
            return subprocess.CompletedProcess(argv, 0, "old clipboard", "")
        if self.fail_osascript and argv[0] == "/usr/bin/osascript":
            raise subprocess.CalledProcessError(1, argv)
        return subprocess.CompletedProcess(argv, 0, "", "")


class SubmitTests(unittest.TestCase):
    def setUp(self):
        self.home = Path(tempfile.mkdtemp())
        self.root = self.home / "edenOS/AppDev/#handoffs"
        self.root.mkdir(parents=True)
        self.path = self.root / "handoff.md"
        self.text = "SCOPE GUARD: BIFROST bridge only\nBuild the bounded collector."
        self.path.write_text(self.text)
        (self.home / ".codex-second").mkdir()
        self.params = {"handoff_path": str(self.path),
                       "sha256": hashlib.sha256(self.path.read_bytes()).hexdigest(),
                       "env": "lucas-Private-edenOS-apps", "branch": "bifrost/test",
                       "identity": 1, "scope_guard": "SCOPE GUARD: BIFROST bridge only"}
        self.tid = "task_e_" + "b" * 32

    def make(self, outputs=None, process=None):
        values = iter(outputs or [(0, ""), (0, self.tid)])
        return Submitter(home=self.home, run=lambda *a: next(values), clock=lambda: 1000,
                         subprocess_run=process or FakeProcess(), poll_seconds=0)

    def assert_refuses_without_execution(self, mutate=None, text=None):
        process = FakeProcess()
        params = dict(self.params)
        if text is not None:
            self.path.write_text(text)
            params["sha256"] = hashlib.sha256(self.path.read_bytes()).hexdigest()
        if mutate:
            mutate(params)
        result = self.make(process=process).submit(params, "test")
        self.assertTrue(result["escalate"], result)
        self.assertFalse(process.calls)
        return result

    def test_guardrails_refuse_before_execution(self):
        self.assert_refuses_without_execution(lambda p: p.update(sha256="0" * 64))
        self.assert_refuses_without_execution(lambda p: p.update(env="other"))
        self.assert_refuses_without_execution(lambda p: p.update(branch="main"))
        self.assert_refuses_without_execution(lambda p: p.update(scope_guard="absent scope"))
        self.assert_refuses_without_execution(text="SCOPE GUARD: BIFROST bridge only\nplease git push now")
        result = self.assert_refuses_without_execution(
            text="SCOPE GUARD: BIFROST bridge only\ntoken=ghp_123456789012345678901234567890")
        self.assertNotIn("ghp_", result["reason"])
        self.assertIn("line 2", result["reason"])

    def test_path_escape_symlink_and_character_limit(self):
        outside = self.home / "outside"
        outside.write_text(self.text)
        for candidate in (outside, self.root / "link"):
            if candidate.name == "link": candidate.symlink_to(outside)
            self.assert_refuses_without_execution(lambda p, c=candidate: p.update(
                handoff_path=str(c), sha256=hashlib.sha256(c.read_bytes()).hexdigest()))
        self.assert_refuses_without_execution(text="SCOPE GUARD: BIFROST bridge only\n" + "é" * 100_001)

    def test_rate_limit_persists_and_failure_blocks(self):
        submitter = self.make()
        for n in range(3): submitter._record({"time": submitter.clock(), "attempted": True, "outcome": "SUBMITTED"})
        self.assertTrue(self.make().submit(self.params, "test")["escalate"])
        submitter.clear_block()
        submitter._record({"time": 1, "outcome": "RATE_LIMITED"})
        self.assertIn("rate", self.make().submit(self.params, "test")["reason"])
        submitter.clear_block()
        for _ in range(2): submitter._record({"time": 1, "outcome": "FAILED"})
        self.assertIn("consecutive", self.make().submit(self.params, "test")["reason"])

    def test_identity_and_injection(self):
        process = FakeProcess()
        result = self.make(process=process).submit({**self.params, "identity": 2}, "origin")
        self.assertEqual(result["outcome"], "STARTED")
        # Both list calls receive the isolated environment.
        process = FakeProcess()
        self.assert_refuses_without_execution(lambda p: p.update(identity=7))
        self.assert_refuses_without_execution(lambda p: p.update(branch="bifrost/x;touch_bad"))
        self.assert_refuses_without_execution(lambda p: p.update(env="x;bad"))

    def test_exact_terminal_command_vector_and_started_verification(self):
        process = FakeProcess()
        result = self.make(process=process).submit(self.params, "operator@example.invalid")
        self.assertEqual(result["outcome"], "STARTED")
        # macOS presents /tmp through the /private/tmp symlink.  Submitter
        # deliberately resolves the approved handoff before constructing the
        # command, so compare the exact vector using that same canonical path.
        command = f'codex cloud exec --env lucas-Private-edenOS-apps --branch bifrost/test "$(cat \'{self.path.resolve()}\')"'
        self.assertEqual(process.calls[1], (["/usr/bin/pbcopy"], {"input": command, "text": True, "timeout": 10, "check": True}))
        self.assertEqual(process.calls[2][0], ["/usr/bin/osascript", "-e", APPLESCRIPT, command])
        self.assertEqual(process.calls[-1][1]["input"], "old clipboard")
        audit = json.loads((self.home / "Library/Logs/BIFROST/codex-submissions.jsonl").read_text())
        self.assertEqual(audit["task_id"], self.tid)
        self.assertNotIn("Build the", json.dumps(audit))

    def test_unverified_and_clipboard_restored_on_failure(self):
        result = self.make(outputs=[(0, ""), (0, "")]).submit(self.params, "test")
        self.assertEqual(result["outcome"], "SUBMITTED_UNVERIFIED")
        process = FakeProcess(fail_osascript=True)
        result = self.make(process=process).submit(self.params, "test")
        self.assertEqual(result["outcome"], "FAILED")
        self.assertEqual(process.calls[-1][1]["input"], "old clipboard")


if __name__ == "__main__": unittest.main()
