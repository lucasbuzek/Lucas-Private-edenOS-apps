"""Mock-only candidate boundary regressions. No network, device, or provider access."""
import importlib.util
from pathlib import Path
import unittest

MODULE = Path(__file__).with_name("boundary.py")
spec = importlib.util.spec_from_file_location("candidate_boundary", MODULE)
boundary = importlib.util.module_from_spec(spec)
spec.loader.exec_module(boundary)

class BoundaryTests(unittest.TestCase):
    def test_mock_status(self):
        actual = boundary.normalize_observation({"kind": boundary.KIND, "operation": "status", "status": "unknown", "token": "must-not-leak"})
        self.assertEqual(actual, {"kind": boundary.KIND, "operation": "status", "status": "unknown", "enabled": False})
    def test_wrong_provider_rejected(self):
        with self.assertRaises(ValueError):
            boundary.normalize_observation({"kind": "other", "operation": "status", "status": "available"})
    def test_command_rejected(self):
        with self.assertRaises(PermissionError):
            boundary.normalize_observation({"kind": boundary.KIND, "operation": "execute", "status": "available"})
    def test_execution_denied(self):
        with self.assertRaises(PermissionError):
            boundary.execute({"command": "echo unsafe"})
    def test_invalid_payload(self):
        with self.assertRaises(ValueError):
            boundary.normalize_observation(None)

if __name__ == "__main__":
    unittest.main()
