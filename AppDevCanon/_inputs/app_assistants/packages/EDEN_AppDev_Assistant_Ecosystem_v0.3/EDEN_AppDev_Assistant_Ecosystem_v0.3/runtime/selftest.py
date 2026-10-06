from pathlib import Path
import json
R=Path(__file__).resolve().parents[1]
assert (R/'specs/assistant.schema.json').exists()
specs=list((R/'specs/assistants').glob('*.json')); assert len(specs)>=14
for p in specs:
 d=json.loads(p.read_text());
 for k in ('id','name','version','purpose','inputs','outputs','modes','handoffs','runtime'): assert k in d, (p,k)
print(f'PASS: {len(specs)} assistant specs; required fields present')
