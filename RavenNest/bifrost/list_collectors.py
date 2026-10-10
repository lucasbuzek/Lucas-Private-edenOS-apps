"""Bounded, metadata-only collectors for Raven's read-only lists."""
from __future__ import annotations

import json
import os
import re
import subprocess
import time
from pathlib import Path

TASK_RE = re.compile(r"task_e_[a-f0-9]{32}")
OUTPUT_LIMIT = 256_000
CHATGPT_MAX_BYTES = int(os.environ.get("RAVEN_CHATGPT_EXPORT_MAX_BYTES", str(50 * 1024 * 1024)))


def _cap(status, summary, evidence=None, items=None):
    return {"status": status, "summary": summary, "evidence": evidence or [],
            "checked_at": time.time(), "items": (items or [])[:50]}


def _run(argv, timeout=60, env=None):
    try:
        p = subprocess.run(argv, stdin=subprocess.DEVNULL, capture_output=True, text=True,
                           timeout=timeout, env=env)
        return p.returncode, (p.stdout + p.stderr)[:OUTPUT_LIMIT]
    except FileNotFoundError:
        return 127, "not found"
    except subprocess.TimeoutExpired:
        return 124, "timeout"


def parse_codex_tasks(text):
    """Defensively extract task metadata; never infer missing fields."""
    items = []
    for line in text.splitlines():
        match = TASK_RE.search(line)
        if not match:
            continue
        task_id = match.group(0)
        rest = line[match.end():].strip(" \t|-")
        fields = [x.strip() for x in re.split(r"\s{2,}|\s*\|\s*", rest) if x.strip()]
        item = {"task_id": task_id}
        for key, value in zip(("title", "environment", "status", "age"), fields):
            item[key] = value[:240]
        items.append(item)
        if len(items) == 50:
            break
    return items


def codex_tasks(env=None):
    code, out = _run(["codex", "cloud", "list", "--limit", "20"], 60, env)
    low = out.lower()
    if code == 127:
        return _cap("NOT_INSTALLED", "Codex CLI not found")
    if code == 124:
        return _cap("UNKNOWN", "Codex cloud list timed out", ["60 second timeout"])
    if "429" in low or "rate limit" in low:
        return _cap("ERROR", "Codex cloud list rate-limited", ["provider returned 429/rate limit"])
    if code != 0:
        status = "UNKNOWN" if "login" in low or "auth" in low else "ERROR"
        return _cap(status, "Codex cloud list unavailable", [out.strip()[:160]])
    items = parse_codex_tasks(out)
    return _cap("OBSERVED", f"{len(items)} Codex cloud tasks observed", items=items)


def claude_sessions(home=None):
    root = Path(home or Path.home()) / ".claude" / "projects"
    if not root.is_dir():
        return _cap("NOT_INSTALLED", "Claude Code session directory not found")
    rows = []
    for path in root.glob("*/*.jsonl"):
        try:
            st = path.stat()
            rows.append((st.st_mtime, {"session_id": path.stem[:200],
                                      "project": path.parent.name[:200],
                                      "size": st.st_size, "mtime": int(st.st_mtime)}))
        except OSError:
            continue
    items = [item for _, item in sorted(rows, reverse=True)[:50]]
    return _cap("OBSERVED", f"{len(items)} Claude Code session files observed",
                ["metadata only; conversation JSONL was not read"], items)


def _export_chats(path):
    try:
        size = path.stat().st_size
        if size > CHATGPT_MAX_BYTES:
            return _cap("ERROR", "ChatGPT export exceeds configured size limit",
                        [f"size={size}", f"limit={CHATGPT_MAX_BYTES}"])
        data = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(data, list):
            raise ValueError("top level is not an array")
        allowed = ("title", "create_time", "update_time", "gizmo_id", "project_id")
        items = [{k: row[k] for k in allowed if k in row and isinstance(row[k], (str, int, float))}
                 for row in data if isinstance(row, dict)]
        items.sort(key=lambda x: x.get("update_time", x.get("create_time", 0)), reverse=True)
        age = max(0, int(time.time() - path.stat().st_mtime))
        return _cap("OBSERVED", f"{min(len(items), 50)} ChatGPT export titles observed",
                    [f"export_age_seconds={age}", "titles/timestamps only; message content omitted"], items)
    except Exception as exc:  # noqa: BLE001
        return _cap("ERROR", "ChatGPT export metadata unreadable", [str(exc)[:160]])


def _app_chats():
    # Static source: all untrusted values arrive as output, never enter AppleScript.
    script = '''tell application "System Events"
if UI elements enabled is false then error "ACCESSIBILITY_PERMISSION_REQUIRED"
tell process "ChatGPT"
set theTitles to name of every static text of entire contents of window 1
end tell
end tell
return theTitles as string'''
    code, out = _run(["/usr/bin/osascript", "-e", script], 20)
    if code:
        if "permission" in out.lower() or "not authorized" in out.lower():
            return _cap("PERMISSION_REQUIRED", "ChatGPT Mac app sidebar unavailable",
                        ["System Settings -> Privacy & Security -> Accessibility"])
        return _cap("UNKNOWN", "ChatGPT Mac app adapter failed (best-effort/fragile)", [out[:160]])
    items = [{"title": title[:240]} for title in out.split(", ") if title.strip()][:50]
    return _cap("OBSERVED", f"{len(items)} visible sidebar titles (best-effort/fragile)",
                ["Accessibility read only; no click, prompt, or typing"], items)


def chatgpt_chats(home=None, app_enabled=None):
    if app_enabled is None:
        app_enabled = os.environ.get("RAVEN_CHATGPT_APP") == "1"
    if app_enabled:
        return _app_chats()
    path = Path(home or Path.home()) / "edenOS" / "Imports" / "chatgpt-export" / "conversations.json"
    if not path.exists():
        return _cap("NOT_CONFIGURED", "ChatGPT export adapter is not configured",
                    [f"expected={path}", "set RAVEN_CHATGPT_APP=1 for the optional Mac app adapter"])
    return _export_chats(path)


def collect_all(home=None, codex_env=None):
    collectors = {"codex.tasks": lambda: codex_tasks(codex_env),
                  "claude_code.sessions": lambda: claude_sessions(home),
                  "chatgpt.chats": lambda: chatgpt_chats(home)}
    result = {}
    for key, fn in collectors.items():
        try:
            result[key] = fn()
        except Exception as exc:  # noqa: BLE001
            result[key] = _cap("ERROR", f"collector failed: {type(exc).__name__}", [str(exc)[:160]])
    return result
