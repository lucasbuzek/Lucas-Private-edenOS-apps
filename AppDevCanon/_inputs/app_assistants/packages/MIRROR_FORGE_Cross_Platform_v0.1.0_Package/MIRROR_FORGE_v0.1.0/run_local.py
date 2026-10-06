from http.server import ThreadingHTTPServer,SimpleHTTPRequestHandler
import os
os.chdir("app");print("Open http://127.0.0.1:8080");ThreadingHTTPServer(("127.0.0.1",8080),SimpleHTTPRequestHandler).serve_forever()
