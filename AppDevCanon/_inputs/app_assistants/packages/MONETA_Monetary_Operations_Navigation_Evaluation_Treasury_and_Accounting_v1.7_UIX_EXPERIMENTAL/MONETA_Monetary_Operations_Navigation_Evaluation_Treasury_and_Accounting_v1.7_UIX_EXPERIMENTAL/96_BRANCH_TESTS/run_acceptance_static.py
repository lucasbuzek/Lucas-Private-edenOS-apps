from pathlib import Path
import json, sys
root=Path(__file__).resolve().parents[1]
reg=json.loads((root/"10_SHARED/MONETA_v1.1_CAPABILITY_REGISTRY.json").read_text())
bc=json.loads((root/"10_SHARED/MONETA_v1.2_BRANCH_CONTRACT.json").read_text())
results=[]
def add(t,status,evidence): results.append((t,status,evidence))

companies=reg["companies"]
ids=[c["id"] for c in companies]; names=[c["name"] for c in companies]
add("T01","PASS" if len(ids)==len(set(ids))==9 and len(names)==len(set(names))==9 else "FAIL",
    f"company IDs={len(ids)}, unique={len(set(ids))}; names={len(names)}, unique={len(set(names))}")
aliases=reg.get("legacy_aliases",{})
current_files=list((root/"20_COMPANIES").glob("*.txt"))+list((root/"30_SUBORDINATES").glob("*/*.txt"))
scribe_current=[str(p.relative_to(root)) for p in current_files if "SCRIBE" in p.name.upper()]
add("T02","PASS" if aliases.get("SCRIBE")=="NUNTIUS" and not scribe_current and "NUNTIUS" in names else "FAIL",
    f"alias={aliases.get('SCRIBE')}; current SCRIBE files={scribe_current}; NUNTIUS current={'NUNTIUS' in names}")
subs=reg["subordinates"]
bad_parent=[s["capability_id"] for s in subs if s["company"] not in names]
top_collision=[s["capability_id"] for s in subs if s["capability_id"].split(".")[-1].upper() in names]
add("T03","PASS" if not bad_parent and not top_collision else "FAIL",
    f"subordinates={len(subs)}; invalid parents={bad_parent}; top-level collisions={top_collision}")
add("T04","NOT_RUN","Requires behavioral context-inheritance harness.")
add("T05","NOT_RUN","Requires executable cross-company handoff/provenance implementation.")
add("T06","NOT_RUN","Requires executable authorization/side-effect policy implementation.")
# T07: executable B1 router currently emits PROPOSED and no execution.
router=(root/"90_BRANCHES/B1_WEB/src/router.mjs").read_text()
add("T07","PASS" if 'status:"PROPOSED"' in router and 'VERIFIED' not in router else "FAIL",
    "Inspected executable B1 router truth-state output.")
branches=set(bc.get("branches",{}))
invariants=" ".join(bc.get("invariants",[])).lower()
add("T08","PASS" if branches=={"B0","B1","B2"} and "branch-independent capability_id" in invariants else "FAIL",
    f"branches={sorted(branches)}; branch-independent capability invariant present={'branch-independent capability_id' in invariants}")
profiles=bc.get("provider_profiles",[])
add("T09","PASS" if "provider is not capability owner" in invariants and len(profiles)>=2 else "FAIL",
    f"provider profiles={profiles}; ownership invariant={'provider is not capability owner' in invariants}")
add("T10","NOT_RUN","Requires cross-project capability/ownership comparison against authoritative CHRONOS/ORACLE/BIFROST/CONDUCTOR/LCAS registries.")
add("T11","NOT_RUN","Requires behavioral consolidation-routing test.")
add("T12","NOT_RUN","Requires behavioral reporting-integrity test with verified source figures.")
for t,s,e in results: print(f"{t}\t{s}\t{e}")
fail=any(s=="FAIL" for _,s,_ in results)
sys.exit(1 if fail else 0)
