"""Truthful BIFROST node capability state for ZERO representations.

Every probe reports what was actually observed, when, and the evidence it is
based on. Probes never read or transmit credentials: they only record whether
an existing provider (gh, codex, wrangler, ...) reports itself authenticated.

Status vocabulary (EDEN evidence rules: UNKNOWN != PASS):
  RUNNING / STOPPED        lifecycle of a managed process
  AUTHENTICATED            provider CLI reports a signed-in account
  AVAILABLE                tool present, sign-in not confirmed
  CREDENTIAL_PRESENT       credential file exists; not validated by this probe
  NOT_INSTALLED            tool not found on this node
  OBSERVED                 informational observation
  ERROR / UNKNOWN          probe failed or could not decide
"""
from __future__ import annotations

import json
import os
import platform
import re
import shutil
import socket
import subprocess
import threading
import time
from pathlib import Path

from .remote_provider import RemoteProvider
from . import list_collectors

HOME = Path.home()
EXTRA_PATH = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin"]


def _env():
    env = dict(os.environ)
    parts = env.get("PATH", "").split(":")
    env["PATH"] = ":".join(EXTRA_PATH + [p for p in parts if p and p not in EXTRA_PATH])
    return env


def _which(name):
    return shutil.which(name, path=_env()["PATH"])


def run(cmd, timeout=15):
    """Run a fixed argv (never a shell string). Returns (code, stdout+stderr)."""
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, env=_env())
        return p.returncode, (p.stdout + p.stderr).strip()
    except FileNotFoundError:
        return 127, "not found"
    except subprocess.TimeoutExpired:
        return 124, "timeout"


def processes():
    """(pid, command) for all processes via ps (pgrep is unreliable here)."""
    code, out = run(["/bin/ps", "-axo", "pid=,command="])
    rows = []
    for line in out.splitlines() if code == 0 else []:
        parts = line.strip().split(None, 1)
        if len(parts) == 2 and parts[0].isdigit():
            rows.append((int(parts[0]), parts[1]))
    return rows


def _cap(status, summary, evidence=None, **extra):
    out = {"status": status, "summary": summary, "evidence": evidence or [], "checked_at": time.time()}
    out.update(extra)
    return out


# ---------------------------------------------------------------- probes

def probe_node():
    code, ver = run(["/usr/bin/sw_vers", "-productVersion"])
    code_b, batt = run(["/usr/bin/pmset", "-g", "batt"])
    power = "unknown"
    m = re.search(r"Now drawing from '([^']+)'", batt)
    if m:
        power = m.group(1)
    pct = re.search(r"(\d+)%", batt)
    code_u, boot = run(["/usr/sbin/sysctl", "-n", "kern.boottime"])
    bm = re.search(r"sec = (\d+)", boot)
    uptime = int(time.time() - int(bm.group(1))) if bm else None
    return _cap("OBSERVED", f"macOS {ver if code == 0 else '?'} · {platform.machine()}",
                [f"hostname={socket.gethostname()}", f"power={power}" + (f" {pct.group(1)}%" if pct else "")],
                hostname=socket.gethostname(), macos=ver if code == 0 else None,
                arch=platform.machine(), power_source=power,
                battery_percent=int(pct.group(1)) if pct else None, uptime_s=uptime)


def _sleep_assertions():
    code, out = run(["/usr/bin/pmset", "-g", "assertions"])
    if code != 0:
        return None, []
    m = re.search(r"PreventUserIdleSystemSleep\s+(\d)", out)
    holders = []
    for line in out.splitlines():
        if "PreventUserIdleSystemSleep named:" in line or "PreventSystemSleep named:" in line:
            hm = re.search(r"pid (\d+)\(([^)]+)\).*named: \"([^\"]+)\"", line)
            if hm:
                holders.append({"pid": int(hm.group(1)), "process": hm.group(2), "name": hm.group(3)})
    return (m.group(1) == "1") if m else None, holders


