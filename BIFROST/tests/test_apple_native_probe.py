import subprocess
import unittest
import sys
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "headless"))
import apple_native_probe as probe


class AppleNativeProbeTests(unittest.TestCase):
    def test_unsupported_host_never_probes(self):
        def forbidden(*args, **kwargs):
            raise AssertionError("must not inspect foreign host")
        result = probe.inspect(system="Linux", which=forbidden, run=forbidden)
        self.assertEqual(result["status"], "unsupported-host")
        self.assertEqual(result["capabilities"], [])

    def test_macos_discovery_does_not_claim_connected(self):
        binaries = {"xcrun", "xcodebuild", "shortcuts", "osascript"}
        result = probe.inspect(
            system="Darwin", which=lambda cmd: "/usr/bin/" + cmd if cmd in binaries else None,
            run=lambda *args, **kwargs: subprocess.CompletedProcess(args, returncode=0))
        records = {r["id"]: r for r in result["capabilities"]}
        self.assertEqual(records["apple.xcode.mcpbridge"]["status"], "binary-found")
        self.assertEqual(records["apple.xcode.mcpbridge"]["permission"], "xcode-setting-unknown")
        self.assertTrue(all(x["connected"] == "unknown" for x in result["capabilities"]))
        self.assertTrue(result["readOnly"])

    def test_absent_xcrun_never_starts_process(self):
        with mock.patch("apple_native_probe.subprocess.run", side_effect=AssertionError("ran")):
            result = probe.inspect(system="Darwin", which=lambda cmd: None)
        xcode = next(x for x in result["capabilities"] if x["id"] == "apple.xcode.mcpbridge")
        self.assertEqual(xcode["status"], "not-detected")

    def test_probe_failure_is_not_success(self):
        result = probe.inspect(system="Darwin", which=lambda cmd: "found" if cmd == "xcrun" else None,
                               run=lambda *args, **kwargs: (_ for _ in ()).throw(subprocess.TimeoutExpired("xcrun", 3)))
        mcp = next(x for x in result["capabilities"] if x["id"] == "apple.xcode.mcpbridge")
        self.assertEqual(mcp["status"], "probe-failed")

    def test_probe_has_fixed_safe_arguments(self):
        called = []
        def runner(argv, **kwargs):
            called.append((argv, kwargs))
            return subprocess.CompletedProcess(argv, returncode=1)
        result = probe.inspect(system="Darwin", which=lambda cmd: "yes" if cmd == "xcrun" else None, run=runner)
        self.assertEqual(called[0][0], ["xcrun", "--find", "mcpbridge"])
        self.assertEqual(called[0][1]["stdin"], subprocess.DEVNULL)
        self.assertFalse(called[0][1]["check"])
        self.assertEqual(result["status"], "inventory-only")


if __name__ == "__main__":
    unittest.main()
