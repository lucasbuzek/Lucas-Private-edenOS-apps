#!/usr/bin/env python3
"""Provider-independent, fail-closed helpers. No network, account access, or publishing."""
from datetime import datetime, timezone
from hashlib import sha256

VERSION = "0.1.0"

def result(helper, status, output, warnings=None, unresolved=None):
    stamp = datetime.now(timezone.utc).isoformat()
    return {"run_id": sha256((helper + stamp).encode()).hexdigest()[:16],
            "helper_id": helper, "helper_version": VERSION, "created_at": stamp,
            "status": status, "input_refs": [], "source_provenance": [],
            "warnings": warnings or [], "unresolved_questions": unresolved or [], "output": output}

def validate_persona(p):
    required = ["persona_id", "account_identity", "mission", "audience", "voice", "expertise", "editorial_scope", "evidence_policy", "publishing"]
    missing = [k for k in required if not p.get(k)]
    identity = p.get("account_identity") or {}
    if identity.get("type") not in {"person", "brand", "project", "publication"}: missing.append("account_identity.type")
    if not identity.get("public_name"): missing.append("account_identity.public_name")
    if not (p.get("audience") or {}).get("language"): missing.append("audience.language")
    if (p.get("publishing") or {}).get("auto_publish") is not False:
        return result("persona_validator", "FAIL", {"valid": False, "missing": missing}, ["auto_publish must be false by default"])
    return result("persona_validator", "FAIL" if missing else "PASS", {"valid": not missing, "missing": missing},
                  unresolved=["Complete missing fields and review account identity, scope, and permissions."] if missing else [])

def triage_topic(topic, persona):
    title = str(topic.get("title", "")).strip()
    sources = topic.get("sources") or []
    scope = persona.get("editorial_scope") or {}
    text = (title + " " + str(topic.get("summary", ""))).casefold()
    blocked = [str(x) for x in scope.get("blocklist", []) if str(x).casefold() in text]
    allow = scope.get("allowlist", [])
    unclear = bool(allow) and not any(str(x).casefold() in text for x in allow)
    status = "FAIL" if not title or blocked else "UNKNOWN" if unclear or not sources else "PASS"
    return result("topic_scout", status, {"title": title, "source_urls": [s.get("url") for s in sources if s.get("url")],
        "blocked_terms": blocked, "outside_or_unclear_scope": unclear, "discovery_performed": False, "trend_verified": False},
        ["Triage only: no live discovery performed."], ["Verify relevance and evidence."] if status == "UNKNOWN" else [])

def map_sources(topic_id, sources):
    rows, errors = [], []
    for i, src in enumerate(sources):
        row = {k: src.get(k) for k in ("url","title","publisher","published_at","event_date","source_type","supports_claims","limitations","accessed_at","independence_group")}
        if not row["url"] or not row["source_type"]: errors.append("source[%d] missing URL or source_type" % i)
        if not row["limitations"]: row["limitations"] = "NOT_RECORDED"
        rows.append(row)
    primary = any(s.get("source_type") == "primary" for s in rows)
    counter = any(s.get("source_type") in {"counterevidence","opposing"} for s in rows)
    status = "FAIL" if errors else "UNKNOWN" if not rows or not primary else "PASS"
    return result("source_cartographer", status, {"topic_id": topic_id, "sources": rows, "primary_source_present": primary,
        "counterevidence_present": counter, "source_contents_fetched": False, "independence_verified": False},
        errors + (["Sources supplied, not fetched or independently verified."] if rows else []),
        ["Verify source content and independence; add counterevidence for disputed claims."] if not counter else [])

