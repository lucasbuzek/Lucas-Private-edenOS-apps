import pathlib,subprocess,unittest
ROOT=pathlib.Path(__file__).resolve().parents[2]
class AlphaAssetScope(unittest.TestCase):
 def pairs(self,mode):
  p=subprocess.run(['bash','-c','source Scripts/factory_lib.sh; asset_pairs "$1"','test',mode],cwd=ROOT,capture_output=True,text=True)
  self.assertEqual(p.returncode,0,p.stderr)
  return p.stdout.split()
 def test_alpha_requires_only_lucia_and_yourdancer(self):
  self.assertEqual(self.pairs('alpha'),['lucia:Lucia','yourdancer:YourDancer'])
 def test_beta_architecture_remains_available_by_explicit_option(self):
  self.assertEqual(len(self.pairs('all')),6)
  self.assertIn('nandi:Nandi',self.pairs('all'))
if __name__=='__main__':unittest.main()