def probe_keep_awake(provider: RemoteProvider):
    st = provider.status()
    prevented, holders = _sleep_assertions()
    managed_pid = st.get("keep_awake_pid")
    managed_holder = any(h["pid"] == managed_pid for h in holders) if managed_pid else False
    caff = [h for h in holders if h["process"] == "caffeinate"]
    ev = [f"bifrost_managed={st['keep_awake']}" + (f" pid={managed_pid}" if st['keep_awake'] == 'running' else ""),
          f"pmset_assertion_held_by_managed_pid={managed_holder}",
          f"system_idle_sleep_prevented={prevented}",
          f"caffeinate_assertions={len(caff)}"]
    return _cap("RUNNING" if st["keep_awake"] == "running" else "STOPPED",
                "BIFROST Keep Awake (native caffeinate) " + st["keep_awake"],
                ev, managed=st["keep_awake"], until=st.get("keep_awake_until"),
                assertion_verified=managed_holder, system_sleep_prevented=prevented,
                assertion_holders=[f"{h['process']}: {h['name']}" for h in holders][:8])


def probe_remote_provider(provider: RemoteProvider):
    st = provider.status()
    external = [pid for pid, cmd in processes()
                if cmd.rstrip().endswith("desktop-commander remote") and not cmd.startswith("npm ")]
    status = "RUNNING" if st["remote"] == "running" or external else st["remote"].upper()
    return _cap(status, "Desktop Commander Remote (optional provider)",
                [f"bifrost_managed={st['remote']}", f"external_processes={len(external)}"],
                managed=st["remote"], external_sessions=len(external))


def probe_codex():
    exe = _which("codex")
    if not exe:
        return _cap("NOT_INSTALLED", "Codex CLI not found")
    _, ver = run([exe, "--version"])
    code, login = run([exe, "login", "status"])
    first = login.splitlines()[0] if login else ""
    authed = code == 0 and "logged in" in first.lower()
    return _cap("AUTHENTICATED" if authed else "AVAILABLE", ver,
                [f"exe={exe}", f"login: {first[:80]}"], version=ver)


def probe_github():
    exe = _which("gh")
    if not exe:
        return _cap("NOT_INSTALLED", "GitHub CLI not found")
    code, out = run([exe, "auth", "status", "--hostname", "github.com"])
    acct = re.search(r"account (\S+)", out)
    scopes = re.search(r"Token scopes: (.+)", out)
    ev = [f"account={acct.group(1)}" if acct else "account=?"]
    if scopes:
        ev.append("scopes=" + scopes.group(1).replace("'", ""))
    return _cap("AUTHENTICATED" if code == 0 and acct else "AVAILABLE",
                f"gh signed in as {acct.group(1)}" if acct else "gh present, not signed in",
                ev, account=acct.group(1) if acct else None)


def probe_claude_code():
    candidates = [_which("claude"), str(HOME / ".claude/local/claude"), str(HOME / ".local/bin/claude")]
    found = next((c for c in candidates if c and Path(c).exists()), None)
    if found:
        _, ver = run([found, "--version"])
        return _cap("AVAILABLE", f"Claude Code {ver}", [f"exe={found}"])
    return _cap("NOT_INSTALLED", "Claude Code CLI not installed on this Mac",
                ["no claude executable on PATH or in ~/.claude/local, ~/.local/bin",
                 "Claude (cloud) reaches this Mac via the Remote Desktop Commander provider"])


def probe_cloudflare():
    cfg = HOME / "Library/Preferences/.wrangler/config/default.toml"
    if cfg.exists():
        return _cap("CREDENTIAL_PRESENT", "wrangler OAuth credential present (not validated by probe)",
                    ["wrangler run via npx", f"config mtime={int(cfg.stat().st_mtime)}"])
    return _cap("NOT_INSTALLED", "No wrangler credential on this Mac")


def probe_bifrost_app():
    running = any("/BIFROST.app/Contents/MacOS/BIFROST" in cmd for _, cmd in processes())
    return _cap("RUNNING" if running else "STOPPED", "BIFROST native macOS app",
                [f"process={'running' if running else 'not running'}"])


