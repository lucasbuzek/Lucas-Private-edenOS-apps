#!/usr/bin/env python3
"""Typecheck the unchanged actual R2 recorder against the installed iOS SDK.
No app launch or recording claim. Isolate native API check from Xcode package/simulator services.
"""
import hashlib,json,pathlib,subprocess,tempfile
root=pathlib.Path(__file__).resolve().parents[2]
path=root/'App/SWAY/Services/NativeCapabilities.swift'
source=path.read_text();recorder=source[source.index('@MainActor\nfinal class SwayPerformanceRecorder:'):]
sdk=subprocess.check_output(['xcrun','--sdk','iphoneos','--show-sdk-path'],text=True).strip()
with tempfile.TemporaryDirectory(prefix='sway-replaykit-check-',dir='/private/tmp') as tmp:
    tmp=pathlib.Path(tmp);native=tmp/'Recorder.swift'
    native.write_text('import Foundation\nimport Combine\nimport UIKit\nimport ReplayKit\n'+recorder)
    subprocess.run(['xcrun','swiftc','-typecheck','-target','arm64-apple-ios26.0','-sdk',sdk,'-module-cache-path',str(tmp/'module-cache'),str(native)],check=True)
print(json.dumps({'status':'SDK_TYPECHECK_PASS','sdk':sdk,'source':str(path),'sourceSHA256':hashlib.sha256(path.read_bytes()).hexdigest(),'runtimeRecording':'UNKNOWN'}))
