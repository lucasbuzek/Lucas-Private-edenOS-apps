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
if __name__=='__main__':unittest.main()
