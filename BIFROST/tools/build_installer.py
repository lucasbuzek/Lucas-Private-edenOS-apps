#!/usr/bin/env python3
"""Verify and build the existing BIFROST installer with one invocation."""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import zipfile
from package_headless import build, ROOT
from install_headless import verify

def main():
    for tool in ('test_portable.py','smoke_pwa.py'):
        subprocess.run([sys.executable,'-B',str(ROOT/'tools'/tool)],cwd=ROOT,check=True)
    output=ROOT.parent/('BIFROSTzeroRAVEN-installer-'+datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')+'.zip')
    build(output)
    with tempfile.TemporaryDirectory(prefix='bifrost-verify-') as temporary:
        with zipfile.ZipFile(output) as archive:
            if archive.testzip() is not None:raise RuntimeError('Archive verification failed')
            archive.extractall(temporary)
        count=len(verify(Path(temporary)/'BIFROST'))
    receipt={'archive':output.name,'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),
             'verifiedFiles':count,'portableChecks':'passed','macOSInstallation':'not-verified',
             'signed':False,'notarized':False}
    output.with_suffix('.receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
    print('Installer ready:',output)
    print('macOS installation still requires device acceptance.')
    if sys.platform=='darwin':subprocess.run(['/usr/bin/open','-R',str(output)],check=False)
if __name__=='__main__':main()
