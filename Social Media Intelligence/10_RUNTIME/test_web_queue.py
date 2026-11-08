"""Regression tests for the original FAMA queue via owner-local HTTP adapter."""
from __future__ import annotations

import datetime as dt
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch

import queue_governor as governor
from web_queue import execute

def future(hours=48):
    return (dt.datetime.now(dt.timezone.utc) + dt.timedelta(hours=hours)).isoformat()

def create_payload():
    return {
        "operation": "create", "post_id": "fama-test-1",
        "persona_id": "private-owner", "platform": "LinkedIn",
        "account_id": "owner-explicit-account", "audience": "consenting readers",
        "text": "An attributable analysis and an open question.",
        "source_urls": ["https://example.org/source"],
        "proposed_publish_at": future(),
    }

class QueueHTTPAdapterTests(unittest.TestCase):
    def setUp(self):
        self.temp = TemporaryDirectory()
        root = Path(self.temp.name)
        self.patches = [
            patch.object(governor, "DATA", root),
            patch.object(governor, "QUEUE", root / "queue.json"),
            patch.object(governor, "AUDIT", root / "audit.jsonl"),
        ]
        for p in self.patches:
            p.start()

    def tearDown(self):
        for p in reversed(self.patches):
            p.stop()
        self.temp.cleanup()

    def test_create_list_show_and_no_social_action(self):
        created = execute(create_payload())
        self.assertEqual(created["result"]["state"], "DRAFT")
        self.assertEqual(created["external_social_action"], "NOT_PERFORMED")
        listed = execute({"operation":"list"})["result"]
        self.assertEqual(len(listed), 1)
        shown = execute({"operation":"show", "post_id":"fama-test-1"})["result"]
        self.assertEqual(shown["source_urls"], ["https://example.org/source"])
        self.assertEqual(shown["account_id"], "owner-explicit-account")

    def test_exact_human_approval_and_local_schedule_only(self):
        execute(create_payload())
        execute({"operation":"ready","post_id":"fama-test-1"})
        post = execute({"operation":"show","post_id":"fama-test-1"})["result"]
        approval = {
            "operation":"approve", "post_id":"fama-test-1",
            "reviewer":"Owner", "action":"PREPARE_SCHEDULE",
            "content_hash":post["content_hash"],
            "platform":post["platform"], "account_id":post["account_id"],
            "expires_at":future(1)
        }
        result = execute(approval)
        self.assertEqual(result["result"]["state"], "APPROVED")
        proposed = execute({"operation":"schedule-proposal","post_id":"fama-test-1"})
        self.assertEqual(proposed["result"]["state"], "SCHEDULE_PREPARED")
        self.assertEqual(proposed["result"]["external_action"], "NOT_PERFORMED")
        self.assertEqual(proposed["external_social_action"], "NOT_PERFORMED")

    def test_edits_invalidate_approval_and_stale_hash_rejected(self):
        execute(create_payload())
        execute({"operation":"ready","post_id":"fama-test-1"})
        original = execute({"operation":"show","post_id":"fama-test-1"})["result"]
        approval = {
            "operation":"approve","post_id":"fama-test-1","reviewer":"Owner",
            "action":"PREPARE_SCHEDULE","content_hash":original["content_hash"],
            "platform":original["platform"],"account_id":original["account_id"],
            "expires_at":future(1)
        }
        execute(approval)
        execute({"operation":"edit","post_id":"fama-test-1","text":"Correction after review."})
        edited = execute({"operation":"show","post_id":"fama-test-1"})["result"]
        self.assertEqual(edited["state"], "READY_FOR_REVIEW")
        self.assertIsNone(edited["approval"])
        with self.assertRaisesRegex(ValueError,"Post changed"):
            execute(approval)

    def test_cross_account_or_stale_approval_denied(self):
        execute(create_payload())
        execute({"operation":"ready","post_id":"fama-test-1"})
        p = execute({"operation":"show","post_id":"fama-test-1"})["result"]
        with self.assertRaisesRegex(ValueError,"Post changed"):
            execute({"operation":"approve","post_id":"fama-test-1","reviewer":"Owner",
                "action":"PREPARE_SCHEDULE","content_hash":p["content_hash"],
                "platform":p["platform"],"account_id":"other-account",
                "expires_at":future(1)})

    def test_negative_input_and_no_remote_action(self):
        bad = [
            {"operation":"create", **{**create_payload(),"source_urls":["http://localhost:7000"]}},
            {"operation":"create", **{**create_payload(),"proposed_publish_at":"2030-01-01T12:00:00"}},
            {"operation":"create", **{**create_payload(),"post_id":"../../tmp"}},
            {"operation":"publish", "post_id":"fama-test-1"},
            {"operation":"list", "workspace_scope":"ELYSIUM_OTHER"},
        ]
        for req in bad:
            with self.subTest(req=req), self.assertRaises(ValueError):
                execute(req)

if __name__ == "__main__":
    unittest.main()
