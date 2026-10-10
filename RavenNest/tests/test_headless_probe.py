"""Raven-to-BIFROST Headless observation is read-only, local and sanitized."""
import json
import unittest
from unittest import mock

from bifrost import node_state


class Response:
    def __init__(self, value):
        self.status = 200
        self.body = value if isinstance(value, bytes) else json.dumps(value).encode()

    def __enter__(self):
        return self

    def __exit__(self, *unused):
        return False

    def read(self, count):
        return self.body[:count]


class RavenHeadlessProbeTests(unittest.TestCase):
    def test_sanitized_observation_with_realistic_state(self):
        sent = []
        def network(req, timeout):
            self.assertEqual(timeout, 2)
            self.assertEqual(req.get_method(), "GET")
            self.assertEqual(req.full_url.split("/api/")[0], "http://127.0.0.1:8798")
            self.assertFalse(req.has_header("Authorization"))
            sent.append(req.full_url)
            if req.full_url.endswith("/api/state"):
                return Response({
                    "headless": {"status": "running", "pid": 34},
                    "tasks": {"status": "observed", "active": 2, "token": "DO_NOT_SEND"},
                    "preferences": {"aiRouting": "auto", "key": "DO_NOT_SEND"},
                    "caffeinate": {"active": True}
                })
            return Response({
                "packages": [
                    {"id": "ai-toolkit", "status": "available", "archive_name": "private.zip"},
                    {"id": "project-workspace", "status": "staged", "path": "/private"},
                    {"id": "evil", "status": "available", "path": "/private"}
                ]
            })
        with mock.patch.object(node_state.urllib.request, "urlopen", side_effect=network):
            state = node_state.probe_bifrost_headless()
        self.assertEqual(state["status"], "RUNNING")
        self.assertEqual(state["active_tasks"], 2)
        self.assertEqual(state["ai_routing"], "auto")
        self.assertTrue(state["caffeinate_active"])
        self.assertEqual(state["setup_packages"], [
            {"id": "ai-toolkit", "state": "available"},
            {"id": "project-workspace", "state": "staged"}
        ])
        self.assertNotIn("DO_NOT_SEND", json.dumps(state))
        self.assertNotIn("private.zip", json.dumps(state))
        self.assertEqual(len(sent), 2)
        self.assertEqual(state["remote_setup_execution"], "disabled")

    def test_unreachable_reports_unknown(self):
        with mock.patch.object(node_state.urllib.request, "urlopen", side_effect=OSError("offline")):
            data = node_state.probe_bifrost_headless()
        self.assertEqual(data["status"], "UNKNOWN")
        self.assertFalse(data["setup_packages"])

    def test_oversized_response_rejected(self):
        with mock.patch.object(node_state.urllib.request, "urlopen", return_value=Response(b"x" * 20000)):
            data = node_state.probe_bifrost_headless()
        self.assertEqual(data["status"], "UNKNOWN")

    def test_no_claim_of_connected_mobile(self):
        with mock.patch.object(node_state.urllib.request, "urlopen", side_effect=OSError("offline")):
            data = node_state.probe_bifrost_headless()
        self.assertNotIn("mobile_authenticated", data)
        self.assertNotIn("mobile_paired", data)


if __name__ == "__main__":
    unittest.main()
