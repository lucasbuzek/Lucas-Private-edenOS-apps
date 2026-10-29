#!/usr/bin/env python3
"""Local, fail-closed queue governor. Standard library only; never publishes."""
from __future__ import annotations
import argparse, hashlib, json, os, sys, tempfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "10_RUNTIME" / "data"
QUEUE = DATA / "queue.json"
AUDIT = DATA / "audit.jsonl"
ALLOWED_STATES = {"DRAFT", "NEEDS_RESEARCH", "READY_FOR_REVIEW", "APPROVED", "SCHEDULE_PREPARED", "REJECTED", "EXPIRED", "WITHDRAWN"}
REQUIRED = ("persona_id", "platform", "account_id", "audience", "text", "source_urls", "proposed_publish_at")

def now():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")

def digest(value):
    blob = json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(",", ":")).encode()
    return hashlib.sha256(blob).hexdigest()

def load():
    DATA.mkdir(parents=True, exist_ok=True)
    if not QUEUE.exists():
        return {"schema_version": 1, "posts": {}}
    try:
        value = json.loads(QUEUE.read_text(encoding="utf-8"))
        if value.get("schema_version") != 1 or not isinstance(value.get("posts"), dict):
            raise ValueError("Unsupported queue schema")
        return value
    except (json.JSONDecodeError, OSError, ValueError) as exc:
        raise RuntimeError(f"Queue integrity/read failure; refusing to proceed: {exc}")

def save(value):
    DATA.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(prefix="queue-", suffix=".tmp", dir=DATA)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(value, f, indent=2, ensure_ascii=False, sort_keys=True)
            f.write("\n")
            f.flush()
            os.fsync(f.fileno())
        os.replace(name, QUEUE)
    finally:
        if os.path.exists(name):
            os.unlink(name)