def audit_claims(claims):
    rows, states = [], []
    for i, c in enumerate(claims):
        evidence, counter = c.get("evidence_refs") or [], c.get("counterevidence_refs") or []
        state = "PASS" if evidence and c.get("human_verified") is True else "UNKNOWN" if evidence else "FAIL"
        disposition = "INCLUDE" if state == "PASS" else "QUALIFY" if state == "UNKNOWN" else "OMIT"
        if c.get("disputed") and not counter: state, disposition = "UNKNOWN", "QUALIFY"
        rows.append({"claim_id": c.get("claim_id", "claim-%d" % (i+1)), "claim": c.get("text", ""),
            "evidence_refs": evidence, "counterevidence_refs": counter, "status": state, "disposition": disposition,
            "reason": "Evidence references are supplied inputs, not proof of truth."})
        states.append(state)
    overall = "FAIL" if "FAIL" in states else "UNKNOWN" if "UNKNOWN" in states or not states else "PASS"
    return result("claim_auditor", overall, {"claims": rows, "claims_count": len(rows)},
                  ["Human verification and source review remain required."])

def compose_draft(brief, persona):
    missing = [k for k in ("topic_id","verified_claims","audience","call_to_action") if not brief.get(k)]
    if not persona.get("persona_id"): missing.append("persona.persona_id")
    return result("draft_composer", "UNKNOWN" if missing else "PASS",
        {"persona_id": persona.get("persona_id"), "topic_id": brief.get("topic_id"), "brief": brief,
         "draft_text": None, "draft_text_generated": False, "missing_fields": missing, "approval_required": True},
        ["Prepares inputs only; does not call a model or invent post copy."])

def assess_risk(post):
    flags = [k for k in ("private_personal_information","unverified_identifiable_allegation","uncleared_copyright_asset","missing_required_disclosure") if post.get(k) is True]
    unchecked = [k for k in ("consent_checked","rights_checked","platform_policy_checked","accessibility_checked") if post.get(k) is not True]
    status = "FAIL" if flags else "UNKNOWN" if unchecked else "PASS"
    return result("risk_rights_reviewer", status, {"decision": "BLOCK" if flags else "REVIEW" if unchecked else "CLEAR_WITH_NOTES",
        "blocking_flags": flags, "unchecked": unchecked}, ["Not legal advice or platform-policy clearance."])

def format_channel(post, channel):
    text = str(post.get("text", "")); limit = channel.get("verified_character_limit")
    issues = []
    if not text.strip(): issues.append("empty_text")
    if limit is None or not channel.get("policy_checked_at"): issues.append("verified_limit_or_policy_date_missing")
    if isinstance(limit, int) and len(text) > limit: issues.append("character_limit_exceeded")
    status = "FAIL" if "character_limit_exceeded" in issues else "UNKNOWN" if issues else "PASS"
    return result("channel_formatter", status, {"text": text, "character_count": len(text),
        "verified_character_limit": limit, "policy_checked_at": channel.get("policy_checked_at"), "issues": issues, "published": False})

def propose_calendar(post, channel, approval=None):
    problems = []
    if not approval: problems.append("human_approval_missing")
    else:
        for key, expected in (("content_hash",post.get("content_hash")),("account_ref",channel.get("account_ref")),
                              ("platform",channel.get("platform")),("action","PREPARE_SCHEDULE")):
            if approval.get(key) != expected: problems.append("approval_mismatch:"+key)
    when = post.get("proposed_publish_at")
    if not when: problems.append("proposed_publish_at_missing")
    state = "FAIL" if any(x.startswith("approval_mismatch") for x in problems) else "UNKNOWN" if problems else "PASS"
    proposal = None if problems else {"post_id":post.get("post_id"),"platform":channel.get("platform"),
        "account_ref":channel.get("account_ref"),"proposed_publish_at":when}
    return result("calendar_planner", state, {"local_schedule_proposal":proposal,"external_schedule_created":False,"problems":problems})

def dispatch(helper_id, payload):
    routes = {"persona_validator":lambda p:validate_persona(p["persona"]),
        "topic_scout":lambda p:triage_topic(p["topic"],p["persona"]),
        "source_cartographer":lambda p:map_sources(p.get("topic_id","unknown"),p.get("sources",[])),
        "claim_auditor":lambda p:audit_claims(p.get("claims",[])),
        "draft_composer":lambda p:compose_draft(p["brief"],p["persona"]),
        "risk_rights_reviewer":lambda p:assess_risk(p["post"]),
        "channel_formatter":lambda p:format_channel(p["post"],p["channel"]),
        "calendar_planner":lambda p:propose_calendar(p["post"],p["channel"],p.get("approval"))}
    if helper_id not in routes: return result(helper_id,"NOT_APPLICABLE",{},["Unknown helper; no action taken."])
    try: return routes[helper_id](payload)
    except (KeyError,TypeError,ValueError) as exc:
        return result(helper_id,"FAIL",{},["Invalid input contract: %s: %s" % (type(exc).__name__,exc)])


