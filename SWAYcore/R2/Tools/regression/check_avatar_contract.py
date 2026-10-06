#!/usr/bin/env python3
import pathlib,subprocess,tempfile
root=pathlib.Path(__file__).resolve().parents[2]
s=(root/'App/SWAY/Avatar/SWAYAvatarRendering.swift').read_text()
# Compile the manifest/registry/resource boundary without pulling in the
# UIKit/RealityKit appearance implementation that follows it.
s=s[s.index('struct SWAYAvatarMoveBinding:'):s.index('struct SWAYResolvedCharacterAppearance:')]
with tempfile.TemporaryDirectory(prefix='sway-avatar-contract-',dir='/private/tmp') as tmp:
 tmp=pathlib.Path(tmp);(tmp/'Manifest.swift').write_text('import Foundation\n'+s)
 subprocess.run(['swiftc','-module-cache-path',str(tmp/'cache'),str(tmp/'Manifest.swift'),str(root/'Tools/regression/avatar_contract_regression.swift'),'-o',str(tmp/'test')],check=True)
 subprocess.run([str(tmp/'test')],check=True)