def audit(event, details):
    DATA.mkdir(parents=True, exist_ok=True)
    row = {"at": now(), "event": event, "details": details}
    with AUDIT.open("a", encoding="utf-8") as f:
        f.write(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n")
        f.flush()
        os.fsync(f.fileno())

def require_post(q, post_id):
    post = q["posts"].get(post_id)
    if not post:
        raise ValueError(f"Unknown post_id: {post_id}")
    return post

def content_payload(post):
    return {k: v for k, v in post.items() if k not in {"content_hash", "approval", "state", "created_at", "updated_at", "history"}}

def refresh_hash(post):
    new_hash = digest(content_payload(post))
    old_hash = post.get("content_hash")
    if old_hash and old_hash != new_hash:
        post["approval"] = None
        if post["state"] in {"APPROVED", "SCHEDULE_PREPARED"}:
            post["state"] = "READY_FOR_REVIEW"
        post["history"].append({"at": now(), "event": "CONTENT_CHANGED_APPROVAL_INVALIDATED"})
    post["content_hash"] = new_hash
    post["updated_at"] = now()

def cmd_add(args):
    q = load()
    post = {
        "post_id": args.id,
        "persona_id": args.persona,
        "platform": args.platform,
        "account_id": args.account,
        "audience": args.audience,
        "text": args.text,
        "source_urls": args.source or [],
        "proposed_publish_at": args.publish_at,
        "state": "DRAFT",
        "approval": None,
        "created_at": now(),
        "updated_at": now(),
        "history": [{"at": now(), "event": "CREATED"}],
    }
    missing = [key for key in REQUIRED if post.get(key) in (None, "", [])]
    if missing:
        raise ValueError("Missing required fields: " + ", ".join(missing))
    if post["post_id"] in q["posts"]:
        raise ValueError("post_id already exists; IDs are never overwritten")
    post["content_hash"] = digest(content_payload(post))
    q["posts"][post["post_id"]] = post
    save(q); audit("POST_CREATED", {"post_id": post["post_id"], "content_hash": post["content_hash"]})
    print(json.dumps({"post_id": post["post_id"], "state": post["state"], "content_hash": post["content_hash"]}, indent=2))

def cmd_list(args):
    q = load()
    rows = []
    for p in q["posts"].values():
        if args.state and p["state"] != args.state:
            continue
        rows.append({k: p.get(k) for k in ("post_id", "persona_id", "platform", "account_id", "state", "proposed_publish_at", "content_hash")})
    print(json.dumps(rows, indent=2, ensure_ascii=False))

def cmd_show(args):
    q = load()
    print(json.dumps(require_post(q, args.id), indent=2, ensure_ascii=False))

def cmd_edit(args):
    q = load(); p = require_post(q, args.id)
    if p["state"] in {"REJECTED", "EXPIRED", "WITHDRAWN"}:
        raise ValueError(f"Cannot edit terminal post state {p['state']}; create a new post version")
    if args.text is not None: p["text"] = args.text
    if args.publish_at is not None: p["proposed_publish_at"] = args.publish_at
    if args.source is not None: p["source_urls"] = args.source
    refresh_hash(p)
    p["history"].append({"at": now(), "event": "EDITED"})
    save(q); audit("POST_EDITED", {"post_id": args.id, "content_hash": p["content_hash"], "approval_invalidated": p["approval"] is None})
    print(json.dumps({"post_id": args.id, "state": p["state"], "content_hash": p["content_hash"], "approval": p["approval"]}, indent=2))

def cmd_review_ready(args):
    q = load(); p = require_post(q, args.id)
    refresh_hash(p)
    if not p.get("source_urls"):
        raise ValueError("Fail closed: at least one source URL is required before review")
    if not p.get("text", "").strip():
        raise ValueError("Fail closed: empty draft")
    p["state"] = "READY_FOR_REVIEW"
    p["history"].append({"at": now(), "event": "MARKED_READY_FOR_REVIEW"})
    save(q); audit("READY_FOR_REVIEW", {"post_id": args.id, "content_hash": p["content_hash"]})
    print(json.dumps({"post_id": args.id, "state": p["state"], "content_hash": p["content_hash"]}, indent=2))

def cmd_approve(args):
    q = load(); p = require_post(q, args.id)
    refresh_hash(p)
    if p["state"] != "READY_FOR_REVIEW":
        raise ValueError(f"Approval requires READY_FOR_REVIEW; current state is {p['state']}")
    if not args.reviewer.strip() or not args.action.strip():
        raise ValueError("Reviewer and exact action are required")
    approval = {
        "reviewer": args.reviewer,
        "decision": "APPROVE",
        "content_hash": p["content_hash"],
        "platform": p["platform"],
        "account_id": p["account_id"],
        "action": args.action,
        "approved_at": now(),
        "expires_at": args.expires_at,
        "note": args.note or "",
    }
    p["approval"] = approval
    p["state"] = "APPROVED"
    p["history"].append({"at": now(), "event": "HUMAN_APPROVED", "content_hash": p["content_hash"]})
    save(q); audit("HUMAN_APPROVED", {"post_id": args.id, "approval": approval})
    print(json.dumps({"post_id": args.id, "state": p["state"], "approval": approval}, indent=2))

def cmd_schedule_proposal(args):
    q = load(); p = require_post(q, args.id)
    refresh_hash(p)
    a = p.get("approval")
    if p["state"] != "APPROVED" or not a:
        raise ValueError("Schedule proposal requires human approval")
    if a["content_hash"] != p["content_hash"] or a["platform"] != p["platform"] or a["account_id"] != p["account_id"]:
        raise ValueError("Approval does not match exact content/account/destination")
    if a["action"] not in {"PREPARE_SCHEDULE", "HUMAN_SUBMIT"}:
        raise ValueError("Approval does not authorize schedule preparation")
    if a.get("expires_at") and a["expires_at"] <= now():
        p["approval"] = None; p["state"] = "READY_FOR_REVIEW"
        save(q); audit("APPROVAL_EXPIRED", {"post_id": args.id})
        raise ValueError("Approval expired; review required again")
    p["state"] = "SCHEDULE_PREPARED"
    p["history"].append({"at": now(), "event": "LOCAL_SCHEDULE_PROPOSAL_PREPARED"})
    save(q); audit("LOCAL_SCHEDULE_PROPOSAL_PREPARED", {"post_id": args.id, "publish_at": p["proposed_publish_at"]})
    print(json.dumps({"post_id": args.id, "state": p["state"], "proposed_publish_at": p["proposed_publish_at"], "external_action": "NOT_PERFORMED"}, indent=2))

def cmd_submit(args):
    raise ValueError("Publishing/submission is deliberately disabled in this runtime. No platform connector exists. Prepare a local proposal and submit manually on the platform.")

def cmd_verify(args):
    q = load(); p = require_post(q, args.id)
    expected = digest(content_payload(p))
    result = {"post_id": args.id, "hash_matches": expected == p.get("content_hash"), "approval_hash_matches": bool(p.get("approval") and p["approval"].get("content_hash") == expected), "state": p["state"], "publishing_enabled": False}
    print(json.dumps(result, indent=2))
    if not result["hash_matches"]:
        sys.exit(2)

def parser():
    ap = argparse.ArgumentParser(description=__doc__)
    sp = ap.add_subparsers(dest="command", required=True)
    a = sp.add_parser("add"); a.add_argument("--id", required=True); a.add_argument("--persona", required=True); a.add_argument("--platform", required=True); a.add_argument("--account", required=True); a.add_argument("--audience", required=True); a.add_argument("--text", required=True); a.add_argument("--source", action="append"); a.add_argument("--publish-at", required=True); a.set_defaults(fn=cmd_add)
    a = sp.add_parser("list"); a.add_argument("--state", choices=sorted(ALLOWED_STATES)); a.set_defaults(fn=cmd_list)
    a = sp.add_parser("show"); a.add_argument("id"); a.set_defaults(fn=cmd_show)
    a = sp.add_parser("edit"); a.add_argument("id"); a.add_argument("--text"); a.add_argument("--publish-at"); a.add_argument("--source", action="append"); a.set_defaults(fn=cmd_edit)
    a = sp.add_parser("ready"); a.add_argument("id"); a.set_defaults(fn=cmd_review_ready)
    a = sp.add_parser("approve"); a.add_argument("id"); a.add_argument("--reviewer", required=True); a.add_argument("--action", required=True, choices=["PREPARE_SCHEDULE", "HUMAN_SUBMIT"]); a.add_argument("--expires-at", required=True, help="UTC ISO-8601 timestamp"); a.add_argument("--note"); a.set_defaults(fn=cmd_approve)
    a = sp.add_parser("schedule-proposal"); a.add_argument("id"); a.set_defaults(fn=cmd_schedule_proposal)
    a = sp.add_parser("submit"); a.add_argument("id"); a.set_defaults(fn=cmd_submit)
    a = sp.add_parser("verify"); a.add_argument("id"); a.set_defaults(fn=cmd_verify)
    return ap

def main():
    args = parser().parse_args()
    try:
        args.fn(args)
    except (ValueError, RuntimeError, OSError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()

