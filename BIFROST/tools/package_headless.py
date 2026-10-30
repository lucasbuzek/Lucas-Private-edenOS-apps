#!/usr/bin/env python3
"""Package existing source as an unsigned installer candidate; no deployment."""
import hashlib
import json
from pathlib import Path
import sys
import zipfile
ROOT=Path(__file__).resolve().parents[1]
def build(output):
    names=json.loads((ROOT/'PACKAGE-FILES.json').read_text())
    if not isinstance(names,list) or len(names)!=len(set(names)):
        raise RuntimeError('Invalid package inclusion list')
    files={}
    for name in names:
        path=ROOT/name
        if Path(name).is_absolute() or '..' in Path(name).parts or not name:
            raise RuntimeError('Unsafe package inclusion')
        if any(part.startswith('.') for part in Path(name).parts):
            raise RuntimeError('Hidden files cannot be packaged')
        if any(parent.is_symlink() for parent in (path,*path.parents)):
            raise RuntimeError('Symlink in package inclusion')
        if not path.is_file():raise RuntimeError('Missing package file: '+name)
        files[name]=path
    for required in ('headless/server.py','headless/icons/icon-192.png','headless/icons/icon-512.png','Install-BIFROST.command'):
        if required not in files:raise RuntimeError('Missing required asset: '+required)
    manifest={name:hashlib.sha256(path.read_bytes()).hexdigest() for name,path in sorted(files.items())}
    with zipfile.ZipFile(output,'x',zipfile.ZIP_DEFLATED) as archive:
        for name,path in sorted(files.items()):archive.write(path,'BIFROST/'+name)
        archive.writestr('BIFROST/INSTALL-MANIFEST.json',json.dumps(manifest,indent=2)+'\n')
    print(output)
if __name__=='__main__':build(Path(sys.argv[1]))
