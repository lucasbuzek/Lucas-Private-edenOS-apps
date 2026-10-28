#!/usr/bin/env python3
"""Owner-private AppleRAVEN Mac agent candidate. Only an allowlisted native read.

Based on the existing owner-owned Raven outbound poll/claim pattern; intentionally
independent of BIFROST source/runtime. No listening port, generic shell, or
screen/Photos/Messages/credentials tool.

Requires the dedicated AppleRAVEN device backend to support /v1/{pair,start,
status,state,next,result}. The currently deployed owner-only Worker does NOT.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
import platform
import secrets
import shutil
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

SERVICE = 'com.lucasbuzek.appleraven.device'
ENDPOINT = 'https://appleraven-device.lucasravensnest.workers.dev'
MAX_REPLY = 8192

class Rejected(Exception):
    pass

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise Rejected('AppleRAVEN service redirect refused')

def post(endpoint, path, payload, token=None, timeout=15):
    if endpoint != ENDPOINT:
        raise Rejected('Only the pinned AppleRAVEN HTTPS service origin is permitted')
    body = json.dumps(payload, separators=(',', ':')).encode()
    if len(body) > 2048:
        raise Rejected('Request exceeds device service limit')
    headers = {'Content-Type': 'application/json', 'User-Agent': 'AppleRAVEN-Mac/0.1-candidate'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    req = urllib.request.Request(endpoint + path, data=body, headers=headers, method='POST')
    try:
        with urllib.request.build_opener(NoRedirect()).open(req, timeout=timeout) as r:
            if r.status == 204:
                return {}
            raw = r.read(MAX_REPLY+1)
            if len(raw) > MAX_REPLY:
                raise Rejected('Backend response too large')
            return json.loads(raw)
    except urllib.error.HTTPError as ex:
        raise Rejected('AppleRAVEN service HTTP ' + str(ex.code)) from None

def keychain_get():
    r = subprocess.run(['/usr/bin/security','find-generic-password','-s',SERVICE,'-w'], capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else None

def keychain_set(token):
    if not isinstance(token,str) or len(token) != 64 or any(c not in '0123456789abcdef' for c in token):
        raise Rejected('Invalid device token format; refusing to store')
    # security(1) receives the credential in argv (the original Raven bridge also
    # does this). Keep it out of logs and revoke if local process exposure matters.
    import getpass
    subprocess.run(['/usr/bin/security','add-generic-password','-U','-s',SERVICE,
      '-a',getpass.getuser(),'-l','AppleRAVEN device credential','-w',token],
      stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,check=True)

def native_shortcuts():
    if not shutil.which('shortcuts'):
        return {'ok': False, 'error': 'macOS Shortcuts CLI unavailable'}
    try:
        r = subprocess.run(['shortcuts','list'], capture_output=True, text=True, timeout=20, check=False)
        # Bound JSON-escaped bytes, including non-ASCII names, below the
        # deployed 2048-byte request envelope. Preserve complete characters.
        output = (r.stdout if r.returncode==0 else r.stderr).strip()[:2800]
        truncated = False
        while len(json.dumps(output).encode()) > 1500:
            output = output[:-1]
            truncated = True
        return {'ok': r.returncode==0, 'shortcuts': output if r.returncode==0 else '', 'truncated': truncated or len(r.stdout.strip()) > 2800, 'error': '' if r.returncode==0 else 'Shortcuts command failed'}
    except (subprocess.TimeoutExpired, OSError):
        return {'ok': False, 'error': 'Shortcuts listing timed out or is unavailable'}

def pair(endpoint):
    if platform.system() != 'Darwin':
        raise Rejected('Pairing must be performed on macOS')
    if keychain_get():
        raise Rejected('A credential already exists. Do not silently replace it; use --status.')
    client_secret = secrets.token_hex(32)
    data = post(endpoint,'/v1/pair/start',{'device_name':socket.gethostname()[:64],'challenge':hashlib.sha256(client_secret.encode()).hexdigest()})
    request_id = data.get('request_id')
    code = data.get('code')
    if not isinstance(request_id,str) or not isinstance(code,str):
        raise Rejected('Pairing not available: backend did not return a valid challenge')
    print('Open this owner-only page: https://appleraven-private.lucasravensnest.workers.dev/pair')
    print('Enter this code: '+code)
    print('Authenticate with your existing Cloudflare Access owner email. Do not enter a password into this script.')
    deadline = time.monotonic()+600
    while time.monotonic()<deadline:
        time.sleep(5)
        value = post(endpoint,'/v1/pair/status',{'request_id':request_id,'client_secret':client_secret})
        if value.get('status') == 'pending':
            continue
        if value.get('status') == 'approved' and value.get('device_token'):
            keychain_set(value['device_token'])
            print('Pairing approved. Credential saved to macOS Keychain.')
            return True
        if value.get('status') in ('expired','rejected','revoked'):
            raise Rejected('Pairing '+value['status'])
    raise Rejected('Pairing expired after ten minutes; restart pairing.')

def once(endpoint):
    token = keychain_get()
    if not token:
        raise Rejected('Mac not paired: run --pair first')
    hello = post(endpoint,'/v1/device/state',{
        'hostname':socket.gethostname()[:64],
        'os':platform.mac_ver()[0], 'model':'MacBook Air',
        'capabilities':['shortcuts.list'], 'agent':'0.1-candidate'
        },token)
    task = post(endpoint,'/v1/device/next',{},token)
    if isinstance(task,dict) and task.get('capability') == 'shortcuts.list' and isinstance(task.get('id'),str):
        result = native_shortcuts()
        post(endpoint,'/v1/device/result',{'id':task['id'],'ok':result['ok'],'result':result},token)
    elif isinstance(task,dict) and task.get('capability'):
        raise Rejected('Refusing an action outside the allowlist')
    return hello

def main():
    a = argparse.ArgumentParser(description='AppleRAVEN device candidate (owner-only)')
    a.add_argument('--pair',action='store_true')
    a.add_argument('--once',action='store_true')
    a.add_argument('--status',action='store_true')
    a.add_argument('--endpoint',default=ENDPOINT)
    args=a.parse_args()
    if args.status:
        print(json.dumps({'macos':platform.mac_ver()[0], 'node':socket.gethostname(),
          'device_credential_present':bool(keychain_get()),'endpoint':args.endpoint},indent=2))
        return
    if args.pair:
        pair(args.endpoint)
        return
    if args.once:
        once(args.endpoint)
        print('Read-only device poll complete')
        return
    while True:
        try:
            once(args.endpoint)
        except (Rejected,urllib.error.URLError,OSError) as e:
            print('AppleRAVEN: '+str(e),file=sys.stderr)
        time.sleep(15)

if __name__=='__main__':
    try:
        main()
    except (Rejected,urllib.error.URLError,OSError) as e:
        print('AppleRAVEN: '+str(e),file=sys.stderr)
        sys.exit(1)
