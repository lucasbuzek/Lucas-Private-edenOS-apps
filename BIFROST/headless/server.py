#!/usr/bin/env python3
"""BIFROST Headless: independent local runtime, compact web dashboard and shared state.

The runtime is deliberately independent of SwiftUI, RavenNest, Cloudflare and RDC.
Binds ONLY to localhost. Mutations require a short-lived same-origin session
request plus a locally stored secret, never exposed over the network.
"""
import json
import hashlib
import os
import pathlib
import secrets
import sqlite3
import signal
import subprocess
import sys
import threading
import time
import zipfile
import setup_manager as setups
import kernel_adapter as core_adapter
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit, parse_qs

HOST = "127.0.0.1"
PORT = int(os.environ.get("BIFROST_HEADLESS_PORT", "8798"))
SUPPORT = pathlib.Path.home() / "Library" / "Application Support" / "BIFROST"
PREFS = SUPPORT / "settings.json"
KEYFILE = SUPPORT / "headless.token"
WEBROOT = pathlib.Path(__file__).resolve().parent
# Public loopback identity detects stale processes and wrong-port collisions;
# this fingerprint is diagnostic, not a security signature or authorization.
RUNTIME_IDENTITY = {
    "schema": "bifrost.headless.identity.v1",
    "productId": "eden.bifrost.headless",
    "runtimeId": hashlib.sha256(str(WEBROOT).encode("utf-8")).hexdigest()[:16],
    "sourceSha256": hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest(),
}
DEFAULTS = {
    "statusIndicators": ["headless", "activeTasks"],
    "aiRouting": "auto",
    "caffeinateMinutes": 60,
    "dashboardSections": ["headless", "tasks", "caffeinate", "raven", "ai"]
}
ALLOWED_INDICATORS = {"headless", "activeTasks"}
ALLOWED_SECTIONS = {"headless", "tasks", "caffeinate", "raven", "ai"}


def normalize(settings):
    src = settings if isinstance(settings, dict) else {}
    result = dict(DEFAULTS)
    if isinstance(src.get("statusIndicators"), list):
        result["statusIndicators"] = list(dict.fromkeys(
            x for x in src["statusIndicators"] if isinstance(x, str) and x in ALLOWED_INDICATORS
        ))
    if src.get("aiRouting") in ("auto", "manual", "local"):
        result["aiRouting"] = src["aiRouting"]
    if type(src.get("caffeinateMinutes")) is int and src["caffeinateMinutes"] in (0, 30, 60, 120):
        result["caffeinateMinutes"] = src["caffeinateMinutes"]
    if isinstance(src.get("dashboardSections"), list):
        result["dashboardSections"] = list(dict.fromkeys(
            x for x in src["dashboardSections"] if isinstance(x, str) and x in ALLOWED_SECTIONS
        ))
    return result


def ensure_private_dir():
    SUPPORT.mkdir(parents=True, exist_ok=True)
    os.chmod(SUPPORT, 0o700)


def atomic_file(path, payload):
    ensure_private_dir()
    tmp = path.with_name(path.name + "." + secrets.token_hex(6) + ".tmp")
    try:
        with open(tmp, "x", encoding="utf-8") as handle:
            os.chmod(tmp, 0o600)
            handle.write(payload)
        os.replace(tmp, path)
    finally:
        if tmp.exists():
            tmp.unlink()


def read_preferences():
    try:
        return normalize(json.loads(PREFS.read_text(encoding="utf-8")))
    except (OSError, ValueError, TypeError):
        return normalize({})


def save_preferences(raw):
    value = normalize(raw)
    atomic_file(PREFS, json.dumps(value, indent=2, sort_keys=True) + "\n")
    return value


def get_token():
    ensure_private_dir()
    if KEYFILE.exists():
        return KEYFILE.read_text(encoding="utf-8").strip()
    token = secrets.token_urlsafe(36)
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    try:
        fd = os.open(KEYFILE, flags, 0o600)
    except FileExistsError:
        return KEYFILE.read_text(encoding="utf-8").strip()
    with os.fdopen(fd, "w", encoding="utf-8") as output:
        output.write(token + "\n")
    return token


