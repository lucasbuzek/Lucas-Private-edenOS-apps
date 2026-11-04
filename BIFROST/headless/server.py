#!/usr/bin/env python3
"""BIFROST Headless: independent local runtime, compact web dashboard and shared state.

The runtime is deliberately independent of SwiftUI and external online plugins.
Binds ONLY to localhost. Mutations require a short-lived same-origin session
request plus a locally stored secret, never exposed over the network.
"""
import json
import hashlib
import os
import pathlib
import plistlib
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
import core_runtime as runtime_inventory
import storage_adapter as storage_metadata
import task_ledger as local_tasks
import orchestration as local_orchestration
import connection_observer as observed_connections
import connectivity_checks
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
    "statusIndicators": ["headless"],
    "caffeinateMinutes": 60,
    "dashboardSections": ["headless", "caffeinate"]
}
ALLOWED_INDICATORS = {"headless"}
ALLOWED_SECTIONS = {"headless", "caffeinate"}


def normalize(settings):
    src = settings if isinstance(settings, dict) else {}
    result = dict(DEFAULTS)
    if isinstance(src.get("statusIndicators"), list):
        result["statusIndicators"] = list(dict.fromkeys(
            x for x in src["statusIndicators"] if isinstance(x, str) and x in ALLOWED_INDICATORS
        ))
    if type(src.get("caffeinateMinutes")) is int and src["caffeinateMinutes"] in (0, 5, 10, 15, 30, 45, 60, 90, 120, 180, 240, 360, 480):
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

    def state(self):
        return {
            "headless": {"status": "running", "pid": os.getpid(), "startedAt": self.started_at,
                         "identity": RUNTIME_IDENTITY},
            "caffeinate": self.awake_state(),
            "preferences": read_preferences(),
            "connectionScope": "local-only"
        }

    def shutdown(self):
        self.stop_awake()


RUNTIME = Runtime()
ORCHESTRATOR = local_orchestration.Orchestrator(SUPPORT)


def allowed_host(host, port=None):
    port = PORT if port is None else port
    return host in ("127.0.0.1:{}".format(port), "localhost:{}".format(port))


def approved_native_app_path():
    """Resolve only the BIFROST app selected in the native menu or Settings.

    No client request can create or change this record. Refuse a stale,
    unapproved or incorrectly identified bundle rather than opening whatever
    LaunchServices currently associates with the bundle identifier.
    """
    path = SUPPORT / "native-app.json"
    try:
        if path.stat().st_mode & 0o077:
            raise OSError("BIFROST app approval record is not private")
        data = json.loads(path.read_text(encoding="utf-8"))
        if (set(data) != {"schema", "bundleIdentifier", "path"} or
            data["schema"] != "bifrost.native-app.v1" or
            data["bundleIdentifier"] != "eden.private.bifrost" or
            not isinstance(data["path"], str)):
            raise OSError("BIFROST app approval record is invalid")
        chosen = pathlib.Path(data["path"])
        if (not chosen.is_absolute() or chosen.suffix.lower() != ".app" or
            chosen.is_symlink() or not chosen.is_dir()):
            raise OSError("BIFROST app path is no longer valid")
        with (chosen / "Contents" / "Info.plist").open("rb") as handle:
            bundle = plistlib.load(handle)
        if bundle.get("CFBundleIdentifier") != "eden.private.bifrost":
            raise OSError("Approved application identity no longer matches BIFROST")
        return chosen
    except (FileNotFoundError, ValueError, TypeError, KeyError, plistlib.InvalidFileException) as exc:
        raise OSError("Select a valid BIFROST native app in the menu controller") from exc


