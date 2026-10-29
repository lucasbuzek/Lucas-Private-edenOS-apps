import importlib.util
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("queue_governor.py")
spec = importlib.util.spec_from_file_location("queue_governor", SCRIPT)
g = importlib.util.module_from_spec(spec)
spec.loader.exec_module(g)

class GovernorTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        g.DATA = root / "data"
        g.QUEUE = g.DATA / "queue.json"
        g.AUDIT = g.DATA / "audit.jsonl"
        self.post = {
            "post_id": "test-1", "persona_id": "explainer",
            "platform": "test-platform", "account_id": "test-account",
            "audience": "test audience", "text": "A sourced test draft.",
            "source_urls": ["https://example.org/source"],
            "proposed_publish_at": "2099-01-01T12:00:00+00:00",
            "state": "READY_FOR_REVIEW", "approval": None,
            "created_at": g.now(), "updated_at": g.now(),
            "history": []
        }
        self.post["content_hash"] = g.digest(g.content_payload(self.post))
        q = {"schema_version": 1, "posts": {"test-1": self.post}}
        g.save(q)

    def tearDown(self):
        self.tmp.cleanup()

    def test_approve_exact_version_and_prepare_only(self):
        q = g.load()
        p = q["posts"]["test-1"]
        p["approval"] = {"reviewer": "human", "content_hash": p["content_hash"],
                         "platform": p["platform"], "account_id": p["account_id"],
                         "action": "PREPARE_SCHEDULE", "expires_at": "2999-01-01T00:00:00+00:00"}
        p["state"] = "APPROVED"
        g.save(q)
        # Schedule preparation does not call any external provider.
        class Args: id = "test-1"
        g.cmd_schedule_proposal(Args())
        self.assertEqual(g.load()["posts"]["test-1"]["state"], "SCHEDULE_PREPARED")

    def test_edit_invalidates_approval(self):
        q = g.load()
        p = q["posts"]["test-1"]
        p["approval"] = {"content_hash": p["content_hash"]}
        p["state"] = "APPROVED"
        p["text"] = "Changed text"
        g.refresh_hash(p)
        self.assertIsNone(p["approval"])
        self.assertEqual(p["state"], "READY_FOR_REVIEW")

    def test_submit_is_fail_closed(self):
        class Args: id = "test-1"
        with self.assertRaisesRegex(ValueError, "deliberately disabled"):
            g.cmd_submit(Args())

    def test_hash_detects_tampering(self):
        q = g.load()
        p = q["posts"]["test-1"]
        p["text"] = "tampered"
        self.assertNotEqual(g.digest(g.content_payload(p)), p["content_hash"])

if __name__ == "__main__":
    unittest.main(verbosity=2)

