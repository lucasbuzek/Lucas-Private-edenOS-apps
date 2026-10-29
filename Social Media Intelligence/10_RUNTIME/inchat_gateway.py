#!/usr/bin/env python3
"""Small JSON request/response adapter for future authenticated ChatGPT/BIFROST routing.

No listening socket, daemon, account credentials, platform posting or ELYSIUM reads.
"""
from __future__ import annotations
import argparse
import json
import sys
from pathlib import Path
from workspace_policy import authorize
from persona_studio import validate as validate_persona
from auto_pipeline import build_calendar_slots
ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.1.0"

def execute(request):
    if not isinstance(request, dict):
        return {"status": "FAIL", "error": "Expected object request"}
    op = request.get("operation")
    if op == "capabilities":
        return {"status": "PASS", "gateway_version": VERSION, "mode": "LOCAL_STANDALONE",
                "operations": ["capabilities", "validate_persona", "calendar_preview", "workspace_authorization"],
                "account_connections": "NOT_CONFIGURED", "model_provider": "EXTERNAL_OPTIONAL",
                "chatgpt_connector": "NOT_CONFIGURED", "bifrost_bridge": "NOT_VERIFIED",
                "publishing": "DISABLED", "remote_scheduling": "DISABLED"}
    if op == "validate_persona":
        persona = request.get("persona")
        if not isinstance(persona, dict): return {"status": "FAIL", "error": "Persona object required"}
        errors = validate_persona(persona)
        return {"status": "PASS" if not errors else "FAIL", "errors": errors, "active": persona.get("status") == "ACTIVE"}
    if op == "workspace_authorization":
        decision = request.get("authorization")
        if not isinstance(decision, dict): return {"status": "FAIL", "error": "Authorization object required"}
        return authorize(decision)
    if op == "calendar_preview":
        persona = request.get("persona")
        if not isinstance(persona, dict): return {"status": "FAIL", "error": "Persona object required"}
        if persona.get("status") != "ACTIVE":
            return {"status": "FAIL", "error": "Active, human-reviewed persona required"}
        auth = request.get("authorization")
        if not isinstance(auth, dict):
            return {"status": "UNKNOWN", "error": "Verified workspace authorization required"}
        decision = authorize({**auth, "action": "VIEW_CALENDAR"})
        if not decision["allowed"]: return {"status": decision["status"], "error": decision["reason"]}
        if persona.get("workspace_scope", "LUCAS_PRIVATE") != auth.get("workspace_scope"):
            return {"status": "FAIL", "error": "Persona/workspace scope mismatch"}
        slots, state = build_calendar_slots(persona, request.get("horizon_days", 7))
        return {"status": state["status"], "calendar": slots,
                "human_approval_required": True, "external_action": "NOT_PERFORMED"}
    return {"status": "FAIL", "error": "Operation not supported"}

def main():
    p = argparse.ArgumentParser(description="Local JSON command interface. No daemon or outbound social actions.")
    p.add_argument("--request-file", type=Path, help="Read one JSON request from a file, otherwise stdin")
    args = p.parse_args()
    try:
        raw = args.request_file.read_text(encoding="utf-8") if args.request_file else sys.stdin.read(256000)
        result = execute(json.loads(raw))
    except (ValueError, OSError, UnicodeError, json.JSONDecodeError) as exc:
        result = {"status": "FAIL", "error": f"Invalid request: {type(exc).__name__}"}
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    return 0 if result.get("status") == "PASS" else 1

if __name__ == "__main__":
    raise SystemExit(main())

