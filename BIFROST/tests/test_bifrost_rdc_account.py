"""BIFROSTcore account onboarding: synthetic, credential-free regression tests."""
from pathlib import Path
import subprocess
import sys
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import bifrost_rdc_account as account


LIST = (
    "  RDC5 RDC 5 (existing) saved local session present\n"
    "* RDC6 RDC 6 (active) saved local session present\n"
    "  bifrostLucasTest1 bifrostLucasTest1 not paired locally\n"
)


class BifrostRdcAccountTests(unittest.TestCase):
    def test_profile_parser_preserves_selected_original(self):
        with mock.patch.object(account, "rdc_command", return_value=(
                subprocess.CompletedProcess([], 0, LIST, ""))):
            previous, target = account.profiles()
        self.assertEqual(previous, "RDC6")
        self.assertIn("not paired locally", target)

    def test_refuses_missing_target_and_ambiguous_selected(self):
        for output in (
                "* RDC6 saved session\n",
                "* RDC6 saved\n* RDC5 saved\n"
                "  bifrostLucasTest1 bifrostLucasTest1 not paired locally\n",
                "* RDC6 saved\n"
                "  bifrostLucasTest1 bifrostLucasTest1 not paired locally\n"
                "  bifrostLucasTest1 duplicate not paired locally\n"):
            with self.subTest(output=output), mock.patch.object(
                    account, "rdc_command", return_value=(
                    subprocess.CompletedProcess([], 0, output, ""))):
                with self.assertRaises(account.EnrollmentError):
                    account.profiles()

    def test_supported_native_safari_destinations_only(self):
        calls = []
        def simulated(argv, **kwargs):
            calls.append(argv)
            return subprocess.CompletedProcess(argv, 0, "", "")
        with mock.patch.object(account.subprocess, "run", side_effect=simulated):
            account.open_safari(account.APPLE_URL)
            account.open_safari(account.RDC_URL)
            with self.assertRaises(account.EnrollmentError):
                account.open_safari("https://untrusted.example/account")
        self.assertEqual(calls, [
            ["/usr/bin/open", "-a", "Safari", account.APPLE_URL],
            ["/usr/bin/open", "-a", "Safari", account.RDC_URL],
        ])

    def test_login_requires_user_confirmed_apple_and_vendor_gate(self):
        with mock.patch.object(account, "rdc_command") as remote:
            with self.assertRaises(account.EnrollmentError):
                account.login(relay_confirmed=False, vendor_confirmed=True)
            with self.assertRaises(account.EnrollmentError):
                account.login(relay_confirmed=True, vendor_confirmed=False)
        remote.assert_not_called()

    def test_login_cannot_use_unapproved_default_browser(self):
        with mock.patch.object(account, "https_browser", return_value="com.google.Chrome"), \
             mock.patch.object(account, "rdc_command") as remote:
            with self.assertRaises(account.EnrollmentError):
                account.login(relay_confirmed=True, vendor_confirmed=True)
        remote.assert_not_called()

    def test_login_invokes_only_existing_official_launcher_and_restores_selection(self):
        calls = []
        def runner(args, capture=True):
            calls.append((args, capture))
            if args == ["list"]:
                return subprocess.CompletedProcess([], 0, LIST, "")
            return subprocess.CompletedProcess([], 0, "", "")
        with mock.patch.object(account, "https_browser", return_value=account.SAFARI_ID), \
             mock.patch.object(account, "rdc_command", side_effect=runner):
            result = account.login(relay_confirmed=True, vendor_confirmed=True)
        self.assertEqual(result, 0)
        self.assertEqual(calls, [
            (["list"], True),
            (["login", account.LABEL], False),
            (["switch", "RDC6"], True),
        ])

    def test_login_refuses_existing_session_without_reauthentication(self):
        paired = LIST.replace("not paired locally", "saved local session present")
        with mock.patch.object(account, "https_browser", return_value=account.SAFARI_ID), \
             mock.patch.object(account, "rdc_command", return_value=(
                subprocess.CompletedProcess([], 0, paired, ""))) as vendor:
            with self.assertRaises(account.EnrollmentError):
                account.login(relay_confirmed=True, vendor_confirmed=True)
        vendor.assert_called_once_with(["list"])

    def test_safari_resolution_refuses_unknown(self):
        with mock.patch.object(account.subprocess, "run", return_value=(
                subprocess.CompletedProcess([], 1, "", "denied"))):
            self.assertEqual(account.https_browser(), "UNKNOWN")

    def test_help_and_guide_do_not_access_vendor_or_credentials(self):
        with mock.patch.object(account, "rdc_command") as vendor, \
             mock.patch.object(account, "open_safari") as browser, \
             mock.patch.object(account, "https_browser") as btype:
            self.assertEqual(account.main(["guide"]), 0)
        vendor.assert_not_called()
        browser.assert_not_called()
        btype.assert_not_called()


if __name__ == "__main__":
    unittest.main()
