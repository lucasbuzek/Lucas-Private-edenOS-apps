import json, re, os
def _norm(n): return re.sub(r"[^a-z0-9]", "", re.sub(r"(?i)[._]([lr])$", lambda m: "_" + m.group(1).lower(), n).lower())
def _norm_side(n):
    s = n.strip()
    m = re.search(r"(?i)[._\-]([lr])$", s)
    side = m.group(1).lower() if m else ""
    base = re.sub(r"(?i)[._\-]([lr])$", "", s) if m else s
    return re.sub(r"[^a-z0-9]", "", base.lower()) + ("_" + side if side else "")
def load_map(path):
    with open(path) as fh: return json.load(fh)
def resolve(source_bones, mapping):
    """Returns (joint->source bone name, missing list). Case-insensitive, suffix tolerant. Never guesses."""
    by_norm = {}
    for b in source_bones: by_norm.setdefault(_norm_side(b), b)
    out, missing = {}, []
    for joint, aliases in mapping["map"].items():
        hit = next((by_norm[_norm_side(a)] for a in aliases if _norm_side(a) in by_norm), None)
        if hit: out[joint] = hit
        else: missing.append(joint)
    return out, missing
