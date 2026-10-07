#!/usr/bin/env python3
import pathlib
import subprocess
import tempfile
root=pathlib.Path(__file__).resolve().parents[2]
source=(root/'App/SWAY/Services/NativeCapabilities.swift').read_text()
policy=source[source.index('enum SwayCameraFrameOrientation {'):source.index('final class CameraPoseService:')]
with tempfile.TemporaryDirectory(prefix='sway-camera-policy-') as directory:
 temporary=pathlib.Path(directory)
 path=temporary/'Policy.swift'
 path.write_text('import Foundation\nimport ImageIO\n'+policy)
 binary=temporary/'test'
 subprocess.run(['swiftc','-module-cache-path',str(temporary/'cache'),str(path),str(root/'Tools/regression/camera_orientation_regression.swift'),'-o',str(binary)],check=True)
 subprocess.run([str(binary)],check=True)
