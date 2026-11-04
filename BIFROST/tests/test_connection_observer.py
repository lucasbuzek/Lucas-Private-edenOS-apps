"""BIFROST ZERO: Mac-owned live fabric and explicit LAN-scan security."""
import http.client
import ipaddress
import json
from pathlib import Path
import sys
import threading
import unittest
from unittest import mock
from http.server import ThreadingHTTPServer

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "headless"))
import connection_observer as obs
import server


class SnapshotTests(unittest.TestCase):
    def test_mac_interface_is_private_and_derived_from_default_route(self):
        def source(args, timeout=3):
            if args[:2] == ["/usr/sbin/netstat", "-rn"]:
                return "Destination Gateway Flags Netif\ndefault 192.168.8.1 UGScg en0\n"
            if args == ["/sbin/ifconfig", "en0"]:
                return "en0: flags=...\n inet 192.168.8.254 netmask 0xffffff00 broadcast 192.168.8.255\n"
            return ""
        with mock.patch.object(obs, "_fixed_read", side_effect=source):
            adapter = obs._interface()
        self.assertEqual(adapter["name"], "en0")
        self.assertEqual(adapter["subnet"], "192.168.8.0/24")
        self.assertEqual(adapter["address"], "192.168.8.254")

    def test_no_private_interface_for_public_wan_or_unrecognized_route(self):
        for route, address in [("default 8.8.8.8 UGScg en0", "8.8.8.8"),
                               ("default 192.168.8.1 UGScg utun2", "192.168.8.254")]:
            def source(args, timeout=3):
                if args[0] == "/usr/sbin/netstat":
                    return route
                return " inet " + address + " netmask 0xffffff00"
            with self.subTest(route=route), mock.patch.object(
                obs, "_fixed_read", side_effect=source):
                self.assertIsNone(obs._interface())

    def test_arp_cache_is_observation_not_proof_online(self):
        network = ipaddress.IPv4Network("192.168.8.0/24")
        output = "? (192.168.8.1) at 0:1:2 on en0\n? (192.168.8.2) at (incomplete) on en0\n"
        with mock.patch.object(obs, "_fixed_read", return_value=output):
            self.assertEqual(obs._arp(network, "192.168.8.254"), ["192.168.8.1"])

    def test_rdc_profile_metadata_does_not_claim_authenticated(self):
        result = obs._rdc()
        self.assertEqual(result["authentication"], "not-verified-from-local-profile")
        self.assertEqual(result["liveChatGPTTransport"], "independent-verification-required")

    def test_missing_local_rdc_manager_does_not_imply_account_loss(self):
        with mock.patch.object(obs, "CONNECTORS", Path("/nonexistent-bifrost-test")), \
             mock.patch.object(obs, "_fixed_read") as read:
            result = obs._rdc()
        self.assertEqual(result["state"], "not-found")
        self.assertEqual(result["profiles"], [])
        self.assertEqual(result["authentication"], "not-verified-from-local-profile")
        self.assertEqual(result["liveChatGPTTransport"], "independent-verification-required")
        read.assert_not_called()

    def test_monitor_unauthorized_and_invalid_scans_cannot_execute(self):
        monitor = obs.LANMonitor()
        with mock.patch.object(obs, "_interface", return_value={
            "name":"en0", "address":"192.168.8.254",
            "subnet":"192.168.8.0/24",
            "network": ipaddress.IPv4Network("192.168.8.0/24")}):
            for args in [
                (1, 4, False), (0, 4, True), (20, 10, True),
                (1, 254, True), (1, 66, True), ("1", 2, True)
            ]:
                with self.subTest(args=args), self.assertRaises(ValueError):
                    monitor.begin(args[0], args[1], confirmed=args[2])
            self.assertEqual(monitor.status, "not-scanned")
            self.assertEqual(monitor.snapshot()["responders"], [])

    def test_confirmed_scanning_is_bounded_and_does_not_claim_completion(self):
        monitor = obs.LANMonitor()
        iface = {"name":"en0", "address":"192.168.8.254",
                 "subnet":"192.168.8.0/24",
                 "network":ipaddress.IPv4Network("192.168.8.0/24")}
        with mock.patch.object(obs, "_interface", return_value=iface), \
             mock.patch.object(threading.Thread, "start"):
            status = monitor.begin(1, 32, confirmed=True)
            self.assertEqual(status["status"], "scanning")
            self.assertEqual(status["total"], 32)
            self.assertFalse(status["effectsVerified"])
            with self.assertRaises(ValueError):
                monitor.begin(1, 32, confirmed=True)

    def test_snapshot_never_tries_to_probe_on_read(self):
        with mock.patch.object(obs, "_interface", return_value=None), \
             mock.patch.object(obs.LANMonitor, "begin") as scan:
            state = obs.snapshot(home=Path("/tmp/bifrost-fake"))
        self.assertEqual(state["lan"]["observedPeers"], [])
        self.assertFalse(state["privacy"]["backgroundNetworkScan"])
        self.assertFalse(state["privacy"]["credentialRead"])
        self.assertFalse(state["privacy"]["launchAuthority"])
        scan.assert_not_called()

    def test_connector_identity_keeps_plugins_distinct_from_execution(self):
        with mock.patch.object(obs, "_interface", return_value=None):
            result = obs.snapshot(home=Path("/tmp/no-edenOS"))
        connectors = {v["id"]:v for v in result["connectors"]}
        self.assertIn("rdc", connectors)
        self.assertIn("workincodex", connectors)
        self.assertIn("files-storage", connectors)
        self.assertIn("ai-toolkit", connectors)
        self.assertIn("adobe", connectors)
        apps = {v["id"]:v for v in result["apps"]}
        self.assertTrue(apps["janitor"]["chatgptPluginObserved"])
        self.assertIsNone(apps["janitor"]["webURL"])
        self.assertFalse(apps["janitor"]["webVerified"])

    def test_extended_caffeinate_preserves_existing_default_and_upper_bound(self):
        self.assertEqual(server.normalize({})["caffeinateMinutes"],60)
        for duration in (0,5,10,15,30,45,60,90,120,180,240,360,480):
            self.assertEqual(server.normalize({"caffeinateMinutes": duration})["caffeinateMinutes"],duration)
        for invalid in (481,-1,True,7,"480"):
            self.assertEqual(server.normalize({"caffeinateMinutes": invalid})["caffeinateMinutes"],60)


class HTTPTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.http = ThreadingHTTPServer(("127.0.0.1", 0), server.Handler)
        cls.http.daemon_threads = True
        cls.port = cls.http.server_address[1]
        cls.p1 = mock.patch.object(server, "PORT", cls.port)
        cls.p2 = mock.patch.object(server, "get_token", return_value="test-no-real-secret")
        cls.p1.start()
        cls.p2.start()
        cls.thread = threading.Thread(target=cls.http.serve_forever,daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.http.shutdown()
        cls.http.server_close()
        cls.thread.join(timeout=2)
        cls.p2.stop()
        cls.p1.stop()

    def send(self, route, method="GET", data=None, authorized=True):
        client = http.client.HTTPConnection("127.0.0.1",self.port,timeout=4)
        headers = {"Host":"127.0.0.1:" + str(self.port)}
        if authorized:
            headers["X-Bifrost-Token"]="test-no-real-secret"
        payload = None
        if data is not None:
            payload = json.dumps(data)
            headers["Content-Type"]="application/json"
        try:
            client.request(method,route,body=payload,headers=headers)
            answer=client.getresponse()
            return answer.status,json.loads(answer.read())
        finally:
            client.close()

    def test_connection_read_requires_original_session(self):
        code,_=self.send("/api/connections/v1",authorized=False)
        self.assertEqual(code,403)
        with mock.patch.object(server.observed_connections, "snapshot",return_value={
                "schema":obs.SCHEMA,"thisDevice":{"name":"TEST"}}) as observed:
            code,data=self.send("/api/connections/v1")
        self.assertEqual(code,200)
        self.assertEqual(data["thisDevice"]["name"],"TEST")
        observed.assert_called_once()

    def test_connection_get_rejects_query_parameters(self):
        code,_=self.send("/api/connections/v1?token=guess")
        self.assertEqual(code,400)

    def test_scan_requires_session_and_explicit_confirmation(self):
        with mock.patch.object(server.observed_connections.MONITOR,"begin") as scan:
            bad={"start":1,"end":3,"confirmed":True}
            code,_=self.send("/api/connections/scan","POST",bad,authorized=False)
            self.assertEqual(code,403)
            for bad in [{"start":1,"end":3},{"start":1,"end":3,"confirmed":False},
                        {"start":1,"end":3,"confirmed":True,"command":"whoami"}]:
                code,_=self.send("/api/connections/scan","POST",bad)
                self.assertEqual(code,400)
            scan.assert_not_called()

    def test_scan_handoff_uses_only_native_bounded_adapter(self):
        with mock.patch.object(server.observed_connections.MONITOR,"begin",
                               return_value={"status":"scanning","total":3}) as scan:
            code,data=self.send("/api/connections/scan","POST",
                                {"start":1,"end":3,"confirmed":True})
        self.assertEqual(code,202)
        self.assertEqual(data["scan"]["status"],"scanning")
        scan.assert_called_once_with(1,3,confirmed=True)


if __name__=="__main__":
    unittest.main()
