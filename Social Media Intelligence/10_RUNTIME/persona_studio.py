#!/usr/bin/env python3
"""Guided local persona creation/update with version snapshots and an audit trail."""
from __future__ import annotations
import argparse, datetime as dt, json, re
from zoneinfo import ZoneInfo
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TEMPLATE = ROOT / "03_PERSONAS" / "PERSONA_CUSTOMIZATION_TEMPLATE.json"
PROFILES = ROOT / "03_PERSONAS" / "Profiles"
HISTORY = PROFILES / "history"
AUDIT = PROFILES / "persona_changes.jsonl"

def now():
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

def slug(value):
    value = re.sub(r"[^a-zA-Z0-9_-]+", "-", value.strip()).strip("-").lower()
    if not value: raise ValueError("Persona ID must contain letters or numbers.")
    return value[:80]

def ask(label, current="", is_list=False, required=False):
    suffix = " [comma-separated; '-' clears]" if is_list else ""
    existing = ", ".join(current) if isinstance(current, list) else str(current or "")
    answer = input(f"{label}{suffix} [{existing}]: ").strip()
    if not answer:
        if required and not existing: raise ValueError(f"{label} is required.")
        return current
    if is_list:
        return [] if answer == "-" else [x.strip() for x in answer.split(",") if x.strip()]
    return answer

def validate(persona):
    errors = []
    identity = persona.get("account_identity", {})
    audience = persona.get("audience", {})
    if not persona.get("persona_id"): errors.append("persona_id is missing")
    if not persona.get("display_name"): errors.append("display_name is missing")
    if not persona.get("mission"): errors.append("mission is missing")
    if not identity.get("type") or identity.get("type") not in {"person","brand","project","publication"}:
        errors.append("account_identity.type must be person, brand, project or publication")
    if not identity.get("public_name"): errors.append("account_identity.public_name is missing")
    if not identity.get("platforms"): errors.append("select at least one target platform")
    if not audience.get("description"): errors.append("audience.description is missing")
    if not audience.get("timezone"): errors.append("audience.timezone is missing")
    else:
        try: ZoneInfo(audience["timezone"])
        except Exception: errors.append("audience.timezone must be a valid IANA timezone")
    if not persona.get("editorial_scope", {}).get("allowlist"): errors.append("add at least one allowed topic")
    if persona.get("publishing", {}).get("auto_publish") is not False:
        errors.append("publishing.auto_publish must remain false")
    if persona.get("publishing", {}).get("default_mode") != "HUMAN_APPROVAL_REQUIRED":
        errors.append("publishing.default_mode must be HUMAN_APPROVAL_REQUIRED")
    return errors

