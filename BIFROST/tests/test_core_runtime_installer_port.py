"""BIFROST custom-port discovery is pinned to the installed owner LaunchAgent."""
from pathlib import Path
import plistlib
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "headless"))
import core_runtime as core


class HeadlessPortTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.agent = self.home / "Library/LaunchAgents/eden.bifrost.headless.plist"
        self.agent.parent.mkdir(parents=True)

    def write_config(self, *, port="9012", label=core.HEADLESS_PRODUCT,
                     script=None):
        path = script or self.home / (
            "Library/Application Support/BIFROST/HeadlessRuntime/headless/server.py")
        spec = {"Label": label,
                "ProgramArguments": ["/usr/bin/python3", "-B", str(path)],
                "EnvironmentVariables": {"BIFROST_HEADLESS_PORT": port}}
        self.agent.write_bytes(plistlib.dumps(spec))

    def test_missing_launch_agent_defaults_safely(self):
        self.assertEqual(core.headless_endpoint(self.home), core.HEADLESS_ENDPOINT)

    def test_custom_installer_port_read_back(self):
        self.write_config(port="9012")
        self.assertEqual(core.headless_endpoint(self.home),
                         "http://127.0.0.1:9012/api/health")

    def test_wrong_launch_agent_identity_refused(self):
        self.write_config(label="other.app", port="9012")
        self.assertEqual(core.headless_endpoint(self.home), core.HEADLESS_ENDPOINT)

    def test_arbitrary_script_refused(self):
        self.write_config(script=self.home/"attacker/server.py")
        self.assertEqual(core.headless_endpoint(self.home), core.HEADLESS_ENDPOINT)

    def test_invalid_port_refused(self):
        for port in ("https://example.com", "0", "-42", "99999", "00090", "9\n10"):
            self.write_config(port=port)
            self.assertEqual(core.headless_endpoint(self.home), core.HEADLESS_ENDPOINT)

    def test_symlinked_launch_agent_refused(self):
        private = self.home / "elsewhere.plist"
        self.write_config()
        self.agent.rename(private)
        self.agent.symlink_to(private)
        self.assertEqual(core.headless_endpoint(self.home), core.HEADLESS_ENDPOINT)

    def test_old_installed_runtime_is_still_supported(self):
        self.write_config(script=self.home/(
            "Library/Application Support/BIFROST/runtime/server.py"))
        self.assertEqual(core.headless_endpoint(self.home),
                         "http://127.0.0.1:9012/api/health")

    def test_unknown_or_malformed_plist_refused(self):
        self.agent.write_bytes(b"broken!")
        self.assertEqual(core.headless_endpoint(self.home), core.HEADLESS_ENDPOINT)


if __name__ == "__main__":
    unittest.main()
