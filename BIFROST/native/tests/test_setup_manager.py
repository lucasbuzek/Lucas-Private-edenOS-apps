"""BIFROST setup discovery and safe import regression tests.

Never executes any of the source archives' installers.
"""
import importlib.util
import io
import pathlib
import tempfile
import unittest
import zipfile

SRC = pathlib.Path(__file__).resolve().parents[1] / "headless" / "setup_manager.py"
spec = importlib.util.spec_from_file_location("bifrost_setup_manager", SRC)
setup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup)


def build_zip(path, kind, traversal=False):
    with zipfile.ZipFile(path, "w") as out:
        root = "" if kind == "ai-toolkit" else "Universal Project Workspace/"
        required = ("installer.py", "catalog_metadata.json", "index.html") if kind == "ai-toolkit" else (
            "project.json", "update_index.py", "index.html"
        )
        for name in required:
            out.writestr(root + name, "read-only fixture")
        if traversal:
            out.writestr("../escape.txt", "unsafe")


class PackageTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="bifrost-setup-tests-")
        self.temp_root = pathlib.Path(self.temp.name)
        dl = self.temp_root / "Downloads"
        dl.mkdir()
        self.originals = setup.DOWNLOADS, setup.SUPPORT, setup.STAGED
        setup.DOWNLOADS = dl
        setup.SUPPORT = self.temp_root / "Private Support"
        setup.STAGED = setup.SUPPORT / "Setup Packages"

    def tearDown(self):
        setup.DOWNLOADS, setup.SUPPORT, setup.STAGED = self.originals
        self.temp.cleanup()

    def test_catalog_does_not_claim_installed(self):
        build_zip(setup.DOWNLOADS / "Universal_AI_Toolkit_Final.zip", "ai-toolkit")
        build_zip(setup.DOWNLOADS / "Universal_Project_Workspace_v0.2.zip", "project-workspace")
        catalog = setup.catalog()
        self.assertFalse(catalog["executionsEnabled"])
        self.assertEqual([x["status"] for x in catalog["packages"]], ["available", "available"])
        self.assertTrue(all(x["installation"] == "not-verified" for x in catalog["packages"]))

    def test_stage_only_extracts_reviewable_files(self):
        zip_path = setup.DOWNLOADS / "Universal_AI_Toolkit_Final.zip"
        build_zip(zip_path, "ai-toolkit")
        staged = setup.stage_package("ai-toolkit")
        self.assertEqual(staged["status"], "staged")
        script = setup.STAGED / "ai-toolkit" / "installer.py"
        self.assertTrue(script.is_file())
        self.assertEqual(script.stat().st_mode & 0o111, 0)
        self.assertTrue(zip_path.is_file())
        self.assertTrue(setup.stage_package("ai-toolkit")["already_present"])

    def test_workspace_top_directory_is_flattened(self):
        build_zip(setup.DOWNLOADS / "Universal_Project_Workspace_v0.2.zip", "project-workspace")
        setup.stage_package("project-workspace")
        self.assertTrue((setup.STAGED / "project-workspace" / "project.json").is_file())

    def test_traversal_rejected(self):
        build_zip(setup.DOWNLOADS / "Universal_AI_Toolkit_Final.zip", "ai-toolkit", traversal=True)
        with self.assertRaises(setup.SetupError):
            setup.stage_package("ai-toolkit")
        self.assertFalse((self.temp_root / "escape.txt").exists())

    def test_reject_wrong_package_type(self):
        build_zip(setup.DOWNLOADS / "Universal_AI_Toolkit_Final.zip", "project-workspace")
        with self.assertRaises(setup.SetupError):
            setup.stage_package("ai-toolkit")

    def test_unknown_id_rejected(self):
        with self.assertRaises(setup.SetupError):
            setup.stage_package("../unknown")

    def test_missing_import_does_not_claim_stage_is_current(self):
        original = setup.DOWNLOADS / "Universal_AI_Toolkit_Final.zip"
        build_zip(original, "ai-toolkit")
        setup.stage_package("ai-toolkit")
        original.unlink()
        record = next(p for p in setup.catalog()["packages"] if p["id"] == "ai-toolkit")
        self.assertEqual(record["status"], "review-required")
        self.assertTrue(record["staged"])
        self.assertFalse(record["available"])

    def test_changed_archive_does_not_replace_stage(self):
        zip_path = setup.DOWNLOADS / "Universal_AI_Toolkit_Final.zip"
        build_zip(zip_path, "ai-toolkit")
        setup.stage_package("ai-toolkit")
        with zipfile.ZipFile(zip_path, "a") as archive:
            archive.writestr("different.txt", "new version")
        with self.assertRaises(setup.SetupError):
            setup.stage_package("ai-toolkit")


if __name__ == "__main__":
    unittest.main()
