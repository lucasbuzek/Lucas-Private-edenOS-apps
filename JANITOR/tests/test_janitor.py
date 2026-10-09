"""Controlled fixtures. No personal-data scans or destructive tests.

The shell library loader redirects literal home references in memory to a
fixture root, without changing HOME or the on-disk product.
"""
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / "core/janitor-macos.sh"


class JanitorTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="janitor-fixture-", dir="/private/tmp")
        self.root = Path(self.tmp.name)
        for p in ["Downloads", "Documents", "Desktop", "Pictures", "Movies", "cache", "reports", "quarantine"]:
            (self.root / p).mkdir()
        source = CORE.read_text().split('\ncase "${1:-}" in')[0]
        source = source.replace('$HOME', '$FIXTURE_ROOT')
        self.library = self.root / "library.sh"
        self.library.write_text(source)
        self.env = dict(os.environ, FIXTURE_ROOT=str(self.root), JANITOR_CACHE_DIR=str(self.root / "cache"),
                        JANITOR_REPORT_DIR=str(self.root / "reports"), JANITOR_QUARANTINE=str(self.root / "quarantine"))

    def tearDown(self):
        self.tmp.cleanup()

    def shell(self, code, input="", timeout=12):
        return subprocess.run(["/bin/bash", "-c", 'source "$1"; ' + code, "test", str(self.library)],
                              env=self.env, input=input, text=True, capture_output=True, timeout=timeout)

    def file(self, name, data=b"fixture contents\n"):
        p = self.root / name
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(data)
        return p

    def test_known_folders_deferred_without_visible_icloud(self):
        for name in ("Documents", "Desktop"):
            r = self.shell('local_scan_guard "$FIXTURE_ROOT/' + name + '"')
            self.assertNotEqual(r.returncode, 0, name + " must remain unknown/provider deferred")

    def test_legacy_provider_root_deferred(self):
        (self.root / "Dropbox").mkdir()
        self.assertNotEqual(self.shell('local_scan_guard "$FIXTURE_ROOT/Dropbox"').returncode, 0)

    def test_photos_symlink_guard(self):
        lib = self.root / "Pictures/Test.photoslibrary"
        lib.mkdir()
        (self.root / "Downloads/library-alias").symlink_to(lib, target_is_directory=True)
        self.assertNotEqual(self.shell('local_scan_guard "$FIXTURE_ROOT/Downloads/library-alias"').returncode, 0)

    def test_parent_escape_refused(self):
        self.assertNotEqual(self.shell('local_scan_guard "$FIXTURE_ROOT/quarantine/../../"').returncode, 0)

    def test_timeout_stops_descendant_work(self):
        r = self.shell('slow(){ /bin/bash -c \'sleep 3; echo escaped > "$FIXTURE_ROOT/escaped"\' & wait; }; '
                       'run_deadline 1 "$CACHE_DIR/out" "$CACHE_DIR/err" slow; echo "RC=$?"', timeout=8)
        self.assertIn("RC=124", r.stdout)
        time.sleep(3)
        self.assertFalse((self.root / "escaped").exists(), "timed-out descendant still ran")

    def test_outer_timeout_also_stops_nested_deadline_worker(self):
        r = self.shell('outer(){ run_deadline 10 "$CACHE_DIR/nested-out" "$CACHE_DIR/nested-err" /bin/bash -c \'sleep 3; echo escaped > "$FIXTURE_ROOT/nested-escaped"\'; }; '
                       'run_deadline 1 "$CACHE_DIR/out" "$CACHE_DIR/err" outer; echo "RC=$?"', timeout=8)
        self.assertIn("RC=124", r.stdout)
        time.sleep(3)
        self.assertFalse((self.root / "nested-escaped").exists(), "nested deadline escaped its parent budget")

    def test_missing_size_is_partial_not_zero(self):
        r = self.shell('scan_path "missing" "$FIXTURE_ROOT/Downloads/missing"')
        self.assertNotIn("0 KB", r.stdout)

    def test_file_size_uses_allocated_blocks(self):
        self.file("Downloads/sparse")
        with (self.root / "Downloads/sparse").open("r+b") as f:
            f.truncate(1024 * 1024 * 1024)
        r = self.shell('bounded_size_kb "$FIXTURE_ROOT/Downloads" 3')
        self.assertEqual(r.returncode, 0)
        self.assertLess(int(r.stdout.strip()), 1024, "sparse apparent length advertised as reclaimable storage")

    def test_provider_descendant_pruned_from_duplicates(self):
        self.file("Downloads/a", b"duplicate")
        self.file("Downloads/b", b"duplicate")
        self.file("Downloads/CloudStorage/Provider/private", b"duplicate")
        r = self.shell('exact_duplicates_path "$FIXTURE_ROOT/Downloads"')
        self.assertIn("/Downloads/a", r.stdout)
        self.assertIn("/Downloads/b", r.stdout)
        self.assertNotIn("/Provider/private", r.stdout)

    def test_manual_quarantine_collision_keeps_both_manifests(self):
        self.file("Downloads/one")
        self.file("Downloads/two")
        r = self.shell('now(){ echo fixed; }; quarantine_path "$FIXTURE_ROOT/Downloads/one"; quarantine_path "$FIXTURE_ROOT/Downloads/two"')
        self.assertEqual(r.returncode, 0, r.stderr)
        manifests = list((self.root / "quarantine").glob("*/MANIFEST.txt"))
        self.assertEqual(len(manifests), 2, "second action overwrote recovery evidence")

    def test_manifest_cannot_restore_unrelated_file(self):
        victim = self.file("Downloads/ordinary")
        m = self.file("quarantine/session/MANIFEST.txt",
                      f"Original: {self.root}/Downloads/stolen\nQuarantined: {victim}\n".encode())
        r = self.shell("recover_manifest " + shlex.quote(str(m)))
        self.assertNotEqual(r.returncode, 0)
        self.assertTrue(victim.exists())

    def test_missing_manual_quarantine_is_tolerated(self):
        m = self.file("quarantine/session/MANIFEST.txt",
                      f"Original: {self.root}/Downloads/old\nQuarantined: {self.root}/quarantine/session/items/old\n".encode())
        r = self.shell("recover_manifest " + shlex.quote(str(m)))
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn("Missing", r.stdout)

    def test_manual_quarantine_restore_round_trip(self):
        original = self.file("Downloads/round-trip", b"important local data")
        r = self.shell('quarantine_path "$FIXTURE_ROOT/Downloads/round-trip"; m=$(quarantine_manifests); recover_manifest "$m"')
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertEqual(original.read_bytes(), b"important local data")

    def test_git_worktree_not_intermediate_cleanup_candidate(self):
        for n in (1, 2, 3):
            self.file(f"Downloads/Fixture_BUILD{n}/data")
        self.file("Downloads/Fixture_BUILD2/.git", b"gitdir: elsewhere\n")
        r = self.shell('dev_build_inventory "$CACHE_DIR/builds"; cat "$CACHE_DIR/builds"')
        line = next(l for l in r.stdout.splitlines() if "Fixture_BUILD2" in l)
        self.assertEqual(line.split("\t")[3], "1", "Git .git-file worktree not protected")

    def test_menu_exits_on_eof(self):
        try:
            r = self.shell("menu", timeout=3)
        except subprocess.TimeoutExpired:
            self.fail("menu loops forever after closed stdin")
        self.assertEqual(r.returncode, 0)

    def test_scope_prompt_does_not_pollute_selected_path(self):
        r = self.shell('p=$(choose_scope); printf "SELECTED=%s\\n" "$p"', input=str(self.root / "Downloads") + "\n")
        self.assertEqual(r.stdout.strip(), "SELECTED=" + str(self.root / "Downloads"))

    def test_photos_metadata_footprint_is_not_zero(self):
        self.file("Pictures/Test.photoslibrary/originals/photo", b"x" * 8192)
        r = self.shell('photos_analyze_library "$FIXTURE_ROOT/Pictures/Test.photoslibrary"')
        self.assertNotIn("0 KB", r.stdout)
        self.assertRegex(r.stdout, r"Filesystem footprint:\s+[1-9][0-9]* KB")

    def test_quarantine_refuses_nested_provider_boundary(self):
        src = self.file("Downloads/local-container/CloudStorage/Provider/data")
        r = self.shell('quarantine_path "$FIXTURE_ROOT/Downloads/local-container"')
        self.assertNotEqual(r.returncode, 0)
        self.assertTrue(src.exists())

    def test_manifest_original_cannot_be_protected_system_path(self):
        q = self.file("quarantine/session/items/file")
        m = self.file("quarantine/session/MANIFEST.txt", f"Original: /bin/JANITOR_TEST_NEVER_WRITE\nQuarantined: {q}\n".encode())
        r = self.shell("recover_manifest " + shlex.quote(str(m)))
        self.assertNotEqual(r.returncode, 0)
        self.assertTrue(q.exists())

    def test_quick_full_developer_workflows_remain_separate(self):
        self.file("Library/Caches/pip/cache", b"cache" * 2048)
        self.file("Downloads/Fixture_BUILD1/data")
        self.file("Downloads/Fixture_BUILD2/data")
        self.file("Downloads/Fixture_BUILD3/data")
        for code, key, choice in (("quick_scan", "QUICK SCAN", "q\n"),
                                  ("full_scan", "FULL SCAN", "b\n"),
                                  ("developer_quick_scan", "DEVELOPER QUICK SCAN", "b\n")):
            started = time.monotonic()
            r = self.shell(code, input=choice, timeout=25)
            self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
            self.assertIn(key, r.stdout)
            self.assertLess(time.monotonic() - started, 20)
        self.assertTrue((self.root / "Downloads/Fixture_BUILD2/data").exists())

    def test_developer_quarantine_preserves_first_latest(self):
        for n in (1, 2, 3):
            self.file(f"Downloads/Fixture_BUILD{n}/data", f"build{n}".encode())
        r = self.shell("developer_quick_scan", input="q\ny\n\n", timeout=25)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertTrue((self.root / "Downloads/Fixture_BUILD1/data").exists())
        self.assertFalse((self.root / "Downloads/Fixture_BUILD2").exists())
        self.assertTrue((self.root / "Downloads/Fixture_BUILD3/data").exists())
        m = next((self.root / "quarantine").glob("*/MANIFEST.txt"))
        r = self.shell("recover_manifest " + shlex.quote(str(m)))
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertEqual((self.root / "Downloads/Fixture_BUILD2/data").read_bytes(), b"build2")

    def test_safe_clean_and_cache_delete_are_reviewed_and_recorded(self):
        item = self.file("Library/Caches/pip/cache", b"cache" * 2048)
        r = self.shell("safe_clean_general", input="q\ny\n\n", timeout=25)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertFalse(item.exists())
        m = next((self.root / "quarantine").glob("*/MANIFEST.txt"))
        r = self.shell("recover_manifest " + shlex.quote(str(m)))
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertTrue(item.exists())
        r = self.shell('kb=$(quick_safe_inventory "$CACHE_DIR/inv"); quick_delete_safe "$CACHE_DIR/inv" "$kb"', input="y\n", timeout=25)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertFalse(item.exists())
        self.assertIn("DELETE_RESULT\t0", (self.root / "reports/actions.tsv").read_text())

    def test_deep_project_discovery_is_depth_bounded(self):
        self.file("Downloads/Project/Package.swift")
        self.file("Downloads/" + "nested/" * 8 + "package.json")
        self.file("Documents/CloudProject/Package.swift")
        r = self.shell("project_discovery", input="\n", timeout=20)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        data = (self.root / "cache/last-project-discovery.tsv").read_text()
        self.assertIn("/Downloads/Project", data)
        self.assertNotIn("nested", data)
        self.assertNotIn("CloudProject", data)

    def test_media_similar_names_and_broken_links_are_read_only(self):
        self.file("Downloads/photo copy.jpg", b"same local media")
        self.file("Downloads/photo final.jpg", b"same local media")
        (self.root / "Downloads/broken-link").symlink_to(self.root / "missing")
        for code in ("media_inventory", "similar_names"):
            r = self.shell(code, input=str(self.root / "Downloads") + "\n\n", timeout=15)
            self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
            self.assertIn("photo", r.stdout)
        r = self.shell("broken_items", input="\n", timeout=15)
        self.assertIn("broken-link", r.stdout)
        self.assertEqual(len(list((self.root / "Downloads").iterdir())), 3)

    def test_top_level_modes_and_protected_process_group(self):
        r = self.shell("menu", input="x\n")
        for mode in ("STANDARD", "DEVELOPER", "MEDIA", "FULL CREW", "QUARANTINE / RECOVERY"):
            self.assertIn(mode, r.stdout)
        r = self.shell("running_processes", input="\n")
        for mode in ("INSTALLED APPS", "USER / DEVELOPMENT", "macOS / APPLE SYSTEM", "UNKNOWN / REVIEW", "COLLAPSED / PROTECTED / READ-ONLY"):
            self.assertIn(mode, r.stdout)

    def test_permission_error_is_partial(self):
        p = self.root / "Downloads/denied"
        p.mkdir()
        self.file("Downloads/denied/file")
        p.chmod(0)
        try:
            r = self.shell('scan_summary "$FIXTURE_ROOT/Downloads"', timeout=15)
            self.assertIn("PARTIAL", r.stdout)
        finally:
            p.chmod(0o700)

    def test_invalid_timeout_fails_promptly(self):
        r = self.shell('run_deadline nonsense "$CACHE_DIR/out" "$CACHE_DIR/err" sleep 30')
        self.assertNotEqual(r.returncode, 0)

    def test_provider_cloud_actions_remain_deferred(self):
        src = self.file("Downloads/CloudStorage/Provider/cloud-file")
        r = self.shell('cloud_move_same_provider "$FIXTURE_ROOT/Downloads/CloudStorage/Provider/cloud-file" quarantine')
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("DEFERRED TO NATIVE", r.stderr)
        self.assertTrue(src.exists())

    def test_process_inspection_failure_is_not_empty_success(self):
        r = self.shell('ps(){ return 1; }; running_processes', input="\n")
        self.assertIn("PARTIAL", r.stdout)

    def test_quarantine_session_delete_refuses_boundary_tree(self):
        src = self.file("quarantine/session/CloudStorage/Provider/data")
        r = self.shell('recover_menu', input="d\n" + str(self.root / "quarantine/session") + "\nDELETE\n\n")
        self.assertTrue(src.exists(), "session delete recursively entered provider boundary")

    def test_build_dependency_discovery_executes_on_empty_and_populated_scope(self):
        self.file("Downloads/Project/node_modules/pkg/index.js")
        r = self.shell("large_dev", input="\n", timeout=15)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn("node_modules", r.stdout)

    def test_startup_inventory_groups_by_declared_executable(self):
        import plistlib
        executables = ["/System/Library/Fixture", "/Applications/Fixture.app/Contents/MacOS/Fixture",
                       "/opt/homebrew/bin/fixture", "/unknown/fixture"]
        for n, exe in enumerate(executables):
            self.file(f"Library/LaunchAgents/fixture-{n}.plist", plistlib.dumps({"ProgramArguments": [exe]}))
        r = self.shell("background_items", input="\n")
        for group in ("INSTALLED APPS", "USER / DEVELOPMENT", "macOS / APPLE SYSTEM", "UNKNOWN / REVIEW"):
            self.assertIn(group, r.stdout)
        self.assertIn(executables[1], r.stdout)
        self.assertNotIn(executables[0], r.stdout, "Apple jobs must remain collapsed")


if __name__ == "__main__":
    unittest.main(verbosity=2)
