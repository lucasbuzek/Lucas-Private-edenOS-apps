import unittest
from adapter import summarize_models


class LiteLLMTests(unittest.TestCase):
    def test_model_list(self):
        x = summarize_models({"object": "list", "data": [
            {"id": "local/llama-3", "object": "model", "secret": "DO-NOT-RETURN"},
            {"id": "local/llama-3"}, {"id": "other/model"}]})
        self.assertEqual(x["available_models"], ["local/llama-3", "other/model"])
        self.assertNotIn("DO-NOT-RETURN", repr(x))
        self.assertEqual(x["pricing"], "unknown")
        self.assertFalse(x["enabled"])

    def test_bad_response(self):
        with self.assertRaises(ValueError):
            summarize_models({"data": {}})

    def test_injection_id_rejected(self):
        with self.assertRaises(ValueError):
            summarize_models({"data": [{"id": "model\nX-Bifrost-Token: secret"}]})

    def test_unbounded_rejected(self):
        with self.assertRaises(ValueError):
            summarize_models({"data": [{"id": "x"}] * 1001})

    def test_missing_id_rejected(self):
        with self.assertRaises(ValueError):
            summarize_models({"data": [{}]})
