import json, os
ROOT=os.path.dirname(os.path.dirname(__file__))
required=[
 "README.txt","CHANGELOG.txt","docs/01_ECOSYSTEM_INVENTORY.txt",
 "docs/21_RECENT_CONVERSATION_CANON_UPDATE.txt",
 "docs/22_APPDEV_RULES.txt","specs/PROJECT_MANIFEST.example.json"
]
missing=[x for x in required if not os.path.exists(os.path.join(ROOT,x))]
m=json.load(open(os.path.join(ROOT,"specs/PROJECT_MANIFEST.example.json"),encoding="utf-8"))
assert m["schema_version"]=="0.2"
assert "IMPLEMENT_INTEGRATE_BEFORE_RECREATE" in m["principles"]
assert not missing, missing
print("LUCAS/LCAS Ecosystem v0.2 package structure: PASS")
