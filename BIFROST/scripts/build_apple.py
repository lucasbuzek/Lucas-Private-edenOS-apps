"""Developer/CI Apple packaging; normal users receive the app, never this script."""
import hashlib
import json
import plistlib
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

if sys.platform != "darwin":
    raise SystemExit("Apple packaging requires macOS; gate remains UNKNOWN")
root = Path(__file__).resolve().parents[1]
app = root / "dist/BIFROST Native Access.app"
if app.exists():
    raise SystemExit("Refusing to overwrite an existing app artifact; retain or move it first")
subprocess.run(["swift", "build", "--package-path", str(root/"apple"), "-c", "release"], check=True)
bindir = subprocess.check_output(["swift", "build", "--package-path", str(root/"apple"), "-c", "release", "--show-bin-path"], text=True).strip()
contents = app/"Contents"
(contents/"MacOS").mkdir(parents=True)
(contents/"Resources").mkdir()
shutil.copy2(Path(bindir)/"BIFROSTNativeAccess", contents/"MacOS/BIFROSTNativeAccess")
for name, module in (("native-host", "native_mcp"), ("native-control", "native_control")):
    entry = root / "build" / (name+".py")
    entry.parent.mkdir(exist_ok=True)
    entry.write_text("from bifrost."+module+" import main\nmain()\n")
    subprocess.run([sys.executable, "-m", "PyInstaller", "--noconfirm", "--onedir", "--name", name,
        "--paths", str(root), "--collect-submodules", "mcp",
        "--hidden-import", "keyring.backends.macOS",
        "--distpath", str(contents/"Resources"),
        "--workpath", str(root/"build"/name), "--specpath", str(root/"build"),
        str(entry)], check=True)
info = {"CFBundleName":"BIFROST Native Access", "CFBundleDisplayName":"BIFROST Computer Access",
        "CFBundleIdentifier":"org.eden.bifrost.native-access", "CFBundleVersion":"1",
        "CFBundleShortVersionString":"0.1.0", "CFBundleExecutable":"BIFROSTNativeAccess",
        "CFBundlePackageType":"APPL", "LSMinimumSystemVersion":"13.0",
        "NSHumanReadableCopyright":"BIFROST",
        "NSDocumentsFolderUsageDescription":"Access only the work folder you explicitly select.",
        "NSDownloadsFolderUsageDescription":"Access only the work folder you explicitly select.",
        "NSDesktopFolderUsageDescription":"Access only the work folder you explicitly select."}
with (contents/"Info.plist").open("wb") as stream:
    plistlib.dump(info, stream)
# CI artifacts are unsigned candidates. Distribution signing/notarization is a later gate.
output = root/"dist/BIFROST-Native-Access-unsigned.zip"
with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(app.rglob("*")):
        archive.write(path, path.relative_to(app.parent))
with zipfile.ZipFile(output) as archive:
    assert archive.testzip() is None
checksum = hashlib.sha256(output.read_bytes()).hexdigest()
(root/"dist/BIFROST-Native-Access-unsigned.sha256").write_text(checksum+"  "+output.name+"\n")
print(json.dumps({"package":str(output), "sha256":checksum, "signing":"UNKNOWN", "physical":"UNKNOWN"}))
