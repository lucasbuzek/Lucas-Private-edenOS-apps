"""Labelled intentional USD rejection fixtures; production candidate untouched."""
import contextlib
import io
import json
import os
import runpy
import shutil
import sys
import tempfile
from pathlib import Path
from pxr import Usd, UsdGeom, UsdSkel
root = Path(__file__).resolve().parents[2]
arguments = sys.argv[sys.argv.index('--') + 1:]
source = Path(arguments[arguments.index('--root') + 1]).resolve()
def check(candidate, expected):
    report = candidate / 'negative_report.json'
    sys.argv = ['blender', '--', '--root', str(candidate), '--report', str(report)]
    output = io.StringIO()
    with contextlib.redirect_stdout(output):
        try:
            runpy.run_path(str(root / 'AssetFactory/blender/sway_verify_runtime_usd.py'), run_name='__main__')
        except SystemExit as failure:
            assert failure.code == 1, 'fixture did not reject cleanly'
        else:
            raise AssertionError('corrupt fixture accepted')
    result = json.loads(report.read_text())
    assert any(expected in issue for issue in result['issues']), result['issues']
    print('[NEGATIVE FIXTURE / EXPECTED REJECTION] ' + expected + ': PASS')
with tempfile.TemporaryDirectory(prefix='sway-usd-negative-') as temporary:
    for name, expected in [('eyes', 'expected body'), ('weights', 'invalid skin arrays'), ('duration', 'cycle duration mismatch')]:
        candidate = Path(temporary) / name
        shutil.copytree(source, candidate)
        if name == 'duration':
            path = candidate / 'Animations/sway_squat_v1.usdc'
            stage = Usd.Stage.Open(str(path))
            stage.SetEndTimeCode(stage.GetEndTimeCode() + 2)
        else:
            stage = Usd.Stage.Open(str(candidate / 'LuciaReality.usdc'))
            mesh = next(p for p in stage.Traverse() if p.IsA(UsdGeom.Mesh) and ('eye_L' in str(p.GetPath()) if name == 'eyes' else 'body_' in str(p.GetPath())))
            if name == 'eyes':
                stage.RemovePrim(mesh.GetPath())
            else:
                UsdSkel.BindingAPI(mesh).GetJointWeightsPrimvar().SetElementSize(5)
        stage.GetRootLayer().Save()
        stage = None
        check(candidate, expected)
print('[NEGATIVE FIXTURES ONLY] 3/3 rejection guards PASS; no production asset FAIL claim')
