#!/usr/bin/env python3
"""THEMBIcouncil device endpoint: consent-gated files and subprocess provider.
Windows, macOS, Linux. Python >=3.10. No dependencies and no embedded credentials.
Pair ONLY after the device owner issues a one-use code from their own Council MCP.
"""
from __future__ import annotations
import argparse
import base64
import ctypes
import getpass
import json
import os
from pathlib import Path
import platform
import shlex
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request

API = "https://thembicouncil-mcp.lucasravensnest.workers.dev"
HOME = Path.home() / ".thembicouncil"
CONF = HOME / "agent.json"
MAX_READ = 60000
MAX_REPLY = 90000
DEFAULT_COMMANDS = {"whoami", "hostname", "date", "uname", "uptime", "ipconfig", "systeminfo", "tasklist"}
PLATFORM = {"Windows": "windows", "Darwin": "macos", "Linux": "linux"}.get(platform.system())


def require_owner_permissions():
    if not HOME.exists():
        HOME.mkdir(mode=0o700, parents=True)
    if os.name != "nt":
        os.chmod(HOME, 0o700)
    else:
        # The local user can view the token only after Windows DPAPI unprotects it.
        # Avoid sharing the configuration folder through synced/shared storage.
        if str(HOME).startswith("\\\\"):
            raise RuntimeError("A local, non-network Windows user profile is required.")


def _blob(raw: bytes):
    from ctypes import wintypes
    class DATA_BLOB(ctypes.Structure):
        _fields_ = [("cbData", wintypes.DWORD), ("pbData", ctypes.POINTER(ctypes.c_ubyte))]
    data = ctypes.create_string_buffer(raw)
    result = DATA_BLOB(len(raw), ctypes.cast(data, ctypes.POINTER(ctypes.c_ubyte)))
    return result, data, DATA_BLOB


def protect_token(token: str) -> dict:
    if os.name != "nt":
        return {"token": token, "storage": "owner-only-posix-file"}
    import ctypes.wintypes
    source, buf, Blob = _blob(token.encode("utf-8"))
    out = Blob()
    ok = ctypes.windll.crypt32.CryptProtectData(ctypes.byref(source), "THEMBIcouncil", None, None, None, 0, ctypes.byref(out))
    if not ok:
        raise RuntimeError("Windows DPAPI refused to protect the device token.")
    try:
        protected = ctypes.string_at(out.pbData, out.cbData)
        return {"dpapi": base64.b64encode(protected).decode(), "storage": "windows-user-dpapi"}
    finally:
        ctypes.windll.kernel32.LocalFree(ctypes.cast(out.pbData, ctypes.c_void_p))


def unprotect_token(obj: dict) -> str:
    if obj.get("storage") != "windows-user-dpapi":
        if os.name == "nt":
            raise RuntimeError("Windows requires a DPAPI-protected token.")
        return str(obj["token"])
    if os.name != "nt":
        raise RuntimeError("This device token belongs to another platform.")
    source, buf, Blob = _blob(base64.b64decode(obj["dpapi"]))
    out = Blob()
    ok = ctypes.windll.crypt32.CryptUnprotectData(ctypes.byref(source), None, None, None, None, 0, ctypes.byref(out))
    if not ok:
        raise RuntimeError("Windows cannot decrypt this account's device token.")
    try:
        return ctypes.string_at(out.pbData, out.cbData).decode("utf-8")
    finally:
        ctypes.windll.kernel32.LocalFree(ctypes.cast(out.pbData, ctypes.c_void_p))


def request(path: str, payload: dict, token: str | None = None) -> dict:
    headers = {"Content-Type": "application/json", "Accept": "application/json", "User-Agent": "THEMBIcouncil-Device/0.1"}
    if token:
        headers["Authorization"] = "Bearer " + token
    req = urllib.request.Request(API + path, data=json.dumps(payload).encode(), headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=25) as resp:
            data = resp.read(120000)
        return json.loads(data.decode("utf-8"))
    except urllib.error.HTTPError as e:
        # Never echo authentication tokens in errors/logs.
        raise RuntimeError("Cloud endpoint returned HTTP %s for %s" % (e.code, path))


