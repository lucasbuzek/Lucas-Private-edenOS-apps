"""PWA adapter source and Headless HTTP safety contract (no Mac service mutation)."""
from __future__ import annotations
import http.client
import importlib.util
import json
import pathlib
import struct
import sys
import tempfile
import threading
import unittest
from http.server import ThreadingHTTPServer

ROOT = pathlib.Path(__file__).resolve().parents[1]
WEB = ROOT / "headless"
sys.path.insert(0, str(WEB))
spec = importlib.util.spec_from_file_location("bifrost_pwa_headless_under_test", WEB / "server.py")
server = importlib.util.module_from_spec(spec)
spec.loader.exec_module(server)


class PWAStaticTests(unittest.TestCase):
    def test_manifest_installable_local_origin(self):
        manifest = json.loads((WEB / "manifest.webmanifest").read_text())
        self.assertEqual(manifest["scope"], "/")
        self.assertEqual(manifest["start_url"], "/")
        self.assertEqual(manifest["display"], "standalone")
        self.assertEqual(manifest["id"], "/bifrost-local")
        self.assertEqual({x["sizes"] for x in manifest["icons"]}, {"192x192", "512x512"})

    def test_png_icons_are_real_and_valid_size(self):
        for size in (192,512):
            icon = (WEB / "icons" / f"icon-{size}.png").read_bytes()
            self.assertTrue(icon.startswith(b"\x89PNG\r\n\x1a\n"))
            self.assertEqual(struct.unpack(">II",icon[16:24]), (size,size))
            self.assertGreater(len(icon), 1000)

    def test_service_worker_does_not_declare_api_cache(self):
        worker = (WEB / "sw.js").read_text()
        self.assertIn('req.method !== "GET"', worker)
        self.assertIn('url.pathname.startsWith("/api/")',worker)
        self.assertIn('req.mode === "navigate"',worker)
        self.assertIn('new Response("BIFROST is offline',worker)
        self.assertIn('cache.put(OFFLINE, offline)',worker)
        self.assertNotIn('cache.put(req,',worker)
        self.assertNotIn('caches.match(req)',worker)

    def test_contract_has_pwa_without_changing_six_targets(self):
        contract = json.loads((ROOT / "docs" / "bifrost.platform-targets.json").read_text())
        self.assertEqual(len(contract["deployment_targets"]),6)
        pwa = contract["web_pwa"]
        self.assertEqual(pwa["role"],"first-class-representation-and-transport-adapter")
        self.assertFalse(pwa["is_separate_product_core"])
        self.assertEqual(pwa["local_lan_interconnect"], "SPECIFIED_NOT_BUILT")
        self.assertEqual(pwa["actual_mobile_installation"], "NOT_VERIFIED")
        self.assertIn("cache-static-shell-only", pwa["offline_policy"])


class PWAHTTPTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.saved = (server.SUPPORT,server.PREFS,server.KEYFILE,server.PORT,server.RUNTIME)
        cls.tmp = tempfile.TemporaryDirectory(prefix="bifrost-pwa-api-")
        server.SUPPORT = pathlib.Path(cls.tmp.name)
        server.PREFS = server.SUPPORT / "settings.json"
        server.KEYFILE = server.SUPPORT / "headless.token"
        server.RUNTIME = server.Runtime()
        server.RUNTIME.raven_status = lambda: "unknown"
        server.RUNTIME.update_tasks_async = lambda force=False: None
        cls.httpd = ThreadingHTTPServer(("127.0.0.1",0),server.Handler)
        server.PORT = cls.httpd.server_address[1]
        cls.thread=threading.Thread(target=cls.httpd.serve_forever,daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.httpd.shutdown()
        cls.httpd.server_close()
        cls.thread.join(timeout=3)
        server.SUPPORT,server.PREFS,server.KEYFILE,server.PORT,server.RUNTIME = cls.saved
        cls.tmp.cleanup()

    def fetch(self,path, method="GET",headers=None):
        c=http.client.HTTPConnection("127.0.0.1",server.PORT,timeout=4)
        c.request(method,path,headers=headers or {})
        r=c.getresponse()
        body=r.read()
        result=(r.status,dict(r.getheaders()),body)
        c.close()
        return result

    def test_manifest_and_worker_have_strict_csp_and_mime(self):
        for path,mime in (("/manifest.webmanifest","application/manifest+json"),
                          ("/sw.js","text/javascript"),
                          ("/icons/icon-192.png","image/png"),
                          ("/offline.html","text/html")):
            status,headers,body=self.fetch(path)
            self.assertEqual(status,200,path)
            self.assertIn(mime, headers["Content-Type"])
            self.assertGreater(len(body),50)
            self.assertIn("no-store",headers["Cache-Control"])
            self.assertIn("worker-src 'self'",headers["Content-Security-Policy"])
            self.assertIn("manifest-src 'self'",headers["Content-Security-Policy"])

    def test_adapter_is_read_only_and_truthful(self):
        status,headers,raw=self.fetch("/api/pwa/adapter")
        self.assertEqual(status,200)
        data=json.loads(raw)
        self.assertEqual(data["transport"],"same-origin-loopback")
        self.assertFalse(data["crossOriginApiEnabled"])
        self.assertFalse(data["offlineActionsEnabled"])
        self.assertFalse(data["optionalRemoteProvider"]["mobilePairingVerified"])
        self.assertFalse(data["optionalRemoteProvider"]["directApiProxy"])
        rights={x["id"]:x for x in data["capabilities"]}
        self.assertTrue(rights["node.state.read"]["enabled"])
        self.assertFalse(rights["remote.setup.execute"]["enabled"])
        self.assertEqual(rights["setup.stage"]["requires"],"local-session-and-confirmation")

    def test_unknown_remote_url_cannot_be_proxied(self):
        status,_,_ = self.fetch("/api/proxy?url=https://example.org")
        self.assertEqual(status,404)
        status,_,_ = self.fetch("/api/pwa/adapter",headers={"Host":"evil.example"})
        self.assertEqual(status,403)


if __name__=="__main__":
    unittest.main()
