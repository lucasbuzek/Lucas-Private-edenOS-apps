"""Build evidence and dependency notices, without user secrets."""
import importlib.metadata
import json
import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path

app=Path(sys.argv[1])
resources=app/"Contents/Resources"
revision=subprocess.check_output(["git","rev-parse","HEAD"],text=True).strip()
(resources/"TASK1_BUILD.json").write_text(json.dumps({
    "source_revision":revision,"build_id":os.getenv("GITHUB_RUN_ID","local-candidate"),
    "app":"BIFROST","plugin_version":"0.1.0","channel":"candidate",
    "target":"macOS-"+platform.machine(),"provider_schema":1,
    "physical_gates":"UNKNOWN","promotion":"NOT_PROMOTED",
    "baseline":"2c50f36b9be6f88b80c322355e60f52820295e52"
},indent=2))
notices=resources/"ThirdPartyNotices"
notices.mkdir(exist_ok=True)
for dist in importlib.metadata.distributions():
    for file in dist.files or []:
        name=str(file).lower()
        if ".dist-info/" in name and any(part in Path(name).name for part in ["license","notice","copying"]):
            original=dist.locate_file(file)
            if original.is_file():
                destination=notices/(dist.metadata["Name"]+"-"+dist.version+"-"+Path(file).name)
                shutil.copyfile(original,destination)