def choose_roots(paths):
    roots = []
    for entry in paths:
        p = Path(entry).expanduser().resolve(strict=True)
        if not p.is_dir() or str(p) == p.anchor:
            raise ValueError("Each --root must name an existing specific folder, never an entire disk.")
        if p not in roots:
            roots.append(p)
    if not roots:
        raise ValueError("Specify at least one --root folder to allow.")
    return roots


def pair(args):
    if not PLATFORM:
        raise RuntimeError("Use Windows, macOS, or Linux.")
    if CONF.exists():
        raise RuntimeError("Already paired. Revoke the old device in your Council first, then remove local agent.json.")
    roots = choose_roots(args.root)
    print("Only these folder roots will be accessible:")
    for root in roots:
        print(" -", root)
    if input("Approve pairing this device and these directories? Type YES: ").strip() != "YES":
        raise RuntimeError("Pairing declined.")
    code = getpass.getpass("Enter the one-time Council pairing code: ").strip()
    if not code.startswith("tc_") or len(code) != 51:
        raise ValueError("Invalid one-use pairing code format.")
    result = request("/agent/claim", {"code": code, "label": args.label, "platform": PLATFORM})
    token = result.get("agent_token")
    if not token or not result.get("device_id"):
        raise RuntimeError("Council did not return a valid device registration.")
    require_owner_permissions()
    data = {"device_id": result["device_id"], "label": args.label,
            "platform": PLATFORM, "roots": [str(p) for p in roots],
            "allowed_commands": sorted(set(DEFAULT_COMMANDS) | set(args.allow_command or [])),
            "credentials": protect_token(token)}
    # Use exclusive creation; no accidental overwrite of an existing key.
    fd = os.open(str(CONF), os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    if os.name != "nt":
        os.chmod(CONF, 0o600)
    print("Paired device:", result["device_id"])
    print("Run: python thembicouncil_agent.py run")
    print("A visible prompt is required for EACH requested device action.")


def config():
    if not CONF.exists():
        raise RuntimeError("No local pairing. Run the pair command first.")
    cfg = json.loads(CONF.read_text(encoding="utf-8"))
    if cfg["platform"] != PLATFORM:
        raise RuntimeError("This pairing belongs to a different operating system.")
    cfg["token"] = unprotect_token(cfg["credentials"])
    cfg["roots"] = choose_roots(cfg["roots"])
    return cfg


def permitted(path: str, cfg, exists=False):
    p = Path(path).expanduser()
    if not p.is_absolute():
        raise ValueError("Use an absolute path inside one of your paired folders.")
    p = p.resolve(strict=exists)
    if not any(p == root or root in p.parents for root in cfg["roots"]):
        raise PermissionError("Path is outside approved folders.")
    return p


def execute(job: dict, cfg: dict):
    name = str(job.get("action", ""))
    a = job.get("args") or {}
    if name == "files.list":
        p = permitted(a.get("path", ""), cfg, exists=True)
        if not p.is_dir():
            raise ValueError("Not a directory.")
        found = sorted(p.iterdir(), key=lambda x: x.name.lower())
        return {"path": str(p), "entries": [
            {"name": c.name, "type": "directory" if c.is_dir() else "file", "bytes": c.stat().st_size if c.is_file() else None}
            for c in found[:100]], "truncated": len(found) > 100}
    if name == "files.read":
        p = permitted(a.get("path", ""), cfg, exists=True)
        if not p.is_file() or p.stat().st_size > MAX_READ:
            raise ValueError("Only UTF-8 text files up to 60 KB can be read.")
        return {"path": str(p), "content": p.read_text(encoding="utf-8")}
    if name == "files.write":
        p = permitted(a.get("path", ""), cfg)
        if not p.parent.is_dir():
            raise ValueError("Parent folder must exist.")
        content = a.get("content")
        if not isinstance(content, str) or len(content.encode("utf-8")) > MAX_READ:
            raise ValueError("Text limit exceeded.")
        mode = "w" if a.get("overwrite") is True else "x"
        with p.open(mode, encoding="utf-8", newline="\n") as f:
            f.write(content)
        return {"path": str(p), "bytes_written": len(content.encode("utf-8"))}
    if name == "terminal.exec":
        raw = a.get("command")
        if not isinstance(raw, str) or len(raw) > 1600:
            raise ValueError("Invalid command.")
        argv = shlex.split(raw, posix=os.name != "nt")
        if not argv:
            raise ValueError("Empty command.")
        exe = Path(argv[0]).name.lower().removesuffix(".exe")
        allowed = {x.lower().removesuffix(".exe") for x in cfg["allowed_commands"]}
        if exe not in allowed:
            raise PermissionError("Executable is not in this device's approved command list.")
        executable = shutil.which(argv[0])
        if executable is None:
            raise FileNotFoundError("Executable not available.")
        cwd = a.get("cwd")
        target = permitted(cwd, cfg, exists=True) if cwd else cfg["roots"][0]
        if not target.is_dir():
            raise ValueError("Working directory must be a permitted folder.")
        timeout = max(1, min(30, int(a.get("timeout_seconds") or 15)))
        run = subprocess.run([executable, *argv[1:]], cwd=target, capture_output=True, text=True,
                             encoding="utf-8", errors="replace", timeout=timeout, shell=False)
        return {"exit_code": run.returncode, "stdout": run.stdout[:30000], "stderr": run.stderr[:10000]}
    raise ValueError("Unknown device action; refusing execution.")


def run(args):
    cfg = config()
    print("Council device connected:", cfg["device_id"])
    print("Local user approval is required per job. Ctrl+C exits.")
    token = cfg.pop("token")
    try:
        while True:
            try:
                resp = request("/agent/poll", {}, token)
                job = resp.get("job")
                if not job:
                    time.sleep(max(4, args.interval))
                    continue
                print("\nREQUEST", job.get("id"), job.get("action"))
                print(json.dumps(job.get("args") or {}, indent=2)[:3000])
                print("Approved roots:", *(str(r) for r in cfg["roots"]), sep="\n - ")
                decision = input("Execute this exact action? Type YES: ").strip()
                if decision != "YES":
                    result = {"job_id": job["id"], "status": "denied", "error": "Declined by local device owner"}
                else:
                    try:
                        value = execute(job, cfg)
                        if len(json.dumps(value)) > MAX_REPLY:
                            raise ValueError("Result exceeds supported response limit.")
                        result = {"job_id": job["id"], "status": "completed", "result": value}
                    except (ValueError, OSError, PermissionError, subprocess.TimeoutExpired, UnicodeError) as exc:
                        result = {"job_id": job["id"], "status": "failed", "error": type(exc).__name__ + ": " + str(exc)[:400]}
                request("/agent/result", result, token)
                print("Result submitted:", result["status"])
            except (OSError, RuntimeError, ValueError) as exc:
                print("Connection issue:", type(exc).__name__, file=sys.stderr)
                if "HTTP 401" in str(exc):
                    print("Device pairing revoked or expired. Exiting.", file=sys.stderr)
                    break
                time.sleep(max(8, args.interval))
    except KeyboardInterrupt:
        print("\nStopped by owner.")


def main():
    ap = argparse.ArgumentParser(description="THEMBIcouncil consent-gated local device connector")
    sub = ap.add_subparsers(dest="action", required=True)
    paircmd = sub.add_parser("pair", help="Pair after Council issues an individual one-use code")
    paircmd.add_argument("--label", required=True, help="Friendly name (e.g. Thembi Windows)")
    paircmd.add_argument("--root", action="append", required=True, help="Allowed local folder; repeat for multiple")
    paircmd.add_argument("--allow-command", action="append", default=[], help="Explicitly allow a named executable")
    runp = sub.add_parser("run", help="Poll cloud for queued actions and ask owner per action")
    runp.add_argument("--interval", type=int, default=8, help="Poll interval in seconds (default 8)")
    args = ap.parse_args()
    try:
        pair(args) if args.action == "pair" else run(args)
    except (RuntimeError, ValueError, OSError) as exc:
        print("THEMBIcouncil device:", exc, file=sys.stderr)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
