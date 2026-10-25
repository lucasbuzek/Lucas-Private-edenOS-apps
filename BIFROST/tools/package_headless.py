#!/usr/bin/env python3
"""Package existing source as an unsigned installer candidate; no deployment."""
import hashlib
import json
from pathlib import Path
import sys
import zipfile
ROOT=Path(__file__).resolve().parents[1]
def build(output, install_options=None):
    # Package only headless runtime components, not the entire development
    # tree: unrelated private documents, backups and account state must never
    # be turned into an installable archive.
    RUNTIME_TOP = {'headless', 'core', 'tools', 'bifrost', 'web'}
    ROOT_ASSETS = {'Install-BIFROST.command', 'Build-Installer.command',
                   'INSTALL-README.md', 'BIFROST-Info.plist'}
    SUFFIXES = {'.py', '.js', '.mjs', '.css', '.html', '.json', '.md',
                '.txt', '.plist', '.png', '.svg', '.webmanifest',
                '.sh', '.command', '.ico', '.woff', '.woff2'}
    BLOCKED_DIRS = {'.git', '.venv', '__pycache__', 'node_modules',
                    'backups', 'backup', 'secrets', 'credentials', 'sessions',
                    'tokens', 'user-data', 'cache', 'logs', 'temporary', 'tmp',
                    'incoming', 'deriveddata', 'downloads', 'private', 'vault'}
    BLOCKED_FILES = {'.env', '.env.local', 'id_rsa', 'id_ed25519',
                     'oauth_token.json', 'access_token.json', 'refresh_token.json',
                     'rclone.conf', 'device.json', 'headless.token',
                     'storage-profiles.v1.json'}
    files = {}
    for p in ROOT.rglob('*'):
        if p.is_symlink() or not p.is_file():
            continue
        relative = p.relative_to(ROOT)
        if any(part.lower() in BLOCKED_DIRS or part.startswith('.')
               for part in relative.parts):
            continue
        if p.name.lower() in BLOCKED_FILES or p.suffix.lower() in {'.key', '.pem', '.p12', '.p8', '.db', '.sqlite', '.sqlite3'}:
            continue
        if len(relative.parts) == 1:
            if p.name not in ROOT_ASSETS:
                continue
        elif relative.parts[0] not in RUNTIME_TOP:
            continue
        if p.suffix.lower() not in SUFFIXES or p.name == 'INSTALL-MANIFEST.json':
            continue
        if p.stat().st_size > 5 * 1024 * 1024:
            continue
        files[relative.as_posix()] = p
    for required in ('headless/server.py','headless/icons/icon-192.png','headless/icons/icon-512.png','Install-BIFROST.command'):
        if required not in files:raise RuntimeError('Missing required asset: '+required)
    manifest={name:hashlib.sha256(path.read_bytes()).hexdigest() for name,path in sorted(files.items())}
    options_blob = None
    if install_options is not None:
        options_blob = (json.dumps(install_options, sort_keys=True, indent=2)+'\n').encode('utf-8')
        manifest['INSTALL-OPTIONS.json'] = hashlib.sha256(options_blob).hexdigest()
    with zipfile.ZipFile(output,'x',zipfile.ZIP_DEFLATED) as archive:
        for name,path in sorted(files.items()):archive.write(path,'BIFROST/'+name)
        if options_blob is not None:
            archive.writestr('BIFROST/INSTALL-OPTIONS.json',options_blob)
        archive.writestr('BIFROST/INSTALL-MANIFEST.json',json.dumps(manifest,indent=2)+'\n')
    print(output)
if __name__=='__main__':build(Path(sys.argv[1]))