def open_native_bifrost():
    """Launch the exact pre-approved local BIFROST bundle by user action only."""
    if sys.platform != "darwin":
        raise OSError("BIFROST native app launch is supported only on macOS")
    chosen = approved_native_app_path()
    result = subprocess.run(
        ["/usr/bin/open", "-a", str(chosen)],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=6,
        check=False,
    )
    if result.returncode != 0:
        raise OSError("Approved BIFROST native app launch was not accepted")
    return {"accepted": True, "action": "app.open",
            "execution": "macos-launchservices-approved-app",
            "uiVisibleVerified": False}


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
            "/connection_fabric.js": ("connection_fabric.js", "text/javascript"),
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
                    {"id": "node.status.typed.read", "method": "GET", "route": "/api/status/v1",
                     "enabled": True, "effect": "read", "requires": "local-session"},
                    {"id": "bifrost.native.app.open", "method": "POST", "route": "/api/control",
                     "enabled": sys.platform == "darwin", "effect": "user-visible-app-launch",
                     "requires": "local-session-and-explicit-user-action"},
                    {"id": "orchestration.local.workflow", "method": "POST",
                     "route": "/api/orchestration/v1", "enabled": sys.platform == "darwin",
                     "effect": "confirmed-native-workflow",
                     "requires": "local-session-user-confirmation-installed-catalog"},
                    {"id": "tasks.local.observe", "method": "POST", "route": "/api/tasks/v1",
                     "enabled": True, "effect": "local-observation-receipt",
                     "requires": "local-session-and-user-action"},
                    {"id": "tasks.local.list", "method": "GET", "route": "/api/tasks/v1",
                     "enabled": True, "effect": "read", "requires": "local-session"},
                    {"id": "setup.catalog.read", "method": "GET",
                     "route": "/api/setup/catalog", "enabled": True, "effect": "read"},
                    {"id": "setup.stage", "method": "POST",
                     "route": "/api/setup/stage", "enabled": True,
                     "effect": "local-write", "requires": "local-session-and-confirmation"},
                    {"id": "bifrostcore.runtime.observe", "method": "GET",
                     "route": "/api/core/v1", "enabled": True,
                     "effect": "read", "requires": "local-session",
                     "execution": "read-only-federation"},
                    {"id": "bifrost.storage.catalog.read", "method": "GET",
                     "route": "/api/storage/v1", "enabled": True,
                     "effect": "metadata-read", "requires": "local-session",
                     "execution": "bifrostcore-storage"},
                    {"id": "bifrost.storage.accounts.metadata.read", "method": "GET",
                     "route": "/api/storage/v1/accounts", "enabled": True,
                     "effect": "private-metadata-read", "requires": "local-session",
                     "execution": "bifrostcore-storage"},
                    {"id": "bifrost.storage.profile.preview", "method": "POST",
                     "route": "/api/storage/v1/preview", "enabled": True,
                     "effect": "bounded-metadata-read", "requires": "local-session",
                     "execution": "explicit-saved-profile-and-selected-folder"},
                    {"id": "kernel.status.read", "method": "GET",
                     "route": "/api/kernel/status", "enabled": True, "effect": "read"},
                    {"id": "kernel.search.read", "method": "GET",
                     "route": "/api/kernel/search", "enabled": True,
                     "effect": "read", "requires": "local-session"},
                    {"id": "kernel.scan", "enabled": False,
                     "effect": "local-write", "requires": "explicit-cli-or-native-approval"},
                ],
                "onlineExecution": "not-bundled",
                "externalPlugins": "independently-installed",
                "offlineActionsEnabled": False,
                "crossOriginApiEnabled": False,
            })
        if route in ("/api/storage/v1", "/api/storage/v1/accounts", "/api/storage/v1/profiles"):
            # Storage exposes metadata only, through the SAME private
            # Headless session, identity, Host and Origin checks as Core.
            # Never permit a path or command via arbitrary query strings.
            if not self.authentic():
                return self.response(403, {"error": "local session required"})
            if urlsplit(self.path).query:
                return self.response(400, {"error": "unsupported storage query"})
            try:
                payload = (storage_metadata.catalog()
                           if route == "/api/storage/v1"
                           else storage_metadata.profiles() if route.endswith("/profiles")
                           else storage_metadata.accounts())
            except (OSError, RuntimeError, ValueError, UnicodeError):
                return self.response(503, {"error": "storage metadata unavailable"})
            return self.response(200, payload)
        if route == "/api/core/v1":
            if not self.authentic():
                return self.response(403, {"error": "local session required"})
            # Observe current known Core/Headless identities without starting
            # legacy services or reading any credentials or databases.
            return self.response(200, runtime_inventory.snapshot(
                headless_identity=RUNTIME_IDENTITY, headless_runtime=WEBROOT))
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
        if route == "/api/connections/v1":
            if not self.authentic():
                return self.response(403, {"error": "local session required"})
            if urlsplit(self.path).query:
                return self.response(400, {"error": "no connection query parameters"})
            return self.response(200, observed_connections.snapshot(runtime_id=RUNTIME_IDENTITY["runtimeId"]))
        if route == "/api/orchestration/v1":
            if not self.authentic():
                return self.response(403, {"error": "local session required"})
            return self.response(200, {"status": ORCHESTRATOR.status(),
                                       "catalog": local_orchestration.catalog()})
        if route == "/api/tasks/v1":
            if not self.authentic():
                return self.response(403, {"error": "local session required"})
            query = parse_qs(urlsplit(self.path).query, keep_blank_values=True)
            if set(query) - {"limit"} or any(len(value) != 1 for value in query.values()):
                return self.response(400, {"error": "unsupported list parameters"})
            try:
                limit = int(query.get("limit", ["20"])[0])
                return self.response(200, local_tasks.recent(SUPPORT, limit))
            except (ValueError, OSError, sqlite3.Error) as exc:
                return self.response(400, {"error": "invalid or unavailable local ledger"})
        if route.startswith("/api/tasks/v1/"):
            if not self.authentic():
                return self.response(403, {"error": "local session required"})
            try:
                record = local_tasks.get(SUPPORT, route[len("/api/tasks/v1/"):])
            except (ValueError, OSError, sqlite3.Error):
                return self.response(400, {"error": "invalid local task id"})
            return self.response(200, record) if record else self.response(404, {"error": "local task not found"})
        if route == "/api/status/v1":
            # Read-only, typed local status. This is NOT a task submission or
            # proof of remote execution. Never issue fabricated task IDs.
            if not self.authentic():
                return self.response(403, {"error": "local session required"})
            snapshot = RUNTIME.state()
            return self.response(200, {
                "schema": "bifrost.status.v1",
                "kind": "node.status",
                "taskId": None,
                "taskState": "not-submitted",
                "execution": "local-readonly-status",
                "authority": "local-headless",
                "observedAt": int(time.time()),
                "headless": snapshot.get("headless", {}),
                "connectionScope": "local-only",
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
        if route == "/api/storage/v1/preview":
            if (urlsplit(self.path).query or
                set(data) - {"profile", "folder", "readRemote"} or
                not isinstance(data.get("profile"), str) or
                not isinstance(data.get("folder", ""), str) or
                type(data.get("readRemote", False)) is not bool):
                return self.response(400, {"error": "invalid storage selection"})
            try:
                result = storage_metadata.preview(
                    data["profile"], folder=data.get("folder", ""),
                    read_remote=data.get("readRemote", False))
            except (ValueError, TypeError):
                return self.response(422, {"error": "storage scope or account denied"})
            except (OSError, RuntimeError, UnicodeError):
                return self.response(503, {"error": "storage preview unavailable"})
            return self.response(200, result)
        if route == "/api/connections/diagnose":
            if (urlsplit(self.path).query or set(data) != {"scope", "confirmed"}
                    or data.get("confirmed") is not True
                    or data.get("scope") not in connectivity_checks.ALLOWED):
                return self.response(400, {"error": "explicit fixed-scope network check consent required"})
            try:
                return self.response(200, connectivity_checks.check(
                    data["scope"], confirmed=True))
            except (ValueError, PermissionError, TypeError):
                return self.response(422, {"error": "network diagnostic denied or unavailable"})
        if route == "/api/connections/scan":
            if (urlsplit(self.path).query or set(data) != {"start", "end", "confirmed"}
                    or data.get("confirmed") is not True):
                return self.response(400, {"error": "explicit confirmed LAN range required"})
            try:
                return self.response(202, {"scan": observed_connections.MONITOR.begin(
                    data["start"], data["end"], confirmed=True)})
            except (ValueError, TypeError):
                return self.response(422, {"error": "LAN scan range unavailable or denied"})
        if route == "/api/orchestration/v1":
            if set(data) != {"action", "kind", "id", "confirmed"} or\
               data.get("action") != "workflow.run" or data.get("confirmed") is not True:
                return self.response(400, {"error": "explicit confirmed workflow selection required"})
            try:
                return self.response(200, {"receipt": ORCHESTRATOR.run(data["kind"], data["id"])})
            except (ValueError, TypeError):
                return self.response(409, {"error": "workflow unavailable, unapproved or already running"})
        if route == "/api/tasks/v1":
            try:
                snapshot = {"caffeinateActive": RUNTIME.awake_state()["active"]}
                receipt, created = local_tasks.record(SUPPORT, data, snapshot)
                return self.response(201 if created else 200, receipt)
            except (ValueError, OSError, sqlite3.Error):
                return self.response(400, {"error": "invalid or unavailable local observation"})
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
                if action == "app.open":
                    if set(data) != {"action"}:
                        return self.response(400, {"error": "unsupported app launch argument"})
                    try:
                        return self.response(200, open_native_bifrost())
                    except (OSError, subprocess.TimeoutExpired):
                        return self.response(409, {"error": "BIFROST native app unavailable or launch not accepted"})
                if action == "caffeinate.start":
                    minutes = data.get("minutes", read_preferences()["caffeinateMinutes"])
                    return self.response(200, {"caffeinate": RUNTIME.start_awake(minutes)})
                if action == "caffeinate.stop":
                    return self.response(200, {"caffeinate": RUNTIME.stop_awake()})
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
    ORCHESTRATOR.start()
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
        ORCHESTRATOR.shutdown()
        RUNTIME.shutdown()
        server.server_close()


if __name__ == "__main__":
    run_server()
