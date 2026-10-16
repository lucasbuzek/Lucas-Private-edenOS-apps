import unittest
from adapter import observe_reply


class IMessageTests(unittest.TestCase):
    def test_matching_reply_is_not_authorization(self):
        x = observe_reply({"text": "ABCDEF12", "sender": "untrusted-sender"}, "ABCDEF12")
        self.assertTrue(x["matched_untrusted"])
        self.assertEqual(x["authorization"], "none")
        self.assertFalse(x["enabled"])
        self.assertNotIn("sender", x)

    def test_wrong_challenge(self):
        self.assertFalse(observe_reply({"text": "ABCDEF13"}, "ABCDEF12")["matched_untrusted"])

    def test_invalid_challenge(self):
        with self.assertRaises(ValueError):
            observe_reply({"text": "123"}, "123")

    def test_oversize_rejected(self):
        with self.assertRaises(ValueError):
            observe_reply({"text": "X" * 129}, "ABCDEF12")

    def test_invalid_text_rejected(self):
        with self.assertRaises(ValueError):
            observe_reply({"text": {"a": "b"}}, "ABCDEF12")