class Runtime:
    def __init__(self):
        self.lock = threading.RLock()
        self.started_at = time.time()
        self.awake = None
        self.awake_until = None
        self.tasks = {"status": "unknown", "active": None, "total": None, "checkedAt": None}
        self._last_task_check = 0.0
        self._checking = False

    def awake_state(self):
        with self.lock:
            live = self.awake is not None and self.awake.poll() is None
            if not live:
                self.awake = None
                self.awake_until = None
            return {"active": live, "expiresAt": self.awake_until if live else None}

    def start_awake(self, minutes):
        if type(minutes) is not int or minutes < 0 or minutes > 480:
            raise ValueError("duration must be an integer from 0 to 480 minutes")
        with self.lock:
            self.stop_awake()
            args = ["/usr/bin/caffeinate", "-dimsu"]
            if minutes > 0:
                args.extend(["-t", str(minutes * 60)])
            self.awake = subprocess.Popen(args, stdin=subprocess.DEVNULL,
                                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            self.awake_until = time.time() + minutes * 60 if minutes else None
            return self.awake_state()

    def stop_awake(self):
        with self.lock:
            if self.awake is not None and self.awake.poll() is None:
                self.awake.terminate()
                try:
                    self.awake.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    self.awake.kill()
                    self.awake.wait(timeout=2)
            self.awake = None
            self.awake_until = None
            return {"active": False, "expiresAt": None}

    def update_tasks_async(self, force=False):
        with self.lock:
            if self._checking or (not force and time.time() - self._last_task_check < 90):
                return
            self._checking = True
            self._last_task_check = time.time()

        def collect():
            data = {"status": "unavailable", "active": None, "total": None, "checkedAt": time.time()}
            try:
                result = subprocess.run(["/opt/homebrew/bin/codex", "cloud", "list", "--json", "--limit", "20"],
                                        capture_output=True, text=True, timeout=8, check=False)
                if result.returncode == 0:
                    parsed = json.loads(result.stdout)
                    entries = parsed if isinstance(parsed, list) else (
                        parsed.get("tasks", []) if isinstance(parsed, dict) else []
                    )
                    if isinstance(entries, list):
                        active = 0
                        for item in entries:
                            if isinstance(item, dict) and str(item.get("status", "")).lower() in (
                                "pending", "queued", "running", "in_progress", "in-progress", "started"
                            ):
                                active += 1
                        data.update(status="observed", active=active, total=len(entries))
            except (OSError, subprocess.SubprocessError, ValueError):
                pass
            finally:
                with self.lock:
                    self.tasks = data
                    self._checking = False

        threading.Thread(target=collect, name="BifrostTaskCollector", daemon=True).start()

    def raven_status(self):
        try:
            result = subprocess.run(["/bin/launchctl", "print",
                                     "gui/{}/eden.bifrost.raven-bridge".format(os.getuid())],
                                    capture_output=True, text=True, timeout=2, check=False)
            if result.returncode == 0 and "state = running" in result.stdout:
                return "running"
            return "unavailable" if result.returncode else "stopped"
        except (OSError, subprocess.SubprocessError):
            return "unknown"

    def state(self):
        self.update_tasks_async()
        with self.lock:
            task = dict(self.tasks)
        return {
            "headless": {"status": "running", "pid": os.getpid(), "startedAt": self.started_at,
                         "identity": RUNTIME_IDENTITY},
            "tasks": task,
            "caffeinate": self.awake_state(),
            "raven": {"bridge": self.raven_status(), "integration": "separate-provider"},
            "ai": {"routing": read_preferences()["aiRouting"], "provider": "not-configured"},
            "preferences": read_preferences()
        }

    def shutdown(self):
        self.stop_awake()


RUNTIME = Runtime()


def allowed_host(host, port=None):
    port = PORT if port is None else port
    return host in ("127.0.0.1:{}".format(port), "localhost:{}".format(port))


class Handler(BaseHTTPRequestHandler):
    server_version = "BIFROSTHeadless/0.1"
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        sys.stderr.write("%s %s\n" % (self.log_date_time_string(), fmt % args))

    def response(self, status, obj):
        if status >= 400:
            self.close_connection = True
        raw = json.dumps(obj).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(raw)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        if status >= 400:
            self.send_header("Connection", "close")
        self.send_header("Content-Security-Policy", "default-src 'none'")
        self.end_headers()
        self.wfile.write(raw)

    def host_ok(self):
        return allowed_host(self.headers.get("Host", ""))

    def authentic(self):
        host = self.headers.get("Host", "")
        origin = self.headers.get("Origin")
        if origin and origin not in ("http://127.0.0.1:{}".format(PORT),
                                    "http://localhost:{}".format(PORT)):
            return False
        return (self.host_ok() and
                secrets.compare_digest(self.headers.get("X-Bifrost-Token", ""), get_token()))

    def do_GET(self):
        if not self.host_ok():
            return self.response(403, {"error": "invalid host"})
        route = urlsplit(self.path).path
        static_resources = {
            "/": ("index.html", "text/html"),
            "/index.html": ("index.html", "text/html"),
            "/dashboard.js": ("dashboard.js", "text/javascript"),
            "/dashboard.css": ("dashboard.css", "text/css"),
            "/manifest.webmanifest": ("manifest.webmanifest", "application/manifest+json"),
            "/sw.js": ("sw.js", "text/javascript"),
            "/offline.html": ("offline.html", "text/html"),
            "/icons/icon-192.png": ("icons/icon-192.png", "image/png"),
            "/icons/icon-512.png": ("icons/icon-512.png", "image/png"),
        }
        if route in static_resources:
            name, mime = static_resources[route]
            path = WEBROOT / name
            try:
                data = path.read_bytes()
            except OSError:
                return self.response(404, {"error": "missing dashboard resource"})
            self.send_response(200)
            self.send_header("Content-Type", mime + (
                "; charset=utf-8" if mime.startswith("text/") or mime.endswith("+json") else ""
            ))
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.send_header("Content-Security-Policy",
                             "default-src 'none'; script-src 'self'; worker-src 'self'; manifest-src 'self'; "
                             "img-src 'self'; style-src 'self'; connect-src 'self'; base-uri 'none'; "
                             "form-action 'none'; frame-ancestors 'none'")
            self.end_headers()
            return self.wfile.write(data)
        if route == "/api/pwa/adapter":
            return self.response(200, {
                "schema": "bifrost.pwa.adapter.v1",
                "representation": "local-headless-pwa",
                "transport": "same-origin-loopback",
                "node": {"status": "running", "authority": "Headless"},
                "capabilities": [
                    {"id": "node.state.read", "method": "GET", "route": "/api/state",
                     "enabled": True, "effect": "read"},
                    {"id": "setup.catalog.read", "method": "GET",
                     "route": "/api/setup/catalog", "enabled": True, "effect": "read"},
                    {"id": "setup.stage", "method": "POST",
                     "route": "/api/setup/stage", "enabled": True,
                     "effect": "local-write", "requires": "local-session-and-confirmation"},
                    {"id": "kernel.status.read", "method": "GET",
                     "route": "/api/kernel/status", "enabled": True, "effect": "read"},
                    {"id": "kernel.search.read", "method": "GET",
                     "route": "/api/kernel/search", "enabled": True,
                     "effect": "read", "requires": "local-session"},
                    {"id": "kernel.scan", "enabled": False,
                     "effect": "local-write", "requires": "explicit-cli-or-native-approval"},
                    {"id": "remote.setup.execute", "enabled": False, "effect": "remote-write"},
                ],
                "optionalRemoteProvider": {
                    "name": "RavenNest",
                    "url": "https://lucas-raven.pages.dev/",
                    "agent": RUNTIME.raven_status(),
                    "mobilePairingVerified": False,
                    "directApiProxy": False,
                },
                "offlineActionsEnabled": False,
                "crossOriginApiEnabled": False,
            })
        if route == "/api/kernel/status":
            return self.response(200, core_adapter.status(SUPPORT))
        if route == "/api/kernel/search":
            if not self.authentic():
                return self.response(403, {"error": "local session required"})
            query = parse_qs(urlsplit(self.path).query, keep_blank_values=True)
            if set(query) - {"q", "limit"}:
                return self.response(400, {"error": "unsupported search parameter"})
            try:
                term = query.get("q", [""])[0]
                limit = int(query.get("limit", ["25"])[0])
                return self.response(200, core_adapter.search(SUPPORT, term, limit))
            except (ValueError, OSError, RuntimeError, sqlite3.Error):
                return self.response(400, {"error": "invalid or unavailable kernel query"})
        if route == "/api/setup/catalog":
            return self.response(200, setups.catalog())
        if route == "/api/health":
            return self.response(200, {"ok": True, "service": "BIFROST Headless",
                                       "identity": RUNTIME_IDENTITY})
        if route == "/api/mobile/bridge":
            return self.response(200, {
                "provider": "RavenNest",
                "url": "https://lucas-raven.pages.dev/",
                "agent": RUNTIME.raven_status(),
                "headlessRemoteControl": "not-enabled",
                "mobilePairingVerified": False,
                "localAPIExposed": False,
            })
        if route == "/api/state":
            return self.response(200, RUNTIME.state())
        if route == "/api/session":
            return self.response(200, {"token": get_token()})
        return self.response(404, {"error": "not found"})

    def do_POST(self):
        if not self.authentic():
            return self.response(403, {"error": "unauthorized"})
        route = urlsplit(self.path).path
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if length < 1 or length > 4096:
                return self.response(400, {"error": "invalid body size"})
            raw = self.rfile.read(length)
            data = json.loads(raw)
            if not isinstance(data, dict):
                return self.response(400, {"error": "expected JSON object"})
        except (ValueError, OSError):
            return self.response(400, {"error": "invalid JSON"})
        if route == "/api/setup/stage":
            if set(data) != {"id"} or not isinstance(data["id"], str):
                return self.response(400, {"error": "invalid package id"})
            try:
                return self.response(200, setups.stage_package(data["id"]))
            except (OSError, setups.SetupError, zipfile.BadZipFile) as error:
                return self.response(422, {"error": str(error)})
        if route == "/api/preferences":
            if set(data) - set(DEFAULTS):
                return self.response(400, {"error": "unknown preference"})
            merged = read_preferences()
            merged.update(data)
            return self.response(200, {"preferences": save_preferences(merged)})
        if route == "/api/control":
            try:
                action = data.get("action")
                if action == "caffeinate.start":
                    minutes = data.get("minutes", read_preferences()["caffeinateMinutes"])
                    return self.response(200, {"caffeinate": RUNTIME.start_awake(minutes)})
                if action == "caffeinate.stop":
                    return self.response(200, {"caffeinate": RUNTIME.stop_awake()})
                if action == "tasks.refresh":
                    RUNTIME.update_tasks_async(force=True)
                    return self.response(200, {"accepted": True})
            except (OSError, ValueError) as error:
                return self.response(400, {"error": str(error)})
            return self.response(400, {"error": "unknown action"})
        return self.response(404, {"error": "not found"})


def run_server():
    ensure_private_dir()
    get_token()
    if not PREFS.exists():
        save_preferences(DEFAULTS)
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    server.daemon_threads = True
    server.timeout = 1

    def halt(_signum, _frame):
        # Avoid deadlock: shutdown must run off the serving thread.
        threading.Thread(target=server.shutdown, daemon=True).start()

    signal.signal(signal.SIGTERM, halt)
    signal.signal(signal.SIGINT, halt)
    print("BIFROST Headless local dashboard at http://{}:{}/".format(HOST, PORT), flush=True)
    try:
        server.serve_forever(poll_interval=0.5)
    finally:
        RUNTIME.shutdown()
        server.server_close()


if __name__ == "__main__":
    run_server()