def prompt_profile(persona, create=False):
    print("\nPersona Studio — blank keeps the current value; '-' clears a list.\n")
    persona["display_name"] = ask("Display name", persona.get("display_name",""), required=True)
    identity = persona.setdefault("account_identity", {})
    identity["type"] = ask("Account type (person/brand/project/publication)", identity.get("type","brand"), required=True).lower()
    identity["public_name"] = ask("Public account/persona name", identity.get("public_name",""), required=True)
    identity["ownership_disclosure"] = ask("Ownership/disclosure text", identity.get("ownership_disclosure",""))
    identity["platforms"] = ask("Platforms (e.g. Instagram, LinkedIn, YouTube)", identity.get("platforms",[]), True, True)
    identity["account_refs"] = ask("Non-secret account identifiers/handles (no passwords or tokens)", identity.get("account_refs",[]), True)
    persona["mission"] = ask("Mission and purpose", persona.get("mission",""), required=True)
    audience = persona.setdefault("audience", {})
    audience["description"] = ask("Target audience", audience.get("description",""), required=True)
    audience["geography"] = ask("Geography/markets", audience.get("geography",""))
    audience["language"] = ask("Primary language", audience.get("language","en"))
    audience["timezone"] = ask("IANA timezone (e.g. Africa/Johannesburg)", audience.get("timezone",""), required=True)
    voice = persona.setdefault("voice", {})
    voice["traits"] = ask("Voice traits", voice.get("traits",["direct","clear"]), True)
    voice["tone_examples"] = ask("Examples of preferred tone", voice.get("tone_examples",[]), True)
    voice["avoid_phrases"] = ask("Phrases/styles to avoid", voice.get("avoid_phrases",[]), True)
    voice["format_preferences"] = ask("Preferred formats", voice.get("format_preferences",[]), True)
    expertise = persona.setdefault("expertise", {})
    expertise["areas"] = ask("Expertise areas", expertise.get("areas",[]), True)
    expertise["limits"] = ask("Expertise limits / claims not to make", expertise.get("limits",[]), True)
    expertise["must_escalate_topics"] = ask("Topics requiring specialist review", expertise.get("must_escalate_topics",[]), True)
    scope = persona.setdefault("editorial_scope", {})
    scope["allowlist"] = ask("Allowed topics/search themes", scope.get("allowlist",[]), True, True)
    scope["blocklist"] = ask("Excluded topics", scope.get("blocklist",[]), True)
    scope["controversy_definition"] = "Documented disagreement or material public-interest debate; never manufacture conflict."
    persona.setdefault("moderation", {})["policy"] = ask("Comment/moderation policy", persona.get("moderation",{}).get("policy",""))
    persona["commercial_disclosures"] = ask("Required commercial/sponsorship disclosures", persona.get("commercial_disclosures",[]), True)
    persona.setdefault("engagement_strategy", {})["goals"] = ask("Engagement goals (not rage/controversy for its own sake)", persona.get("engagement_strategy",{}).get("goals",[]), True)
    persona.setdefault("metrics_allowlist", ["reach","retention","saves","shares","qualified_clicks","constructive_comments"])
    persona["metrics_allowlist"] = ask("Metrics allowed for learning", persona.get("metrics_allowlist",[]), True)
    calendar = persona.setdefault("calendar", {})
    try:
        current_count = calendar.get("posts_per_week")
        answer = input(f"Posts per week (blank keeps current, '-' disables cadence) [{current_count if current_count is not None else ''}]: ").strip()
        if answer == "-": calendar["posts_per_week"] = None
        elif answer: calendar["posts_per_week"] = max(1, min(21, int(answer)))
    except ValueError:
        print("Invalid posts-per-week value; keeping existing setting.")
    calendar["preferred_days"] = ask("Preferred days (Mon,Tue,Wed,Thu,Fri,Sat,Sun)", calendar.get("preferred_days",[]), True)
    calendar["preferred_local_times"] = ask("Preferred local times (24-hour HH:MM)", calendar.get("preferred_local_times",[]), True)
    try:
        answer = input(f"Minimum hours between posts [{calendar.get('minimum_gap_hours') or ''}]: ").strip()
        if answer: calendar["minimum_gap_hours"] = max(1, min(168, int(answer)))
    except ValueError:
        print("Invalid minimum-gap value; keeping existing setting.")
    calendar["timezone"] = "USE_AUDIENCE_TIMEZONE"
    calendar["approval_required_for_each_slot"] = True
    calendar["remote_scheduling_enabled"] = False
    persona.setdefault("workspace_scope", "LUCAS_PRIVATE")
    persona.setdefault("model_routing", {"preferred": "APPLE_ON_DEVICE_WHEN_AVAILABLE", "cloud_allowed": False,
                                         "allow_household_context_to_cloud": False, "fallback": "HOLD_AND_ASK"})
    persona["status"] = "CONFIGURED_PENDING_REVIEW"
    persona.setdefault("review", {})["last_human_review"] = None
    persona["review"]["reviewer"] = ""
    # Publishing permissions are intentionally not editable in this wizard.
    persona.setdefault("publishing", {})["default_mode"] = "HUMAN_APPROVAL_REQUIRED"
    persona["publishing"]["auto_publish"] = False
    persona["publishing"]["allowed_actions"] = ["RESEARCH","DRAFT","PREPARE_LOCAL_SCHEDULE"]
    return persona

