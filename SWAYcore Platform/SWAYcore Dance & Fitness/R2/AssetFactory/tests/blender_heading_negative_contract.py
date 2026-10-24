"""Expected rejection of the retained candidate that never turned in 3D."""
import bpy
import contextlib
import io
import json
import pathlib
import runpy
import sys
import tempfile
root = pathlib.Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='sway-heading-negative-') as directory:
    report = pathlib.Path(directory) / 'motion.json'
    sys.argv = ['blender','--','--clips',str(root/'AssetFactory/data/clip_manifest.json'),
                '--map',str(root/'AssetFactory/data/retarget_map_girush.json'),'--report',str(report)]
    with contextlib.redirect_stdout(io.StringIO()):
        try:
            runpy.run_path(str(root/'AssetFactory/blender/sway_inspect_motion.py'),run_name='__main__')
        except SystemExit as failure:
            assert failure.code == 1
        else:
            raise AssertionError('No-turn candidate incorrectly accepted')
    result = json.loads(report.read_text())
    assert result['canonicalPoseRegression'] == 'FAIL'
    assert any('authored heading differs' in issue for issue in result['poseIssues'])
print('[NEGATIVE FIXTURE / EXPECTED REJECTION] retained no-turn candidate rejected by heading gate: PASS')
