"""BIFROST local workflow orchestration. No cloud, shell, arbitrary scripts or default actions.

Native UI grants one folder and one exact saved Shortcut; browser may invoke
existing discovered workflows with explicit confirmation. Folder monitoring
is opt-in, shallow, capped and dormant until Headless is explicitly started.
"""
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import threading
import time

SCHEMA = "bifrost.orchestration.v1"
MAX_FILES = 500
ALLOWED_WORKFLOW_ROOTS = ("Library/Services", "Library/Workflows/Applications/Finder")


def _safe_folder(folder, home=None):
    home = Path(home or Path.home()).resolve()
    if not isinstance(folder, str) or not folder.startswith("/") or len(folder) > 1024:
        raise ValueError("Select a folder using the native BIFROST picker")
    raw = Path(folder)
    if raw.is_symlink() or not raw.is_dir() or raw.resolve() != raw:
        raise ValueError("Folder no longer matches its approved location")
    if raw == home or home not in raw.parents:
        raise ValueError("Grant an individual folder within the user home")
    parts = raw.relative_to(home).parts
    if any(part.startswith(".") for part in parts) or "Library" in parts:
        raise ValueError("Hidden or Library folders are not eligible for watches")
    if len(parts) >= 2 and parts[:2] == ("edenOS", "Projects"):
        raise ValueError("Protected project overview folders are excluded")
    return raw


def discover_shortcuts():
    if sys.platform != "darwin":
        return []
    try:
        result = subprocess.run(
            ["/usr/bin/shortcuts", "list"], stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL, stdin=subprocess.DEVNULL, timeout=8,
            check=False, text=True
        )
    except (OSError, subprocess.TimeoutExpired):
        return []
    if result.returncode != 0:
        return []
    values = []
    for name in result.stdout.splitlines()[:250]:
        name = name.strip()
        if 0 < len(name.encode("utf-8")) <= 160 and not any(ord(c) < 32 for c in name):
            values.append(name)
    return sorted(set(values))


def discover_automator(home=None):
    base = Path(home or Path.home())
    found = []
    for sub in ALLOWED_WORKFLOW_ROOTS:
        parent = base / sub
        if parent.is_symlink() or not parent.is_dir():
            continue
        try:
            for child in sorted(parent.iterdir())[:100]:
                if child.suffix == ".workflow" and not child.is_symlink() and child.is_dir():
                    if child.resolve() == child and len(child.name.encode("utf-8")) <= 180:
                        found.append({"name": child.stem, "id": str(child), "kind": "automator"})
        except OSError:
            pass
    return found[:100]


def catalog():
    return {
        "schema": SCHEMA,
        "shortcuts": [{"name": name, "id": name, "kind": "shortcut"} for name in discover_shortcuts()],
        "automator": discover_automator(),
        "browserAutomation": "local-dashboard-only",
        "externalProviderAccess": "not-authorized"
    }


def load_rule(support, home=None, check_catalog=True):
    path = Path(support) / "orchestration-rule.json"
    try:
        if path.is_symlink() or path.stat().st_mode & 0o077:
            raise ValueError("Rule approval record is not private")
        data = json.loads(path.read_text(encoding="utf-8"))
        if set(data) != {"schema", "enabled", "folder", "shortcut"} or data["schema"] != SCHEMA:
            raise ValueError("Invalid native approval record")
        if type(data["enabled"]) is not bool or not isinstance(data["shortcut"], str):
            raise ValueError("Invalid rule")
        _safe_folder(data["folder"], home)
        if check_catalog and data["shortcut"] not in discover_shortcuts():
            raise ValueError("Approved Shortcut missing from current catalog")
        return data, None
    except FileNotFoundError:
        return None, None
    except (OSError, ValueError, TypeError, KeyError) as err:
        return None, str(err)


def _snapshot(folder):
    """Read only direct child names/inodes; never follow symlinks or file contents."""
    answer = {}
    try:
        for i, child in enumerate(Path(folder).iterdir()):
            if i >= MAX_FILES:
                raise ValueError("Watched folder has more than 500 direct items")
            if child.name.startswith(".") or child.is_symlink():
                continue
            info = child.stat(follow_symlinks=False)
            if stat.S_ISREG(info.st_mode):
                answer[child.name] = (info.st_ino, info.st_size, info.st_mtime_ns)
    except OSError as err:
        raise ValueError("Approved folder unavailable") from err
    return answer


