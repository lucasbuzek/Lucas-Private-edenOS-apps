#!/usr/bin/env python3
"""BIFROSTcore ZERO: test one existing BIFROST account workflow on macOS.

Internal experimental BIFROST capability. Not a separate product, daemon,
credential broker, sign-up bot or substitute for the existing BIFROSTcore CLI.
Uses the existing headless/core_runtime.py and tools/bifrost_rdc_account.py.
Only local, non-secret journey metadata is persisted, with explicit consent.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parents[1]
CORE = HERE / 'headless' / 'core_runtime.py'
RDC = HERE / 'tools' / 'bifrost_rdc_account.py'
NETWORK = HERE / 'tools' / 'bifrost_network_resilience.py'
LABEL = 'bifrostLucasTest1'
SCHEMA = 'bifrost.core.zero.journey.v1'
CAPABILITIES = {
    'apple-guide': 'Open Apple-managed Hide My Email interface in Safari',
    'vendor-guide': 'Open official RDC registration in Safari',
    'rdc-observe': 'Inspect local RDC profile metadata only',
    'rdc-pair': 'Start the existing RDC vendor device-code authorization',
    'shortcuts': 'Inspect local Apple Shortcuts names or open its editor',
    'settings': 'Open Apple-managed macOS System Settings',
    'network-watch': 'Owner-selected bounded network monitoring; no automatic Wi-Fi switching',
    'network-settings': 'Open macOS System Settings for owner-managed Wi-Fi/Instant Hotspot',
}


class ZeroError(RuntimeError):
    pass


def state_file(home=None):
    base = Path.home() if home is None else Path(home)
    return base / 'Library/Application Support/BIFROST/zero/workflow.json'


def blank():
    return {'schema': SCHEMA, 'profile': LABEL, 'grants': {}, 'userClaims': {},
            'journal': [], 'revision': 0}


def _safe_path(path):
    for component in (path, *path.parents):
        if not component.is_symlink():
            continue
        # macOS uses root-owned /var -> /private/var for its standard
        # TemporaryDirectory. Permit only this verified OS redirect.
        if (sys.platform == 'darwin' and component == Path('/var')
                and component.resolve() == Path('/private/var')
                and component.lstat().st_uid == 0):
            continue
        raise ZeroError('Refusing linked state or parent')


def load(path=None):
    path = state_file() if path is None else Path(path)
    _safe_path(path)
    if not path.exists():
        return blank()
    fd = os.open(str(path), os.O_RDONLY | getattr(os, 'O_NOFOLLOW', 0))
    try:
        st = os.fstat(fd)
        if not stat.S_ISREG(st.st_mode) or st.st_uid != os.getuid() or st.st_mode & 0o077 or st.st_size > 65536:
            raise ZeroError('Refusing unsafe state permissions or size')
        source = os.read(fd, 65537)
    finally:
        os.close(fd)
    try:
        payload = json.loads(source)
    except (ValueError, TypeError) as error:
        raise ZeroError('State corrupted; original retained') from error
    if (not isinstance(payload, dict) or payload.get('schema') != SCHEMA
            or payload.get('profile') != LABEL
            or not isinstance(payload.get('journal'), list)
            or not isinstance(payload.get('userClaims'), dict)
            or not isinstance(payload.get('grants'), dict)):
        raise ZeroError('State schema unrecognized; original retained')
    return payload


def save(data, path=None):
    path = state_file() if path is None else Path(path)
    _safe_path(path)
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    if path.parent.is_symlink():
        raise ZeroError('Refusing linked state directory')
    path.parent.chmod(0o700)
    _safe_path(path)
    if path.exists():
        st = path.stat()
        if not stat.S_ISREG(st.st_mode) or st.st_uid != os.getuid() or st.st_mode & 0o077:
            raise ZeroError('Existing private state is unsafe; refusing replacement')
    encoded = (json.dumps(data, sort_keys=True, indent=2) + '\n').encode()
    if len(encoded) > 65536:
        raise ZeroError('Journal full; no files overwritten')
    fd, temporary = tempfile.mkstemp(dir=path.parent, prefix='.zero-')
    try:
        with os.fdopen(fd, 'wb') as handle:
            os.fchmod(handle.fileno(), 0o600)
            handle.write(encoded)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def record(data, action, outcome, path=None):
    data['revision'] += 1
    data['journal'].append({'id': 'local-zero-{}'.format(data['revision']),
                            'at': datetime.now(timezone.utc).isoformat(),
                            'action': action, 'outcome': outcome,
                            'verifiedProviderAccount': False})
    data['journal'] = data['journal'][-50:]
    save(data, path)


def decide(data, capability, ask=input, path=None):
    if capability not in CAPABILITIES:
        raise ZeroError('Unknown capability')
    current = data['grants'].get(capability, 'ask')
    if current == 'deny':
        raise ZeroError('Denied. Reset the named grant before retrying.')
    if current == 'allow-all':
        return True
    option = ask('{}: {} [1] Allow Once [a] Allow All [d] Deny: '.format(
        capability, CAPABILITIES[capability])).strip().lower()
    if option == '1':
        return True
    if option in ('a', 'd'):
        data['grants'][capability] = 'allow-all' if option == 'a' else 'deny'
        record(data, 'grant-' + capability, data['grants'][capability], path)
    return option == 'a'


def _native(args, *, max_seconds=20, capture=True):
    result = subprocess.run(args, capture_output=capture, text=capture,
                            check=False, timeout=max_seconds)
    if result.returncode:
        raise ZeroError('Native tool unavailable or returned {}'.format(result.returncode))
    return result.stdout if capture else ''


def _existing_python(source, args, *, capture=True, timeout=30):
    if not source.is_file() or source.is_symlink():
        raise ZeroError('Required existing BIFROST module unavailable')
    return _native([sys.executable, '-B', str(source), *args],
                   capture=capture, max_seconds=timeout)


def observed():
    result = json.loads(_existing_python(CORE, ['status', '--json']))
    if result.get('schema') != 'bifrost.core.runtime-state.v1':
        raise ZeroError('Core status identity/schema is not verified')
    return result


def plan(data):
    return {'schema': SCHEMA, 'product': 'BIFROST', 'phase': 'ZERO',
            'profile': LABEL, 'apple': 'USER_CLAIM_ONLY' if data['userClaims'].get('apple') else 'UNKNOWN',
            'vendor': 'USER_CLAIM_ONLY' if data['userClaims'].get('vendor') else 'UNKNOWN',
            'rdcSession': 'NOT_INFERRED_FROM_ACCOUNT_LABEL',
            'chatgptLink': 'REQUIRES_SEPARATE_PROVIDER_OAUTH',
            'grants': {x: data['grants'].get(x, 'ask') for x in CAPABILITIES},
            'journalEvents': len(data['journal']), 'storesCredentials': False}


def permitted_action(data, action, ask=input, path=None):
    actions = {
        'apple': ('apple-guide', lambda: _existing_python(RDC, ['apple'])),
        'vendor': ('vendor-guide', lambda: _existing_python(RDC, ['provider'])),
        'settings': ('settings', lambda: _native(['/usr/bin/open', '-a', 'System Settings'])),
        'shortcuts': ('shortcuts', lambda: _native(['/usr/bin/open', '-a', 'Shortcuts'])),
        'shortcuts-list': ('shortcuts', lambda: _native(['/usr/bin/shortcuts', 'list'])),
        'automator': ('shortcuts', lambda: _native(['/usr/bin/open', '-a', 'Automator'])),
        'profile': ('rdc-observe', lambda: _existing_python(RDC, ['status'])),
        'network-status': ('network-watch', lambda: _existing_python(NETWORK, ['status'])),
        'wifi-settings': ('network-settings', lambda: _existing_python(NETWORK, ['settings', '--approve-settings'])),
    }
    if action not in actions:
        raise ZeroError('Unknown action')
    capability, run = actions[action]
    if not decide(data, capability, ask=ask, path=path):
        return None
    value = run()
    record(data, action, 'NATIVE_ACTION_COMPLETED_NOT_ACCOUNT_CREATED', path)
    return value


def attest(data, name, ask=input, path=None):
    if name not in ('apple', 'vendor'):
        raise ZeroError('Unsupported attestation')
    if name == 'vendor' and not data['userClaims'].get('apple'):
        raise ZeroError('First choose and confirm an Apple email or user-owned email')
    if ask('Confirm {} in the official Apple/provider UI? Type YES: '.format(name)).strip() != 'YES':
        return False
    data['userClaims'][name] = {'at': datetime.now(timezone.utc).isoformat(),
                               'verification': 'USER_ATTESTED_ONLY'}
    record(data, 'user-confirmed-' + name, 'USER_ATTESTED_NOT_PROVIDER_VERIFIED', path)
    return True


def pair(data, ask=input, path=None):
    if not data['userClaims'].get('apple') or not data['userClaims'].get('vendor'):
        raise ZeroError('Complete official Apple/email and provider user-confirmation gates first')
    if not decide(data, 'rdc-pair', ask=ask, path=path):
        return False
    if ask('Start OFFICIAL RDC5 OAuth device pairing? Type START: ').strip() != 'START':
        return False
    # Official RDC5 launcher owns OAuth, isolated HOME and browser identity.
    # It may run interactively for minutes; never extract passwords or tokens.
    _existing_python(RDC, ['login', '--apple-relay-created', '--rdc-account-created'],
                     capture=False, timeout=14400)
    record(data, 'rdc-pair', 'RDC_CLI_RETURNED_VERIFICATION_STILL_REQUIRED', path)
    return True


def native_capabilities():
    return {'shortcutsCLI': Path('/usr/bin/shortcuts').exists(),
            'automatorCLI': Path('/usr/bin/automator').exists(),
            'appleScript': Path('/usr/bin/osascript').exists(),
            'safari': Path('/Applications/Safari.app').exists(),
            'systemSettings': Path('/System/Applications/System Settings.app').exists(),
            'networkResilienceObserver': NETWORK.is_file()}


def network_watch(data, ask=input, path=None):
    """Start ONE opt-in foreground observer; never silently mutate Wi-Fi."""
    if not decide(data, 'network-watch', ask=ask, path=path):
        return False
    target = ask('Check endpoint [rdc/apple] (blank cancels): ').strip()
    interval = ask('Interval seconds [15/30/60/120/300/600/900]: ').strip()
    if target not in ('rdc', 'apple') or interval not in (
            '15', '30', '60', '120', '300', '600', '900'):
        raise ZeroError('Only approved endpoint and interval choices are allowed')
    # The child needs a real Mac TTY and independently asks the owner to type
    # MONITOR. It remains in this Terminal until Ctrl-C; no background daemon.
    _existing_python(NETWORK, ['watch', '--target', target,
                     '--interval', interval, '--approve-probe'],
                     capture=False, timeout=14400)
    record(data, 'network-watch', 'OWNER_APPROVED_OBSERVATION_ONLY_NO_SWITCH', path)
    return True


def menu(ask=input, path=None):
    data = load(path)
    choices = {'2': 'apple', '3': 'settings', '5': 'vendor',
               '7': 'profile', '8': 'shortcuts-list', 's': 'shortcuts',
               'a': 'automator'}
    while True:
        print('\nBIFROSTcore · ZERO   |   ' + LABEL)
        print('1 Status/plan   2 Apple Hide My Email   3 System Settings')
        print('4 Confirm email choice   5 RDC provider   6 Confirm RDC signup')
        print('7 RDC profile   8 List Shortcuts   9 Official RDC authorization')
        print('s Open Shortcuts   a Open Automator   p Permissions   r Recent actions   q Quit')
        try:
            option = ask('Choose: ').strip().lower()
            if option == 'q':
                return 0
            if option == '1':
                print(json.dumps(plan(data), indent=2))
                print('Headless:', observed()['headless']['state'])
            elif option in choices:
                print(permitted_action(data, choices[option], ask=ask, path=path) or 'No action')
            elif option == '4':
                attest(data, 'apple', ask=ask, path=path)
            elif option == '6':
                attest(data, 'vendor', ask=ask, path=path)
            elif option == '9':
                pair(data, ask=ask, path=path)
            elif option == 'm':
                print(permitted_action(data, 'network-status', ask=ask, path=path) or 'No action')
            elif option == 'n':
                network_watch(data, ask=ask, path=path)
            elif option == 'w':
                print(permitted_action(data, 'wifi-settings', ask=ask, path=path) or 'No action')
            elif option == 'p':
                print(json.dumps(plan(data)['grants'], indent=2))
                selection = ask('Reset grant name to ASK (empty cancels): ').strip()
                if selection in CAPABILITIES:
                    data['grants'].pop(selection, None)
                    record(data, 'reset-grant-' + selection, 'ASK', path)
            elif option == 'r':
                print(json.dumps(data['journal'][-8:], indent=2))
        except (ZeroError, ValueError, OSError, subprocess.TimeoutExpired) as exc:
            print('BIFROST:', exc, file=sys.stderr)
        except (EOFError, KeyboardInterrupt):
            return 130


def main(argv=None):
    cli = argparse.ArgumentParser(prog='BIFROSTcore ZERO',
                                  description='Test the BIFROSTcore account journey, not a separate product')
    cli.add_argument('action', nargs='?', default='menu',
                     choices=('menu', 'status', 'capabilities', 'receipts', 'guide'))
    cli.add_argument('--json', action='store_true')
    args = cli.parse_args(argv)
    try:
        if args.action == 'menu':
            if not sys.stdin.isatty():
                raise ZeroError('Use a Mac Terminal for interactive setup')
            return menu()
        data = load()
        if args.action == 'status':
            result = {'journey': plan(data), 'core': observed(), 'native': native_capabilities()}
            print(json.dumps(result, indent=2) if args.json else
                  'BIFROSTcore ZERO | Headless: {} | {}: {}'.format(
                      result['core']['headless']['state'], LABEL, result['journey']['vendor']))
        elif args.action == 'capabilities':
            print(json.dumps(native_capabilities(), indent=2))
        elif args.action == 'receipts':
            print(json.dumps(data['journal'], indent=2))
        elif args.action == 'guide':
            print('BIFROSTcore ZERO reuses native Mac/Shortcuts and RDC5.')
            print('Apple/email choice → official RDC signup → official device pairing → separate ChatGPT connector.')
            print('No credentials are stored by ZERO; account success requires provider verification.')
        return 0
    except (ZeroError, ValueError, OSError, subprocess.TimeoutExpired) as exc:
        print('BIFROST ZERO:', exc, file=sys.stderr)
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
