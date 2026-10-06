from pathlib import Path
import json,sys
root=Path(__file__).resolve().parents[1]
b=json.loads((root/"10_SHARED/MONETA_HERMES_ORACLE_THEMIS_BOUNDARY_v1.3.json").read_text())
r=json.loads((root/"10_SHARED/MONETA_v1.3_CAPABILITY_REGISTRY.json").read_text())
res=[]
def ck(name,cond,ev): res.append((name,"PASS" if cond else "FAIL",ev))
ck("BND01",b["applications"]["MONETA"]["owns"][0]=="financial_state","MONETA financial-state ownership declared")
ck("BND02","jobs_and_opportunities" in b["applications"]["HERMES"]["owns"],"HERMES opportunity lifecycle retained")
ck("BND03","generalized_quantitative_analysis" in b["applications"]["ORACLE"]["owns"],"ORACLE generalized analytics retained")
ck("BND04","legal_semantics" in b["applications"]["THEMIS"]["owns"],"THEMIS legal semantics retained")
ids=[x["capability_id"] for x in r["subordinates"]]
ck("BND05",len(ids)==59 and len(ids)==len(set(ids)),"59 existing MONETA subordinate IDs preserved without duplication")
ck("BND06",all(x in [c["name"] for c in r["companies"]] for x in ["LEDGER","MERCURY","ALLOCATE","VAULT","MARGIN","NUNTIUS","PATRON","RECEIPT","TRIBUTE"]),"all established MONETA companies preserved")
for x in res: print("\t".join(map(str,x)))
sys.exit(1 if any(s=="FAIL" for _,s,_ in res) else 0)
