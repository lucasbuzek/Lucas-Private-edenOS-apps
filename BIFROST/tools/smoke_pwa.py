#!/usr/bin/env python3
"""Isolated PWA/Headless smoke; never touches actual port 8798 or live assertion.

Run: python3 tools/smoke_pwa.py
"""
from __future__ import annotations

import http.client
import json
import os
import pathlib
import socket
import subprocess
import sys
import tempfile
import time

ROOT = pathlib.Path(__file__).resolve().parents[1]
SERVER = ROOT / "headless" / "server.py"


def call(port, path, method="GET", data=None, host=None):
    connection = http.client.HTTPConnection("127.0.0.1", port, timeout=3)
    headers = {"Host": host or f"127.0.0.1:{port}"}
    if data is not None:
        headers["Content-Type"] = "application/json"
    connection.request(method, path, body=json.dumps(data).encode() if data is not None else None,
                       headers=headers)
    response = connection.getresponse()
    result = response.status, dict(response.getheaders()), response.read()
    connection.close()
    return result


def main():
    with tempfile.TemporaryDirectory(prefix="bifrost-pwa-smoke-") as folder:
        host = pathlib.Path(folder)
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            port = sock.getsockname()[1]

        environment = dict(os.environ, HOME=folder, BIFROST_HEADLESS_PORT=str(port))
        with (host / "stdout.log").open("wb") as stdout:
            process = subprocess.Popen(
                [sys.executable, "-B", str(SERVER)],
                cwd=SERVER.parent, env=environment,
                stdin=subprocess.DEVNULL, stdout=stdout, stderr=subprocess.STDOUT)
            try:
                for _ in range(60):
                    try:
                        status, _, content = call(port, "/api/health")
                        if status == 200 and json.loads(content)["ok"]:
                            break
                    except (OSError, ValueError):
                        if process.poll() is not None:
                            raise RuntimeError("isolated BIFROST exited early: " + (host / "stdout.log").read_text(errors="replace")[-4000:])
                        time.sleep(0.1)
                else:
                    raise RuntimeError("isolated Headless unavailable: " + (host / "stdout.log").read_text(errors="replace")[-4000:])

                expected = {
                    "/": "text/html",
                    "/manifest.webmanifest": "application/manifest+json",
                    "/sw.js": "text/javascript",
                    "/offline.html": "text/html",
                    "/dashboard.js": "text/javascript",
                    "/icons/icon-192.png": "image/png",
                    "/icons/icon-512.png": "image/png",
                }
                for path, mime in expected.items():
                    status, headers, body = call(port, path)
                    assert status == 200, (path, status)
                    assert mime in headers["Content-Type"], (path, headers)
                    assert headers["Cache-Control"] == "no-store", path
                    assert "worker-src 'self'" in headers["Content-Security-Policy"], path
                    assert len(body) > 20, path
                    if path.endswith(".png"):
                        assert body[:8] == bytes.fromhex("89504e470d0a1a0a")
                    print("STATIC_PASS", path)

                status, _, content = call(port, "/api/pwa/adapter")
                descriptor = json.loads(content)
                assert status == 200 and descriptor["transport"] == "same-origin-loopback"
                # Online/routing components were moved out of BIFROST core.
                # Older optionalRemoteProvider assertions incorrectly expect
                # a field that current local-first canon explicitly excludes.
                assert "optionalRemoteProvider" not in descriptor
                assert descriptor["onlineExecution"] == "not-bundled"
                assert descriptor["externalPlugins"] == "independently-installed"
                assert descriptor["crossOriginApiEnabled"] is False
                assert descriptor["offlineActionsEnabled"] is False
                print("PWA_ADAPTER_READONLY=PASS")

                for path in ("/api/control", "/api/setup/stage"):
                    status, _, _ = call(port, path, "POST", {"id": "ai-toolkit"})
                    assert status == 403, (path, status)
                    print("UNAUTHORIZED_ACTION_DENIED", path)

                status, _, _ = call(port, "/manifest.webmanifest", host="malicious.invalid")
                assert status == 403, status
                print("HOST_DENIAL=PASS")
                status, _, _ = call(port, "/api/proxy?target=http%3A%2F%2Fexample.com")
                assert status == 404
                print("UNSAFE_PROXY_ABSENT=PASS")
                print("ISOLATED_PWA_SMOKE=PASS")
            finally:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait(timeout=5)
                print("ISOLATED_RUNTIME_TERMINATED=PASS")


if __name__ == "__main__":
    main()
