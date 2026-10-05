import tempfile
import unittest
from pathlib import Path
from bifrost.native_host import NativeError
from bifrost.native_transport import ssh_stdio_command


class SSHTransportTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.known = Path(self.tmp.name)/"known_hosts"
        self.known.write_text("test-only")
        self.kw = dict(host="mac.local", user="owner", port=22, known_hosts=self.known,
                       launcher="/Applications/BIFROST Native Access.app/Contents/Resources/native-host",
                       device_id="00000000-0000-0000-0000-000000000000", approved=True)

    def test_strict_host_key_and_no_forwarding(self):
        command = ssh_stdio_command(**self.kw)
        self.assertIn("StrictHostKeyChecking=yes", command)
        self.assertIn("BatchMode=yes", command)
        self.assertIn("ForwardAgent=no", command)
        self.assertIn("ClearAllForwardings=yes", command)
        self.assertIn("-T", command)
        self.assertNotIn("accept-new", " ".join(command))
        self.assertIn("'/Applications/BIFROST Native Access.app/", command[-1])

    def test_injection_unapproved_and_invalid_peer_rejected(self):
        for changes in ({"approved":False}, {"host":"-oProxyCommand=evil"}, {"host":"mac;evil"},
                        {"user":"owner;evil"}, {"port":0}, {"device_id":"not-a-uuid"},
                        {"known_hosts":Path("/missing")}):
            with self.assertRaises(NativeError):
                ssh_stdio_command(**(self.kw | changes))
