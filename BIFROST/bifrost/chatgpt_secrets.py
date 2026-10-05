"""Secrets remain in Apple Keychain; never fall back to a file backend."""
import json
import sys
from .chatgpt_provider import ProviderError

class AppleSecrets:
    def __init__(self):
        if sys.platform != "darwin": raise ProviderError("apple_keychain_required")
        from keyring.backends.macOS import Keyring
        self.backend = Keyring()
        if self.backend.priority <= 0: raise ProviderError("apple_keychain_unavailable")

    def read(self, key):
        try:
            value=self.backend.get_password("app.eden.bifrost.chatgpt",key)
            return json.loads(value) if value is not None else None
        except Exception as e: raise ProviderError("keychain_read_failed") from e

    def write(self,key,value):
        try: self.backend.set_password("app.eden.bifrost.chatgpt",key,json.dumps(value))
        except Exception as e: raise ProviderError("keychain_write_failed") from e
