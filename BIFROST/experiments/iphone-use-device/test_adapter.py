import unittest
from adapter import summarize_phone_status


class IPhoneUseTests(unittest.TestCase):
    def test_ready_status_is_not_permission(self):
        x = summarize_phone_status({"device_state": "ready", "drivable": True,
                                    "device": {"name": "PRIVATE"}, "lock_readiness": {"verdict": "ready"}})
        self.assertTrue(x["ready_observed"])
        self.assertFalse(x["enabled"])
        self.assertNotIn("PRIVATE", repr(x))

    def test_released_is_not_ready(self):
        self.assertFalse(summarize_phone_status({"device_state": "released"})["ready_observed"])

    def test_handoff_conflict_rejected(self):
        with self.assertRaises(ValueError):
            summarize_phone_status({"device_state": "ready", "drivable": True, "human_handoff": True})

    def test_unknown_state_rejected(self):
        with self.assertRaises(ValueError):
            summarize_phone_status({"device_state": "executing"})

    def test_untrusted_lock_data_rejected(self):
        with self.assertRaises(ValueError):
            summarize_phone_status({"device_state": "ready", "lock_readiness": {"verdict": "unlock_with_password"}})
