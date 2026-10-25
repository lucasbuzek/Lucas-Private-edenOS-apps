"""BIFROST Headless first-use account inventory; no second registry or service.

Reads only existing BIFROST Files & Storage account metadata and RDC profile
directory names. Never opens provider configs, secrets, device.json, or sessions.
Observed profile names are NOT evidence of login, pairing, quota, or readiness.
"""
from __future__ import annotations
from datetime import datetime, timezone
from pathlib import Path
import re

SCHEMA = "bifrost.first-use.accounts.v1"
RDC_LABEL = re.compile(r"^RDC(?:[1-9][0-9]*)(?:-home)?$|^RDCravensnest(?:-home)?$")
RAVEN_EMAIL_HINT = "lucasravensnest@gmail.com"


def _rdc_profile_names(home: Path) -> list[str]:
    root = home / ".local/share/rdc5-identities"
    if root.is_symlink() or not root.is_dir():
        return []
    result: list[str] = []
    for entry in sorted(root.iterdir(), key=lambda x: x.name.lower()):
        if len(result) >= 48:
            break
        if not RDC_LABEL.fullmatch(entry.name) or entry.is_symlink() or not entry.is_dir():
            continue
        result.append(entry.name)
    return result


def snapshot(*, home: Path | None = None, accounts_reader=None) -> dict:
    """Return non-secret account *labels* for the authenticated Headless UI.

    Caller MUST enforce the existing BIFROST Headless Host, Origin and session
    authentication; this helper is not an API or authorization engine.
    """
    if home is None:
        home = Path.home()
    if accounts_reader is None:
        import storage_adapter
        accounts_reader = storage_adapter.accounts
    raw = accounts_reader()
    accounts = raw.get("accounts", []) if isinstance(raw, dict) else []
    safe = []
    for record in accounts[:64]:
        if not isinstance(record, dict):
            continue
        provider = record.get("provider")
        source = record.get("source")
        name = record.get("name")
        if not all(isinstance(v, str) and len(v) <= 80 for v in (provider, source, name)):
            continue
        if not all(re.fullmatch(r"[A-Za-z0-9_-]{1,80}", v) for v in (provider, source, name)):
            continue
        safe.append({
            "provider": provider,
            "configSource": source,
            "remoteLabel": name,
            "authenticatedAccountId": None,
            "authorizationVerified": False,
            "readVerified": False,
        })
    names = _rdc_profile_names(home)
    manager = home / "bin/rdc5"
    manager_present = manager.is_file() and not manager.is_symlink()
    return {
        "schema": SCHEMA,
        "observedAt": datetime.now(timezone.utc).isoformat(),
        "mode": "metadata-only-read",
        "rdc": {
            "installedManagerFound": manager_present,
            "profileLabels": names,
            "ravensnest": {
                "alias": "RDCravensnest",
                "historicalAlias": "RDC7 (historical only; do not select by name)",
                "principalHint": RAVEN_EMAIL_HINT,
                "sessionAuthenticated": "UNKNOWN",
                "deviceReady": "UNKNOWN",
                "deviceAccountVerified": False,
                "candidateLabelPresent": any(x.startswith("RDCravensnest") for x in names),
            },
            "rdc7ReservedForDifferentAccount": True,
            "noProfileChanged": True,
        },
        "cloud": {
            "configuredRemoteLabels": safe,
            "authenticatedAccountIds": "NOT_VERIFIED",
            "noTokenRead": True,
            "oauthGrantMade": False,
        },
        "capabilities": {
            "readOnly": True,
            "providerPairing": "NOT_IMPLEMENTED",
            "autoSync": False,
            "copy": False,
            "move": False,
            "delete": False,
        },
        "note": "Labels are not authentication, live connectivity, device readiness or permission grants.",
    }
