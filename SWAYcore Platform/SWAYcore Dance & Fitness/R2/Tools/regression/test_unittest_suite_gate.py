import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


RUNNER = Path(__file__).with_name("run_unittest_suite.py")


class UnittestSuiteGateTests(unittest.TestCase):
    def test_zero_test_discovery_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            result = subprocess.run(
                [sys.executable, str(RUNNER), "-s", directory],
                text=True,
                capture_output=True,
                check=False,
            )
        self.assertEqual(result.returncode, 3)
        self.assertIn("zero-test discovery", result.stderr)

    def test_discovered_passing_test_passes(self):
        with tempfile.TemporaryDirectory() as directory:
            Path(directory, "test_fixture.py").write_text(
                "import unittest\n"
                "class Fixture(unittest.TestCase):\n"
                "    def test_true(self): self.assertTrue(True)\n",
                encoding="utf-8",
            )
            result = subprocess.run(
                [sys.executable, str(RUNNER), "-s", directory],
                text=True,
                capture_output=True,
                check=False,
            )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Discovered 1 test(s)", result.stdout)


if __name__ == "__main__":
    unittest.main()
