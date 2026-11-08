"""Authorized cloud access variant for the original THEMIS legal application.

Never place the owner key in source, arguments, logs, or saved JSON.
The existing offline ThemisStore remains the local authority until a
user-authorized, conflict-aware synchronization is implemented and verified.
"""
from __future__ import annotations
import argparse
import json
import os
from urllib.parse import urlsplit
from urllib.request import Request, build_opener, HTTPRedirectHandler
from urllib.error import HTTPError, URLError

DEFAULT_URL = "https://themis-private.lucasravensnest.workers.dev"

class RejectRedirects(HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, msg, headers, newurl):
        raise RuntimeError("Refusing redirect: owner key must stay at the configured origin")

class CloudThemisClient:
    def __init__(self, url=DEFAULT_URL, owner_key=None, timeout=15):
        url = url.rstrip("/")
        parsed = urlsplit(url)
        if not parsed.hostname or parsed.username or parsed.password or parsed.query or parsed.fragment:
            raise ValueError("Invalid service URL")
        if parsed.scheme != "https" and not (parsed.scheme == "http" and parsed.hostname in {"127.0.0.1", "localhost"}):
            raise ValueError("TLS is required for a non-local service")
        if not owner_key or not isinstance(owner_key, str):
            raise ValueError("THEMIS_OWNER_KEY must be provided securely")
        self.url, self.owner_key, self.timeout = url, owner_key, timeout
        self.opener = build_opener(RejectRedirects)

    def request(self, path, method="GET", payload=None):
        if not path.startswith("/") or path.startswith("//"):
            raise ValueError("Invalid API route")
        data = json.dumps(payload).encode("utf-8") if payload is not None else None
        headers = {"Authorization": "Bearer " + self.owner_key, "Accept": "application/json"}
        if data is not None:
            headers["Content-Type"] = "application/json"
        req = Request(self.url + path, method=method, headers=headers, data=data)
        try:
            with self.opener.open(req, timeout=self.timeout) as response:
                return json.load(response)
        except HTTPError as exc:
            raise RuntimeError("THEMIS HTTP " + str(exc.code) + " (" + exc.reason + ")") from None
        except URLError as exc:
            raise RuntimeError("THEMIS connection unavailable: " + str(exc.reason)) from None

    def health(self):
        return self.request("/api/health")
    def list_records(self, kind=None):
        from urllib.parse import quote
        return self.request("/api/records" + ("?kind=" + quote(kind, safe="") if kind else ""))
    def get_record(self, record_id):
        from urllib.parse import quote
        return self.request("/api/records/" + quote(str(record_id), safe=""))
    def create_record(self, kind, title, fields=None, provenance=None):
        return self.request("/api/records", "POST", {"kind": kind, "title": title, "fields": fields or {}, "provenance": provenance or {}})
    def update_record(self, record_id, revision, fields=None, title=None):
        from urllib.parse import quote
        payload = {"expected_revision": revision, "fields": fields or {}}
        if title is not None:
            payload["title"] = title
        return self.request("/api/records/" + quote(str(record_id), safe=""), "PUT", payload)
    def snapshots(self):
        return self.request("/api/snapshots")
    def snapshot(self, label="checkpoint", set_lkg=False):
        return self.request("/api/snapshots", "POST", {"label": label, "set_lkg": bool(set_lkg)})
    def export(self):
        return self.request("/api/export")

def main():
    parser = argparse.ArgumentParser(prog="python -m themis.cloud_client", description="Secure remote THEMIS access; offline CLI is unchanged")
    parser.add_argument("command", choices=["health", "list", "snapshots", "export"])
    parser.add_argument("--kind", default=None)
    parser.add_argument("--url", default=os.environ.get("THEMIS_URL", DEFAULT_URL))
    args = parser.parse_args()
    client = CloudThemisClient(args.url, os.environ.get("THEMIS_OWNER_KEY"))
    operation = {"health": client.health, "list": lambda: client.list_records(args.kind), "snapshots": client.snapshots, "export": client.export}[args.command]
    print(json.dumps(operation(), indent=2, ensure_ascii=False))

if __name__ == "__main__":
    main()
