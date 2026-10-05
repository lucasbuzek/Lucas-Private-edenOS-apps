"""Effect and security tests; no provider/network/Apple credentials involved."""
import base64
import json
import os
import sys
import tempfile
import time
import unittest
from pathlib import Path

from bifrost.native_host import NativeHost, NativeError, Session


class MemorySecrets:
    """Ephemeral injected test vault, never a production fallback."""
    def __init__(self):
        self.values = {}
    def get(self, key):
        return self.values.get(key)
    def put(self, key, value):
        self.values[key] = value
    def delete(self, key):
        self.values.pop(key, None)


class NativeHostTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.root = self.base / "share"
        self.root.mkdir()
        self.vault = MemorySecrets()
        self.host = NativeHost(self.base / "state", self.vault)
        self.addCleanup(self.host.close)
        self.device = self.host.enroll("Test Mac", approved=True)
        self.session = self.host.authenticate(self.device["id"], self.vault.get(self.device["id"]))
        self.grant = self.host.grant(self.device["id"], self.root, ["read", "write", "search"], approved=True)

    def assertDenied(self, fn, *args, **kwargs):
        with self.assertRaises(NativeError):
            fn(*args, **kwargs)

    def test_identity_survives_reopen(self):
        second = NativeHost(self.base / "state", self.vault)
        self.addCleanup(second.close)
        self.assertEqual(second.identity, self.host.identity)
        self.assertEqual(second.devices()[0]["name"], "Test Mac")

    def test_enrollment_requires_confirmation(self):
        self.assertDenied(self.host.enroll, "Unapproved", approved=False)

    def test_authentication_and_revocation(self):
        self.assertDenied(self.host.authenticate, self.device["id"], "wrong")
        self.host.revoke(self.device["id"], approved=True)
        self.assertDenied(self.host.read, self.session, self.grant["id"], "missing")
        self.assertDenied(self.host.authenticate, self.device["id"], "wrong")

    def test_other_device_cannot_use_grant(self):
        other = self.host.enroll("Other", approved=True)
        session = self.host.authenticate(other["id"], self.vault.get(other["id"]))
        self.assertDenied(self.host.list, session, self.grant["id"])

    def test_forged_session_is_rejected(self):
        self.assertDenied(self.host.list, Session(self.device["id"], "forged"), self.grant["id"])

    def test_no_default_scope(self):
        other = self.host.enroll("Empty", approved=True)
        session = self.host.authenticate(other["id"], self.vault.get(other["id"]))
        self.assertEqual(self.host.status(session)["grants"], [])

    def test_no_global_root_or_state_grant(self):
        for root in (Path("/"), self.base / "state", self.base):
            self.assertDenied(self.host.grant, self.device["id"], root, ["read"], approved=True)

    def test_traversal_absolute_and_symlink_denied(self):
        (self.root / "link").symlink_to(self.base)
        (self.root / "file").symlink_to(self.base / "outside")
        for path in ("../outside", str(self.base / "outside"), "link/outside", "file"):
            self.assertDenied(self.host.read, self.session, self.grant["id"], path)

    def test_hardlinks_and_fifo_denied(self):
        outside = self.base / "outside"
        outside.write_bytes(b"private")
        os.link(outside, self.root / "hard")
        os.mkfifo(self.root / "fifo")
        for path in ("hard", "fifo"):
            self.assertDenied(self.host.read, self.session, self.grant["id"], path)

    def test_binary_transfer_and_metadata(self):
        data = bytes(range(256)) * 20
        self.host.write(self.session, self.grant["id"], "binary", base64.b64encode(data).decode())
        first = self.host.read(self.session, self.grant["id"], "binary", offset=0, length=1000)
        second = self.host.read(self.session, self.grant["id"], "binary", offset=1000, length=10000)
        self.assertEqual(base64.b64decode(first["data"]) + base64.b64decode(second["data"]), data)
        self.assertEqual(first["next_offset"], 1000)
        self.assertEqual(self.host.metadata(self.session, self.grant["id"], "binary")["size"], len(data))

    def test_overwrite_requires_current_digest(self):
        self.host.write(self.session, self.grant["id"], "a", base64.b64encode(b"old").decode())
        self.assertDenied(self.host.write, self.session, self.grant["id"], "a", base64.b64encode(b"new").decode())
        digest = self.host.read(self.session, self.grant["id"], "a")["sha256"]
        self.host.write(self.session, self.grant["id"], "a", base64.b64encode(b"new").decode(), expected_sha256=digest)
        self.assertEqual(base64.b64decode(self.host.read(self.session, self.grant["id"], "a")["data"]), b"new")

    def test_readonly_scope(self):
        grant = self.host.grant(self.device["id"], self.root, ["read"], approved=True)
        self.assertDenied(self.host.write, self.session, grant["id"], "a", "eA==")

    def test_bounds_and_base64_errors(self):
        for offset, length in ((-1, 4), (0, 0), (0, 9999999)):
            self.assertDenied(self.host.read, self.session, self.grant["id"], "a", offset=offset, length=length)
        self.assertDenied(self.host.write, self.session, self.grant["id"], "a", "not-base64!")

    def test_mkdir_listing_move_and_delete(self):
        self.host.mkdir(self.session, self.grant["id"], "folder")
        self.host.write(self.session, self.grant["id"], "folder/a", "aGVsbG8=")
        self.assertEqual(self.host.list(self.session, self.grant["id"], "folder")["entries"][0]["name"], "a")
        self.assertDenied(self.host.remove, self.session, self.grant["id"], "folder/a")
        digest = self.host.read(self.session, self.grant["id"], "folder/a")["sha256"]
        destructive = self.host.grant(self.device["id"], self.root, ["read", "write", "delete"], approved=True)
        self.host.move(self.session, destructive["id"], "folder/a", "folder/b")
        self.host.remove(self.session, destructive["id"], "folder/b", expected_sha256=digest)
        self.assertFalse((self.root / "folder/b").exists())

    def test_search_real_content_bounded(self):
        (self.root / "alpha.txt").write_text("needle\nother\n")
        (self.root / "sub").mkdir()
        (self.root / "sub/beta.txt").write_text("needle again\n")
        (self.root / "escape").symlink_to(self.base)
        found = self.host.search(self.session, self.grant["id"], "needle", content=True)
        self.assertEqual({r["path"] for r in found["results"]}, {"alpha.txt", "sub/beta.txt"})
        self.assertEqual(len(self.host.search(self.session, self.grant["id"], "txt", limit=1)["results"]), 1)

    def test_process_scope_is_exact_and_output_is_real(self):
        argv = [str(Path(sys.executable).resolve()), "-c", "import sys; print('out'); print('err', file=sys.stderr); sys.exit(7)"]
        command = self.host.approve_command(self.device["id"], argv, self.grant["id"], ".", approved=True)
        job = self.host.start(self.session, command["id"])
        for _ in range(100):
            result = self.host.process(self.session, job["id"])
            if result["state"] != "running":
                break
            time.sleep(.02)
        self.assertEqual(result["exit_code"], 7)
        self.assertIn("out", base64.b64decode(result["stdout"]).decode())
        self.assertIn("err", base64.b64decode(result["stderr"]).decode())
        self.assertDenied(self.host.start, self.session, "unapproved")

    def test_process_environment_no_inherited_secret(self):
        os.environ["BIFROST_TEST_PRIVATE_TOKEN"] = "must-not-inherit"
        self.addCleanup(os.environ.pop, "BIFROST_TEST_PRIVATE_TOKEN", None)
        argv = [str(Path(sys.executable).resolve()), "-c", "import os; print(os.getenv('BIFROST_TEST_PRIVATE_TOKEN','absent')); print(os.getenv('LANG'))"]
        command = self.host.approve_command(self.device["id"], argv, self.grant["id"], ".", approved=True)
        job = self.host.start(self.session, command["id"])
        for _ in range(100):
            result = self.host.process(self.session, job["id"])
            if result["state"] != "running":
                break
            time.sleep(.02)
        self.assertIn(b"absent", base64.b64decode(result["stdout"]))
        self.assertDenied(self.host.approve_command, self.device["id"], argv, self.grant["id"], ".", environment={"DYLD_INSERT_LIBRARIES":"x"}, approved=True)

    def test_control_only_owned_jobs_and_revoke_terminates(self):
        argv = [str(Path(sys.executable).resolve()), "-c", "import time; time.sleep(60)"]
        command = self.host.approve_command(self.device["id"], argv, self.grant["id"], ".", approved=True)
        job = self.host.start(self.session, command["id"])
        self.assertDenied(self.host.terminate, self.session, "arbitrary-pid")
        self.host.revoke(self.device["id"], approved=True)
        self.assertIsNotNone(self.host._jobs[job["id"]].p.poll())

    def test_secret_not_in_database_or_audit(self):
        secret = self.vault.get(self.device["id"])
        self.host.list(self.session, self.grant["id"])
        for file in (self.base / "state").iterdir():
            if file.is_file():
                self.assertNotIn(secret.encode(), file.read_bytes())

    def test_discovery_is_availability_not_trust(self):
        result = self.host.discovery(self.session)
        self.assertIn("ssh", result["tools"])
        self.assertEqual(result["remote"]["enabled"], False)
        self.assertNotIn("credentials", json.dumps(result))

    def test_grant_revocation_is_immediate(self):
        self.host.revoke_grant(self.grant["id"], approved=True)
        self.assertDenied(self.host.list, self.session, self.grant["id"])

    def test_output_limit_drains_without_deadlock(self):
        argv = [str(Path(sys.executable).resolve()), "-c", "import sys; sys.stdout.buffer.write(b'x'*2000000); sys.stderr.buffer.write(b'y'*2000000)"]
        command = self.host.approve_command(self.device["id"], argv, self.grant["id"], ".", approved=True)
        job = self.host.start(self.session, command["id"])
        for _ in range(200):
            result = self.host.process(self.session, job["id"])
            if result["state"] != "running":
                break
            time.sleep(.02)
        self.assertEqual(result["exit_code"], 0)
        self.assertTrue(result["truncated"])
        self.assertLessEqual(result["stdout_size"], self.host.output_limit)


if __name__ == "__main__":
    unittest.main()
