import json,sys
from pathlib import Path
r=Path(sys.argv[1]); L=lambda p:json.loads((r/p).read_text())
apps=L('platform/app-registry.json')['apps']; js=(r/'shell/eden.js').read_text(); html=(r/'shell/index.html').read_text()
assert len(apps)>=10
assert all(a['surface'] in js for a in apps)
assert not any(a['name'].lower()=='heimdall' for a in apps)
p=L('platform/profiles.json'); assert p['experience_depth']['default']=='full'; assert p['areas']['composable']; assert p['roaming']['rule'].startswith('Logical workspace roams')
prov=L('platform/provider-model.json'); assert prov['hard_rule'].startswith('INTEGRATE BEFORE IMPLEMENT')
ux=L('platform/ux-principles.json'); assert any('dignity' in x.lower() for x in ux['principles'])
ue=L('platform/user-environment.json'); assert ue['identity_data_state_separation']
assert 'data-depth' in js and 'data-area' in js and 'Search' in js and 'Control Center' in js
print('PASS v1.7 integrated experience contracts')
print('PASS app surfaces',len(apps))
print('PASS HEIMDALL externalized from runtime app registry')
print('PASS experience depth + composable Areas + roaming model')
print('PASS integration-first provider model')
portal=L('platform/web-portal-integration.json'); assert portal['testing']['network_downloads_required'] is False
bp=L('platform/build-parameters.json'); assert bp['shell_default']=='desktop' and bp['files_default']=='files'
assert bp['portal_testing'].startswith('preview-only')
assert 'Desktop' in html and 'Workspace' in html and 'Explore' in js
assert any(a['name']=='SKALD' and a.get('portal_capable') for a in apps)
assert sum(1 for a in apps if a.get('portal_capable')) >= 9
print('PASS v2.0 Desktop/Workspace + Files/Explore baseline')
print('PASS v2.0 hybrid portal application contract')
print('PASS v2.0 preview-only provider policy')
