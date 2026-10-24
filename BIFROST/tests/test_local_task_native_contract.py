"""Contract for native local status receipts without online plugin execution."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Sources"


class NativeLocalReceiptTests(unittest.TestCase):
    def test_native_receipt_client_is_user_driven_and_local_only(self):
        text = (SOURCE / "HeadlessClient.swift").read_text()
        self.assertIn('baseURL.appendingPathComponent("api/tasks/v1")', text)
        self.assertIn('URLQueryItem(name: "limit", value: "8")', text)
        self.assertIn('request.setValue(token, forHTTPHeaderField: "X-Bifrost-Token")', text)
        self.assertIn('"kind": "local.status.snapshot"', text)
        self.assertIn('"idempotencyKey": UUID().uuidString', text)
        self.assertIn('"local-readonly-observation"', text)
        self.assertIn('!receipt.remoteExecutionVerified', text)
        self.assertIn('func recordLocalObservation()', text)
        self.assertIn('func refreshLocalReceipts()', text)
        self.assertIn('guard isRunning else', text)
        self.assertNotIn('"remote.executor.start"', text)

    def test_native_dashboard_never_mislabels_receipts_as_remote_execution(self):
        text = (SOURCE / "BifrostDashboardView.swift").read_text()
        self.assertIn('BifrostPanel(title: "Local activity"', text)
        self.assertIn('Button("Record check") { headless.recordLocalObservation() }', text)
        self.assertIn('.disabled(!headless.isRunning)', text)
        self.assertIn('Durable Headless receipts · no cloud work or background automation', text)
        self.assertIn('headless.localReceipts.prefix(5)', text)
        self.assertIn('headless.refreshLocalReceipts()', text)
        self.assertNotIn('system.remote', text)

    def test_disconnection_hides_stale_receipts(self):
        client = (SOURCE / "HeadlessClient.swift").read_text()
        self.assertIn('localReceipts = []', client)
        self.assertIn('Headless disconnected; local receipts hidden', client)
        self.assertIn('Unverified Headless identity on localhost', client)


if __name__ == "__main__":
    unittest.main()
