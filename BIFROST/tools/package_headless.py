#!/usr/bin/env python3
"""Package existing source as an unsigned installer candidate; no deployment."""
import hashlib
import json
from pathlib import Path
import sys
import zipfile
ROOT=Path(__file__).resolve().parents[1]
def build(output):
    files={p.relative_to(ROOT).as_posix():p for p in ROOT.rglob('*')
           if p.is_file() and not p.is_symlink() and '__pycache__' not in p.parts
           and p.suffix not in ('.pyc','.zip') and p.name != 'INSTALL-MANIFEST.json'}
    for required in ('headless/server.py','headless/icons/icon-192.png','headless/icons/icon-512.png','Install-BIFROST.command'):
        if required not in files:raise RuntimeError('Missing required asset: '+required)
    manifest={name:hashlib.sha256(path.read_bytes()).hexdigest() for name,path in sorted(files.items())}
    with zipfile.ZipFile(output,'x',zipfile.ZIP_DEFLATED) as archive:
        for name,path in sorted(files.items()):archive.write(path,'BIFROST/'+name)
        archive.writestr('BIFROST/INSTALL-MANIFEST.json',json.dumps(manifest,indent=2)+'\n')
    print(output)
if __name__=='__main__':build(Path(sys.argv[1]))
