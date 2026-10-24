"""Independent local SQLite observation receipts. No network or installed service."""
import importlib.util
import pathlib
import sqlite3
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "headless/task_ledger.py"
spec = importlib.util.spec_from_file_location("bifrost_task_ledger_test", SOURCE)
ledger = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ledger)


class LocalTaskLedgerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="bifrost-ledger-test-")
        self.root = pathlib.Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def test_durable_record_receipt_and_no_remote_execution(self):
        payload = {"kind": "local.status.snapshot"}
        receipt, created = ledger.record(self.root, payload, {"caffeinateActive": False})
        self.assertTrue(created)
        self.assertRegex(receipt["taskId"], r"^local_[a-f0-9]{32}$")
        self.assertEqual(receipt["state"], "completed")
        self.assertEqual(receipt["kind"], "local.status.snapshot")
        self.assertEqual(receipt["execution"], "local-readonly-observation")
        self.assertFalse(receipt["remoteExecutionVerified"])
        self.assertIsNone(receipt["result"]["remoteTaskId"])
        self.assertFalse(receipt["result"]["caffeinateActive"])
        self.assertEqual(receipt, ledger.get(self.root, receipt["taskId"]))
        self.assertEqual(ledger.recent(self.root)["tasks"][0], receipt)
        self.assertEqual((self.root / ledger.DATABASE).stat().st_mode & 0o777, 0o600)
        self.assertEqual(self.root.stat().st_mode & 0o777, 0o700)

    def test_concurrent_retry_commits_one_receipt(self):
        from concurrent.futures import ThreadPoolExecutor
        payload = {"kind": "local.status.snapshot",
                   "idempotencyKey": "concurrent-20261017-same-key"}
        def submit(_):
            return ledger.record(self.root, payload, {"caffeinateActive": False})
        with ThreadPoolExecutor(max_workers=8) as pool:
            records = list(pool.map(submit, range(12)))
        self.assertEqual(len({record["taskId"] for record, _ in records}), 1)
        self.assertEqual(sum(created for _, created in records), 1)
        self.assertEqual(ledger.recent(self.root)["count"], 1)

    def test_idempotence_survives_reopening_database(self):
        body = {"kind": "local.status.snapshot", "idempotencyKey": "check-unique-987654321"}
        first, created = ledger.record(self.root, body, {"caffeinateActive": True})
        self.assertTrue(created)
        other, created = ledger.record(self.root, body, {"caffeinateActive": False})
        self.assertFalse(created)
        self.assertEqual(first, other)
        self.assertEqual(ledger.recent(self.root)["count"], 1)

    def test_no_arbitrary_commands_or_external_provider_payload(self):
        for request in (
            {}, {"kind": "shell.exec"},
            {"kind": "local.status.snapshot", "command": "date"},
            {"kind": "local.status.snapshot", "provider": "remote"},
            {"kind": "local.status.snapshot", "idempotencyKey": "too short"},
            {"kind": "local.status.snapshot", "idempotencyKey": "../../up"},
            {"kind": "local.status.snapshot", "idempotencyKey": True},
            {"kind": ["local.status.snapshot"]}, [],
        ):
            with self.subTest(request=request):
                with self.assertRaises(ledger.TaskError):
                    ledger.record(self.root, request, {"caffeinateActive": False})
        self.assertFalse((self.root / ledger.DATABASE).exists())

    def test_only_boolean_authoritative_observations(self):
        for bad in ({"caffeinateActive": "false"}, {"caffeinateActive": 0},
                    {"headless": "running"}, {"caffeinateActive": None}):
            with self.assertRaises(ledger.TaskError):
                ledger.record(self.root, {"kind": "local.status.snapshot"}, bad)

    def test_unknown_ids_and_bounded_queries(self):
        with self.assertRaises(ledger.TaskError):
            ledger.get(self.root, "../../other")
        with self.assertRaises(ledger.TaskError):
            ledger.get(self.root, "remote_" + "0" * 32)
        with self.assertRaises(ledger.TaskError):
            ledger.recent(self.root, limit=500)
        with self.assertRaises(ledger.TaskError):
            ledger.recent(self.root, limit=True)
        self.assertIsNone(ledger.get(self.root, "local_" + "0" * 32))
        self.assertEqual(ledger.recent(self.root, limit=1)["tasks"], [])

    def test_storage_rejects_symlink_and_contains_no_secrets(self):
        outside = self.root / "outside.db"
        outside.write_text("do not touch")
        store = self.root / "storage"
        store.mkdir()
        (store / ledger.DATABASE).symlink_to(outside)
        with self.assertRaises(ledger.TaskError):
            ledger.record(store, {"kind": "local.status.snapshot"}, {"caffeinateActive": True})
        self.assertEqual(outside.read_text(), "do not touch")

    def test_observation_only_storage_schema(self):
        receipt, _ = ledger.record(self.root, {"kind": "local.status.snapshot"},
                                   {"caffeinateActive": False, "token": "test-secret-should-not-store"})
        with sqlite3.connect(self.root / ledger.DATABASE) as db:
            result = db.execute("SELECT result_json FROM local_tasks").fetchone()[0]
        self.assertNotIn("test-secret", result)
        self.assertNotIn("token", result)
        self.assertFalse(receipt["remoteExecutionVerified"])


if __name__ == "__main__":
    unittest.main()
