import json,sys,pathlib
root=pathlib.Path(__file__).resolve().parent
c=json.loads((root/'contracts/SWAYHumanoid-v1.json').read_text())
assert c['contract']=='SWAYHumanoid-v1' and len(c['joints'])==23
assert len(c['joints'])==len(set(c['joints']))
print('PASS SWAYHumanoid-v1:',len(c['joints']),'unique joints; proof clips:',','.join(c['requiredAnimations']))
