#!/usr/bin/env python3
"""Typecheck actual resource lookup and RealityKit renderer; never claims playback."""
import hashlib
import json
import pathlib
import subprocess
import tempfile
root = pathlib.Path(__file__).resolve().parents[2]
path = root / 'App/SWAY/Avatar/SWAYAvatarRendering.swift'
source = path.read_text()
renderer = source[:source.index('// Production-stage view.')]
sdk = subprocess.check_output(['xcrun', '--sdk', 'iphoneos', '--show-sdk-path'], text=True).strip()
with tempfile.TemporaryDirectory(prefix='sway-avatar-sdk-', dir='/private/tmp') as directory:
    temporary = pathlib.Path(directory)
    options = ['-target', 'arm64-apple-ios26.0', '-sdk', sdk, '-module-cache-path', str(temporary / 'cache')]
    sources = sorted((root / 'Packages/SWAYcoreEngine/Sources/SWAYcoreEngine').glob('*.swift'))
    subprocess.run(['xcrun', 'swiftc', '-emit-module', '-module-name', 'SWAYcoreEngine', *options,
                    *map(str, sources), '-emit-module-path', str(temporary / 'SWAYcoreEngine.swiftmodule')], check=True)
    extracted = temporary / 'Renderer.swift'
    extracted.write_text(renderer)
    subprocess.run(['xcrun', 'swiftc', '-typecheck', *options, '-I', str(temporary), str(extracted)], check=True)
print(json.dumps({'status': 'SDK_TYPECHECK_PASS', 'sdk': sdk, 'sourceSHA256': hashlib.sha256(path.read_bytes()).hexdigest(),
                  'realityKitPlayback': 'UNKNOWN', 'wholeAppBuild': 'UNKNOWN'}))
