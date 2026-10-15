from __future__ import annotations
import json, shutil, hashlib
from pathlib import Path
from datetime import datetime, timezone
from uuid import uuid4

KINDS = {
 "matter","party","agreement","clause","obligation","jurisdiction","evidence",
 "correspondence","research","deadline","version","approval"
}

def now():
    return datetime.now(timezone.utc).isoformat()

class ThemisStore:
    def __init__(self, path):
        self.path = Path(path)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.snapdir = self.path.parent / "snapshots"
        self.snapdir.mkdir(parents=True, exist_ok=True)
        if not self.path.exists():
            self._save({"schema":1,"records":{},"events":[],"lkg":None})

    def _load(self):
        return json.loads(self.path.read_text(encoding="utf-8"))

    def _save(self, data):
        tmp = self.path.with_suffix(self.path.suffix+".tmp")
        tmp.write_text(json.dumps(data, indent=2, sort_keys=True), encoding="utf-8")
        tmp.replace(self.path)

    def add(self, kind, title, fields=None, provenance=None):
        if kind not in KINDS:
            raise ValueError("unsupported kind")
        data=self._load()
        rid=str(uuid4())
        rec={"id":rid,"kind":kind,"title":title,"fields":fields or {},
             "provenance":provenance or {}, "created_at":now(),"updated_at":now()}
        data["records"][rid]=rec
        data["events"].append({"at":now(),"action":"add","record_id":rid,"kind":kind})
        self._save(data)
        return rec

    def get(self, rid):
        return self._load()["records"].get(rid)

    def list(self, kind=None):
        vals=list(self._load()["records"].values())
        return [x for x in vals if kind is None or x["kind"]==kind]

    def update(self, rid, fields):
        data=self._load()
        rec=data["records"][rid]
        rec["fields"].update(fields)
        rec["updated_at"]=now()
        data["events"].append({"at":now(),"action":"update","record_id":rid})
        self._save(data)
        return rec

    def snapshot(self, label="snapshot", set_lkg=False):
        data=self._load()
        stamp=datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        p=self.snapdir/f"{stamp}_{label}.json"
        p.write_text(json.dumps(data, indent=2, sort_keys=True), encoding="utf-8")
        digest=hashlib.sha256(p.read_bytes()).hexdigest()
        if set_lkg:
            data["lkg"]={"path":str(p),"sha256":digest,"set_at":now()}
            data["events"].append({"at":now(),"action":"set_lkg","snapshot":str(p),"sha256":digest})
            self._save(data)
        return {"path":str(p),"sha256":digest}

    def rollback_lkg(self):
        data=self._load()
        lkg=data.get("lkg")
        if not lkg:
            raise RuntimeError("no LKG set")
        p=Path(lkg["path"])
        if hashlib.sha256(p.read_bytes()).hexdigest()!=lkg["sha256"]:
            raise RuntimeError("LKG hash mismatch")
        restored=json.loads(p.read_text(encoding="utf-8"))
        restored["lkg"]=lkg
        restored["events"].append({"at":now(),"action":"rollback_lkg","snapshot":str(p)})
        self._save(restored)
        return lkg
