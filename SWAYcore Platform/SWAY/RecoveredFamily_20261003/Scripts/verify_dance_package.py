#!/usr/bin/env python3
"""Verify that the packaged Dance app contains the validated character outputs."""
import hashlib
import json
import os
import sys
import zipfile

root, package = sys.argv[1:]
characters = os.path.join(root, "Assets", "Characters")
with zipfile.ZipFile(package) as archive:
    prefix = "SWAYcoreDanceFitness.app/"
    assert prefix + "Info.plist" in archive.namelist(), "app Info.plist missing"
    checked = 0
    for directory, _, files in os.walk(characters):
        for name in files:
            if name.startswith('.'):
                continue
            path = os.path.join(directory, name)
            relative = os.path.relpath(path, characters).replace(os.sep, '/')
            member = prefix + "Characters/" + relative
            assert member in archive.namelist(), "bundled asset missing: " + relative
            with open(path, 'rb') as source:
                expected = hashlib.sha256(source.read()).digest()
            assert hashlib.sha256(archive.read(member)).digest() == expected, "bundled asset differs: " + relative
            checked += 1
    for cid in ('lucia', 'nandi', 'thabo', 'zuri', 'kyle', 'yourdancer'):
        manifest = json.loads(archive.read(prefix + "Characters/" + cid + ".character.json"))
        assert manifest['characterID'] == cid and manifest['contract'] == 'SWAYHumanoid-v2'
        assert manifest['visualQuality'] == 'UNREVIEWED'
        assert prefix + "Characters/" + manifest['asset'] in archive.namelist()
print("PASS: packaged six identities and %d character files match generated assets byte-for-byte; visualQuality=UNREVIEWED" % checked)
