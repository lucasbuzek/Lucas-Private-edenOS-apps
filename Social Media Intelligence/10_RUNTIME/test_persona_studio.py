import json, unittest
from pathlib import Path
from persona_studio import slug, validate

class PersonaStudioTests(unittest.TestCase):
    def valid_persona(self):
        p=json.loads((Path(__file__).resolve().parent.parent/'03_PERSONAS'/'PERSONA_CUSTOMIZATION_TEMPLATE.json').read_text())
        p.update({"persona_id":"test-persona","display_name":"Test persona","mission":"Explain evidence clearly"})
        p["account_identity"].update({"type":"brand","public_name":"Test Brand","platforms":["LinkedIn"]})
        p["audience"].update({"description":"Professionals","timezone":"Africa/Johannesburg"})
        p["editorial_scope"]["allowlist"]=["AI policy"]
        p["status"]="CONFIGURED_PENDING_REVIEW"
        return p
    def test_valid_profile_passes(self):
        self.assertEqual(validate(self.valid_persona()), [])
    def test_bad_timezone_fails(self):
        p=self.valid_persona(); p["audience"]["timezone"]="Mars/Olympus"
        self.assertTrue(any("IANA timezone" in x for x in validate(p)))
    def test_auto_publish_is_rejected(self):
        p=self.valid_persona(); p["publishing"]["auto_publish"]=True
        self.assertTrue(any("auto_publish" in x for x in validate(p)))
    def test_slug_is_normalized(self):
        self.assertEqual(slug("My Brand / Private"), "my-brand-private")

if __name__=="__main__": unittest.main()