def probe_registry():
    path = HOME / ".eden/bifrost/registry.json"
    try:
        reg = json.loads(path.read_text())
    except Exception as e:  # noqa: BLE001
        return _cap("UNKNOWN", "BIFROST App registry unreadable", [str(e)[:120]])
    apps = []
    for a in reg.get("apps", []):
        p = a.get("path")
        apps.append({"id": a.get("id"), "name": a.get("name"), "lifecycle": a.get("lifecycle"),
                     "test_state": a.get("test_state"), "path_exists": bool(p and Path(p).exists())})
    present = sum(1 for a in apps if a["path_exists"])
    return _cap("OBSERVED", f"{len(apps)} Apps REGISTERED (registration ≠ operational)",
                [f"registry updated={reg.get('updated')}", f"registered paths present={present}/{len(apps)}"],
                apps=apps)


SLOW_PROBES = {"codex": probe_codex, "github": probe_github, "claude_code": probe_claude_code,
               "cloudflare": probe_cloudflare, "registry": probe_registry}


class StateCollector:
    """Collects node state; slow provider probes are cached."""

    def __init__(self, provider: RemoteProvider | None = None, slow_ttl: float = 300):
        self.provider = provider or RemoteProvider()
        self.slow_ttl = slow_ttl
        self._slow: dict = {}
        self._slow_at = 0.0
        self._lists: dict = {
            key: _cap("UNKNOWN", "collector has not completed yet", items=[])
            for key in ("codex.tasks", "claude_code.sessions", "chatgpt.chats")
        }
        self._lists_at: dict = {}
        self._lists_thread = None

    def refresh_lists(self, force=False):
        """Refresh metadata lists; Codex retains its five-minute back-off."""
        now = time.time()
        jobs = {
            "codex.tasks": list_collectors.codex_tasks,
            "claude_code.sessions": list_collectors.claude_sessions,
            "chatgpt.chats": list_collectors.chatgpt_chats,
        }
        for key, fn in jobs.items():
            if key == "codex.tasks" and now - self._lists_at.get(key, 0) < 300:
                continue
            if not force and now - self._lists_at.get(key, 0) < self.slow_ttl:
                continue
            try:
                self._lists[key] = fn()
            except Exception as e:  # noqa: BLE001
                self._lists[key] = _cap("ERROR", f"collector failed: {type(e).__name__}",
                                        [str(e)[:120]], items=[])
            self._lists_at[key] = now
        return self._lists.copy()

    def schedule_lists(self, force=False):
        """Run slow list I/O away from the 30-second state publishing path."""
        if self._lists_thread and self._lists_thread.is_alive():
            return
        self._lists_thread = threading.Thread(target=self.refresh_lists, args=(force,),
                                              name="raven-list-collectors", daemon=True)
        self._lists_thread.start()

    def collect(self, force_slow: bool = False):
        now = time.time()
        if force_slow or now - self._slow_at > self.slow_ttl:
            for key, fn in SLOW_PROBES.items():
                try:
                    self._slow[key] = fn()
                except Exception as e:  # noqa: BLE001
                    self._slow[key] = _cap("ERROR", f"probe failed: {type(e).__name__}", [str(e)[:120]])
            self._slow_at = now
        self.schedule_lists(force=force_slow)
        caps = {}
        for key, fn in (("node", probe_node),
                        ("power.keepawake", lambda: probe_keep_awake(self.provider)),
                        ("remote.provider", lambda: probe_remote_provider(self.provider)),
                        ("bifrost.app", probe_bifrost_app)):
            try:
                caps[key] = fn()
            except Exception as e:  # noqa: BLE001
                caps[key] = _cap("ERROR", f"probe failed: {type(e).__name__}", [str(e)[:120]])
        caps.update(self._slow)
        caps.update(self._lists)
        return {"schema": 1, "collected_at": now, "capabilities": caps}
