"""Lifecycle adapter for BIFROST's current remote bridge and macOS power assertion."""
from __future__ import annotations

import json
import os
import shutil
import signal
import subprocess
from pathlib import Path


class RemoteProvider:
    def __init__(self, state_dir: Path | None = None, dry_run: bool = False):
        self.state_dir = Path(state_dir or Path.home() / ".eden" / "bifrost")
        self.state_file = self.state_dir / "remote-provider.json"
        self.dry_run = dry_run
        self._fake_pid = 41000

    def _load(self):
        try:
            return json.loads(self.state_file.read_text())
        except (FileNotFoundError, json.JSONDecodeError):
            return {}

    def _save(self, state):
        self.state_dir.mkdir(parents=True, exist_ok=True)
        tmp = self.state_file.with_suffix(".tmp")
        tmp.write_text(json.dumps(state, indent=2, sort_keys=True))
        os.replace(tmp, self.state_file)

    def _alive(self, pid):
        if not pid:
            return False
        if self.dry_run:
            return True
        try:
            os.kill(int(pid), 0)
            return True
        except (OSError, ValueError):
            return False

    def provider_available(self):
        return bool(shutil.which("npx") or shutil.which("desktop-commander"))

    def status(self):
        state = self._load()
        remote_pid = state.get("remote_pid")
        awake_pid = state.get("keep_awake_pid")
        if self._alive(remote_pid):
            remote = "running"
        elif remote_pid:
            remote = "stale"
        elif state.get("remote_stopped"):
            remote = "stopped"
        elif self.provider_available():
            remote = "available"
        else:
            remote = "unavailable"
        return {"remote": remote, "keep_awake": "running" if self._alive(awake_pid) else "stopped",
                "remote_pid": remote_pid, "keep_awake_pid": awake_pid}

    def _spawn(self, command):
        if self.dry_run:
            self._fake_pid += 1
            return self._fake_pid
        return subprocess.Popen(command, start_new_session=True,
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).pid

    def start_remote(self):
        state = self._load()
        if self._alive(state.get("remote_pid")):
            return {"status": "running", "pid": state["remote_pid"], "changed": False}
        if not self.dry_run and not shutil.which("npx"):
            return {"status": "unavailable", "reason": "npx is not installed"}
        pid = self._spawn(["npx", "@wonderwhy-er/desktop-commander@latest", "remote"])
        state["remote_pid"] = pid
        state.pop("remote_stopped", None)
        self._save(state)
        return {"status": "running", "pid": pid, "changed": True}

    def _stop_key(self, key):
        state = self._load()
        pid = state.get(key)
        if pid and self._alive(pid) and not self.dry_run:
            os.killpg(os.getpgid(int(pid)), signal.SIGTERM)
        state.pop(key, None)
        self._save(state)
        return {"status": "stopped", "pid": pid}

    def stop_remote(self):
        result = self._stop_key("remote_pid")
        state = self._load()
        state["remote_stopped"] = True
        self._save(state)
        return result

    def restart_remote(self):
        self.stop_remote()
        return self.start_remote()

    def start_keep_awake(self):
        state = self._load()
        if self._alive(state.get("keep_awake_pid")):
            return {"status": "running", "pid": state["keep_awake_pid"], "changed": False}
        if not self.dry_run and not Path("/usr/bin/caffeinate").exists():
            return {"status": "unavailable", "reason": "macOS caffeinate is unavailable"}
        pid = self._spawn(["/usr/bin/caffeinate", "-i", "-s"])
        state["keep_awake_pid"] = pid
        self._save(state)
        return {"status": "running", "pid": pid, "changed": True}

    def stop_keep_awake(self):
        return self._stop_key("keep_awake_pid")
