"""First-use BIFROST storage / RDC read-only identity regression tests."""
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "headless"))
import first_use_accounts as first_use


class AccountInventoryTests(unittest.TestCase):
    def test_no_login_or_device_claim_from_saved_labels(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            profiles = home / ".local/share/rdc5-identities"
            profiles.mkdir(parents=True)
            (profiles / "RDC1-home").mkdir()
            (profiles / "RDC6-home").mkdir()
            (profiles / "RDCravensnest-home").mkdir()
            result = first_use.snapshot(
                home=home, accounts_reader=lambda: {"accounts": []})
            self.assertEqual(result["rdc"]["ravensnest"]["deviceReady"], "UNKNOWN")
            self.assertFalse(result["rdc"]["ravensnest"]["deviceAccountVerified"])
            self.assertTrue(result["rdc"]["rdc7ReservedForDifferentAccount"])
            self.assertIn("RDC6-home", result["rdc"]["profileLabels"])
            self.assertTrue(result["rdc"]["noProfileChanged"])
            self.assertFalse(result["capabilities"]["autoSync"])

    def test_not_confuse_legacy_rdc7_with_current_ravennest(self):
        with tempfile.TemporaryDirectory() as directory:
            home=Path(directory)
            profiles=home / ".local/share/rdc5-identities"
            profiles.mkdir(parents=True)
            (profiles / "RDC7-home").mkdir()
            result=first_use.snapshot(home=home,accounts_reader=lambda:{"accounts":[]})
            self.assertFalse(result["rdc"]["ravensnest"]["candidateLabelPresent"])
            self.assertIn("RDC7-home",result["rdc"]["profileLabels"])

    def test_symlinked_profile_ignored(self):
        with tempfile.TemporaryDirectory() as directory:
            home=Path(directory)
            profiles=home / ".local/share/rdc5-identities"
            profiles.mkdir(parents=True)
            target=home / "other";target.mkdir()
            (profiles / "RDCravensnest-home").symlink_to(target)
            result=first_use.snapshot(home=home,accounts_reader=lambda:{"accounts":[]})
            self.assertEqual(result["rdc"]["profileLabels"],[])
            self.assertFalse(result["rdc"]["ravensnest"]["candidateLabelPresent"])

    def test_cloud_token_fields_never_emitted(self):
        fake={"accounts":[{"source":"system","name":"ravenCloud","provider":"drive",
                           "token":"SECRET","email":"other@private.test",
                           "authorized_by_storagecore":True}]}
        with tempfile.TemporaryDirectory() as directory:
            r=first_use.snapshot(home=Path(directory),accounts_reader=lambda:fake)
            account=r["cloud"]["configuredRemoteLabels"][0]
            self.assertEqual(account["remoteLabel"],"ravenCloud")
            self.assertFalse(account["authorizationVerified"])
            self.assertNotIn("token",account)
            self.assertNotIn("email",account)
            self.assertNotIn("SECRET",str(r))
            self.assertFalse(r["cloud"]["oauthGrantMade"])

    def test_malformed_and_unknown_fields_excluded(self):
        fake={"accounts":[{"source":"system","name":"good","provider":"drive"},
                          {"source":"system","name":"http://malicious","provider":"drive"},
                          {"source":"system","name":"private","provider":"drive", "secret":"bad"}]}
        with tempfile.TemporaryDirectory() as directory:
            r=first_use.snapshot(home=Path(directory),accounts_reader=lambda:fake)
            self.assertEqual([x["remoteLabel"] for x in r["cloud"]["configuredRemoteLabels"]],["good","private"])
            self.assertNotIn("bad",str(r))

    def test_rdc_manager_is_metadata_only(self):
        with tempfile.TemporaryDirectory() as directory:
            home=Path(directory);(home/"bin").mkdir()
            (home/"bin/rdc5").write_text("manager fixture",encoding="utf-8")
            first=first_use.snapshot(home=home,accounts_reader=lambda:{"accounts":[]})
            self.assertTrue(first["rdc"]["installedManagerFound"])
            (home/"bin/rdc5").unlink()
            (home/"bin/rdc5").symlink_to(home/"bin/target")
            second=first_use.snapshot(home=home,accounts_reader=lambda:{"accounts":[]})
            self.assertFalse(second["rdc"]["installedManagerFound"])


if __name__=="__main__":
    unittest.main()
