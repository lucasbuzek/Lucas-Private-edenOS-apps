#!/usr/bin/env python3
"""Compile actual shared Swift pose and compare all Alpha joints/heading to its bake port."""
import json
import pathlib
import subprocess
import sys
import tempfile
root = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(root / 'AssetFactory/python'))
import coach_pose_port as cp
path = root / 'App/SWAY/Views/StickFigureView.swift'
source = path.read_text()
pose = source[source.index('struct SwayCoachPose {'):source.index('/// Display-refresh-driven COACH renderer.')]
with tempfile.TemporaryDirectory(prefix='sway-pose-port-', dir='/private/tmp') as directory:
    temporary = pathlib.Path(directory)
    (temporary / 'Pose.swift').write_text('import Foundation\n' + pose)
    moves = json.dumps(cp.AUTHORED)
    properties = ','.join('p.' + joint for joint in cp.JOINTS)
    main = '''import Foundation
var rows:[[String:Any]]=[]
for move in MOVES { for bpm in [20.0, 60.0, 97.0, 120.0, 180.0] { for frame in 0...96 {
 let t=Double(frame)/12*60/bpm
 let p=SwayCoachPoseEngine.pose(moveID:move,musicalTime:t,bpm:bpm)
 let points:[CGPoint]=[PROPERTIES]
 rows.append(["move":move,"bpm":bpm,"time":t,"points":points.map{[Double($0.x),Double($0.y)]},"heading":p.bodyYaw])
}}}
let data=try JSONSerialization.data(withJSONObject:rows)
print(String(data:data,encoding:.utf8)!)
'''.replace('MOVES', moves).replace('PROPERTIES', properties)
    (temporary / 'main.swift').write_text(main)
    timeline = root / 'Packages/SWAYcoreEngine/Sources/SWAYcoreEngine/SwayTimelineMath.swift'
    binary = temporary / 'pose'
    subprocess.run(['swiftc', '-module-cache-path', str(temporary / 'cache'), str(timeline),
                    str(temporary / 'Pose.swift'), str(temporary / 'main.swift'), '-o', str(binary)], check=True)
    rows = json.loads(subprocess.check_output([str(binary)], text=True))
    assert len(rows) == len(cp.AUTHORED) * 5 * 97, 'Missing pose samples'
    worst = 0
    for row in rows:
        expected = cp.pose(row['move'], row['time'], row['bpm'])
        for joint, point in zip(cp.JOINTS, row['points']):
            worst = max(worst, *(abs(a-b) for a,b in zip(point,expected[joint])))
        worst = max(worst, abs(row['heading']-cp.heading(row['move'],row['time'],row['bpm'])))
    assert worst < 1e-10, 'Swift/Python pose drift: ' + str(worst)
    cp.assert_in_sync(str(path))
    print('ACTUAL_SWIFT_POSE_PORT PASS: ' + str(len(rows)) + ' samples, all 13 joints plus heading, max error ' + str(worst))
