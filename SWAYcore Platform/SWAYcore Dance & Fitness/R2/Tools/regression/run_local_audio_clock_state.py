#!/usr/bin/env python3
"""Exact local native-time adapter with controlled render-time doubles; not audio PASS."""
import os, subprocess, tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
s=(ROOT/'App/SWAY/Services/NativeCapabilities.swift').read_text().split('final class SwayLocalAudioPlayer:ObservableObject {',1)[1]
if 'var currentTime:TimeInterval {' not in s:raise SystemExit('FAIL: local currentTime is a constant published value without native render-time adapter')
def block(marker):
 a=s.index(marker);b=s.index('{',a);depth=1;e=b+1
 while depth:
  depth+=(s[e]=='{')-(s[e]=='}');e+=1
 return s[a:e]
fixture="""import Foundation
struct AudioTime {var sampleTime:Int64;var sampleRate:Double}
final class Node {
 var lastRenderTime:AudioTime?=AudioTime(sampleTime:0,sampleRate:44100)
 var position:AudioTime?=AudioTime(sampleTime:22050,sampleRate:44100)
 func playerTime(forNodeTime:AudioTime)->AudioTime? {position}
 func pause() {}
}
final class Local {
 var heldTime:TimeInterval=0,duration:TimeInterval=3;var isPlaying=true;let node=Node()
"""+block('var currentTime:TimeInterval {')+'\n'+block('func pause()')+"""
}
let local=Local();precondition(abs(local.currentTime-0.5)<0.000001)
local.pause();local.node.position=AudioTime(sampleTime:44100,sampleRate:44100)
precondition(abs(local.currentTime-0.5)<0.000001,"pause must hold native position")
local.isPlaying=true;local.node.position=nil
precondition(abs(local.currentTime-0.5)<0.000001,"missing render time must hold last sample")
local.node.position=AudioTime(sampleTime:44100,sampleRate:0)
precondition(abs(local.currentTime-0.5)<0.000001,"invalid sample rate cannot advance clock")
print("LOCAL_AUDIO_CLOCK_STATE PASS (exact adapter; controlled render-time doubles)")
"""
with tempfile.TemporaryDirectory(prefix='sway-local-clock-') as f:
 f=Path(f);(f/'main.swift').write_text(fixture);env=dict(os.environ);env['CLANG_MODULE_CACHE_PATH']=str(f/'cache')
 subprocess.run(['swiftc',str(f/'main.swift'),'-o',str(f/'sample')],check=True,env=env)
 subprocess.run([str(f/'sample')],check=True)
