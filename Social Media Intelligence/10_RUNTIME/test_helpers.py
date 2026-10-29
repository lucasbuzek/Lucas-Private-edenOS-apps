import unittest
from helpers import validate_persona, triage_topic, map_sources, audit_claims, assess_risk, format_channel, propose_calendar

class HelperTests(unittest.TestCase):
    def persona(self):
        return {"persona_id":"p1","account_identity":{"type":"brand","public_name":"Example"},"mission":"Explain",
          "audience":{"language":"en"},"voice":{"traits":["clear"]},"expertise":{"areas":["policy"],"limits":["legal advice"]},
          "editorial_scope":{"allowlist":["policy"],"blocklist":["private data"]},"evidence_policy":{"primary_sources_required_for_material_claims":True},
          "publishing":{"auto_publish":False}}
    def test_persona_valid(self): self.assertEqual(validate_persona(self.persona())["status"],"PASS")
    def test_auto_publish_fails(self):
        p=self.persona(); p["publishing"]["auto_publish"]=True
        self.assertEqual(validate_persona(p)["status"],"FAIL")
    def test_topic_without_sources_unknown(self): self.assertEqual(triage_topic({"title":"Policy change"},self.persona())["status"],"UNKNOWN")
    def test_no_primary_source_unknown(self): self.assertEqual(map_sources("t1",[{"url":"https://example.org","source_type":"commentary"}])["status"],"UNKNOWN")
    def test_disputed_claim_without_counterevidence_unknown(self):
        self.assertEqual(audit_claims([{"text":"Claim","evidence_refs":["s1"],"human_verified":True,"disputed":True}])["status"],"UNKNOWN")
    def test_private_data_blocks(self): self.assertEqual(assess_risk({"private_personal_information":True})["output"]["decision"],"BLOCK")
    def test_missing_channel_policy_unknown(self): self.assertEqual(format_channel({"text":"hello"}, {})["status"],"UNKNOWN")
    def test_calendar_needs_approval(self):
        r=propose_calendar({"post_id":"p1","content_hash":"abc","proposed_publish_at":"2026-10-12T10:00:00+02:00"},{"platform":"x","account_ref":"acct"})
        self.assertEqual(r["status"],"UNKNOWN"); self.assertFalse(r["output"]["external_schedule_created"])

if __name__ == "__main__": unittest.main()


class ExtendedHelperTests(unittest.TestCase):
    def test_editorial_strategy_requires_verified_claims(self):
        from helpers import editorial_strategy
        self.assertEqual(editorial_strategy({"topic_title":"Topic"}, {"persona_id":"p1"})["status"], "UNKNOWN")
    def test_metrics_never_claims_causality(self):
        from helpers import analyze_metrics
        r=analyze_metrics([{"platform":"x","retrieved_at":"2026-10-11","metric_name":"saves","value":3}], {})
        self.assertFalse(r["output"]["causal_conclusions"])

