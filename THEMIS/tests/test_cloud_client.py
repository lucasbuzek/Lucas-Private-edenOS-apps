"""Local no-charge tests of the actual CloudThemisClient protocol and key handling."""
import json
import sys
import threading
from pathlib import Path
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))
from themis.cloud_client import CloudThemisClient

class Handler(BaseHTTPRequestHandler):
    records = []
    def respond(self, code, value):
        data = json.dumps(value).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)
    def authorized(self):
        return self.headers.get("Authorization") == "Bearer local-test-token"
    def do_GET(self):
        if not self.authorized(): return self.respond(401, {"error": "Authentication required"})
        if self.path == "/api/health": return self.respond(200, {"service": "THEMIS", "ready": True})
        if self.path.startswith("/api/records"): return self.respond(200, {"records": self.records})
        if self.path == "/api/snapshots": return self.respond(200, {"snapshots": []})
        return self.respond(404, {"error": "Not found"})
    def do_POST(self):
        if not self.authorized(): return self.respond(401, {"error": "Authentication required"})
        body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", "0"))))
        if self.path == "/api/records":
            item = {"id": "test-id", **body, "revision": 1}
            self.records.append(item)
            return self.respond(201, {"record": item})
        return self.respond(404, {"error": "Not found"})
    def log_message(self, *_): pass

server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
thread = threading.Thread(target=server.serve_forever, daemon=True)
thread.start()
try:
    url = "http://127.0.0.1:" + str(server.server_port)
    c = CloudThemisClient(url, "local-test-token")
    assert c.health()["ready"]
    created = c.create_record("matter", "Test matter", {"status": "draft"}, {"source": "test"})["record"]
    assert created["kind"] == "matter"
    assert c.list_records()["records"][0]["id"] == created["id"]
    assert c.snapshots()["snapshots"] == []
    try:
        CloudThemisClient("http://example.com", "local-test-token")
        assert False, "insecure remote HTTP allowed"
    except ValueError: pass
    try:
        CloudThemisClient(url, "incorrect").list_records()
        assert False, "wrong credential accepted"
    except RuntimeError as exc: assert "401" in str(exc)
    print("PASS: authenticated cloud client, record creation, listing, backups route, TLS gate, denied key")
finally:
    server.shutdown()
    server.server_close()
