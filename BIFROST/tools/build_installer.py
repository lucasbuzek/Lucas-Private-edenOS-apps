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
from install_headless import verify, validate_install_options, DEFAULT_INSTALL_OPTIONS

def choose_options():
    options = dict(DEFAULT_INSTALL_OPTIONS)
    if sys.stdin.isatty():
        print('BIFROST Headless + Web UI: custom installer builder')
        print('No account registration, data sync, or device pairing is performed.')
        port = input('Local Web UI port [8798]: ').strip()
        if port:
            try:
                options['port'] = int(port)
            except ValueError as exc:
                raise RuntimeError('Port must be a number') from exc
        for key, label in (('startAtLogin','Start BIFROST automatically at login'),
                           ('openDashboard','Open browser after successful installation')):
            default = 'Y/n' if options[key] else 'y/N'
            answer = input(label+' ['+default+']: ').strip().lower()
            if answer not in ('', 'y', 'n', 'yes', 'no'):
                raise RuntimeError('Answer yes or no')
            if answer:
                options[key] = answer in ('y','yes')
    return validate_install_options(options)

def main():
    for tool in ('test_portable.py','smoke_pwa.py'):
        subprocess.run([sys.executable,'-B',str(ROOT/'tools'/tool)],cwd=ROOT,check=True)
    options=choose_options()
    release_dir=Path.home()/'edenOS'/'Releases'
    if any(p.is_symlink() for p in (release_dir,*release_dir.parents)):
        raise RuntimeError('Symlinked release path refused')
    release_dir.mkdir(parents=True,exist_ok=True)
    output=release_dir/('BIFROSTzeroRAVEN-installer-'+datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')+'.zip')
    build(output, install_options=options)
    with tempfile.TemporaryDirectory(prefix='bifrost-verify-') as temporary:
        with zipfile.ZipFile(output) as archive:
            if archive.testzip() is not None:raise RuntimeError('Archive verification failed')
            archive.extractall(temporary)
        count=len(verify(Path(temporary)/'BIFROST'))
    receipt={'archive':output.name,'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),
             'verifiedFiles':count,'portableChecks':'passed','installOptions':options,'macOSInstallation':'not-verified',
             'signed':False,'notarized':False}
    output.with_suffix('.receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
    print('Installer ready:',output)
    print('macOS installation still requires device acceptance.')
    if sys.platform=='darwin':subprocess.run(['/usr/bin/open','-R',str(output)],check=False)
if __name__=='__main__':main()
