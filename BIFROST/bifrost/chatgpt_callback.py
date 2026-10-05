"""Short-lived loopback OAuth receiver; not a BIFROST API or remote listener."""
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlsplit
from .chatgpt_provider import ProviderError

class Callback:
    def __init__(self,port=0): self.port=port
    def __enter__(self):
        self.result=None
        self.done=threading.Event()
        owner=self
        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                parsed=urlsplit(self.path)
                if parsed.path!="/auth/callback" or len(self.path)>16384:
                    self.send_response(404); self.end_headers(); return
                data=parse_qs(parsed.query,keep_blank_values=True)
                if not owner.accept(data):
                    self.send_response(400); self.end_headers(); return
                if owner.done.is_set():
                    self.send_response(409); self.end_headers(); return
                owner.result=data
                owner.done.set()
                self.send_response(200)
                self.send_header("Content-Type","text/plain; charset=utf-8")
                self.send_header("Cache-Control","no-store")
                self.end_headers()
                self.wfile.write(b"Return to BIFROST to finish connecting.")
            def log_message(self,*args): pass
        self.accept=lambda data: True
        self.server=HTTPServer(("127.0.0.1",self.port),Handler)
        self.uri=f"http://127.0.0.1:{self.server.server_port}/auth/callback"
        self.thread=threading.Thread(target=self.server.serve_forever,daemon=True)
        self.thread.start()
        return self

    def wait(self,timeout=300):
        if not self.done.wait(timeout): raise ProviderError("sign_in_timeout")
        return self.result

    def __exit__(self,*args):
        self.server.shutdown(); self.server.server_close(); self.thread.join(timeout=2)
