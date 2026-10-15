import sys, tempfile
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]/"src"))
from themis.store import ThemisStore, KINDS

with tempfile.TemporaryDirectory() as td:
    db=Path(td)/"themis.json"; s=ThemisStore(db)
    ids=[]
    for k in sorted(KINDS):
        r=s.add(k, f"test-{k}", {"status":"test"}, {"source":"self-test"})
        assert s.get(r["id"])["kind"]==k; ids.append(r["id"])
    assert len(s.list())==len(KINDS)
    snap=s.snapshot("known-good", set_lkg=True)
    s.update(ids[0], {"changed":True})
    s.rollback_lkg()
    assert "changed" not in s.get(ids[0])["fields"]
print("PASS: THEMIS domain store + all supported record kinds + snapshot/LKG/rollback")
