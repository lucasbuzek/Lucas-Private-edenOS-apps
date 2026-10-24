"""Scoped BIFROST file previews: synthetic accounts and exact-directory tests."""
import json
import pathlib
import sys
import tempfile
import unittest
from unittest import mock

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "core"))
import storage_capability as storage
import storage_preview as browser


class StoragePreviewTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = (pathlib.Path(self.tmp.name).resolve() / "home")
        self.home.mkdir()

    def folder(self, relative):
        p = self.home / relative
        p.mkdir(parents=True, exist_ok=True)
        return p

    def accounts(self, config="[personal]\ntype = drive\n[work]\ntype = onedrive\n"):
        dest = self.folder(".config/rclone") / "rclone.conf"
        dest.write_text(config)
        dest.chmod(0o600)
        return dest

    def create(self, name, provider, source, remote, root, remote_root=None):
        return storage.configure_profile(
            name, provider, source, remote, str(root), home=self.home,
            apply=True, remote_root=remote_root
        )

    def test_local_root_and_nested_folder_are_exact_and_not_recursive(self):
        root = self.folder("Documents/Photos")
        (root / "top.jpg").write_bytes(b"top")
        child = root / "2026"
        child.mkdir()
        (child / "child.jpg").write_bytes(b"child")
        (child / "nested").mkdir()
        (child / "nested" / "not-visible.txt").write_text("hidden from this level")
        self.create("Photos", "local", "native-local", "", root)
        first = browser.preview("Photos", home=self.home)
        self.assertEqual(first["status"], "LOCAL_READ_ONLY")
        self.assertEqual({e["name"] for e in first["entries"]},
                         {"top.jpg", "2026"})
        second = browser.preview("Photos", folder="2026", home=self.home)
        self.assertEqual({e["name"] for e in second["entries"]},
                         {"child.jpg", "nested"})
        self.assertNotIn("not-visible.txt", json.dumps(second))
        self.assertFalse(second["remote_read_executed"])

    def test_invalid_relative_paths_and_symlink_targets_are_denied(self):
        root = self.folder("Documents/Photos")
        selected = root / "selected"
        selected.mkdir()
        (selected / "shortcut").symlink_to(root, target_is_directory=True)
        self.create("Photos", "local", "native-local", "", root)
        for relative in ("/", ".", "..", "a//b", "a/..", "../outside",
                         "a\\b", "c:/drive", "%2e%2e", "a/./b"):
            with self.subTest(relative=relative):
                with self.assertRaises((storage.StorageDenied, browser.core.StorageDenied)):
                    browser.preview("Photos", folder=relative, home=self.home)
        with self.assertRaises((storage.StorageDenied, browser.core.StorageDenied)):
            browser.preview("Photos", folder="selected/shortcut", home=self.home)
        with self.assertRaises((storage.StorageDenied, browser.core.StorageDenied)):
            browser.preview("not configured", home=self.home)

    def test_icloud_preview_only_looks_at_selected_drive_folder(self):
        root = self.folder("Library/Mobile Documents/com~apple~CloudDocs/Chosen")
        (root / "clouditem").write_bytes(b"fixture")
        self.create("Apple", "icloud", "native-icloud", "", root)
        item = browser.preview("Apple", home=self.home)
        self.assertEqual(item["provider"], "icloud")
        self.assertEqual(item["count"], 1)
        self.assertFalse(item["remote_read_executed"])

    def test_multiple_accounts_never_share_scopes(self):
        self.accounts()
        root = self.folder("Documents/Storage")
        self.create("Google", "drive", "system", "personal", root, "Photos")
        self.create("Microsoft", "onedrive", "system", "work", root, "Documents")
        requests = []
        def fake(source, remote, folder, provider):
            requests.append((source, remote, folder, provider))
            return [{"name":"readme.txt", "kind":"file", "bytes":11}]
        idle = browser.preview("Google", folder="2026", home=self.home,
                               remote_reader=fake)
        self.assertEqual(idle["status"], "REMOTE_READ_NOT_REQUESTED")
        self.assertEqual(requests, [])
        self.assertEqual(idle["folder"], "Photos/2026")
        one = browser.preview("Google", folder="2026", home=self.home,
                              read_remote=True, remote_reader=fake)
        two = browser.preview("Microsoft", home=self.home,
                              read_remote=True, remote_reader=fake)
        self.assertEqual(one["account_id"], "system:personal")
        self.assertEqual(two["account_id"], "system:work")
        self.assertEqual(requests,
                         [("system","personal","Photos/2026","drive"),
                          ("system","work","Documents","onedrive")])
        self.assertTrue(one["remote_read_executed"])

    def test_no_saved_cloud_scope_and_config_changed_fail_closed(self):
        self.accounts("[personal]\ntype = drive\n")
        root = self.folder("Documents/Storage")
        self.create("LegacyNoGrant", "drive", "system", "personal", root)
        with self.assertRaises((storage.StorageDenied, browser.core.StorageDenied)):
            browser.preview("LegacyNoGrant", home=self.home, read_remote=True)
        self.create("Scoped", "drive", "system", "personal", root, "Allowed")
        config = self.home / ".config/rclone/rclone.conf"
        config.write_text("[personal]\ntype = dropbox\n")
        with self.assertRaises((storage.StorageDenied, browser.core.StorageDenied)):
            browser.preview("Scoped", home=self.home, read_remote=True)

    def test_remote_scope_validation_and_read_result_validation(self):
        self.accounts("[personal]\ntype = drive\n")
        root = self.folder("Documents/Storage")
        for invalid in ("/", ".", "..", "../other", "a//b", "a/../b",
                        "a:folder", "a\\folder", "a%2fb"):
            with self.subTest(folder=invalid):
                with self.assertRaises((storage.StorageDenied, browser.core.StorageDenied)):
                    storage.configure_profile(
                        "Test", "drive", "system", "personal", str(root),
                        home=self.home, remote_root=invalid
                    )
        self.create("Google", "drive", "system", "personal", root, "Chosen")
        for invalid in ([{"name":"../not-allowed", "kind":"file", "bytes":1}],
                        [{"name":"x","kind":"other","bytes":1}],
                        [{"name":"x","kind":"file","bytes":-1}],
                        [{"name":"x","kind":"file","bytes":True}]):
            with self.assertRaises((storage.StorageDenied, browser.core.StorageDenied)):
                browser.preview("Google", home=self.home, read_remote=True,
                                remote_reader=lambda *args: invalid)
        with self.assertRaises((storage.StorageDenied, browser.core.StorageDenied)):
            browser.preview("Google", home=self.home, read_remote=True)
        self.assertEqual(storage.profiles(home=self.home)[0]["remote_root"], "Chosen")

    def test_rclone_metadata_reader_only_runs_bounded_command_when_requested(self):
        self.accounts("[personal]\ntype = drive\n")
        root = self.folder("Documents/Storage")
        self.create("Google", "drive", "system", "personal", root, "Photos")
        command = []
        class Result:
            returncode = 0
        def fake_run(args, **kwargs):
            command.extend(args)
            kwargs["stdout"].write(b'[{"Name":"photo.jpg","IsDir":false,"Size":12}]')
            return Result()
        with mock.patch.object(browser, "subprocess", create=True):
            with mock.patch("subprocess.run", side_effect=fake_run):
                with mock.patch("shutil.which", return_value="/usr/local/bin/rclone"):
                    result = browser.preview(
                        "Google", home=self.home, read_remote=True,
                        remote_reader=lambda a,b,c,d:
                        browser.rclone_metadata_reader(a,b,c,d,home=self.home)
                    )
        self.assertEqual(result["count"], 1)
        self.assertIn("lsjson", command)
        self.assertIn("--max-depth", command)
        self.assertIn("1", command)
        self.assertIn("--disable", command)
        self.assertIn("ListR", command)
        self.assertNotIn("sync", command)
        self.assertNotIn("copy", command)


    def test_same_remote_label_from_two_sources_retains_two_accounts(self):
        self.accounts("[same]\ntype = drive\n")
        config = self.folder("Library/Application Support/Dropbox Lite") / "rclone.conf"
        config.write_text("[same]\ntype = drive\n")
        config.chmod(0o600)
        root = self.folder("Documents/Selected")
        self.create("Primary", "drive", "system", "same", root, "Family")
        self.create("Secondary", "drive", "managed-dropbox-lite", "same",
                    root, "Work")
        invoked = []
        def fake(source, remote, folder, provider):
            invoked.append((source, remote, folder))
            return [{"name": "summary", "kind": "file", "bytes": 1}]
        a = browser.preview("Primary", home=self.home,
                            read_remote=True, remote_reader=fake)
        b = browser.preview("Secondary", home=self.home,
                            read_remote=True, remote_reader=fake)
        self.assertNotEqual(a["account_id"], b["account_id"])
        self.assertEqual(invoked, [("system","same","Family"),
                                   ("managed-dropbox-lite","same","Work")])

    def test_account_reassigned_without_changing_provider_revokes_saved_scope(self):
        config = self.accounts("[personal]\ntype = drive\ntoken = SYNTHETIC_OLD\n")
        root = self.folder("Documents/Selected")
        self.create("Google", "drive", "system", "personal", root, "Chosen")
        original = browser.preview("Google", home=self.home)
        self.assertEqual(original["status"], "REMOTE_READ_NOT_REQUESTED")
        config.write_text("[personal]\ntype = drive\ntoken = SYNTHETIC_NEW\n")
        with self.assertRaises(browser.core.StorageDenied):
            browser.preview("Google", home=self.home)
        self.assertFalse(storage.profiles(home=self.home)[0]["transfers_authorized"])

    def test_provider_credentials_need_private_regular_config(self):
        cfg = self.accounts("[personal]\ntype = drive\n")
        root = self.folder("Documents/Selected")
        self.create("Google", "drive", "system", "personal", root, "Chosen")
        cfg.chmod(0o644)
        with self.assertRaises(browser.core.StorageDenied):
            browser.rclone_metadata_reader("system", "personal", "Chosen",
                                          "drive", home=self.home)
        cfg.chmod(0o600)
        with self.assertRaises(browser.core.StorageDenied):
            browser.rclone_metadata_reader("system", "personal", "Chosen",
                                          "onedrive", home=self.home)

    def test_bounded_rclone_output_denies_invalid_provider_entry(self):
        self.accounts("[personal]\ntype = drive\n")
        def synthetic(args, **kwargs):
            kwargs["stdout"].write(b'[{"Name":"unsafe","IsDir":"invalid","Size":1}]')
            return type("Result", (), {"returncode": 0})()
        with mock.patch("subprocess.run", side_effect=synthetic):
            with mock.patch("shutil.which", return_value="/usr/local/bin/rclone"):
                with self.assertRaises(browser.core.StorageDenied):
                    browser.rclone_metadata_reader("system", "personal", "Chosen",
                                                  "drive", home=self.home)


if __name__ == "__main__":
    unittest.main()
