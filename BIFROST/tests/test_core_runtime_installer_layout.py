"""Regression: canonical Headless and recovered installer layouts can both verify."""
import hashlib
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "headless"))
import core_runtime as core


class InstallerLayoutTests(unittest.TestCase):
    def identity(self, directory, body):
        return {"schema": "bifrost.headless.identity.v1",
                "productId": core.HEADLESS_PRODUCT,
                "runtimeId": hashlib.sha256(str(directory).encode()).hexdigest()[:16],
                "sourceSha256": hashlib.sha256(body).hexdigest()}

    def create(self, root, relative, body=b"verified fixture"):
        folder = root / relative
        folder.mkdir(parents=True, exist_ok=True)
        (folder / "server.py").write_bytes(body)
        return folder

    def test_recovered_installer_layout_is_verified(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            layout = self.create(home, "Library/Application Support/BIFROST/HeadlessRuntime/headless")
            status = core.headless_state(home, identity=self.identity(layout, b"verified fixture"))
            self.assertEqual(status["state"], "identity-verified")

    def test_legacy_layout_still_verifies(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            layout = self.create(home, "Library/Application Support/BIFROST/runtime")
            status = core.headless_state(home, identity=self.identity(layout, b"verified fixture"))
            self.assertEqual(status["state"], "identity-verified")

    def test_no_implicit_fallback_when_explicit_path_requested(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            new = self.create(home, "Library/Application Support/BIFROST/HeadlessRuntime/headless")
            legacy = home / "Library/Application Support/BIFROST/runtime"
            status = core.headless_state(home, identity=self.identity(new, b"verified fixture"),
                                         runtime_path=legacy)
            self.assertEqual(status["state"], "unverified")

    def test_different_source_cannot_inherit_verified_state(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            new = self.create(home, "Library/Application Support/BIFROST/HeadlessRuntime/headless")
            wrong = self.identity(new, b"different")
            self.assertEqual(core.headless_state(home, identity=wrong)["state"], "unverified")

    def test_other_unrecognized_layout_never_verifies(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            custom = self.create(home, "Library/Application Support/BIFROST/OtherRuntime")
            ident = self.identity(custom, b"verified fixture")
            self.assertEqual(core.headless_state(home, identity=ident)["state"], "unverified")


if __name__ == "__main__":
    unittest.main()
