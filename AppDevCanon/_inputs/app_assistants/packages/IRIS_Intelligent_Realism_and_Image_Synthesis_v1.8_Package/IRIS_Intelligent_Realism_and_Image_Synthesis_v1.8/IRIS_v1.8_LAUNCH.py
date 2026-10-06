#!/usr/bin/env python3
from __future__ import annotations
import argparse, os, sys, webbrowser, threading
from pathlib import Path
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler

ROOT = Path(__file__).resolve().parent
TARGETS = {
    "batch": (ROOT / "batch", "IRIS_v1.8_BATCH_STUDIO.html", 8765),
    "visual": (ROOT / "visual", "IRIS_v1.8_VISUAL_WORKSPACE.html", 8766),
}
class Quiet(SimpleHTTPRequestHandler):
    def log_message(self, fmt, *args): pass

def serve(kind:str, no_browser:bool=False):
    folder, page, preferred = TARGETS[kind]
    os.chdir(folder)
    server=None
    for port in range(preferred, preferred+20):
        try:
            server=ThreadingHTTPServer(("127.0.0.1",port),Quiet); break
        except OSError: continue
    if server is None: raise RuntimeError("No free local port available")
    url=f"http://127.0.0.1:{server.server_port}/{page}"
    print(f"◉ IRIS {kind.title()} UI: {url}")
    if not no_browser: threading.Timer(.35, lambda:webbrowser.open(url)).start()
    try: server.serve_forever()
    except KeyboardInterrupt: pass
    finally: server.server_close()

def main():
    ap=argparse.ArgumentParser(description="◉ IRIS cross-platform launcher")
    ap.add_argument("target",choices=["batch","visual"],nargs="?",default="visual")
    ap.add_argument("--no-browser",action="store_true")
    a=ap.parse_args(); serve(a.target,a.no_browser)
if __name__=="__main__": main()
