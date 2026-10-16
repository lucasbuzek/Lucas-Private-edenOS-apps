"""Untrusted iMessage transport acknowledgement. Not an authorization source."""

import hmac
import re

CHALLENGE_RE = re.compile(r"[A-Z0-9]{8,16}\\Z")


def observe_reply(message, challenge):
    """Match a displayed challenge but NEVER grant capability or execute."""
    if not isinstance(message, dict) or not isinstance(challenge, str):
        raise ValueError("invalid reply")
    if not CHALLENGE_RE.fullmatch(challenge):
        raise ValueError("invalid challenge format")
    text = message.get("text")
    if not isinstance(text, str) or len(text) > 128:
        raise ValueError("invalid message text")
    # Caller must independently authenticate subject, device and action.
    matched = hmac.compare_digest(text.strip().encode("utf-8"), challenge.encode("ascii"))
    return {"schema": "bifrost.candidate.imessage.v1", "matched_untrusted": matched,
            "authorization": "none", "enabled": False}
