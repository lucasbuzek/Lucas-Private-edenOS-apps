import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest import mock
ROOT=Path(__file__).resolve().parents[1]
def load(name):
 s=importlib.util.spec_from_file_location(name,ROOT/'tools'/(name+'.py'));m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
class RegressionTests(unittest.TestCase):
 def test_package_inclusion_excludes_unrelated_files(self):
  import zipfile
  m=load('package_headless')
  with tempfile.TemporaryDirectory() as temp:
   root=Path(temp)/'source';root.mkdir()
   names=['headless/server.py','headless/icons/icon-192.png','headless/icons/icon-512.png','Install-BIFROST.command']
   for name in names+['.env','notes.txt']:
    p=root/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text('fixture')
   (root/'PACKAGE-FILES.json').write_text(json.dumps(names))
   with mock.patch.object(m,'ROOT',root):m.build(Path(temp)/'out.zip')
   with zipfile.ZipFile(Path(temp)/'out.zip') as z:
    self.assertNotIn('BIFROST/.env',z.namelist());self.assertNotIn('BIFROST/notes.txt',z.namelist())
 def test_copy_failure_preserved_and_retry_not_blocked(self):
  m=load('install_headless')
  with tempfile.TemporaryDirectory() as temp:
   home=Path(temp)
   with mock.patch.object(m.sys,'platform','darwin'),mock.patch.object(m.os,'geteuid',return_value=501),mock.patch.object(m.Path,'home',return_value=home),mock.patch.object(m,'verify',return_value={'file':'hash'}),mock.patch.object(m.subprocess,'run',return_value=mock.Mock(returncode=1)),mock.patch.object(m.socket,'socket'),mock.patch.object(m.shutil,'copy2',side_effect=OSError('copy failed')):
    for _ in range(2):
     with self.assertRaisesRegex(OSError,'copy failed'):m.install(home)
   support=home/'Library/Application Support/BIFROST'
   self.assertFalse((support/'HeadlessRuntime').exists())
   self.assertEqual(len(list(support.glob('HeadlessRuntime.failed-*'))),2)
 def test_launcher_preserves_nonzero_exit(self):
  with tempfile.TemporaryDirectory() as temp:
   root=Path(temp);fake=root/'python';fake.write_text('#!/bin/sh\n[ "$1" = "-c" ] && exit 0\nexit 7\n');fake.chmod(0o755)
   text=(ROOT/'Install-BIFROST.command').read_text().replace('/opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3',str(fake))
   script=root/'Install.command';script.write_text(text)
   result=subprocess.run(['bash',str(script)],input='',text=True,capture_output=True)
   self.assertEqual(result.returncode,7);self.assertIn('Installation failed',result.stdout)
