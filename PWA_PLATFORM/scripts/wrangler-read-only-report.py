#!/usr/bin/env python3
"""Read-only Cloudflare inventory using an *already authenticated* Mac Wrangler session.

No explicit login, Cloudflare account writes, site creations or deployments.
Credentials stay in memory and are never printed or written to the report.
"""
from __future__ import annotations
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tomllib

SCRIPT = Path(__file__).resolve().with_name('cloudflare-private-preflight.mjs')
HOME = Path.home()
PROFILE = HOME / 'Library/Preferences/.wrangler/config/default.toml'
PATTERN = re.compile(r'\b[a-f0-9]{32}\b')

def main() -> int:
    if sys.platform != 'darwin':
        print('{"status":"BLOCKED_NOT_DEPLOYABLE","reason":"MAC_WRANGLER_PROFILE_UNAVAILABLE"}')
        return 2
    if not PROFILE.is_file():
        print('{"status":"BLOCKED_NOT_DEPLOYABLE","reason":"WRANGLER_OAUTH_PROFILE_UNAVAILABLE"}')
        return 2
    profile = tomllib.loads(PROFILE.read_text())
    token = profile.get('oauth_token')
    if not isinstance(token, str) or len(token) < 12:
        print('{"status":"BLOCKED_NOT_DEPLOYABLE","reason":"WRANGLER_OAUTH_SESSION_INVALID"}')
        return 2
    cli = os.environ.get('WRANGLER_BIN') or shutil.which('wrangler')
    if not cli:
        candidates=sorted((HOME/'.npm/_npx').glob('*/node_modules/.bin/wrangler'))
        if len(candidates) == 1:
            cli = str(candidates[0])
        else:
            print('{"status":"BLOCKED_NOT_DEPLOYABLE","reason":"EXPLICIT_WRANGLER_BIN_REQUIRED"}')
            return 2
    result = subprocess.run(
        [cli, 'whoami'],
        capture_output=True,text=True,timeout=18,
        env={**os.environ,'CI':'true','WRANGLER_SEND_METRICS':'false'},
    )
    ids = set(PATTERN.findall(result.stdout))
    if result.returncode != 0 or len(ids) != 1:
        print('{"status":"BLOCKED_NOT_DEPLOYABLE","reason":"AUTHENTICATED_ACCOUNT_UNVERIFIED"}')
        return 2
    env={**os.environ,'CLOUDFLARE_API_TOKEN':token,
         'CLOUDFLARE_ACCOUNT_ID':next(iter(ids))}
    cli_result=subprocess.run(
        ['node',str(SCRIPT)],
        cwd=str(SCRIPT.parent.parent),env=env,
        capture_output=True,text=True,timeout=35,
    )
    try:
        report=json.loads(cli_result.stdout)
        if report.get('deployAllowed') is not False:
            raise ValueError('Unsafe readiness assertion')
        print(json.dumps(report,indent=2))
    except Exception:
        print('{"status":"BLOCKED_NOT_DEPLOYABLE","reason":"READ_ONLY_REPORT_UNVERIFIED"}')
    return 2

if __name__=='__main__':
    try:raise SystemExit(main())
    except (OSError,TimeoutError,subprocess.TimeoutExpired,ValueError):
        print('{"status":"BLOCKED_NOT_DEPLOYABLE","reason":"READ_ONLY_SESSION_ERROR"}')
        raise SystemExit(2)
