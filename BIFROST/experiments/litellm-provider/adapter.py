"""Read-only LiteLLM/OpenAI-compatible GET /models response adapter."""

import re

MODEL_RE = re.compile(r"[A-Za-z0-9][A-Za-z0-9._:/+-]{0,127}\Z")


def summarize_models(response):
    if not isinstance(response, dict) or not isinstance(response.get("data"), list):
        raise ValueError("model list response invalid")
    entries = response["data"]
    if len(entries) > 1000:
        raise ValueError("too many models")
    models = set()
    for item in entries:
        if not isinstance(item, dict):
            raise ValueError("invalid model entry")
        model_id = item.get("id")
        if not isinstance(model_id, str) or not MODEL_RE.fullmatch(model_id):
            raise ValueError("invalid model identifier")
        models.add(model_id)
    return {"schema": "bifrost.candidate.litellm.v1", "enabled": False,
            "available_models": sorted(models), "pricing": "unknown", "credentials": "not-accessed"}
