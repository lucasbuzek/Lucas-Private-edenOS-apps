"""BIFROST Files & Storage offline safety and account boundary regression tests."""
import json
import os
import pathlib
import stat
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "core"))
from storage_capability import (StorageDenied, accounts, configure_profile, list_direct,
                                profiles, providers, status)


class StorageCoreTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        # macOS /var is a symlink to /private/var. Resolve test sandbox,
        # not user selections, so fixtures do not violate the safety gate.
        self.home = pathlib.Path(self.tmp.name).resolve() / "home"
        self.home.mkdir()

    def folder(self, rel):
        result = self.home / rel
        result.mkdir(parents=True, exist_ok=True)
        return result

    def config(self, text):
        path = self.folder(".config/rclone") / "rclone.conf"
        path.write_text(text, encoding="utf-8")
        return path

    def test_status_is_offline_fails_closed_and_no_sync(self):
        state = status()
        self.assertEqual(state["schema"], "bifrost.storage.v1")
        for key in ("connected_to_bifrost_headless", "chatgpt_action_bridge_verified",
                    "auto_sync", "hosting_enabled", "accounts_authorized_by_this_module",
                    "acceptedLKG" if "acceptedLKG" in state else "auto_sync"):
            self.assertFalse(state[key])

    def test_catalog_includes_user_provider_choices_without_claimed_writes(self):
        rows = providers()
        ids = {row["id"] for row in rows}
        self.assertTrue({"local", "icloud", "dropbox", "drive", "onedrive",
                         "sftp", "smb", "webdav", "s3", "syncthing"} <= ids)
        self.assertTrue(all(row["state"] != "verified-write" for row in rows))

    def test_multiple_rclone_accounts_metadata_only_and_no_secret_leak(self):
        self.config("""
        [personal]
        type = drive
        token = SENSITIVE_TOKEN_VALUE
        client_secret = SENSITIVE_SECRET_VALUE
        [work]
        type = onedrive
        token = PRIVATE_WORK_TOKEN
        [creative]
        type = dropbox
        token = PRIVATE_DROPBOX_TOKEN
        """)
        found = accounts(home=self.home)
        self.assertEqual([a["name"] for a in found], ["creative", "personal", "work"])
        self.assertEqual({a["provider"] for a in found}, {"dropbox", "drive", "onedrive"})
        self.assertNotIn("SENSITIVE", json.dumps(found))
        self.assertNotIn("PRIVATE_", json.dumps(found))
        self.assertTrue(all(not a["authorized_by_storagecore"] for a in found))

    def test_duplicate_remote_name_different_config_sources_stays_distinct(self):
        self.config("[same]\ntype = drive\n")
        managed = self.folder("Library/Application Support/Dropbox Lite") / "rclone.conf"
        managed.write_text("[same]\ntype = dropbox\n")
        found = accounts(home=self.home)
        self.assertEqual(len(found), 2)
        self.assertNotEqual(found[0]["id"], found[1]["id"])

    def test_encrypted_config_denied_not_modified(self):
        config = self.config("RCLONE_ENCRYPT_V0:\nsecret")
        before = config.read_bytes()
        with self.assertRaises(StorageDenied):
            accounts(home=self.home)
        self.assertEqual(config.read_bytes(), before)

    def test_config_symlink_denied_without_following(self):
        target = self.folder("other") / "source.conf"
        target.write_text("[hidden]\ntype = dropbox\n")
        config = self.folder(".config/rclone") / "rclone.conf"
        config.symlink_to(target)
        with self.assertRaises(StorageDenied):
            accounts(home=self.home)

    def test_one_level_local_list_never_opens_child_contents(self):
        folder = self.folder("Pictures")
        (folder / "image.jpg").write_bytes(b"harmless local fixture")
        (folder / "nested").mkdir()
        (folder / "nested" / "private.txt").write_text("not-allowed")
        visible = list_direct(str(folder), home=self.home)
        self.assertEqual(visible["count"], 2)
        self.assertEqual({a["name"] for a in visible["entries"]}, {"image.jpg", "nested"})
        self.assertNotIn("private.txt", json.dumps(visible))
        self.assertEqual(visible["mode"], "one-level-metadata-only")

    def test_symlink_directory_cannot_be_used_as_selected_scope(self):
        hidden = self.folder("secrets")
        folder = self.folder("Pictures")
        (folder / "redirect").symlink_to(hidden)
        with self.assertRaises(StorageDenied):
            list_direct(str(folder / "redirect"), home=self.home)

    def test_forbidden_dev_roots_secrets_and_icloud_via_local(self):
        for rel in ("edenOS/Software Development", "edenOS/Releases",
                    "edenOS/Products", "edenOS/Projects", ".ssh",
                    ".config", "Library/Application Support",
                    "Library/Mobile Documents/com~apple~CloudDocs"):
            folder = self.folder(rel)
            with self.subTest(folder=rel), self.assertRaises(StorageDenied):
                list_direct(str(folder), home=self.home)
        with self.assertRaises(StorageDenied):
            list_direct("/etc", home=self.home)
        with self.assertRaises(StorageDenied):
            list_direct(str(self.home / "../../etc"), home=self.home)

    def test_explicit_icloud_view_accepts_only_cloud_docs(self):
        cloud = self.folder("Library/Mobile Documents/com~apple~CloudDocs")
        (cloud / "test.txt").write_text("fixture")
        entry = list_direct(str(cloud), home=self.home, icloud=True)
        self.assertEqual(entry["count"], 1)
        with self.assertRaises(StorageDenied):
            list_direct(str(self.folder("Desktop")), home=self.home, icloud=True)

    def test_empty_and_over_limit_are_bounded(self):
        root = self.folder("Large")
        for n in range(201):
            (root / ("item%04d" % n)).touch()
        with self.assertRaises(StorageDenied):
            list_direct(str(root), home=self.home)

    def test_profile_preview_is_not_persisted_and_requires_known_account(self):
        self.config("[lucas]\ntype = drive\n")
        root = self.folder("Documents/Storage")
        answer = configure_profile("LucasGoogle", "drive", "system", "lucas",
                                   str(root), home=self.home)
        self.assertEqual(answer["status"], "PREVIEW_ONLY")
        self.assertFalse(answer["changed"])
        self.assertEqual(profiles(home=self.home), [])
        with self.assertRaises(StorageDenied):
            configure_profile("Unknown", "onedrive", "system", "lucas",
                              str(root), home=self.home)
        with self.assertRaises(StorageDenied):
            configure_profile("Bad", "drive", "system", "unconfigured",
                              str(root), home=self.home)

    def test_explicit_apply_is_only_metadata_without_sync_permissions(self):
        self.config("[lucas]\ntype = drive\n")
        root = self.folder("Documents/Storage")
        result = configure_profile("LucasGoogle", "drive", "system", "lucas",
                                   str(root), home=self.home, apply=True)
        self.assertTrue(result["changed"])
        self.assertEqual(result["profile"]["sync_mode"], "off")
        self.assertFalse(result["profile"]["transfers_authorized"])
        found = profiles(home=self.home)
        self.assertEqual(len(found), 1)
        url = self.home / "Library/Application Support/BIFROST/storage-profiles.v1.json"
        self.assertEqual(stat.S_IMODE(url.stat().st_mode), 0o600)
        with self.assertRaises(StorageDenied):
            configure_profile("LucasGoogle", "drive", "system", "lucas",
                              str(root), home=self.home, apply=True)
        self.assertEqual(len(profiles(home=self.home)), 1)

    def test_local_profile_needs_native_source_and_never_remote_token(self):
        root = self.folder("Documents/Local")
        answer = configure_profile("MacStorage", "local", "native-local", "",
                                   str(root), home=self.home)
        self.assertEqual(answer["status"], "PREVIEW_ONLY")
        with self.assertRaises(StorageDenied):
            configure_profile("Invalid", "local", "system", "",
                              str(root), home=self.home)

    def test_local_capability_contract_is_versioned_and_not_live_connected(self):
        contract = json.loads((pathlib.Path(__file__).resolve().parents[1] /
                               "docs/integrations/files-storage-capability.v1.json").read_text())
        self.assertEqual(contract["id"], "bifrost.files-storage")
        self.assertEqual(contract["owner"], "BIFROST")
        self.assertEqual(contract["executionOwner"], "BIFROSTcore")
        self.assertFalse(contract["runtime"]["installedInExistingHeadless"])
        self.assertFalse(contract["runtime"]["alwaysOnDaemon"])
        actions = {action["name"]: action for action in contract["actions"]}
        self.assertEqual(actions["storage.chatgpt.action"]["availability"], "NOT_CONNECTED")
        self.assertEqual(actions["storage.cloud.sync"]["availability"], "NOT_IMPLEMENTED")
        self.assertEqual(actions["storage.profiles.add.apply"]["availability"], "implemented")
        self.assertTrue(contract["runtime"]["sourceHeadlessRoutesImplemented"])
        self.assertTrue(contract["runtime"]["testedInIsolatedHTTP"])
        self.assertTrue(contract["runtime"]["nativeSourceBundleResourcesVerified"])
        self.assertFalse(contract["runtime"]["liveInstalledHeadlessRouteVerified"])
        self.assertEqual(contract["runtime"]["sourceRoutes"],
                         ["/api/storage/v1", "/api/storage/v1/accounts",
                          "/api/storage/v1/preview"])
        self.assertTrue(contract["runtime"]["sourceScopedPreviewTested"])
        self.assertFalse(contract["runtime"]["liveInstalledHeadlessRouteVerified"])
        self.assertEqual(actions["storage.profile.preview"]["availability"],
                         "implemented")
        self.assertEqual(actions["storage.headless.profile.preview.source"]["availability"],
                         "SOURCE_TESTED_NOT_DEPLOYED")
        self.assertEqual(actions["storage.headless.catalog.source"]["availability"],
                         "SOURCE_TESTED_NOT_DEPLOYED")
        self.assertEqual(actions["storage.headless.accounts.metadata.source"]["availability"],
                         "SOURCE_TESTED_NOT_DEPLOYED")

    def test_terminal_status_json_is_true_to_core_and_has_no_credential_data(self):
        import subprocess
        cli = pathlib.Path(__file__).resolve().parents[1] / "tools/bifrost_storage.py"
        finished = subprocess.run([sys.executable, "-B", str(cli), "status"],
                                  capture_output=True, text=True, timeout=5, check=True)
        result = json.loads(finished.stdout)
        self.assertEqual(result, status())
        self.assertNotIn("token", finished.stdout.lower())
        self.assertNotIn("password", finished.stdout.lower())

    def test_unknown_profile_schema_denied(self):
        destination = self.folder("Library/Application Support/BIFROST")
        (destination / "storage-profiles.v1.json").write_text('{"schema":"wrong","profiles":[]}')
        with self.assertRaises(StorageDenied):
            profiles(home=self.home)


if __name__ == "__main__":
    unittest.main()
