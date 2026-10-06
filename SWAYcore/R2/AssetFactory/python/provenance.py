"""Provenance + licence gate for external models/animations. Unknown or unapproved licence => REJECT (mandate: unknown licensing means do not incorporate).
A source entry (AssetFactory/PROVENANCE/ledger.json) must carry: id, name, url, licence_id, licence_text_sha256 (of the saved licence file), retrieved (ISO date),
files[{path, sha256}], decision in {ADOPT, ADAPT, REFERENCE, REJECT}, rights{commercial, modification, redistribution, app_distribution}."""
import hashlib, json, os

ALLOWED_LICENCES = {"CC0-1.0"}                 # allowlist; add only after legal review is recorded in the ledger
DECISIONS = {"ADOPT", "ADAPT", "REFERENCE", "REJECT"}
RIGHTS = ["commercial", "modification", "redistribution", "app_distribution"]

def sha256_file(p):
    h = hashlib.sha256()
    with open(p, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""): h.update(chunk)
    return h.hexdigest()

def validate_entry(e, root=None, require_files=False):
    errs = []
    for k in ("id", "name", "url", "licence_id", "decision"):
        if not e.get(k): errs.append("missing " + k)
    if "rights" not in e: errs.append("missing rights")
    if e.get("decision") not in DECISIONS: errs.append("bad decision %r" % e.get("decision"))
    incorporated = e.get("decision") in ("ADOPT", "ADAPT")
    if incorporated:
        if e.get("licence_id") not in ALLOWED_LICENCES: errs.append("licence %r not in allowlist; cannot incorporate" % e.get("licence_id"))
        r = e.get("rights") or {}
        for k in RIGHTS:
            if r.get(k) is not True: errs.append("right %s not confirmed" % k)
        if not e.get("retrieved"): errs.append("missing retrieved date")
        if not e.get("licence_text_sha256"): errs.append("licence text not archived (licence_text_sha256)")
        if require_files:
            if not e.get("files"): errs.append("no files recorded")
            for f in e.get("files", []):
                p = os.path.join(root or ".", f["path"])
                if not os.path.isfile(p): errs.append("file missing: " + f["path"])
                elif sha256_file(p) != f.get("sha256"): errs.append("sha256 mismatch: " + f["path"])
    return errs

def validate_ledger(path, root=None, require_files=False):
    with open(path) as fh: d = json.load(fh)
    out = {}
    for e in d.get("sources", []): out[e.get("id", "?")] = validate_entry(e, root, require_files)
    return out
