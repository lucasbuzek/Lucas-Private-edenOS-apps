#!/usr/bin/env python3
"""Register an acquired external asset in the provenance ledger. This is the ONLY way an external model/animation becomes ADAPT/ADOPT.
It records sha256 of every file and of the archived licence text, and REQUIRES the human to assert the rights explicitly.
  register_source.py --id quaternius-ubc --files AssetFactory/sources/UBC.glb --licence-file AssetFactory/sources/UBC_LICENSE.txt \
      --decision ADAPT --confirm-commercial --confirm-modification --confirm-redistribution --confirm-app-distribution --retrieved 2026-10-04
Refuses if the licence id is not on the allowlist or any right is unconfirmed."""
import argparse, json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import provenance as pv
ap = argparse.ArgumentParser(); ap.add_argument("--id", required=True); ap.add_argument("--files", nargs="+", required=True)
ap.add_argument("--licence-file", required=True); ap.add_argument("--licence-id", default="CC0-1.0"); ap.add_argument("--decision", default="ADAPT")
ap.add_argument("--retrieved", required=True)
for r in pv.RIGHTS: ap.add_argument("--confirm-" + r.replace("_", "-"), action="store_true")
a = ap.parse_args()
root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
lp = os.path.join(root, "AssetFactory", "PROVENANCE", "ledger.json")
with open(lp) as fh: ledger = json.load(fh)
e = next((x for x in ledger["sources"] if x["id"] == a.id), None)
if not e: sys.exit("unknown ledger id " + a.id)
rights = {r: getattr(a, "confirm_" + r) for r in pv.RIGHTS}
files = []
for f in a.files:
    p = os.path.abspath(f)
    if not os.path.isfile(p): sys.exit("file not found: " + f)
    files.append({"path": os.path.relpath(p, root), "sha256": pv.sha256_file(p)})
e.update({"licence_id": a.licence_id, "decision": a.decision, "retrieved": a.retrieved, "files": files, "rights": rights, "status": "ACQUIRED",
          "licence_text_path": os.path.relpath(os.path.abspath(a.licence_file), root), "licence_text_sha256": pv.sha256_file(a.licence_file)})
errs = pv.validate_entry(e, root, require_files=True)
if errs: sys.exit("REFUSED: " + "; ".join(errs))
with open(lp, "w") as fh: json.dump(ledger, fh, indent=2)
print("registered %s as %s (%d files)" % (a.id, a.decision, len(files)))
