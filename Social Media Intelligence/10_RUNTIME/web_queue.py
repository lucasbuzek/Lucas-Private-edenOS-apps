#!/usr/bin/env python3
"""Owner-local HTTP adapter for the ORIGINAL FAMA queue_governor.

No publishing, credential access, cloud identity, remote scheduling, or new
queue storage. The existing queue_governor is the only state-machine owner.
"""
from __future__ import annotations

import contextlib
import datetime as dt
import io
import json
import threading
from argparse import Namespace
import queue_governor as governor
from research_runner import safe_public_url

LOCK = threading.RLock()
OPERATIONS = {
    "list": ({"operation", "state"}, governor.cmd_list),
    "show": ({"operation", "post_id"}, governor.cmd_show),
    "create": ({"operation", "post_id", "persona_id", "platform", "account_id",
                "audience", "text", "source_urls", "proposed_publish_at"}, governor.cmd_add),
    "edit": ({"operation", "post_id", "text", "source_urls", "proposed_publish_at"}, governor.cmd_edit),
    "ready": ({"operation", "post_id"}, governor.cmd_review_ready),
    "approve": ({"operation", "post_id", "reviewer", "action", "expires_at",
                 "content_hash", "account_id", "platform", "note"}, governor.cmd_approve),
    "schedule-proposal": ({"operation", "post_id"}, governor.cmd_schedule_proposal),
    "verify": ({"operation", "post_id"}, governor.cmd_verify),
}
POST_ID_CHARS = set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")

def limited_text(value, label, maximum, *, required=True):
    if not isinstance(value, str) or len(value) > maximum or (required and not value.strip()):
        raise ValueError(label + " must be nonempty text of at most " + str(maximum) + " characters")
    return value.strip()

def post_id(data):
    value = limited_text(data.get("post_id"), "post_id", 80)
    if not set(value) <= POST_ID_CHARS:
        raise ValueError("post_id contains unsupported characters")
    return value

def utc_future(value, label):
    value = limited_text(value, label, 40)
    try:
        when = dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ValueError(label + " must be an ISO-8601 timestamp") from exc
    if when.tzinfo is None or when.utcoffset() is None:
        raise ValueError(label + " requires an explicit timezone")
    if when.astimezone(dt.timezone.utc) <= dt.datetime.now(dt.timezone.utc):
        raise ValueError(label + " must be in the future")
    return when.astimezone(dt.timezone.utc).isoformat(timespec="seconds")

def sources(value):
    if not isinstance(value, list) or not 1 <= len(value) <= 8:
        raise ValueError("source_urls must contain 1..8 public source URLs")
    result = []
    for url in value:
        if not isinstance(url, str) or len(url) > 500 or not safe_public_url(url):
            raise ValueError("Only valid public HTTP(S) source URLs are accepted")
        result.append(url)
    return result

def execute(data):
    if not isinstance(data, dict):
        raise ValueError("Expected request object")
    op = data.get("operation")
    if not isinstance(op, str) or op not in OPERATIONS:
        raise ValueError("Unsupported queue operation")
    keys, runner = OPERATIONS[op]
    if set(data) - keys:
        raise ValueError("Unsupported queue fields")
    with LOCK:
        params = {}
        if op == "list":
            state = data.get("state")
            if state is not None and state not in governor.ALLOWED_STATES:
                raise ValueError("Unsupported state filter")
            params["state"] = state
        else:
            params["id"] = post_id(data)
        if op == "create":
            params.update(
                persona=limited_text(data.get("persona_id"), "persona_id", 80),
                platform=limited_text(data.get("platform"), "platform", 40),
                account=limited_text(data.get("account_id"), "account_id", 100),
                audience=limited_text(data.get("audience"), "audience", 200),
                text=limited_text(data.get("text"), "text", 1800),
                source=sources(data.get("source_urls")),
                publish_at=utc_future(data.get("proposed_publish_at"), "proposed_publish_at"),
            )
        elif op == "edit":
            if not any(k in data for k in ("text", "source_urls", "proposed_publish_at")):
                raise ValueError("No draft changes supplied")
            params.update(
                text=limited_text(data["text"], "text", 1800) if "text" in data else None,
                source=sources(data["source_urls"]) if "source_urls" in data else None,
                publish_at=utc_future(data["proposed_publish_at"], "proposed_publish_at")
                if "proposed_publish_at" in data else None,
            )
        elif op == "approve":
            expected_hash = limited_text(data.get("content_hash"), "content_hash", 64)
            if len(expected_hash) != 64 or any(ch not in "0123456789abcdef" for ch in expected_hash):
                raise ValueError("Expected SHA-256 content hash")
            expected_account = limited_text(data.get("account_id"), "account_id", 100)
            expected_platform = limited_text(data.get("platform"), "platform", 40)
            current = governor.require_post(governor.load(), params["id"])
            actual_hash = governor.digest(governor.content_payload(current))
            if (current.get("content_hash") != actual_hash
                or expected_hash != actual_hash or expected_account != current.get("account_id")
                or expected_platform != current.get("platform")):
                raise ValueError("Post changed: reload current draft before approval")
            action = data.get("action")
            if action not in ("PREPARE_SCHEDULE", "HUMAN_SUBMIT"):
                raise ValueError("Exact approval action required")
            params.update(
                reviewer=limited_text(data.get("reviewer"), "reviewer", 100),
                action=action,
                expires_at=utc_future(data.get("expires_at"), "expires_at"),
                note=limited_text(data.get("note", ""), "note", 400, required=False),
            )
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            runner(Namespace(**params))
        result = json.loads(output.getvalue())
        return {"status": "PASS", "operation": op, "result": result,
                "external_social_action": "NOT_PERFORMED",
                "data_scope": "LOCAL_OWNER_QUEUE"}
