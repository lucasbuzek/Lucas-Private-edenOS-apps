"""BIFROST ZERO bridge: Lucas Raven (Web representation) <-> this BIFROST node.

Outbound-only. The node never listens on a port; it publishes state to and
claims queued actions from the Raven edge API using its own node key, which is
read from the macOS Keychain. The edge provider (currently Cloudflare Pages +
D1) is replaceable: only RAVEN_URL and the HTTP contract matter.

Only actions in ACTIONS can run, with validated bounded parameters. There is
no generic command or shell action, by design.
"""
from __future__ import annotations

import fcntl
import json
import logging
import os
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request
import re
import random
from logging.handlers import RotatingFileHandler
from pathlib import Path

from .node_state import StateCollector
from .remote_provider import RemoteProvider
from .list_collectors import _run
from .workincodex import Submitter

RAVEN_URL = os.environ.get("RAVEN_URL", "https://lucas-raven.pages.dev").rstrip("/")
KEYCHAIN_SERVICE_NODE = "eden.bifrost.raven.node"
NODE_ID = os.environ.get("BIFROST_NODE_ID", "lucas-macbook")
POLL_S = float(os.environ.get("RAVEN_POLL_S", "4"))
STATE_EVERY_S = float(os.environ.get("RAVEN_STATE_EVERY_S", "30"))
LOG_DIR = Path.home() / "Library/Logs/BIFROST"
VERSION = "zero-0.1.0"
CATALOG_PATH = Path(__file__).resolve().parents[1] / "catalog" / "capabilities.v1.json"
LOCK_PATH = Path.home() / "Library/Application Support/BIFROST/raven-bridge.lock"

log = logging.getLogger("bifrost.raven")


class ActionError(ValueError):
    pass


def _no_params(params):
    if params:
        raise ActionError("this action takes no parameters")


def act_keepawake_start(ctx, params):
    m = params["minutes"]
    return ctx["provider"].start_keep_awake(seconds=m * 60)


def act_keepawake_stop(ctx, params):
    _no_params(params)
    return ctx["provider"].stop_keep_awake()


def act_state_refresh(ctx, params):
    _no_params(params)
    ctx["force_slow"] = True
    return {"status": "refreshed"}


def act_lists_refresh(ctx, params):
    _no_params(params)
    values = ctx["collector"].refresh_lists(force=True)
    return {"status": "refreshed", "lists": {k: {"status": v["status"], "summary": v["summary"]}
                                                 for k, v in values.items()}}


def act_codex_status(ctx, params):
    code, out = _run(["codex", "cloud", "status", params["task_id"]], 60)
    return {"status": "observed" if code == 0 else "unknown", "code": code,
            "output": out.strip()[:4000]}


def act_codex_submit(ctx, params):
    return ctx["submitter"].submit(params, ctx.get("origin", "raven-action"))


# capability id -> handler. Mirrors the edge catalogue; both sides validate.
HANDLERS = {
    "power.keepawake.start": act_keepawake_start,
    "power.keepawake.stop": act_keepawake_stop,
    "bifrost.state.refresh": act_state_refresh,
    "lists.refresh": act_lists_refresh,
    "codex.cloud.status": act_codex_status,
    "codex.cloud.submit": act_codex_submit,
}

FALLBACK_SPECS = {
    "power.keepawake.start": {"executor": "device", "params": {"minutes": {"type": "int", "min": 1, "max": 480, "default": 60}}},
    "power.keepawake.stop": {"executor": "device", "params": {}},
    "bifrost.state.refresh": {"executor": "device", "params": {}},
}


def load_actions(path=CATALOG_PATH):
    try:
        raw = json.loads(Path(path).read_text())
        if raw.get("version") != 1 or not isinstance(raw.get("capabilities"), dict):
            raise ValueError("unsupported catalog")
        specs = raw["capabilities"]
    except Exception as exc:  # noqa: BLE001
        log.error("capability catalog unavailable/invalid; using original fail-closed set: %s", exc)
        specs = FALLBACK_SPECS
    return {name: {"handler": HANDLERS[name], "params": spec.get("params", {})}
            for name, spec in specs.items() if spec.get("executor") == "device" and name in HANDLERS}


