#!/usr/bin/env python3
"""FAMA owner-only local browser agent. Reuses original runtime; no social actions.

Bound exclusively to 127.0.0.1. Requires an explicit per-session bearer token
from a private environment variable. This is NOT an Internet-facing authenticator,
Cloudflare Access verifier, remote MCP server, or multi-tenant account connector.
"""
from __future__ import annotations

import hmac
import json
import os
import time
from collections import defaultdict, deque
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit
from inchat_gateway import execute
from research_runner import run_research

ROOT = Path(__file__).resolve().parent
MAX_BODY = 4096
HOST = "127.0.0.1"
DEFAULT_PORT = 8765
ASSETS = {
    "/": ("web/index.html", "text/html; charset=utf-8"),
    "/app.js": ("web/app.js", "text/javascript; charset=utf-8"),
}
RATE = defaultdict(deque)

def authorize(value: str, bearer: str) -> bool:
    return bool(value) and hmac.compare_digest(value, "Bearer " + bearer)

def validate_research(data):
    if not isinstance(data, dict):
        raise ValueError("Expected JSON object")
    if set(data) - {"query", "hours", "limit"}:
        raise ValueError("Unknown research arguments")
    q = data.get("query")
    if not isinstance(q, str) or not 2 <= len(q.strip()) <= 120:
        raise ValueError("Query length must be between 2 and 120 characters")
    h = data.get("hours", 72)
    n = data.get("limit", 5)
    if type(h) is not int or not 1 <= h <= 168:
        raise ValueError("hours outside 1..168")
    if type(n) is not int or not 1 <= n <= 5:
        raise ValueError("limit outside 1..5")
    return q.strip(), h, n

def make_handler(token: str):
    if not isinstance(token, str) or len(token) < 32:
        raise ValueError("FAMA_WEB_TOKEN must be at least 32 characters")
    class Handler(BaseHTTPRequestHandler):
        server_version = "FAMA-Owner-Agent"
        sys_version = ""
        def log_message(self, *_args):
            return  # Never log bearer or submitted research text.
        def response(self, status: int, obj):
            encoded = json.dumps(obj, ensure_ascii=False).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(encoded)))
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.send_header("Referrer-Policy", "no-referrer")
            self.end_headers()
            self.wfile.write(encoded)
        def do_GET(self):
            path = urlsplit(self.path).path
            if path == "/health":
                return self.response(200, {"status": "RUNNING", "exposure": "LOOPBACK_ONLY"})
            if path in ASSETS:
                path_file, mime = ASSETS[path]
                p = ROOT / path_file
                if not p.is_file():
                    return self.response(404, {"error": "Asset unavailable"})
                blob = p.read_bytes()
                self.send_response(200)
                self.send_header("Content-Type", mime)
                self.send_header("Content-Length", str(len(blob)))
                self.send_header("Cache-Control", "no-store")
                self.send_header("X-Content-Type-Options", "nosniff")
                self.send_header("Referrer-Policy", "no-referrer")
                self.send_header("Content-Security-Policy", "default-src 'none'; script-src 'self'; connect-src 'self'; style-src 'self'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'")
                self.end_headers()
                self.wfile.write(blob)
                return
            return self.response(404, {"error": "Not found"})
        def do_POST(self):
            path = urlsplit(self.path).path
            if path not in ("/api/capabilities", "/api/validate-persona", "/api/research"):
                return self.response(404, {"error": "Operation not exposed"})
            if not authorize(self.headers.get("Authorization", ""), token):
                return self.response(401, {"error": "Authentication required"})
            origin = self.headers.get("Origin")
            expected_origin = "http://127.0.0.1:" + str(self.server.server_port)
            if origin and origin != expected_origin:
                return self.response(403, {"error": "Cross-origin request denied"})
            try:
                rawlen = self.headers.get("Content-Length")
                if not rawlen or not rawlen.isdigit() or not 0 < int(rawlen) <= MAX_BODY:
                    return self.response(413, {"error": "Request size denied"})
                data = json.loads(self.rfile.read(int(rawlen)))
            except (ValueError, UnicodeError):
                return self.response(400, {"error": "Invalid JSON"})
            if path == "/api/capabilities":
                return self.response(200, execute({"operation": "capabilities"}))
            if path == "/api/validate-persona":
                if not isinstance(data, dict) or not isinstance(data.get("persona"), dict):
                    return self.response(400, {"error": "Persona object required"})
                return self.response(200, execute({"operation": "validate_persona", "persona": data["persona"]}))
            try:
                q, h, n = validate_research(data)
            except ValueError as exc:
                return self.response(400, {"error": str(exc)})
            # Owner-initiated public research only; no source URL input, posting,
            # paid model, persona file access or local storage mutation.
            now = time.monotonic()
            queue = RATE[self.client_address[0]]
            while queue and now - queue[0] > 60:
                queue.popleft()
            if len(queue) >= 3:
                return self.response(429, {"error": "Bounded public research rate limit"})
            queue.append(now)
            try:
                result = run_research([q], hours=h, limit=n, capture=False)
                # Trim descriptive text; do not return full external article bodies.
                result["candidates"] = result.get("candidates", [])[:10]
                for item in result["candidates"]:
                    if isinstance(item, dict):
                        item.pop("captured_text", None)
                result["external_social_action"] = "NOT_PERFORMED"
                return self.response(200, result)
            except Exception:
                return self.response(502, {"error": "Research provider failed; no result claimed"})
    return Handler

def main():
    token = os.environ.get("FAMA_WEB_TOKEN", "")
    if len(token) < 32:
        raise SystemExit("BLOCKED: configure a private 32+ character FAMA_WEB_TOKEN")
    port = int(os.environ.get("FAMA_WEB_PORT", str(DEFAULT_PORT)))
    if not 1 <= port <= 65535:
        raise SystemExit("Invalid FAMA_WEB_PORT")
    server = ThreadingHTTPServer((HOST, port), make_handler(token))
    print(f"FAMA local owner agent: http://{HOST}:{port} (NOT a public portal)")
    try:
        server.serve_forever(poll_interval=0.5)
    except KeyboardInterrupt:
        server.server_close()

if __name__ == "__main__":
    main()
