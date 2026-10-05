import time
import unittest
from unittest.mock import patch
from bifrost.chatgpt_auth import ChatAuth, SCOPE
from bifrost.chatgpt_provider import ProviderError

class Store:
    def __init__(self):
        self.record = {"client_id": "issued", "subject": "person", "token": {
            "scope": SCOPE, "access_token": "old", "refresh_token": "old-refresh", "expires_at": 1}}
    def read(self, key): return self.record if key == "connection" else None
    def write(self, key, value): self.record = value

class RefreshTests(unittest.TestCase):
    def fresh(self):
        return {"scope": SCOPE, "access_token": "fresh", "refresh_token": "rotated",
                "id_token": "signed", "expires_at": time.time() + 600}

    def test_rotated_token_survives_identity_network_failure_then_recovers(self):
        store = Store()
        auth = ChatAuth(store)
        with patch("bifrost.chatgpt_auth.discovery", return_value={"token_endpoint": "https://auth.openai.com/token"}), \
             patch("bifrost.chatgpt_auth.OAuth2Session") as oauth, \
             patch("bifrost.chatgpt_auth.verify_identity", side_effect=[OSError("network"), {"sub": "person"}]), \
             patch("openai.OpenAI", return_value="client") as client:
            oauth.return_value.refresh_token.return_value = self.fresh()
            with self.assertRaises(OSError): auth.client()
            self.assertEqual(store.record["pending"]["token"]["refresh_token"], "rotated")
            self.assertEqual(auth.client(), ("person:issued", "client"))
            oauth.return_value.refresh_token.assert_called_once()
            self.assertNotIn("pending", store.record)
            self.assertEqual(store.record["token"]["refresh_token"], "rotated")
            client.assert_called_once()

    def test_changed_identity_never_creates_inference_client(self):
        store = Store()
        with patch("bifrost.chatgpt_auth.discovery", return_value={"token_endpoint": "https://auth.openai.com/token"}), \
             patch("bifrost.chatgpt_auth.OAuth2Session") as oauth, \
             patch("bifrost.chatgpt_auth.verify_identity", return_value={"sub": "someone-else"}), \
             patch("openai.OpenAI") as client:
            oauth.return_value.refresh_token.return_value = self.fresh()
            with self.assertRaises(ProviderError): ChatAuth(store).client()
            client.assert_not_called()
            self.assertIn("pending", store.record)

    def test_early_refresh_is_not_attempted(self):
        store = Store()
        store.record["token"]["earliest_refresh_at"] = time.time() + 600
        with patch("bifrost.chatgpt_auth.discovery", return_value={}), \
             patch("bifrost.chatgpt_auth.OAuth2Session") as oauth:
            with self.assertRaises(ProviderError): ChatAuth(store).client()
            oauth.assert_not_called()

    def test_reduced_refresh_scope_never_creates_inference_client(self):
        store = Store()
        fresh = self.fresh()
        fresh["scope"] = "openid profile email"
        with patch("bifrost.chatgpt_auth.discovery", return_value={"token_endpoint": "https://auth.openai.com/token"}), \
             patch("bifrost.chatgpt_auth.OAuth2Session") as oauth, \
             patch("bifrost.chatgpt_auth.verify_identity", return_value={"sub": "person"}), \
             patch("openai.OpenAI") as client:
            oauth.return_value.refresh_token.return_value = fresh
            with self.assertRaises(ProviderError): ChatAuth(store).client()
            client.assert_not_called()
