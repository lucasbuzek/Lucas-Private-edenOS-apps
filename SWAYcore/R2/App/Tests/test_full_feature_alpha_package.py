from pathlib import Path
import re, json

ROOT=Path(__file__).resolve().parents[1]
LAUNCHER=ROOT/"FULL_FEATURE_ALPHA.command"

def text(p): return p.read_text()

def test_launcher_exists_and_is_local_first():
    s=text(LAUNCHER)
    assert "curl " not in s and "wget " not in s
    assert "OFFLINE" in s
    assert "/Applications/Blender.app/Contents/MacOS/Blender" in s
    assert "/Applications/Xcode.app/Contents/Developer" in s

def test_no_hardcoded_device_udid():
    s=text(LAUNCHER)
    assert "00008130-000A71383A0B803A" not in s
    assert "list devices" in s and "DEVICECTL" in s

def test_launcher_runs_contract_gates():
    s=text(LAUNCHER)
    for gate in ["validate_contract.py","validate_reality_character_contract.py","VERIFY_SWIFT_SOURCE_HAZARDS.command"]:
        assert gate in s

def test_launcher_creates_evidence_bundle():
    s=text(LAUNCHER)
    assert "AlphaEvidence" in s
    assert "environment.txt" in s
    assert "physical_test_checklist.md" in s

def test_build_identity_153():
    y=text(ROOT/"project.yml")
    p=text(ROOT/"SWAY.xcodeproj/project.pbxproj")
    assert "CURRENT_PROJECT_VERSION: 153" in y
    assert "INFOPLIST_KEY_CFBundleVersion: 153" in y
    assert "CURRENT_PROJECT_VERSION = 153" in p
    assert "INFOPLIST_KEY_CFBundleVersion = 153" in p

def test_authoritative_physical_journey_is_packaged():
    s=text(ROOT/"AlphaTest/physical_test_checklist.md")
    required=["Fresh install","Learn","Generated Beat","YOUR DANCER","Create Move",".swaypack",
              "Follow-Along","six-action calibration","READY TO SWAY","Record SWAY",
              "iPad portrait","iPad landscape","Offline"]
    for item in required: assert item in s

def test_r2_has_no_historical_lkg_or_baseline():
    s=text(ROOT/"CAPABILITY_LEDGER.md")
    assert "No historical build is LKG" in s
    assert "Build 149 | WORKING recovered baseline" not in s
    assert "R2 becomes the first genuine SWAYcore LKG" in s
