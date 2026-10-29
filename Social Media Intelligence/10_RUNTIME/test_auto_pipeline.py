import unittest
from auto_pipeline import schedule_proposal, make_prompt, build_calendar_slots, parse_model_json

class AutoPipelineTests(unittest.TestCase):
    def test_schedule_is_not_configured_without_time(self):
        self.assertEqual(schedule_proposal({}, None)["status"], "NOT_CONFIGURED")
    def test_naive_schedule_requires_persona_timezone(self):
        self.assertEqual(schedule_proposal({}, "2026-10-12T12:00:00")["status"], "BLOCKED")
    def test_schedule_is_local_only(self):
        import datetime as dt
        tomorrow = (dt.datetime.now(dt.timezone.utc) + dt.timedelta(days=1)).replace(microsecond=0).isoformat()
        result = schedule_proposal({}, tomorrow)
        self.assertEqual(result["status"], "LOCAL_PROPOSAL_ONLY")
        self.assertEqual(result["external_action"], "NOT_PERFORMED")
    def test_calendar_is_blocked_without_cadence(self):
        slots, status = build_calendar_slots({"audience":{"timezone":"Africa/Johannesburg"}})
        self.assertEqual(slots, [])
        self.assertEqual(status["status"], "NOT_CONFIGURED")
    def test_calendar_proposes_local_future_slots(self):
        persona = {"audience":{"timezone":"Africa/Johannesburg"},
                   "calendar":{"posts_per_week":2,"preferred_days":["Mon","Tue","Wed","Thu","Fri","Sat","Sun"],
                               "preferred_local_times":["23:59"],"minimum_gap_hours":18}}
        slots, status = build_calendar_slots(persona, 7)
        self.assertTrue(slots)
        self.assertEqual(status["status"], "PROPOSALS_READY")
        self.assertTrue(all(x["external_action"] == "NOT_PERFORMED" for x in slots))
    def test_cloud_prompt_excludes_private_account_and_workspace_context(self):
        import json
        persona={"persona_id":"p1","account_identity":{"public_name":"Brand","platforms":["LinkedIn"],
                 "account_refs":["SENSITIVE-PRIVATE-ACCOUNT-ID"]},"workspace_scope":"ELYSIUM_PERSONAL",
                 "model_routing":{"cloud_allowed":True},"review":{"reviewer":"private-staff"}}
        candidate={"title":"One","url":"https://example.org","candidate_id":"a"}
        data=json.loads(make_prompt(persona,candidate,[]))
        self.assertNotIn("SENSITIVE-PRIVATE-ACCOUNT-ID",json.dumps(data))
        self.assertNotIn("ELYSIUM_PERSONAL",json.dumps(data))
        self.assertNotIn("private-staff",json.dumps(data))
    def test_local_model_fenced_json_is_parsed(self):
        self.assertEqual(parse_model_json('```json\n{"check":"available"}\n```')["check"], "available")
    def test_invalid_model_output_fails(self):
        with self.assertRaises(ValueError): parse_model_json('This is not JSON')
    def test_prompt_marks_sources_unverified(self):
        prompt = make_prompt({"persona_id":"test"}, {
            "candidate_id":"a1", "title":"A topic", "url":"https://example.com/a",
            "capture_status":"AGGREGATOR_LINK_ONLY", "snippet":"short lead"
        }, [])
        self.assertIn('"claim_verification_status": "NOT_VERIFIED"', prompt)
        self.assertIn("Never set any claim to verified", prompt)

if __name__ == "__main__":
    unittest.main()

