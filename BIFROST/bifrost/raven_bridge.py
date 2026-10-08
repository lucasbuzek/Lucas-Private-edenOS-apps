"""BIFROST ZERO bridge: Lucas Raven (Web representation) <-> this BIFROST node.

Outbound-only. The node never listens on a port; it publishes state to and
claims queued actions from the Raven edge API using its own node key, which is
read from the macOS Keychain. The edge provider (currently Cloudflare Pages +
D1) is replaceable: only RAVEN_URL and the HTTP contract matter.

Only actions in ACTIONS can run, with validated bounded parameters. There is
no generic command or shell action, by design.
"""
from __future__ import annotations

import json
import logging
import os
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request
from logging.handlers import RotatingFileHandler
from pathlib import Path

from .node_state import StateCollector
from .remote_provider import RemoteProvider

RAVEN_URL = os.environ.get("RAVEN_URL", "https://lucas-raven.pages.dev").rstrip("/")
KEYCHAIN_SERVICE_NODE = "eden.bifrost.raven.node"
NODE_ID = os.environ.get("BIFROST_NODE_ID", "lucas-macbook")
POLL_S = float(os.environ.get("RAVEN_POLL_S", "4"))
STATE_EVERY_S = float(os.environ.get("RAVEN_STATE_EVERY_S", "30"))
LOG_DIR = Path.home() / "Library/Logs/BIFROST"
VERSION = "zero-0.1.0"

log = logging.getLogger("bifrost.raven")


class ActionError(ValueError):
    pass


def _minutes(params):
    raw = params.get("minutes", 60)
    if isinstance(raw, bool) or not isinstance(raw, (int, float)) or int(raw) != raw:
        raise ActionError("minutes must be an integer")
    m = int(raw)
    if not 1 <= m <= 480:
        raise ActionError("minutes must be between 1 and 480")
    return m


def _no_params(params):
    if params:
        raise ActionError("this action takes no parameters")


def act_keepawake_start(ctx, params):
    m = _minutes(params)
    extra = set(params) - {"minutes"}
    if extra:
        raise ActionError(f"unexpected parameters: {sorted(extra)}")
    return ctx["provider"].start_keep_awake(seconds=m * 60)


def act_keepawake_stop(ctx, params):
    _no_params(params)
    return ctx["provider"].stop_keep_awake()


def act_state_refresh(ctx, params):
    _no_params(params)
    ctx["force_slow"] = True
    return {"status": "refreshed"}


# capability id -> handler. Mirrors the edge catalogue; both sides validate.
ACTIONS = {
    "power.keepawake.start": act_keepawake_start,
    "power.keepawake.stop": act_keepawake_stop,
    "bifrost.state.refresh": act_state_refresh,
}


def execute(ctx, capability, params):
    handler = ACTIONS.get(capability)
    if handler is None:
        raise ActionError(f"capability not allowed on this node: {capability}")
    if not isinstance(params, dict):
        raise ActionError("params must be an object")
    return handler(ctx, params)


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


def run_forever(once=False):
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    handler = RotatingFileHandler(LOG_DIR / "raven-bridge.log", maxBytes=1_000_000, backupCount=3)
    logging.basicConfig(level=logging.INFO, handlers=[handler, logging.StreamHandler(sys.stdout)],
                        format="%(asctime)s %(levelname)s %(message)s")
    edge = Edge(RAVEN_URL, keychain_secret(KEYCHAIN_SERVICE_NODE))
    provider = RemoteProvider()
    collector = StateCollector(provider)
    ctx = {"provider": provider, "force_slow": True}
    meta = {"node_id": NODE_ID, "bridge_version": VERSION, "hostname": socket.gethostname(),
            "actions": sorted(ACTIONS), "pid": os.getpid()}
    log.info("bridge start node=%s edge=%s", NODE_ID, RAVEN_URL)
    last_state, backoff = 0.0, POLL_S
    while True:
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
                log.info("action claimed id=%s cap=%s params=%s origin=%s", aid, cap,
                         json.dumps(params), action.get("origin"))
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
            backoff = min(backoff * 2, 120)
        except (urllib.error.URLError, TimeoutError, OSError) as e:
            log.warning("edge unreachable: %s", e)
            backoff = min(backoff * 2, 120)
        if once:
            return
        time.sleep(backoff)


if __name__ == "__main__":
    run_forever(once="--once" in sys.argv)
