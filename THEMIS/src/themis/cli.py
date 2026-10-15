import argparse, json
from .store import ThemisStore, KINDS

def main():
    p=argparse.ArgumentParser(prog="themis")
    p.add_argument("--db", default="data/themis.json")
    sp=p.add_subparsers(dest="cmd", required=True)
    a=sp.add_parser("add"); a.add_argument("kind", choices=sorted(KINDS)); a.add_argument("title")
    a.add_argument("--fields", default="{}"); a.add_argument("--provenance", default="{}")
    l=sp.add_parser("list"); l.add_argument("--kind", choices=sorted(KINDS))
    s=sp.add_parser("snapshot"); s.add_argument("--label", default="snapshot"); s.add_argument("--lkg", action="store_true")
    sp.add_parser("rollback-lkg")
    args=p.parse_args(); st=ThemisStore(args.db)
    if args.cmd=="add":
        out=st.add(args.kind,args.title,json.loads(args.fields),json.loads(args.provenance))
    elif args.cmd=="list": out=st.list(args.kind)
    elif args.cmd=="snapshot": out=st.snapshot(args.label,args.lkg)
    else: out=st.rollback_lkg()
    print(json.dumps(out, indent=2))
if __name__=="__main__": main()
