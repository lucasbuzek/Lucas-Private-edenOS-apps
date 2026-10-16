"""Read-only MobileCLI/mobilecli WebSocket event adapter (post-auth caller only).

Processes caller-supplied server events; does not connect to a daemon, approve tools,
start PTYs, or authenticate clients. No session IDs or terminal text leave this module.
"""

CLI_TYPES = frozenset(("claude", "codex", "gemini", "opencode", "terminal"))
WAIT_TYPES = frozenset(("tool_approval", "plan_approval", "clarifying_question", "awaiting_response"))


def summarize_sessions(event):
    """Summarize ServerMessage::Sessions from MobileCLI's Rust protocol."""
    if not isinstance(event, dict) or event.get("type") != "sessions":
        raise ValueError("expected MobileCLI sessions event")
    sessions = event.get("sessions")
    if not isinstance(sessions, list) or len(sessions) > 100:
        raise ValueError("invalid sessions collection")
    cli_counts = {name: 0 for name in sorted(CLI_TYPES)}
    for session in sessions:
        if not isinstance(session, dict):
            raise ValueError("invalid session")
        cli_type = session.get("cli_type")
        if cli_type not in CLI_TYPES:
            raise ValueError("invalid CLI type")
        cli_counts[cli_type] += 1
    return {"schema": "bifrost.candidate.mobilecli.v1", "enabled": False,
            "observation": "unverified", "sessions": len(sessions), "cli_counts": cli_counts}


def observe_wait_state(event):
    """Report wait reason only; never equate an event with an approved action."""
    if not isinstance(event, dict) or event.get("type") != "waiting_for_input":
        raise ValueError("expected MobileCLI wait event")
    reason, cli_type = event.get("wait_type"), event.get("cli_type")
    if reason not in WAIT_TYPES or cli_type not in CLI_TYPES:
        raise ValueError("unrecognized wait state")
    return {"schema": "bifrost.candidate.mobilecli.v1", "enabled": False,
            "reason": reason, "cli_type": cli_type, "needs_attention": True,
            "authorization": "none", "execution_status": "unknown"}
