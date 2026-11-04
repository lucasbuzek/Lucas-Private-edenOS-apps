#!/usr/bin/env python3
"""Owner-invoked, no-admin fresh install. Existing installations are preserved."""
import hashlib
import json
import os
from pathlib import Path
import plistlib
import shutil
import socket
import subprocess
import sys
import time
import urllib.request
import uuid

LABEL = 'eden.bifrost.headless'

def verify(source):
    manifest = json.loads((source / 'INSTALL-MANIFEST.json').read_text())
    if not manifest or not isinstance(manifest, dict):
        raise RuntimeError('Invalid package manifest')
    for name, digest in manifest.items():
        path = source / name
        if Path(name).is_absolute() or '..' in Path(name).parts or path.is_symlink():
            raise RuntimeError('Unsafe package path')
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != digest:
            raise RuntimeError('Package integrity failed: ' + name)
    for path in source.rglob('*'):
        if path.is_symlink():
            raise RuntimeError('Package contains symlink')
    return manifest

def install(source):
    if sys.platform != 'darwin':
        raise RuntimeError('Install on macOS only; no changes made')
    if sys.version_info < (3, 10):
        raise RuntimeError('Python 3.10 or newer is required')
    if os.geteuid() == 0:
        raise RuntimeError('Run as your normal Mac user, without sudo')
    manifest = verify(source)
    home = Path.home()
    support = home / 'Library/Application Support/BIFROST'
    agent = home / 'Library/LaunchAgents' / (LABEL + '.plist')
    target = support / 'HeadlessRuntime'
    if agent.exists() or agent.is_symlink() or target.exists() or target.is_symlink():
        raise RuntimeError('Existing BIFROST installation preserved. Reconcile it before upgrading.')
    domain = 'gui/' + str(os.getuid())
    found = subprocess.run(['/bin/launchctl','print',domain+'/'+LABEL],capture_output=True)
    if found.returncode == 0:
        raise RuntimeError('Existing BIFROST service preserved; no replacement attempted')
    with socket.socket() as sock:
        sock.bind(('127.0.0.1',8798))
    for path in (support, agent.parent):
        for parent in (path, *path.parents):
            if parent.is_symlink():
                raise RuntimeError('Installation path contains a symlink')
    support.mkdir(parents=True, exist_ok=True, mode=0o700)
    agent.parent.mkdir(parents=True, exist_ok=True)
    target.mkdir(mode=0o700)
    written_agent = False
    bootstrapped = False
    try:
        for name in manifest:
            destination = target/name
            destination.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(source/name,destination)
        server = target/'headless/server.py'
        config = {'Label':LABEL,'ProgramArguments':[sys.executable,'-B',str(server)],
                  'RunAtLoad':True,'KeepAlive':False,'WorkingDirectory':str(target),
                  'EnvironmentVariables':{'BIFROST_HEADLESS_PORT':'8798'},
                  'StandardOutPath':str(support/'headless-install.log'),
                  'StandardErrorPath':str(support/'headless-install.log')}
        with agent.open('xb') as stream:
            written_agent = True
            plistlib.dump(config,stream)
        subprocess.run(['/bin/launchctl','bootstrap',domain,str(agent)],check=True)
        bootstrapped = True
        expected = hashlib.sha256(server.read_bytes()).hexdigest()
        runtime = hashlib.sha256(str(server.parent.resolve()).encode()).hexdigest()[:16]
        for _ in range(40):
            try:
                opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
                with opener.open('http://127.0.0.1:8798/api/health',timeout=1) as response:
                    health = json.load(response)
                identity = health.get('identity',{})
                if health.get('ok') and identity.get('sourceSha256') == expected and identity.get('runtimeId') == runtime:
                    print('Installed and verified: http://127.0.0.1:8798')
                    subprocess.run(['/usr/bin/open','http://127.0.0.1:8798'],check=False)
                    return
            except (OSError,ValueError):
                pass
            time.sleep(.25)
        raise RuntimeError('Service identity/health verification failed')
    except BaseException:
        stopped = not bootstrapped
        if bootstrapped:
            result = subprocess.run(['/bin/launchctl','bootout',domain,str(agent)],capture_output=True)
            stopped = result.returncode == 0
        if stopped:
            if written_agent:
                agent.unlink(missing_ok=True)
            # Only the directory created by THIS attempt is moved. No deletion.
            recovery = support / ('HeadlessRuntime.failed-' + uuid.uuid4().hex)
            target.rename(recovery)
            print('Failed runtime preserved at: ' + str(recovery), file=sys.stderr)
        else:
            print('Service stop unverified; runtime and agent retained for manual recovery.',file=sys.stderr)
        raise

if __name__ == '__main__':
    try:
        install(Path(__file__).resolve().parents[1])
    except Exception as error:
        print('Installation stopped: '+str(error),file=sys.stderr)
        sys.exit(1)