ACTIONS = load_actions()


def _validate(specs, supplied):
    unknown = set(supplied) - set(specs)
    if unknown:
        raise ActionError(f"unexpected parameters: {sorted(unknown)}")
    result = {}
    for name, spec in specs.items():
        if name not in supplied:
            if "default" in spec:
                value = spec["default"]
            else:
                raise ActionError(f"missing parameter: {name}")
        else:
            value = supplied[name]
        if spec.get("type") == "int":
            if isinstance(value, bool) or not isinstance(value, int):
                raise ActionError(f"{name} must be an integer")
            if value < spec.get("min", value) or value > spec.get("max", value):
                raise ActionError(f"{name} is outside its allowed range")
        elif spec.get("type") == "str":
            if not isinstance(value, str):
                raise ActionError(f"{name} must be a string")
            if len(value) < spec.get("minlen", 0) or len(value) > spec.get("maxlen", len(value)):
                raise ActionError(f"{name} length is outside its allowed range")
            if "pattern" in spec and not re.fullmatch(spec["pattern"], value):
                raise ActionError(f"{name} has invalid format")
        else:
            raise ActionError(f"invalid catalog type for {name}")
        result[name] = value
    return result


def execute(ctx, capability, params):
    action = ACTIONS.get(capability)
    if action is None:
        raise ActionError(f"capability not allowed on this node: {capability}")
    if not isinstance(params, dict):
        raise ActionError("params must be an object")
    return action["handler"](ctx, _validate(action["params"], params))


def acquire_lock(path=LOCK_PATH, force=False):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    handle = Path(path).open("a+")
    try:
        fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        handle.close()
        if not force:
            raise RuntimeError("raven-bridge is already running (launchd owns the singleton)") from None
        raise RuntimeError("raven-bridge lock is held; --force will not terminate or bypass the owner") from None
    handle.seek(0); handle.truncate(); handle.write(str(os.getpid())); handle.flush()
    return handle


def keychain_secret(service):
    p = subprocess.run(["/usr/bin/security", "find-generic-password", "-s", service, "-w"],
                       capture_output=True, text=True)
    if p.returncode != 0 or not p.stdout.strip():
        raise RuntimeError(f"Keychain item {service!r} not found (run: bifrostctl.py raven-provision)")
    return p.stdout.strip()


class Edge:
    def __init__(self, base, key):
        self.base, self.key = base, key

    def call(self, path, payload=None, timeout=20):
        body = json.dumps(payload or {}).encode()
        req = urllib.request.Request(self.base + path, data=body, method="POST", headers={
            "Authorization": "Bearer " + self.key, "Content-Type": "application/json",
            "User-Agent": f"BIFROST-node/{VERSION}"})
        with urllib.request.urlopen(req, timeout=timeout) as r:
            raw = r.read()
            return json.loads(raw) if raw else {}


def manual_session_owner():
    """Fail closed unless this local bridge belongs to a visible BIFROST GUI."""
    pid_text = os.environ.get("BIFROST_RAVEN_SESSION_OWNER_PID", "")
    if not pid_text.isascii() or not pid_text.isdecimal() or len(pid_text) > 10:
        raise RuntimeError("RavenNest manual BIFROST session owner missing")
    pid = int(pid_text)
    if pid <= 1 or not owner_alive(pid):
        raise RuntimeError("RavenNest manual BIFROST session owner not running")
    # Only initial validation needs to inspect the full process command.
    # Every subsequent liveness check is a low-cost os.kill(pid, 0).
    check = subprocess.run(["/bin/ps", "-p", str(pid), "-o", "command="],
                           capture_output=True, text=True, timeout=3, check=False)
    if check.returncode != 0 or "/BIFROST.app/Contents/MacOS/BIFROST" not in check.stdout:
        raise RuntimeError("RavenNest owner is not the BIFROST macOS application")
    return pid


