#!/usr/bin/env python3
"""Exercise exact production async-result admission; transport/analysis doubles only."""
import os, subprocess, tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
s=(ROOT/'App/SWAY/Services/NativeCapabilities.swift').read_text()
marker='func applyLibraryAnalysis('
if marker not in s: raise SystemExit('FAIL: library analysis has no source/generation admission guard')
a=s.index(marker);b=s.index('{',a);depth=1;e=b+1
while depth:
 depth+=(s[e]=='{')-(s[e]=='}');e+=1
method=s[a:e]
fixture="""import Foundation
struct SwayBeatGrid {var bpm:Double;var confidence:Double}
final class Engine {
 var usingLibraryTrack=true,libraryAnalysisGeneration=UUID()
 var analyzedBeatGrid:SwayBeatGrid?;var bpm:Double=120;var analysisStatus=""
"""+method+"""
}
let engine=Engine();let old=engine.libraryAnalysisGeneration
engine.libraryAnalysisGeneration=UUID()
engine.applyLibraryAnalysis(SwayBeatGrid(bpm:90,confidence:1),metadataBPM:0,generation:old)
precondition(engine.analyzedBeatGrid == nil && engine.bpm==120,"stale track analysis mutated current source")
let current=engine.libraryAnalysisGeneration;engine.usingLibraryTrack=false
engine.applyLibraryAnalysis(SwayBeatGrid(bpm:90,confidence:1),metadataBPM:0,generation:current)
precondition(engine.analyzedBeatGrid == nil && engine.bpm==120,"library result mutated offline source")
engine.usingLibraryTrack=true
engine.applyLibraryAnalysis(SwayBeatGrid(bpm:90,confidence:0.8),metadataBPM:0,generation:current)
precondition(engine.analyzedBeatGrid?.bpm==90 && engine.bpm==90,"current result was not admitted")
print("LIBRARY_ANALYSIS_STATE PASS (exact production admission; controlled doubles)")
"""
with tempfile.TemporaryDirectory(prefix='sway-analysis-state-') as f:
 f=Path(f);(f/'main.swift').write_text(fixture);env=dict(os.environ);env['CLANG_MODULE_CACHE_PATH']=str(f/'cache')
 subprocess.run(['swiftc',str(f/'main.swift'),'-o',str(f/'sample')],check=True,env=env)
 subprocess.run([str(f/'sample')],check=True)
