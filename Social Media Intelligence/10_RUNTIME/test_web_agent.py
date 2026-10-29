import http.client
import json
import threading
import unittest
from unittest.mock import patch
from http.server import ThreadingHTTPServer
from web_agent import make_handler, validate_research, authorize, RATE

TOKEN="t"*44

class FAMAWebAgentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server=ThreadingHTTPServer(("127.0.0.1",0),make_handler(TOKEN))
        cls.thread=threading.Thread(target=cls.server.serve_forever,daemon=True)
        cls.thread.start()
    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join(timeout=5)

    def request(self,path,payload=None,token=None,origin=None):
        conn=http.client.HTTPConnection("127.0.0.1",self.server.server_port,timeout=5)
        body=None if payload is None else json.dumps(payload)
        h={"Content-Type":"application/json"}
        if token is not None: h["Authorization"]="Bearer "+token
        if origin: h["Origin"]=origin
        conn.request("GET" if payload is None else "POST",path,body=body,headers=h)
        r=conn.getresponse()
        raw=r.read()
        status=r.status
        conn.close()
        return status,json.loads(raw) if r.getheader("Content-Type","").startswith("application/json") else raw

    def setUp(self):
        RATE.clear()

    def test_health_does_not_claim_cloud(self):
        code,data=self.request("/health")
        self.assertEqual(code,200)
        self.assertEqual(data["exposure"],"LOOPBACK_ONLY")

    def test_denies_anonymous_and_wrong_bearer(self):
        self.assertEqual(self.request("/api/research",{"query":"medical devices"})[0],401)
        self.assertEqual(self.request("/api/research",{"query":"medical devices"},"wrong")[0],401)

    def test_rejects_cross_origin(self):
        self.assertEqual(self.request("/api/research",{"query":"medical devices"},TOKEN,"https://attacker.example")[0],403)

    def test_capabilities_are_original_no_publishing(self):
        code,data=self.request("/api/capabilities",{},TOKEN)
        self.assertEqual(code,200)
        self.assertEqual(data["publishing"],"DISABLED")
        self.assertEqual(data["status"],"PASS")

    def test_refuses_unsupported_account_operations(self):
        self.assertEqual(self.request("/api/publish",{"text":"hello"},TOKEN)[0],404)

    def test_input_bounds(self):
        for body in ({"query":"x"},{"query":"valid","limit":100},{"query":"valid","hours":999},{"query":"valid","account_id":"other-tenant"}):
            self.assertEqual(self.request("/api/research",body,TOKEN)[0],400)

    @patch("web_agent.run_research")
    def test_actual_runner_adapter_contract_and_rate_limit(self, runner):
        runner.return_value={"run_status":"RESULTS_FOUND","candidates":[{"title":"Lead","claim_verification_status":"NOT_VERIFIED","captured_text":"Private full article text"}]}
        code,data=self.request("/api/research",{"query":"public policy","limit":3},TOKEN)
        self.assertEqual(code,200)
        self.assertEqual(data["external_social_action"],"NOT_PERFORMED")
        self.assertNotIn("captured_text",data["candidates"][0])
        runner.assert_called_once_with(["public policy"],hours=72,limit=3,capture=False)
        for _ in range(2): self.assertEqual(self.request("/api/research",{"query":"public policy"},TOKEN)[0],200)
        self.assertEqual(self.request("/api/research",{"query":"public policy"},TOKEN)[0],429)

    def test_no_self_asserted_principal_or_shared_workspace(self):
        self.assertFalse(authorize("Bearer "+"x"*44,TOKEN))
        with self.assertRaises(ValueError): validate_research({"query":"topic","workspace_scope":"ELYSIUM_BUSINESS"})

if __name__=="__main__":
    unittest.main()
