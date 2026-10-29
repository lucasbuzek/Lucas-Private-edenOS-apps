import importlib.util, pathlib, unittest, json, subprocess, urllib.request
from unittest.mock import patch
root=pathlib.Path(__file__).parent
spec=importlib.util.spec_from_file_location('agent',root/'appleraven_agent.py')
a=importlib.util.module_from_spec(spec);spec.loader.exec_module(a)
class Tests(unittest.TestCase):
 def test_result_budget(self):
  for output in ['x'*10000,'😀'*3000,'"\\\n'*2000,'Normal shortcut']:
   with self.subTest(output=output[:10]),patch.object(a.shutil,'which',return_value='/usr/bin/shortcuts'),patch.object(a.subprocess,'run',return_value=subprocess.CompletedProcess([],0,output,'')):
    result=a.native_shortcuts()
    body=json.dumps({'id':'act_'+'a'*20,'ok':True,'result':result},separators=(',',':')).encode()
    self.assertLessEqual(len(body),2048)
    self.assertTrue(result['ok'])
 def test_redirect_denied(self):
  req=urllib.request.Request(a.ENDPOINT,headers={'Authorization':'Bearer synthetic'})
  for code in [301,302,303,307,308]:
   with self.assertRaises(a.Rejected):a.NoRedirect().redirect_request(req,None,code,'',{},'https://example.org')
 def test_wrong_endpoint(self):
  with self.assertRaises(a.Rejected):a.post('http://example.org','/v1/device/state',{})
 def test_oversize_before_network(self):
  with patch.object(a.urllib.request,'build_opener') as opener:
   with self.assertRaises(a.Rejected):a.post(a.ENDPOINT,'/v1/device/result',{'x':'x'*2048})
   opener.assert_not_called()
 def test_allowlist(self):
  with patch.object(a,'keychain_get',return_value='a'*64),patch.object(a,'post',side_effect=[{}, {'id':'act_'+'a'*20,'capability':'shell'}]),patch.object(a,'native_shortcuts') as native:
   with self.assertRaises(a.Rejected):a.once()
   native.assert_not_called()
 def test_pair_only_mac(self):
  with patch.object(a.platform,'system',return_value='Linux'):
   with self.assertRaises(a.Rejected):a.pair()
 def test_login_registration_requires_pairing(self):
  s=(root/'Install.command').read_text()
  self.assertLess(s.index('"$PYTHON" "$AGENT" --pair'),s.index('if [[ ! -e "$PLIST" ]]'))
 def test_build_preserves_existing_output(self):
  s=(root/'build_macos.sh').read_text()
  self.assertNotIn('rm -rf "$APP"',s)
  self.assertLess(s.index('[[ ! -e "$OUT" ]]'),s.index('mkdir -p "$OUT"'))
 def test_keychain_never_in_subprocess_argv(self):
  import ctypes
  with patch.object(a.platform,'system',return_value='Darwin'), \
       patch.object(ctypes,'CDLL') as lib, \
       patch('getpass.getuser',return_value='owner'), \
       patch.object(a.subprocess,'run') as process:
   lib.return_value.SecKeychainAddGenericPassword.return_value=0
   a.keychain_set('a'*64)
   process.assert_not_called()
   self.assertEqual(lib.return_value.SecKeychainAddGenericPassword.call_count,1)
 def test_keychain_rejects_invalid_credential(self):
  for v in ['not-a-token','A'*64,'a'*63]:
   with self.subTest(token=v):
    with self.assertRaises(a.Rejected): a.keychain_set(v)
 def test_native_install_is_bundled_and_consent_first(self):
  s=(root/'Install-native.command').read_text()
  self.assertIn('AppleRAVEN-Agent',s)
  self.assertNotIn('command -v python3',s)
  self.assertLess(s.index('"$TARGET" --pair'),s.index('/bin/launchctl bootstrap'))
  self.assertIn('[[ "$YES" == y || "$YES" == Y ]]',s)
 def test_frozen_arm64_build_required(self):
  s=(root/'build_macos.sh').read_text()
  self.assertIn('pyinstaller==6.22.3',s)
  self.assertIn('--target-arch arm64',s)
  self.assertIn('Install-native.command',s)
  self.assertIn('lipo -verify_arch arm64',s)
 def test_mac_ci_checks_native_installer(self):
  s=(root.parent.parent/'.github/workflows/appleraven-native-test-dmg.yml').read_text() if (root.parent.parent/'.github/workflows/appleraven-native-test-dmg.yml').exists() else ''
  self.assertIn('Install-native.command --dry-run',s)
if __name__=='__main__':unittest.main()
