"""BIFROSTcore v1 read-only runtime inventory and terminal entry point.

This reconciles observation of the existing *separate* BIFROST Headless and
legacy Core installations. It never imports legacy app.py (which has database
initialization side effects), opens provider credential stores, changes
launchd, starts services, migrates a database or makes a remote provider call.

One schema is used by the CLI and the optional authenticated Headless API.
Do not interpret this observed federation as a unified execution ledger.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import stat
import subprocess
import sys
import time
import urllib.error
import urllib.request

SCHEMA = "bifrost.core.runtime-state.v1"
HEADLESS_PRODUCT = "eden.bifrost.headless"
LEGACY_LABEL = "org.eden.bifrost.core"
HEADLESS_ENDPOINT = "http://127.0.0.1:8798/api/health"
MAX_SOURCE = 2 * 1024 * 1024
MAX_PLIST = 64 * 1024
MAX_HTTP = 8192


def _regular_bytes(path: Path, limit: int) -> bytes:
    """Read one bounded regular file without following a final symlink."""
    flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
    fd = os.open(str(path), flags)
    try:
        before = os.fstat(fd)
        if not stat.S_ISREG(before.st_mode) or before.st_size > limit:
            raise OSError("unsafe or oversized source")
        data = bytearray()
        while True:
            part = os.read(fd, min(65536, limit + 1 - len(data)))
            if not part:
                break
            data.extend(part)
            if len(data) > limit:
                raise OSError("oversized source")
        after = os.fstat(fd)
        if (before.st_ino, before.st_size, before.st_mtime_ns) != (
                after.st_ino, after.st_size, after.st_mtime_ns):
            raise OSError("source changed during observation")
        return bytes(data)
    finally:
        os.close(fd)


def _sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _valid_headless(identity: object, runtime_path: Path) -> bool:
    """A reply is trusted only when its identity matches installed source."""
    if not isinstance(identity, dict):
        return False
    if identity.get("schema") != "bifrost.headless.identity.v1":
        return False
    if identity.get("productId") != HEADLESS_PRODUCT:
        return False
    if identity.get("runtimeId") != _sha(str(runtime_path).encode())[:16]:
        return False
    source_hash = identity.get("sourceSha256")
    if not isinstance(source_hash, str) or not re.fullmatch(r"[a-f0-9]{64}", source_hash):
        return False
    try:
        return _sha(_regular_bytes(runtime_path / "server.py", MAX_SOURCE)) == source_hash
    except (OSError, ValueError):
        return False


def _request_headless(timeout: float) -> object:
    """Loopback-only, proxy-free health check with bounded response."""
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    request = urllib.request.Request(HEADLESS_ENDPOINT, method="GET")
    with opener.open(request, timeout=timeout) as response:
        if response.status != 200:
            return None
        payload = response.read(MAX_HTTP + 1)
    if len(payload) > MAX_HTTP:
        return None
    return json.loads(payload)


def headless_state(home: Path, *, identity: object = None,
                   runtime_path: Path | None = None,
                   request_health=None) -> dict:
    # Old installed Headless uses BIFROST/runtime/server.py. The recovered
    # no-overwrite installer places its server in HeadlessRuntime/headless/.
    # Reconcile only these two established layouts; require exact hash and
    # runtime ID, never accept an arbitrary service claiming to be BIFROST.
    candidates = ((runtime_path,) if runtime_path is not None else (
        home / "Library/Application Support/BIFROST/runtime",
        home / "Library/Application Support/BIFROST/HeadlessRuntime/headless"))
    provenance = "in-process" if identity is not None else "bounded-local-health"
    if identity is None:
        try:
            reply = (request_health or _request_headless)(0.65)
            identity = reply.get("identity") if isinstance(reply, dict) and reply.get("ok") is True else None
        except (OSError, ValueError, TimeoutError, urllib.error.URLError):
            return {"state": "not-observed", "health": "unavailable",
                    "provenance": provenance}
        if identity is None:
            return {"state": "unverified", "health": "unknown",
                    "provenance": provenance}
    if not any(_valid_headless(identity, candidate) for candidate in candidates):
        return {"state": "unverified", "health": "unknown",
                "provenance": provenance}
    return {
        "state": "identity-verified",
        "health": "responsive" if provenance == "bounded-local-health" else "serving-request",
        "provenance": provenance,
        "runtimeId": identity["runtimeId"],
        "sourceSha256": identity["sourceSha256"],
        "productId": HEADLESS_PRODUCT,
    }


def _launchctl_registration(label: str) -> str:
    if sys.platform != "darwin":
        return "not-supported"
    try:
        result = subprocess.run(
            ["/bin/launchctl", "print", "gui/{}/{}".format(os.getuid(), label)],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL, timeout=1.0, check=False)
        return "registered" if result.returncode == 0 else "not-registered"
    except (OSError, subprocess.TimeoutExpired):
        return "unknown"


def legacy_core_state(home: Path, *, launchctl_status=None) -> dict:
    """Do not connect to the legacy port or inspect old credentials/databases."""
    source = home / "Library/Application Support/EDEN/BIFROST/Core/app.py"
    plist = home / "Library/LaunchAgents/org.eden.bifrost.core.plist"
    result = {
        "state": "not-observed",
        "health": "unknown",
        "launchdLabel": LEGACY_LABEL,
        "registration": "unknown",
        "databaseCompatibility": "unverified",
        "executionOwner": "legacy-core-unchanged",
    }
    try:
        script = _regular_bytes(source, MAX_SOURCE)
    except (OSError, ValueError):
        result["state"] = "source-unavailable"
        return result
    result["sourceSha256"] = _sha(script)
    match = re.search(rb"\bVERSION\s*=\s*['\"]([0-9]+(?:\.[0-9]+){1,3})['\"]", script[:4096])
    if match:
        result["sourceVersion"] = match.group(1).decode("ascii")
    try:
        descriptor = plistlib.loads(_regular_bytes(plist, MAX_PLIST))
        args = descriptor.get("ProgramArguments")
        if (descriptor.get("Label") != LEGACY_LABEL or
            not isinstance(args, list) or len(args) != 2 or
            not isinstance(args[0], str) or not args[0].startswith("/") or
            args[1] != str(source)):
            result["state"] = "unexpected-launch-configuration"
            return result
    except (OSError, ValueError, TypeError, plistlib.InvalidFileException):
        result["state"] = "launch-configuration-unavailable"
        return result
    result["state"] = "configured-only"
    try:
        result["registration"] = (launchctl_status or _launchctl_registration)(LEGACY_LABEL)
    except (OSError, ValueError):
        result["registration"] = "unknown"
    # A launchd registration never establishes service health or BIFROST identity.
    return result


def snapshot(home: Path | None = None, *,
             headless_identity: object = None,
             headless_runtime: Path | None = None,
             request_health=None, launchctl_status=None) -> dict:
    """Observed local connective state. No service activation or state merge."""
    home = home or Path.home()
    headless = headless_state(
        home, identity=headless_identity, runtime_path=headless_runtime,
        request_health=request_health)
    legacy = legacy_core_state(home, launchctl_status=launchctl_status)
    return {
        "schema": SCHEMA,
        "product": "BIFROST",
        "runtime": "BIFROSTcore",
        "observedAt": int(time.time()),
        "mode": "read-only-federation",
        "headless": headless,
        "legacyCore": legacy,
        "stateOwnership": {
            "headless": "existing-headless-local-store",
            "legacyCore": "existing-legacy-store",
            "unifiedDatabase": False,
            "migrationPerformed": False,
        },
        "operations": {
            "remoteExecutionVerified": False,
            "sharedDispatcherVerified": False,
            "credentialsRead": False,
            "externalProviderCalls": False,
            "serviceChanges": False,
        },
    }


def read_headless_preferences(home: Path) -> dict:
    """Read only the established, non-secret Headless preference fields."""
    path = home / "Library/Application Support/BIFROST/settings.json"
    defaults = {
        "statusIndicators": ["headless"],
        "caffeinateMinutes": 60,
        "dashboardSections": ["headless", "caffeinate"],
    }
    try:
        data = json.loads(_regular_bytes(path, 16384))
        if not isinstance(data, dict):
            return defaults
        if type(data.get("caffeinateMinutes")) is int and data["caffeinateMinutes"] in (0, 30, 60, 120):
            defaults["caffeinateMinutes"] = data["caffeinateMinutes"]
        if isinstance(data.get("statusIndicators"), list):
            defaults["statusIndicators"] = [
                "headless"] if "headless" in data["statusIndicators"] else []
        if isinstance(data.get("dashboardSections"), list):
            defaults["dashboardSections"] = [
                v for v in ("headless", "caffeinate") if v in data["dashboardSections"]]
    except (OSError, ValueError, TypeError):
        pass
    return defaults


def apply_headless_preference(home: Path, value: int) -> dict:
    """Explicit owner action using existing authenticated Headless preferences API.

    No service startup, legacy configuration access, credential reissue or
    independent settings store. Never return the existing local token.
    """
    observed = headless_state(home)
    if observed["state"] != "identity-verified":
        raise RuntimeError("Installed BIFROST Headless identity is not verified")
    token_file = home / "Library/Application Support/BIFROST/headless.token"
    st = token_file.lstat()
    if (not stat.S_ISREG(st.st_mode) or st.st_uid != os.getuid()
            or st.st_mode & 0o077):
        raise RuntimeError("Local Headless authorization file is not private")
    token = _regular_bytes(token_file, 512).decode("utf-8").strip()
    if not token or len(token) > 256:
        raise RuntimeError("Local Headless authorization is unavailable")
    payload = json.dumps({"caffeinateMinutes": value}).encode("utf-8")
    request = urllib.request.Request(
        "http://127.0.0.1:8798/api/preferences",
        data=payload, method="POST",
        headers={
            "X-Bifrost-Token": token,
            "Content-Type": "application/json",
            "Origin": "http://127.0.0.1:8798",
        },
    )
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(request, timeout=1.5) as response:
        data = response.read(MAX_HTTP + 1)
        if response.status != 200 or len(data) > MAX_HTTP:
            raise RuntimeError("Headless preference update was not accepted")
    result = json.loads(data)
    if (not isinstance(result, dict) or
        not isinstance(result.get("preferences"), dict) or
        result["preferences"].get("caffeinateMinutes") != value):
        raise RuntimeError("Headless preference update was not verified")
    # The shared settings file is the existing native GUI/Headless state.
    if read_headless_preferences(home)["caffeinateMinutes"] != value:
        raise RuntimeError("Shared Headless preference did not persist")
    return {"saved": True, "field": "caffeinateMinutes", "value": value,
            "authority": "existing-headless-preferences", "serviceRestarted": False}


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(
        prog="bifrostcore", description="BIFROSTcore runtime observation and approved local setup")
    commands = parser.add_subparsers(dest="command", required=True)
    status = commands.add_parser("status", help="Observe local BIFROST runtime identities")
    status.add_argument("--json", action="store_true", help="Emit versioned machine-readable JSON")
    config = commands.add_parser("config", help="Inspect or explicitly update existing Headless settings")
    config.add_argument("action", choices=("show", "set"))
    config.add_argument("key", nargs="?")
    config.add_argument("value", nargs="?")
    config.add_argument("--apply", action="store_true",
                        help="Explicitly save the supported local value; otherwise preview only")
    config.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    if args.command == "status":
        value = snapshot()
        if args.json:
            print(json.dumps(value, sort_keys=True, indent=2))
        else:
            headless = value["headless"]
            legacy = value["legacyCore"]
            print("BIFROSTcore · read-only runtime status")
            print("Headless: {} ({})".format(headless["state"], headless["health"]))
            print("Legacy Core: {} (launchd: {})".format(
                legacy["state"], legacy["registration"]))
            print("Databases: separate; shared dispatcher: not verified")
        return 0
    if args.command == "config":
        home = Path.home()
        current = read_headless_preferences(home)
        if args.action == "show":
            if args.key is not None or args.value is not None or args.apply:
                parser.error("config show accepts no key, value or --apply")
            result = {"schema": "bifrost.core.config-observation.v1",
                      "authority": "existing-headless-preferences",
                      "preferences": current, "written": False}
            print(json.dumps(result, indent=2, sort_keys=True) if args.json
                  else "BIFROST Headless settings (read-only): " + json.dumps(current, sort_keys=True))
            return 0
        if args.key != "caffeinateMinutes" or args.value is None:
            parser.error("supported initial setting: config set caffeinateMinutes 0|30|60|120")
        try:
            minutes = int(args.value)
        except ValueError:
            parser.error("caffeinateMinutes must be an integer")
        if str(minutes) != args.value or minutes not in (0, 30, 60, 120):
            parser.error("caffeinateMinutes must be 0, 30, 60, or 120")
        preview = {"schema": "bifrost.core.config-preview.v1",
                   "authority": "existing-headless-preferences",
                   "field": "caffeinateMinutes",
                   "oldValue": current["caffeinateMinutes"],
                   "newValue": minutes, "written": False}
        if not args.apply:
            print(json.dumps(preview, indent=2, sort_keys=True) if args.json
                  else "Preview only: caffeinateMinutes {} → {}. Add --apply to save.".format(
                      preview["oldValue"], minutes))
            return 0
        try:
            receipt = apply_headless_preference(home, minutes)
        except (OSError, ValueError, RuntimeError, urllib.error.URLError):
            print("BIFROSTcore: local configuration not verified; no service was started", file=sys.stderr)
            return 1
        print(json.dumps(receipt, indent=2, sort_keys=True) if args.json
              else "Saved and verified caffeinateMinutes = {} in existing Headless settings".format(minutes))
        return 0
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