def owner_alive(pid):
    """Zero-signal check, never signals or terminates the application."""
    try:
        os.kill(pid, 0)
        return True
    except (OSError, ValueError):
        return False


def wait_while_owned(seconds, pid):
    """When BIFROST closes unexpectedly, abandon the optional bridge quickly."""
    import time as _time
    remaining = max(float(seconds), 0)
    while remaining > 0:
        if not owner_alive(pid):
            return False
        delay = min(3.0, remaining)
        _time.sleep(delay)
        remaining -= delay
    return owner_alive(pid)


def run_forever(once=False, force=False):
    owner_pid = manual_session_owner()
    lock_handle = acquire_lock(force=force)  # retained for process lifetime
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    handler = RotatingFileHandler(LOG_DIR / "raven-bridge.log", maxBytes=1_000_000, backupCount=3)
    logging.basicConfig(level=logging.INFO, handlers=[handler, logging.StreamHandler(sys.stdout)],
                        format="%(asctime)s %(levelname)s %(message)s")
    edge = Edge(RAVEN_URL, keychain_secret(KEYCHAIN_SERVICE_NODE))
    provider = RemoteProvider()
    collector = StateCollector(provider)
    ctx = {"provider": provider, "collector": collector, "submitter": Submitter(), "force_slow": True}
    meta = {"node_id": NODE_ID, "bridge_version": VERSION, "hostname": socket.gethostname(),
            "actions": sorted(ACTIONS), "pid": os.getpid()}
    log.info("bridge start node=%s edge=%s", NODE_ID, RAVEN_URL)
    last_state, backoff = 0.0, POLL_S
    while True:
        if not owner_alive(owner_pid):
            log.info("BIFROST UI session ended; optional RavenNest Mac bridge exits")
            return
        try:
            if time.time() - last_state >= STATE_EVERY_S or ctx["force_slow"]:
                state = collector.collect(force_slow=ctx["force_slow"])
                ctx["force_slow"] = False
                edge.call("/api/node/state", {**meta, "state": state})
                last_state = time.time()
            claim = edge.call("/api/node/claim", {"node_id": NODE_ID})
            action = claim.get("action")
            if action:
                aid, cap, params = action["id"], action["capability"], action.get("params") or {}
                ctx["origin"] = action.get("origin") or "raven-action"
                log.info("action claimed id=%s cap=%s origin=%s", aid, cap, ctx["origin"])
                try:
                    result, ok = execute(ctx, cap, params), True
                except ActionError as e:
                    result, ok = {"error": str(e)}, False
                except Exception as e:  # noqa: BLE001
                    result, ok = {"error": f"{type(e).__name__}: {e}"}, False
                log.info("action done id=%s ok=%s result=%s", aid, ok, json.dumps(result, default=str))
                last_state = 0.0  # publish fresh state with the result
                state = collector.collect(force_slow=ctx["force_slow"])
                ctx["force_slow"] = False
                edge.call("/api/node/state", {**meta, "state": state})
                edge.call("/api/node/result", {"node_id": NODE_ID, "id": aid, "ok": ok, "result": result})
                last_state = time.time()
                backoff = POLL_S
                continue
            backoff = POLL_S
        except urllib.error.HTTPError as e:
            log.warning("edge HTTP %s on request: %s", e.code, e.read()[:200])
            backoff = min(backoff * 2, 120) * random.uniform(0.85, 1.15)
        except (urllib.error.URLError, TimeoutError, OSError) as e:
            log.warning("edge unreachable: %s", e)
            backoff = min(backoff * 2, 120) * random.uniform(0.85, 1.15)
        if once:
            return
        if not wait_while_owned(backoff, owner_pid):
            log.info("BIFROST UI session ended during wait; RavenNest bridge exits")
            return


if __name__ == "__main__":
    run_forever(once="--once" in sys.argv, force="--force" in sys.argv)
