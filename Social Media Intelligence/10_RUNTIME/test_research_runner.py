import unittest
from research_runner import safe_public_url, canonical_url, make_candidate, parse_date

class ResearchRunnerTests(unittest.TestCase):
    def test_rejects_local_and_non_http_urls(self):
        self.assertFalse(safe_public_url("http://localhost/admin"))
        self.assertFalse(safe_public_url("http://127.0.0.1/private"))
        self.assertFalse(safe_public_url("file:///etc/passwd"))
        self.assertFalse(safe_public_url("https://machine.local/"))
    def test_accepts_public_https_url(self):
        self.assertTrue(safe_public_url("https://example.com/news?id=1"))
    def test_canonical_url_drops_tracking(self):
        self.assertEqual(canonical_url("https://Example.com/a/?utm_source=x&id=3#part"),
                         "https://example.com/a?id=3")
    def test_candidate_is_lead_not_verified(self):
        c = make_candidate("Example headline", "https://example.com/story", "TEST")
        self.assertEqual(c["capture_status"], "LEAD_ONLY")
        self.assertEqual(c["claim_verification_status"], "NOT_VERIFIED")
    def test_bad_url_is_rejected(self):
        self.assertIsNone(make_candidate("Bad", "file:///etc/passwd", "TEST"))
    def test_parse_iso_date(self):
        self.assertEqual(parse_date("2026-10-11T08:00:00Z"), "2026-10-11T08:00:00Z")

if __name__ == "__main__":
    unittest.main()

