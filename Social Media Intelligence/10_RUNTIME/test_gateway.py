import datetime as dt
import unittest
from inchat_gateway import execute
from workspace_policy import authorize

class WorkspaceGatewayTests(unittest.TestCase):
    def test_capabilities_have_no_external_actions(self):
        r=execute({"operation":"capabilities"})
        self.assertEqual(r["status"],"PASS")
        self.assertEqual(r["publishing"],"DISABLED")
    def test_lucas_private_requires_authenticated_principal(self):
        request={"workspace_scope":"LUCAS_PRIVATE","action":"VIEW_PERSONA","principal_id":"lucas"}
        self.assertFalse(authorize(request)["allowed"])
        request["session_authenticated"]=True
        self.assertTrue(authorize(request)["allowed"])
        request["principal_id"]="wife"
        self.assertFalse(authorize(request)["allowed"])
    def test_elysium_defaults_to_denied_even_spouse(self):
        r=authorize({"workspace_scope":"ELYSIUM_PERSONAL","action":"VIEW_DRAFTS",
             "session_authenticated":True,"principal_id":"wife","purpose":"household"})
        self.assertFalse(r["allowed"])
    def test_elysium_requires_specific_fresh_consent(self):
        now=dt.datetime(2026,10,19,tzinfo=dt.timezone.utc)
        base={"workspace_scope":"ELYSIUM_BUSINESS","action":"VIEW_RESEARCH",
              "session_authenticated":True,"principal_id":"wife","purpose":"approved-business-campaign"}
        receipt={"receipt_id":"r1","grantor":"business-owner","grantee":"wife",
                 "action":"VIEW_RESEARCH","workspace_scope":"ELYSIUM_BUSINESS",
                 "purpose":"approved-business-campaign","expires_at":"2026-10-20T00:00:00Z"}
        self.assertTrue(authorize({**base,"consent_receipts":[receipt]},now=now)["allowed"])
        self.assertFalse(authorize({**base,"purpose":"private-finance","consent_receipts":[receipt]},now=now)["allowed"])
        self.assertFalse(authorize({**base,"consent_receipts":[receipt]},now=now+dt.timedelta(days=2))["allowed"])
    def test_external_actions_always_fail_closed(self):
        r=authorize({"workspace_scope":"LUCAS_PRIVATE","action":"PUBLISH",
              "session_authenticated":True,"principal_id":"lucas"})
        self.assertFalse(r["allowed"])
    def test_unknown_gateway_action_fails(self):
        self.assertEqual(execute({"operation":"post_now"})["status"],"FAIL")
    def test_calendar_requires_verified_workspace_context(self):
        r=execute({"operation":"calendar_preview","persona":{"status":"ACTIVE"}})
        self.assertEqual(r["status"],"UNKNOWN")
    def test_calendar_persona_scope_must_match(self):
        r=execute({"operation":"calendar_preview","persona":{"status":"ACTIVE","workspace_scope":"ELYSIUM_BUSINESS"},
            "authorization":{"workspace_scope":"LUCAS_PRIVATE","principal_id":"lucas","session_authenticated":True}})
        self.assertEqual(r["status"],"FAIL")

if __name__=="__main__":
    unittest.main()