def editorial_strategy(dossier, persona):
    """Offer safe framing options from supplied verified material; does not invent topical facts."""
    claims = dossier.get("verified_claims") or []
    topic = dossier.get("topic_title", "")
    if not topic or not claims:
        return result("editorial_strategist", "UNKNOWN", {"options": [], "topic_title": topic},
                      ["Needs a topic and verified claims before proposing a framing."],
                      ["Supply verified claims, counterarguments, audience utility and persona goals."])
    return result("editorial_strategist", "PASS", {"topic_title": topic, "persona_id": persona.get("persona_id"),
        "options": [
          {"angle":"What the evidence establishes","hook_template":"What the available evidence does—and does not—show about [topic].","tradeoff":"High clarity; less provocative."},
          {"angle":"Test a common assumption","hook_template":"A common assumption about [topic] deserves a closer look: [verified limitation].","tradeoff":"Invites discussion; requires fair representation of the opposing case."},
          {"angle":"Practical implications","hook_template":"The practical trade-off in [topic] is [verified trade-off].","tradeoff":"Useful to decision-makers; may need additional context."}],
        "claims_used": claims, "facts_invented": False, "rage_optimization": False},
        ["Templates contain placeholders and must be filled only from the evidence ledger."])

def analyze_metrics(records, goal_definitions):
    """Summarize supplied metrics only; no account retrieval or causal inference."""
    rows, warnings = [], []
    for i, row in enumerate(records):
        if not row.get("platform") or not row.get("retrieved_at") or not row.get("metric_name") or row.get("value") is None:
            warnings.append("record[%d] missing platform, retrieval date, metric name or value" % i)
        rows.append({"platform":row.get("platform"), "post_id":row.get("post_id"), "metric_name":row.get("metric_name"),
            "value":row.get("value"), "denominator":row.get("denominator"), "retrieved_at":row.get("retrieved_at"),
            "comparison_cohort":row.get("comparison_cohort"), "caveat":row.get("caveat")})
    status = "UNKNOWN" if warnings or not rows else "PASS"
    return result("metrics_analyst", status, {"records":rows, "goal_definitions":goal_definitions,
        "causal_conclusions":False, "source":"user-supplied records only"}, warnings,
        ["Provide comparable cohorts and metric definitions before interpreting differences."] if rows else ["No metrics supplied."])

# Stable dispatcher includes every currently implemented helper.
def dispatch(helper_id, payload):
    routes = {"persona_validator":lambda p:validate_persona(p["persona"]),
        "topic_scout":lambda p:triage_topic(p["topic"],p["persona"]),
        "source_cartographer":lambda p:map_sources(p.get("topic_id","unknown"),p.get("sources",[])),
        "claim_auditor":lambda p:audit_claims(p.get("claims",[])),
        "draft_composer":lambda p:compose_draft(p["brief"],p["persona"]),
        "risk_rights_reviewer":lambda p:assess_risk(p["post"]),
        "channel_formatter":lambda p:format_channel(p["post"],p["channel"]),
        "calendar_planner":lambda p:propose_calendar(p["post"],p["channel"],p.get("approval")),
        "editorial_strategist":lambda p:editorial_strategy(p["dossier"],p["persona"]),
        "metrics_analyst":lambda p:analyze_metrics(p.get("records",[]),p.get("goal_definitions",{}))}
    if helper_id not in routes: return result(helper_id,"NOT_APPLICABLE",{},["Unknown helper; no action taken."])
    try: return routes[helper_id](payload)
    except (KeyError,TypeError,ValueError) as exc:
        return result(helper_id,"FAIL",{},["Invalid input contract: %s: %s" % (type(exc).__name__,exc)])

