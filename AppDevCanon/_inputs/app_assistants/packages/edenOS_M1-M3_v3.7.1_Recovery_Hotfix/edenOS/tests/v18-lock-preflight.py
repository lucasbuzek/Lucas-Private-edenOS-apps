from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
lock=(root/'docs/DP07_V18_EXPERIENCE_INTEGRATION_LOCK.txt').read_text()
assert 'Keep the proven machinery. Replace or adapt the experience. Integrate it until it feels like one system.' in lock
pm=json.loads((root/'platform/provider-model.json').read_text())
assert pm['custom_implementation_requires_reason'] is True
assert len(pm['integration_tiers'])==4
cat=json.loads((root/'platform/integration-catalog.json').read_text())
assert len(cat['capabilities'])>=10
apps=json.loads((root/'platform/app-registry.json').read_text())
blob=json.dumps(apps.get('apps',[])).lower()
assert 'heimdall' not in blob
h=json.loads((root/'platform/heimdall-core.json').read_text())
assert h['role']=='experience/UI layer' and h['engine']=='BIFROST'
print('PASS v1.8 experience integration lock')
print('PASS existing-software-first provider policy')
print('PASS integration tiers 0-3')
print('PASS HEIMDALL integrated as experience layer; not standalone runtime app')
