import unittest
import test_native_host as fixtures
from bifrost.native_provider import NativeProvider
from bifrost.native_control import control


class NativeAdapterTests(unittest.TestCase):
    setUp = fixtures.NativeHostTests.setUp
    def test_provider_executes_real_effect_without_automatic_replacement(self):
        provider = NativeProvider(self.host, self.session)
        self.assertFalse(provider.capabilities()["automatic_replacement"])
        provider.execute("filesystem.write", {"grant_id":self.grant["id"], "path":"adapter", "data":"eA=="})
        self.assertEqual((self.root/"adapter").read_bytes(), b"x")

    def test_owner_enable_probes_and_reuses_identity(self):
        request = {"action":"enable", "approved":True, "folder":str(self.root)}
        first = control(self.host, request)
        second = control(self.host, request)
        self.assertEqual(first["device_id"], second["device_id"])
        self.assertEqual(first["state"], "local-ready")
        self.assertFalse(first["remote_enabled"])