class Orchestrator:
    def __init__(self, support):
        self.support = Path(support)
        self.lock = threading.Lock()
        self.thread = None
        self.stop_event = threading.Event()
        self.active = False
        self.message = "Stopped"
        self.last_run = None

    def status(self):
        rule, error = load_rule(self.support)
        return {"schema": SCHEMA, "serviceActive": bool(self.active),
                "rule": rule, "ruleError": error, "status": self.message,
                "lastRun": self.last_run,
                "backgroundStartsAutomatically": False,
                "requiresNativeFolderApproval": True}

    def _receipt(self, kind, name, result, source):
        receipt = {"at": int(time.time()), "kind": kind, "name": name,
                   "source": source, "exitStatus": result,
                   "effectsVerified": False}
        self.last_run = receipt
        try:
            self.support.mkdir(parents=True, exist_ok=True, mode=0o700)
            path = self.support / "orchestration-runs.jsonl"
            flags = os.O_WRONLY | os.O_CREAT | os.O_APPEND
            fd = os.open(path, flags, 0o600)
            with os.fdopen(fd, "a", encoding="utf-8") as handle:
                handle.write(json.dumps(receipt, sort_keys=True) + "\n")
        except OSError:
            self.message = "Execution attempted; receipt storage failed"
        return receipt

    def run(self, kind, ident, source="browser"):
        """Only saved installed workflows, never arbitrary process or URL."""
        if source not in ("browser", "native-folder"):
            raise ValueError("Unknown action origin")
        if not isinstance(ident, str) or len(ident) > 1024:
            raise ValueError("Invalid workflow identifier")
        if kind == "shortcut":
            if ident not in discover_shortcuts():
                raise ValueError("Shortcut is not in the installed catalog")
            args = ["/usr/bin/shortcuts", "run", ident]
        elif kind == "automator":
            if ident not in {item["id"] for item in discover_automator()}:
                raise ValueError("Automator workflow is not an approved saved workflow")
            args = ["/usr/bin/automator", ident]
        else:
            raise ValueError("Unsupported workflow type")
        if sys.platform != "darwin":
            raise ValueError("Workflow execution requires macOS")
        if not self.lock.acquire(blocking=False):
            raise ValueError("Another workflow is already in progress")
        try:
            self.message = "Running " + kind + " workflow"
            try:
                result = subprocess.run(
                    args, stdin=subprocess.DEVNULL,
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                    timeout=60, check=False
                )
                code = result.returncode
                self.message = "Tool exited " + str(code) + "; effects not independently verified"
            except (OSError, subprocess.TimeoutExpired):
                code = -1
                self.message = "Workflow failed or timed out; effects unknown"
            return self._receipt(kind, ident, code, source)
        finally:
            self.lock.release()

    def start(self):
        if self.thread is not None:
            return
        self.thread = threading.Thread(target=self._loop, name="BIFROST-FolderWatch", daemon=True)
        self.thread.start()

    def shutdown(self):
        self.stop_event.set()
        if self.thread is not None:
            self.thread.join(timeout=2)

    def _loop(self):
        """Poll shallow metadata every five seconds; never scan full filesystem."""
        prior_key = None
        previous = {}
        next_allowed = 0
        self.active = True
        self.message = "Idle · no action until native folder rule is enabled"
        try:
            while not self.stop_event.wait(5):
                # A 5-second metadata watch must NOT spawn /usr/bin/shortcuts
                # every tick. The exact installed Shortcut is validated by
                # run() when (and only when) a new-file event occurs.
                rule, error = load_rule(self.support, check_catalog=False)
                if error or not rule or not rule["enabled"]:
                    prior_key, previous = None, {}
                    if error:
                        self.message = "Rule refused: " + error
                    continue
                key = (rule["folder"], rule["shortcut"])
                try:
                    current = _snapshot(rule["folder"])
                except ValueError as err:
                    self.message = str(err)
                    prior_key, previous = None, {}
                    continue
                if prior_key != key:
                    prior_key, previous = key, current
                    self.message = "Watching approved folder; existing files ignored"
                    continue
                added = current.keys() - previous.keys()
                previous = current
                if added and time.monotonic() >= next_allowed:
                    # One execution per burst, no per-file content or names supplied.
                    next_allowed = time.monotonic() + 30
                    try:
                        self.run("shortcut", rule["shortcut"], source="native-folder")
                    except ValueError as err:
                        self.message = str(err)
        finally:
            self.active = False

