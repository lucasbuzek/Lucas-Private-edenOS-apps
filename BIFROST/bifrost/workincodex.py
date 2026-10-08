"""Guarded WORKinCODEX cloud submission transport for the Raven device node.

False positives deliberately escalate. This module never applies a task, pushes,
merges, deletes, or locally executes a submitted workload.
"""
from __future__ import annotations

import fnmatch
import hashlib
import json
import os
import re
import shlex
import subprocess
import time
from pathlib import Path

from .list_collectors import TASK_RE, _run

DEFAULT_ENVIRONMENTS = ("lucas-Private-edenOS-apps",)
DEFAULT_BRANCHES = ("bifrost/*", "swaycore-*", "dev/*")
SECRET_RULES = (
    ("private-key", re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
    ("provider-token", re.compile(r"\b(?:ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,}|xox[a-z]-[A-Za-z0-9-]{20,})")),
    ("aws-access-key", re.compile(r"\b(?:AKIA|ASIA)[A-Z0-9]{16}\b")),
    ("bearer-token", re.compile(r"\bBearer\s+[A-Za-z0-9._~+/=-]{20,}", re.I)),
    ("secret-assignment", re.compile(r"\b(?:password|secret|token)\s*[:=]\s*['\"]?[^\s'\"]{16,}", re.I)),
)
PROHIBITED = re.compile(
    r"(?i)\b(?:run|execute|do|perform|please|must|should|then|and)\b[^\n]{0,80}"
    r"(?:codex\s+cloud\s+apply|git\s+push|push\b|merge\b|delete\b|billing\b|authentication\b|security\b)"
)
APPLESCRIPT = '''on run argv
tell application "Terminal"
activate
do script (item 1 of argv)
end tell
end run'''


class Escalation(ValueError):
    pass


class Submitter:
    def __init__(self, home=None, handoff_root=None, clock=time.time, sleep=time.sleep,
                 run=_run, subprocess_run=subprocess.run, poll_seconds=180):
        self.home = Path(home or Path.home())
        self.handoff_root = Path(handoff_root or self.home / "edenOS/AppDev/#handoffs")
        self.clock, self.sleep, self.run = clock, sleep, run
        self.subprocess_run = subprocess_run
        self.poll_seconds = poll_seconds
        self.state_path = self.home / "Library/Application Support/BIFROST/submissions.jsonl"
        self.audit_path = self.home / "Library/Logs/BIFROST/codex-submissions.jsonl"

    def _records(self):
        try:
            return [json.loads(x) for x in self.state_path.read_text().splitlines() if x.strip()]
        except (FileNotFoundError, json.JSONDecodeError):
            return []

    def clear_block(self):
        """Lucas-only local acknowledgement: clear persisted limiter/failure history."""
        self.state_path.unlink(missing_ok=True)

    def _record(self, record):
        self.state_path.parent.mkdir(parents=True, exist_ok=True)
        with self.state_path.open("a", encoding="utf-8") as f:
            f.write(json.dumps(record, sort_keys=True) + "\n")

    def _audit(self, record):
        self.audit_path.parent.mkdir(parents=True, exist_ok=True)
        with self.audit_path.open("a", encoding="utf-8") as f:
            f.write(json.dumps(record, sort_keys=True) + "\n")

    def _refuse(self, reason):
        return {"ok": False, "escalate": True, "reason": "needs_attended: " + reason}

    def _identity_env(self, identity):
        env = dict(os.environ)
        if identity == 1:
            return env
        path = self.home / (".codex-second" if identity == 2 else f".codex-{identity}")
        if not path.is_dir():
            raise Escalation(f"isolated identity {identity} home does not exist")
        env["CODEX_HOME"] = str(path)
        return env

    def _guard(self, params):
        raw_path = Path(params["handoff_path"]).expanduser()
        root = self.handoff_root.expanduser().resolve(strict=True)
        path = raw_path.resolve(strict=True)
        if not path.is_file() or not path.is_relative_to(root):
            raise Escalation("handoff is not a regular file inside the approved handoff root")
        data = path.read_bytes()
        if hashlib.sha256(data).hexdigest() != params["sha256"]:
            raise Escalation("handoff SHA-256 mismatch")
        try:
            text = data.decode("utf-8")
        except UnicodeDecodeError:
            raise Escalation("handoff is not UTF-8 text") from None
        if len(text) > 100_000:
            raise Escalation("handoff exceeds 100,000 characters")
        if params["env"] not in DEFAULT_ENVIRONMENTS:
            raise Escalation("environment is not allowlisted")
        if not any(fnmatch.fnmatchcase(params["branch"], pattern) for pattern in DEFAULT_BRANCHES):
            raise Escalation("branch is not allowlisted")
        if params["scope_guard"] not in text:
            raise Escalation("scope guard is absent; scope is ambiguous")
        for line_no, line in enumerate(text.splitlines(), 1):
            for name, regex in SECRET_RULES:
                if regex.search(line):
                    raise Escalation(f"secret scan matched {name} on line {line_no}")
        if PROHIBITED.search(text):
            raise Escalation("handoff requests an attended-only or sensitive operation")
        records = self._records()
        hour_ago = self.clock() - 3600
        if sum(bool(r.get("time", 0) >= hour_ago and r.get("attempted")) for r in records) >= 3:
            raise Escalation("rolling limit of 3 submissions per hour reached")
        if any(r.get("outcome") == "RATE_LIMITED" for r in records):
            raise Escalation("a prior attempt recorded provider rate limiting; clear locally after review")
        if len(records) >= 2 and all(r.get("outcome") == "FAILED" for r in records[-2:]):
            raise Escalation("two consecutive failures; clear locally after review")
        return path, text, self._identity_env(params["identity"])

    @staticmethod
    def _task_ids(output):
        return set(TASK_RE.findall(output))

    def _list(self, env):
        code, out = self.run(["codex", "cloud", "list", "--limit", "20"], 60, env)
        if code != 0:
            if "429" in out or "rate limit" in out.lower():
                raise Escalation("provider rate-limited the verification list")
            raise Escalation("Codex cloud list unavailable for start verification")
        return self._task_ids(out)

    def _terminal(self, command):
        previous = self.subprocess_run(["/usr/bin/pbpaste"], capture_output=True, text=True,
                                       timeout=10, check=False).stdout
        try:
            self.subprocess_run(["/usr/bin/pbcopy"], input=command, text=True, timeout=10, check=True)
            self.subprocess_run(["/usr/bin/osascript", "-e", APPLESCRIPT, command],
                                text=True, capture_output=True, timeout=20, check=True)
        finally:
            self.subprocess_run(["/usr/bin/pbcopy"], input=previous, text=True,
                                timeout=10, check=False)

    def submit(self, params, initiator):
        try:
            path, _text, env = self._guard(params)
            before = self._list(env)
        except (Escalation, KeyError, OSError) as exc:
            if "rate-limit" in str(exc):
                self._record({"time": self.clock(), "outcome": "RATE_LIMITED"})
            return self._refuse(str(exc))
        # POSIX-safe quoting is validated again by round-tripping each argument.
        env_value, branch = params["env"], params["branch"]
        if not re.fullmatch(r"[A-Za-z0-9_.-]{1,64}", env_value) or not re.fullmatch(r"[A-Za-z0-9._/-]{1,120}", branch):
            return self._refuse("environment or branch contains invalid characters")
        command = (f"codex cloud exec --env {shlex.quote(env_value)} --branch {shlex.quote(branch)} "
                   f"\"$(cat {shlex.quote(str(path))})\"")
        now = self.clock()
        base = {"time": now, "initiator": str(initiator)[:200], "sha256": params["sha256"],
                "env": env_value, "branch": branch, "identity": params["identity"]}
        try:
            self._terminal(command)
            self._record({"time": now, "attempted": True, "outcome": "SUBMITTED",
                          "sha256": params["sha256"]})
            deadline, task_id = self.clock() + self.poll_seconds, None
            while self.clock() <= deadline:
                code, out = self.run(["codex", "cloud", "list", "--limit", "20"], 60, env)
                if code and ("429" in out or "rate limit" in out.lower()):
                    self._record({"time": self.clock(), "outcome": "RATE_LIMITED"})
                    break
                new = self._task_ids(out) - before if code == 0 else set()
                if new:
                    task_id = sorted(new)[0]
                    break
                if self.clock() >= deadline:
                    break
                self.sleep(min(10, deadline - self.clock()))
            outcome = "STARTED" if task_id else "SUBMITTED_UNVERIFIED"
        except Exception as exc:  # noqa: BLE001
            outcome, task_id = "FAILED", None
            self._record({"time": self.clock(), "outcome": "FAILED"})
            result = {**base, "outcome": outcome, "task_id": task_id}
            self._audit(result)
            return {"ok": False, **result, "reason": f"submission transport failed: {type(exc).__name__}"}
        result = {**base, "outcome": outcome, "task_id": task_id}
        self._audit(result)
        return {"ok": True, **result}
