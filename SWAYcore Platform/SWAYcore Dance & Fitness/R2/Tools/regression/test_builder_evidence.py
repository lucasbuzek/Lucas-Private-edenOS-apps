import pathlib,unittest
ROOT=pathlib.Path(__file__).resolve().parents[2]
class BuilderEvidence(unittest.TestCase):
 def test_preservation_does_not_promote_unverified_output(self):
  s=(ROOT/'Scripts/factory_lib.sh').read_text()
  self.assertNotIn('LKG preserved:',s)
  self.assertIn('RecoveryArchive',s)
 def test_asset_builder_runs_complete_suite(self):
  s=(ROOT/'BUILD_ASSETS.command').read_text()
  self.assertIn('discover -s AssetFactory/tests',s)
 def test_portable_verifier_runs_app_function_contracts(self):
  s=(ROOT/'Tools/verify_all.py').read_text()
  self.assertIn('App/Tests/run_contract_tests.py',s)
 def test_negative_fixture_output_is_labelled(self):
  import subprocess,sys
  p=subprocess.run([sys.executable,'-W','ignore','-m','unittest','discover','-s','AssetFactory/tests','-p','test_asset_factory.py'],cwd=ROOT,capture_output=True,text=True)
  self.assertEqual(p.returncode,0,p.stderr)
  self.assertFalse(any(x.startswith('FAIL ') for x in p.stdout.splitlines()),p.stdout)
  self.assertIn('NEGATIVE_FIXTURE',p.stdout)
if __name__=='__main__':unittest.main()
