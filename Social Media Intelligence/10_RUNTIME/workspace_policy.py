"""Private workspace consent policy for the Social Media Intelligence interface.

This is a policy evaluator, not an authenticator or an ELYSIUM data connector.
All principal claims must originate from an independently verified BIFROST session.
"""
from __future__ import annotations
from datetime import datetime, timezone

KNOWN_SCOPES = frozenset({"LUCAS_PRIVATE", "ELYSIUM_PERSONAL", "ELYSIUM_BUSINESS"})
READ_ACTIONS = frozenset({"VIEW_PERSONA", "VIEW_RESEARCH", "VIEW_DRAFTS", "VIEW_CALENDAR"})
PREPARATION_ACTIONS = frozenset({"PREPARE_RESEARCH", "PREPARE_DRAFT", "PROPOSE_SCHEDULE"})
EXTERNAL_ACTIONS = frozenset({"PUBLISH", "SCHEDULE_REMOTE", "MESSAGE", "COMMENT", "BOOST", "MODIFY_ACCOUNT"})

def _parse_time(value):
    if not isinstance(value, str) or not value: return None
    try:
        v = datetime.fromisoformat(value.replace("Z", "+00:00"))
        if v.tzinfo is None: return None
        return v.astimezone(timezone.utc)
    except (ValueError, TypeError, OverflowError): return None

def authorize(request, now=None):
    """Return a conservative decision; a passing policy check is NOT authentication."""
    now = now or datetime.now(timezone.utc)
    if now.tzinfo is None: raise ValueError("now must be timezone aware")
    scope = request.get("workspace_scope")
    action = request.get("action")
    principal = request.get("principal_id")
    if scope not in KNOWN_SCOPES:
        return {"status": "UNKNOWN", "allowed": False, "reason": "Unknown workspace scope"}
    if action in EXTERNAL_ACTIONS:
        return {"status": "FAIL", "allowed": False, "reason": "External account actions require separate exact-version human approval and a verified connector"}
    if action not in READ_ACTIONS | PREPARATION_ACTIONS:
        return {"status": "FAIL", "allowed": False, "reason": "Action not allowlisted"}
    if request.get("session_authenticated") is not True:
        return {"status": "UNKNOWN", "allowed": False, "reason": "BIFROST-authenticated principal/session evidence absent"}
    if not isinstance(principal, str) or not principal.strip():
        return {"status": "FAIL", "allowed": False, "reason": "Principal missing"}
    if scope == "LUCAS_PRIVATE":
        allowed = principal == "lucas"
        return {"status": "PASS" if allowed else "FAIL", "allowed": allowed,
                "reason": "Local private workspace reserved for Lucas" if not allowed else "Lucas private policy passed"}
    # ELYSIUM is a distinct owner-controlled boundary; no universal spouse/family access.
    receipts = request.get("consent_receipts", [])
    for receipt in receipts if isinstance(receipts, list) else []:
        if not isinstance(receipt, dict): continue
        if not all(receipt.get(k) for k in ("receipt_id", "grantor", "grantee", "purpose", "expires_at")): continue
        if receipt.get("workspace_scope") != scope or receipt.get("grantee") != principal: continue
        if receipt.get("action") != action or receipt.get("purpose") != request.get("purpose"): continue
        if receipt.get("revoked") is True: continue
        expiry = _parse_time(receipt["expires_at"])
        if expiry and expiry > now:
            return {"status": "PASS", "allowed": True, "reason": "Valid, unexpired purpose-bound consent receipt (policy only)"}
    return {"status": "FAIL", "allowed": False,
            "reason": "No matching unexpired, purpose-bound ELYSIUM consent; denied by default"}