def save_profile(persona, path, operation):
    errors = validate(persona)
    if errors:
        print(json.dumps({"status":"VALIDATION_FAILED","errors":errors}, indent=2))
        return 2
    path.parent.mkdir(parents=True, exist_ok=True)
    previous_revision = int(persona.get("config_revision", 0))
    persona["config_revision"] = previous_revision + 1
    persona["updated_at"] = now()
    if operation in {"CREATE", "UPDATE"}:
        persona["status"] = "CONFIGURED_PENDING_REVIEW"
    if path.exists():
        HISTORY.mkdir(parents=True, exist_ok=True)
        stamp = dt.datetime.now().strftime("%Y%m%dT%H%M%S")
        snapshot = HISTORY / f"{path.stem}.r{previous_revision:03d}.{stamp}.json"
        snapshot.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")
    path.write_text(json.dumps(persona, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    AUDIT.parent.mkdir(parents=True, exist_ok=True)
    event = {"timestamp":now(),"operation":operation,"persona_id":persona["persona_id"],
             "config_revision":persona["config_revision"],"path":str(path),"status":persona["status"]}
    with AUDIT.open("a", encoding="utf-8") as f: f.write(json.dumps(event, ensure_ascii=False)+"\n")
    print(json.dumps({"status":"ACTIVATED" if operation == "ACTIVATE" else "SAVED_PENDING_HUMAN_REVIEW","persona_id":persona["persona_id"],
        "revision":persona["config_revision"],"path":str(path),"validation":"PASS",
        "auto_publish":False,"human_approval_required":True}, indent=2))
    return 0

def main():
    ap=argparse.ArgumentParser(description="Create/update/version a social media persona without enabling publishing.")
    sub=ap.add_subparsers(dest="command", required=True)
    n=sub.add_parser("new"); n.add_argument("--id", required=True)
    e=sub.add_parser("edit"); e.add_argument("path", type=Path)
    v=sub.add_parser("validate"); v.add_argument("path", type=Path)
    a=sub.add_parser("activate"); a.add_argument("path", type=Path); a.add_argument("--reviewer", required=True)
    sub.add_parser("list")
    args=ap.parse_args()
    if args.command=="list":
        PROFILES.mkdir(parents=True, exist_ok=True)
        files=sorted(PROFILES.glob("*.json"))
        print(json.dumps([{"persona_id":p.stem,"path":str(p)} for p in files], indent=2))
        return 0
    if args.command=="new":
        persona_id=slug(args.id)
        path=PROFILES / f"{persona_id}.json"
        if path.exists(): print(f"Already exists: {path}; use edit."); return 2
        persona=json.loads(TEMPLATE.read_text(encoding="utf-8"))
        persona["persona_id"]=persona_id
        persona["display_name"]=persona_id.replace("-"," ").title()
        persona["account_identity"].update({"type":"brand","public_name":"","platforms":[],"account_refs":[]})
        persona["mission"]=""
        persona["audience"].update({"description":"","geography":"","timezone":""})
        persona["editorial_scope"].update({"allowlist":[],"blocklist":[]})
        persona["status"]="DRAFT"
        persona=prompt_profile(persona, True)
        return save_profile(persona,path,"CREATE")
    path=args.path.expanduser().resolve()
    if not path.exists(): print(f"Persona file not found: {path}"); return 2
    persona=json.loads(path.read_text(encoding="utf-8"))
    if args.command=="validate":
        errors=validate(persona)
        print(json.dumps({"status":"FAIL" if errors else "PASS","errors":errors,
            "persona_status":persona.get("status"),
            "publishing_mode":persona.get("publishing",{}).get("default_mode"),
            "auto_publish":persona.get("publishing",{}).get("auto_publish")}, indent=2))
        return 1 if errors else 0
    if args.command=="activate":
        if not args.reviewer.strip():
            print(json.dumps({"status":"BLOCKED","errors":["reviewer must not be blank"]},indent=2)); return 2
        errors=validate(persona)
        if errors:
            print(json.dumps({"status":"BLOCKED","errors":errors},indent=2)); return 2
        persona["status"]="ACTIVE"
        persona.setdefault("review",{})["last_human_review"]=now()
        persona["review"]["reviewer"]=args.reviewer
        return save_profile(persona,path,"ACTIVATE")
    persona=prompt_profile(persona)
    return save_profile(persona,path,"UPDATE")

if __name__=="__main__":
    raise SystemExit(main())

