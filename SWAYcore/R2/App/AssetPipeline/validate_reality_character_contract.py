import json, pathlib, sys
root=pathlib.Path(__file__).resolve().parents[1]
contract=json.loads((root/'AssetPipeline/contracts/SWAYHumanoid-v1.json').read_text())
required=set(contract['requiredAnimations'])
renderer=(root/'SWAY/Avatar/SWAYAvatarRendering.swift').read_text()
generator=(root/'AssetPipeline/blender/generate_sway_alpha_character.py').read_text()
assert 'manifest.runtimeApproved == true' in renderer, 'RealityKit assets must pass explicit production approval'
assert '["usdz", "reality"]' in renderer, 'RealityKit must not load unverified USD interchange previews'
assert 'SwayCoachPoseEngine.canonicalMoveID(moveID)' in renderer and 'manifest.animations[canonical]' in renderer, 'RealityKit must only receive moves with authored manifest clips'
assert 'SWAYProceduralAvatarView' not in renderer, 'primitive mannequin renderer must not remain in consumer avatar code'
for rel in ['SWAY/Views/HomeView.swift','SWAY/Views/MoveLibraryView.swift','SWAY/Views/CreateMoveView.swift','SWAY/Views/WorkoutPlayerView.swift']:
    assert 'SWAYCoachAvatarView' in (root/rel).read_text(), f'{rel}: consumer COACH views must share the approved runtime/illustrated route'
assert 'SWAYSkeletal2DAvatarView(role:.coach' in renderer, 'shared COACH route must retain the illustrated fallback'
assert 'bpy.ops.uv.smart_project' in generator and 'SWAYUV' in generator, 'Blender export must include a real UV map'
assert 'BSDF_PRINCIPLED' in generator, 'Blender export must include a PBR material with texture input slots'
assert 'set(mesh.vertex_groups.keys())==required_bones' in generator, 'Blender mesh must be weighted to the common rig'
for rel in ['SWAY/Resources/Characters/Lucia/lucia.character.json','SWAY/Resources/Characters/UserAvatar/user.character.json']:
    p=root/rel; m=json.loads(p.read_text())
    assert m['skeletonContract']==contract['contract'], f'{rel}: wrong skeleton contract'
    resources={v['resource'] for v in m['animations'].values()}
    missing=required-resources
    assert not missing, f'{rel}: missing required clips {sorted(missing)}'
    assert m['renderer']=='realitykit', f'{rel}: renderer must be realitykit'
    if m.get('runtimeApproved'):
        name=m['assetBaseName']
        assert any((root/'SWAY/Resources/Characters').rglob(name+'.'+ext) for ext in ('usdz','reality')), f'{rel}: approved runtime asset is missing'
    else:
        assert m.get('runtimeApproved') is False, f'{rel}: production approval must be explicit'
    print('PASS',m['characterID'],len(resources),'RealityKit animation bindings')
print('PASS Lucia and YOUR DANCER share',contract['contract'],'; generated assets remain unapproved until visual production acceptance')
