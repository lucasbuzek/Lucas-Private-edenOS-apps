"""Regression: headless installer must not package unrelated source or user data."""
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock
import zipfile

ROOT = Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location("firstuse_packager",ROOT/"tools/package_headless.py")
pkg=importlib.util.module_from_spec(spec)
spec.loader.exec_module(pkg)


class PackageSafetyTests(unittest.TestCase):
    def test_no_private_data_or_extra_source(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)/"BIFROST";root.mkdir()
            for directory in ("headless/icons","headless/secrets","core",
                              "tools","docs/private","tests","headless/cache"):
                (root/directory).mkdir(parents=True,exist_ok=True)
            required={
                "headless/server.py":b"print('safe headless')",
                "headless/first_use_accounts.py":b"print('safe account names')",
                "headless/mcp_stdio.py":b"print('on-demand MCP adapter')",
                "headless/icons/icon-192.png":b"PNG192",
                "headless/icons/icon-512.png":b"PNG512",
                "core/storage_capability.py":b"pass",
                "tools/install_headless.py":b"pass",
                "Install-BIFROST.command":b"echo install",
                "INSTALL-README.md":b"read me",
                "headless/secrets/device.json":b"SECRET_PRIVATE_DEVICE_TOKEN",
                "headless/cache/index.json":b"SECRET_CACHED_ITEM",
                "headless/oauth_token.json":b"SECRET_OAUTH_TOKEN",
                "headless/refresh_token.json":b"SECRET_REFRESH_TOKEN",
                "docs/private/owner_data.txt":b"SECRET_PRIVATE_DOC",
                "tests/private_test_data.txt":b"SECRET_TEST_DATA",
            }
            for relative,data in required.items():
                (root/relative).write_bytes(data)
            output=Path(temp)/"candidate.zip"
            with mock.patch.object(pkg,"ROOT",root):
                pkg.build(output,install_options={"port":8798,"startAtLogin":False,"openDashboard":True})
            with zipfile.ZipFile(output) as archive:
                self.assertIsNone(archive.testzip())
                names=set(archive.namelist())
                self.assertIn("BIFROST/headless/first_use_accounts.py",names)
                self.assertIn("BIFROST/headless/mcp_stdio.py",names)
                self.assertIn("BIFROST/headless/server.py",names)
                self.assertIn("BIFROST/core/storage_capability.py",names)
                self.assertIn("BIFROST/INSTALL-OPTIONS.json",names)
                self.assertFalse(any("secret" in x.lower() or "cache" in x.lower() for x in names))
                self.assertFalse(any("docs/private" in x or "tests/" in x for x in names))
                combined=b"".join(archive.read(n) for n in names)
                self.assertNotIn(b"SECRET_",combined)
                manifest=json.loads(archive.read("BIFROST/INSTALL-MANIFEST.json"))
                for path,digest in manifest.items():
                    self.assertEqual(hashlib.sha256(archive.read("BIFROST/"+path)).hexdigest(),digest)

    def test_required_asset_missing_fails_closed(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)/"BIFROST";root.mkdir()
            with mock.patch.object(pkg,"ROOT",root):
                with self.assertRaisesRegex(RuntimeError,"Missing required asset"):
                    pkg.build(Path(temp)/"candidate.zip")


if __name__=="__main__":
    unittest.main()
