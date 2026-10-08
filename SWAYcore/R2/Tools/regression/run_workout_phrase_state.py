#!/usr/bin/env python3
"""Run exact production beat handler with controlled session/store doubles.
Verifies missed-beat cursor behavior; not UI, workout scoring or physical PASS.
"""
import os
from pathlib import Path
import subprocess
import tempfile
ROOT=Path(__file__).resolve().parents[2]
source=(ROOT/'App/SWAY/Views/WorkoutPlayerView.swift').read_text()
start=source.index('func handleBeat(_ beat:Int)');opening=source.index('{',start)
depth=1;end=opening+1
while depth:
    depth+=(source[end]=='{')-(source[end]=='}');end+=1
handler=source[start:end]
start=source.index('func restartMovement()');opening=source.index('{',start);depth=1;end=opening+1
while depth:
    depth+=(source[end]=='{')-(source[end]=='}');end+=1
restart=source[start:end]
start=source.index('@MainActor func prepareSession()');opening=source.index('{',start);depth=1;end=opening+1
while depth:
    depth+=(source[end]=='{')-(source[end]=='}');end+=1
prepare=source[start:end]
fixture='''import Foundation
final class Store {func haptic() {}}
final class Cues {func beat(count:Int,phraseStart:Bool) {}}
final class Timeline {
 var count=1,bar=0;var running=true;var elapsed:Double=5.375
 var currentMovePhraseStartTransportTime:Double=4
 func stop(){running=false}
 func pause(){running=false}
 func start(bpm:Double,beatGrid:Double?,songPosition:Double,timeSource:()->Double){elapsed=songPosition;running=true}
}
final class Music {
 var bpm:Double=120;var analyzedBeatGrid:Double?;var authoritativePlaybackPosition:Double=5.375
 func seek(to seconds:Double){authoritativePlaybackPosition=seconds}
 var isPlaying=true
 func pause(){isPlaying=false}
}
@MainActor final class Session {
 var sessionBeginning=false,startWithTracking=false,showCameraSetup=false
 var countdownEnteredWithAudio=false
 func beginWorkout() async {countdownEnteredWithAudio=music.isPlaying}
 var started=true,paused=false,lastHandledBeat = -1,performedMoves=0,index=0
 var activeSeconds:Double=0;var minutes=20;var trackingThisWorkout=false
 var adaptationMessage="";var activeSteps=[0,1,2,3]
 let store=Store(),cues=Cues(),timeline=Timeline(),music=Music()
 enum Outcome {case completed}
 func finish(outcome:Outcome) {}
 func publishSession() {}
'''+handler+'\n'+restart+'\n'+prepare+'''
}
var failures=0
func equal(_ actual:Int,_ expected:Int,_ name:String) {
 if actual != expected {print("FAIL: \\(name): \\(actual) != \\(expected)");failures+=1}
}
let session=Session()
session.handleBeat(7);session.handleBeat(9)
equal(session.index,1,"missed beat 8 still advances move")
equal(session.performedMoves,1,"one elapsed eight-count retained")
session.handleBeat(25)
equal(session.index,3,"multiple skipped boundaries retain move cursor")
equal(session.performedMoves,3,"three elapsed eight-counts retained")
session.handleBeat(25)
equal(session.performedMoves,3,"duplicate beat cannot double-credit phrase")
let midSong=Session();midSong.handleBeat(16)
equal(midSong.performedMoves,0,"starting at song boundary is not a performed move")
let restartSession=Session();restartSession.restartMovement()
equal(Int(restartSession.music.authoritativePlaybackPosition*1000),4000,"restart seeks native music to phrase anchor")
equal(Int(restartSession.timeline.elapsed*1000),4000,"restart movement derives from seeked audio")
let pausedRestart=Session();pausedRestart.paused=true;pausedRestart.restartMovement()
equal(pausedRestart.timeline.running ? 1:0,0,"restart retains paused state")
let followAlong=Session();await followAlong.prepareSession()
equal(followAlong.countdownEnteredWithAudio ? 1:0,0,"preview audio is held before follow-along countdown")
let tracking=Session();tracking.startWithTracking=true;await tracking.prepareSession()
equal(tracking.music.isPlaying ? 1:0,0,"preview audio is held during calibration")
equal(tracking.timeline.running ? 1:0,0,"calibration has no active movement clock")
print("WORKOUT_PHRASE_STATE",failures==0 ? "PASS":"FAIL","(exact production handler; controlled doubles, not integrated workout)")
exit(failures==0 ? 0:1)
'''
with tempfile.TemporaryDirectory(prefix='sway-workout-state-') as folder:
    folder=Path(folder);swift=folder/'main.swift';swift.write_text(fixture)
    env=dict(os.environ);env['CLANG_MODULE_CACHE_PATH']=str(folder/'module-cache')
    subprocess.run(['swiftc',str(swift),'-o',str(folder/'sample')],check=True,env=env)
    subprocess.run([str(folder/'sample')],check=True)
