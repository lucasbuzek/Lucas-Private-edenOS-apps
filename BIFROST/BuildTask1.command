#!/bin/bash
# Developer/Mac continuation gate, not an ordinary user's setup procedure.
set -euo pipefail
cd "$(dirname "$0")"
command -v python3 >/dev/null || { echo "Python 3.11+ is required for the build."; exit 1; }
command -v xcodegen >/dev/null || { echo "Install XcodeGen for this developer build, then retry."; exit 1; }
xcode-select -p >/dev/null
candidate_dir="${BIFROST_TASK1_OUTPUT:-$PWD/.task1-build}"
mkdir -p "$candidate_dir"
python3 -m venv "$candidate_dir/venv"
"$candidate_dir/venv/bin/pip" install . pyinstaller==6.16.0
"$candidate_dir/venv/bin/python" -m unittest discover -s tests -v
"$candidate_dir/venv/bin/pyinstaller" --noconfirm --onedir --name bifrost-chatgpt-provider \
  --collect-all keyring --collect-submodules mcp.client --collect-submodules mcp.shared --collect-data mcp --collect-all authlib --collect-all openai \
  --distpath "$candidate_dir/provider" --workpath "$candidate_dir/pyinstaller" \
  --specpath "$candidate_dir" provider_entry.py
swift test --package-path Apple
xcodegen generate
xcodebuild -quiet -project BIFROST.xcodeproj -scheme BIFROST -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath "$candidate_dir/DerivedData" CODE_SIGNING_ALLOWED=NO build
candidate_app="$candidate_dir/DerivedData/Build/Products/Debug/BIFROST.app"
mkdir -p "$candidate_app/Contents/Resources/ChatGPTProvider"
cp -R "$candidate_dir/provider/bifrost-chatgpt-provider/." "$candidate_app/Contents/Resources/ChatGPTProvider/"
test -x "$candidate_app/Contents/Resources/ChatGPTProvider/bifrost-chatgpt-provider"
"$candidate_dir/venv/bin/python" package_metadata.py "$candidate_app"
# Inspect the frozen helper in a clean working directory; no network/login.
"$candidate_dir/venv/bin/python" - "$candidate_app" <<'PY'
import json, subprocess, sys
from pathlib import Path
helper=Path(sys.argv[1])/"Contents/Resources/ChatGPTProvider/bifrost-chatgpt-provider"
result=subprocess.run([str(helper)],input=json.dumps({"id":"preflight","op":"status"})+chr(10),
    capture_output=True,text=True,cwd="/tmp",timeout=30,check=True)
record=json.loads(result.stdout)
assert record.get("id")=="preflight" and record.get("result",{}).get("state") in {"connect","connected","permission_required"}, "Frozen provider preflight failed"
print("Frozen provider preflight passed")
PY
/usr/bin/plutil -lint "$candidate_app/Contents/Info.plist"
/usr/bin/ditto -c -k --keepParent "$candidate_app" "$candidate_dir/BIFROST-task1-macos-arm64-candidate.zip"
/usr/bin/unzip -t "$candidate_dir/BIFROST-task1-macos-arm64-candidate.zip"
# Extract the exact archive into a fresh location and exercise its bundled runtime.
"$candidate_dir/venv/bin/python" - "$candidate_dir/BIFROST-task1-macos-arm64-candidate.zip" <<'PY'
import json, subprocess, sys, tempfile
from pathlib import Path
with tempfile.TemporaryDirectory(prefix="bifrost-clean-package-") as clean:
    subprocess.run(["/usr/bin/ditto","-x","-k",sys.argv[1],clean],check=True)
    app=Path(clean)/"BIFROST.app"
    metadata=json.loads((app/"Contents/Resources/TASK1_BUILD.json").read_text())
    assert metadata["promotion"]=="NOT_PROMOTED"
    helper=app/"Contents/Resources/ChatGPTProvider/bifrost-chatgpt-provider"
    result=subprocess.run([str(helper)],input=json.dumps({"id":"clean","op":"status"})+chr(10),
        capture_output=True,text=True,cwd=clean,timeout=30,check=True)
    record=json.loads(result.stdout)
    assert record.get("id")=="clean" and record.get("result",{}).get("state") in {"connect","connected","permission_required"}
    print("Clean extracted app runtime passed")
PY
/usr/bin/shasum -a 256 "$candidate_dir/BIFROST-task1-macos-arm64-candidate.zip" > "$candidate_dir/SHA256SUMS"
echo "Candidate prepared; signing, notarization and physical verification remain UNKNOWN."
