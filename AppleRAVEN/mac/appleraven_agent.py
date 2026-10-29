#!/usr/bin/env python3
"""Owner-private AppleRAVEN native agent. No listening port or generic shell.

The cloud server must approve one-time pairing before any credentials are saved.
Only the exact allowed Shortcuts LIST operation is executed.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import platform
import secrets
import shutil
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request

SERVICE = "com.lucasbuzek.appleraven.device"
ENDPOINT = "https://appleraven-device.lucasravensnest.workers.dev"
MAX_REPLY = 8192

class Rejected(Exception):
    pass

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise Rejected("AppleRAVEN service redirect refused")

def post(endpoint, path, payload, token=None, timeout=15):
    if endpoint != ENDPOINT:
        raise Rejected("Only the pinned AppleRAVEN HTTPS service origin is permitted")
    data = json.dumps(payload, separators=(",", ":")).encode()
    if len(data) > 2048:
        raise Rejected("Request exceeds device service limit")
    headers = {"Content-Type": "application/json", "User-Agent": "AppleRAVEN-Mac/0.1-candidate"}
    if token:
        headers["Authorization"] = "Bearer " + token
    req = urllib.request.Request(endpoint + path, data=data, headers=headers, method="POST")
    try:
        with urllib.request.build_opener(NoRedirect()).open(req, timeout=timeout) as response:
            if response.status == 204:
                return {}
            raw = response.read(MAX_REPLY + 1)
            if len(raw) > MAX_REPLY:
                raise Rejected("Backend response too large")
            return json.loads(raw)
    except urllib.error.HTTPError as exc:
        raise Rejected("AppleRAVEN service HTTP " + str(exc.code)) from None

def keychain_get():
    """Read only this signed-in macOS user's device credential, not another account's."""
    import getpass
    result = subprocess.run(
        ["/usr/bin/security", "find-generic-password", "-s", SERVICE,
         "-a", getpass.getuser(), "-w"],
        capture_output=True, text=True, timeout=10)
    value = result.stdout.strip() if result.returncode == 0 else None
    return value if value and len(value) == 64 and all(c in "0123456789abcdef" for c in value) else None

def keychain_set(token):
    """Store device token using Security.framework, never a command-line argument."""
    if not isinstance(token, str) or len(token) != 64 or any(c not in "0123456789abcdef" for c in token):
        raise Rejected("Invalid device credential")
    if platform.system() != "Darwin":
        raise Rejected("Keychain enrollment is supported only on macOS")
    import ctypes
    import getpass
    from ctypes import c_void_p, c_uint32, c_char_p, c_int32, POINTER
    service = SERVICE.encode("utf-8")
    account = getpass.getuser().encode("utf-8")
    secret = token.encode("ascii")
    sec = ctypes.CDLL("/System/Library/Frameworks/Security.framework/Security")
    add = sec.SecKeychainAddGenericPassword
    add.argtypes = [c_void_p, c_uint32, c_char_p, c_uint32, c_char_p,
                    c_uint32, c_char_p, POINTER(c_void_p)]
    add.restype = c_int32
    status = add(None, len(service), service, len(account), account,
                 len(secret), secret, None)
    if status != 0:
        # Never echo any secret bytes, even in failure paths.
        raise Rejected("macOS Keychain rejected the device credential: OSStatus " + str(status))

def native_shortcuts():
    if not shutil.which("shortcuts"):
        return {"ok": False, "error": "Shortcuts CLI unavailable"}
    try:
        r = subprocess.run(["shortcuts", "list"], capture_output=True, text=True,
                           timeout=20, check=False)
        original = r.stdout.strip() if r.returncode == 0 else ""
        output = original[:2800]
        while len(json.dumps(output).encode()) > 1500:
            output = output[:-1]
        return {"ok": r.returncode == 0,
                "shortcuts": output, "truncated": len(output) < len(original),
                "error": "" if r.returncode == 0 else "Shortcuts command failed"}
    except (subprocess.TimeoutExpired, OSError):
        return {"ok": False, "error": "Shortcuts operation unavailable"}

def pair():
    if platform.system() != "Darwin":
        raise Rejected("Pairing must take place on macOS")
    if keychain_get():
        raise Rejected("A credential already exists; refusing to replace it")
    proof = secrets.token_hex(32)
    data = post(ENDPOINT, "/v1/pair/start", {
        "device_name": socket.gethostname()[:64],
        "challenge": hashlib.sha256(proof.encode()).hexdigest()
    })
    request_id, code = data.get("request_id"), data.get("code")
    if not isinstance(request_id, str) or not isinstance(code, str):
        raise Rejected("Pairing service did not return an approval challenge")
    print("Open https://appleraven-private.lucasravensnest.workers.dev/pair")
    print("Enter the pairing code: " + code)
    print("Approve using your existing owner Cloudflare Access login. No password is requested in Terminal.")
    deadline = time.monotonic() + 600
    while time.monotonic() < deadline:
        time.sleep(5)
        result = post(ENDPOINT, "/v1/pair/status",
                      {"request_id": request_id, "client_secret": proof})
        if result.get("status") == "pending":
            continue
        if result.get("status") == "approved" and result.get("device_token"):
            keychain_set(result["device_token"])
            print("Owner approved: Mac credential stored in Keychain.")
            return
        if result.get("status") in ("expired", "rejected", "revoked"):
            raise Rejected("Pairing " + result["status"])
    raise Rejected("Pairing timed out; retry with a new code")

def once():
    token = keychain_get()
    if not token:
        raise Rejected("Device not paired; open AppleRAVEN.app and approve pairing first")
    hello = post(ENDPOINT, "/v1/device/state", {
        "hostname": socket.gethostname()[:64],
        "os": platform.mac_ver()[0], "model": "MacBook Air",
        "capabilities": ["shortcuts.list"], "agent": "0.1-candidate"
    }, token)
    task = post(ENDPOINT, "/v1/device/next", {}, token)
    if isinstance(task, dict) and task.get("capability") == "shortcuts.list" and isinstance(task.get("id"), str):
        result = native_shortcuts()
        post(ENDPOINT, "/v1/device/result", {
            "id": task["id"], "ok": result["ok"], "result": result
        }, token)
    elif isinstance(task, dict) and task.get("capability"):
        raise Rejected("Action outside AppleRAVEN allowlist denied")
    return hello

def main():
    parser = argparse.ArgumentParser(description="AppleRAVEN owner Mac agent")
    parser.add_argument("--pair", action="store_true")
    parser.add_argument("--once", action="store_true")
    parser.add_argument("--status", action="store_true")
    args = parser.parse_args()
    if args.status:
        print(json.dumps({"macos": platform.mac_ver()[0], "node": socket.gethostname(),
                          "device_credential_present": bool(keychain_get()),
                          "endpoint": ENDPOINT}, indent=2))
        return
    if args.pair:
        pair()
        return
    if args.once:
        once()
        print("Read-only poll completed")
        return
    while True:
        try:
            once()
        except (Rejected, urllib.error.URLError, OSError) as exc:
            print("AppleRAVEN: " + str(exc), file=sys.stderr)
        time.sleep(15)

if __name__ == "__main__":
    try:
        main()
    except (Rejected, urllib.error.URLError, OSError) as exc:
        print("AppleRAVEN: " + str(exc), file=sys.stderr)
        sys.exit(1)

