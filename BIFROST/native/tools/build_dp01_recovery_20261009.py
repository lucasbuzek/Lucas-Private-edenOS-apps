#!/usr/bin/env python3
"""BIFROST complete discovered-scope portable recovery, no services changed."""
import hashlib
import json
import pathlib
import re
import zipfile
from datetime import datetime

h=pathlib.Path("/Users/lucas")  # RDC sessions may use an isolated HOME; user-owned project root is explicit
eden=h/"edenOS"
src=eden/"Projects/EDEN Apps/BIFROST"
git=eden/"Temporary/BIFROST-Raven-Headless-20261009/BIFROST"
legacy=eden/"AppDev/#App Backups/Legacy-Root-Backups"
appback=eden/"AppDev/#App Backups/Apps/BIFROST"
back=appback/"BIFROST_BACKUP_READY_20261009"
release=eden/"Backups/BIFROST/RELEASES_TESTING_LEGACY_20261009/BIFROST"  # preserved historical test candidates
support=h/"Library/Application Support/BIFROST"
out=appback/"BIFROST_EXPANDED_RECOVERY_WITH_DP01_KERNEL_20261009.zip"
manifest=appback/"BIFROST_EXPANDED_RECOVERY_WITH_DP01_KERNEL_20261009.manifest.json"
sources=[
("00_CANON_CURRENT_APPDEV_BIBLE.md",eden/"AppDev/#appDev Bible/APPDEV_BIBLE.md"),
("00_CANON_CURRENT_APPDEV_BIBLE.txt",eden/"AppDev/#appDev Bible/APPDEV_BIBLE.txt"),
("00_CANON_RULES/UNIVERSAL_APP_INTEGRATION_HIERARCHY_RULE.md",eden/"AppDev/#appDev Bible/AppDevRules/UNIVERSAL_APP_INTEGRATION_HIERARCHY_RULE.md"),
("00_CANON_RULES/UNIVERSAL_PROJECT_STORAGE_RULE.md",eden/"AppDev/#appDev Bible/AppDevRules/UNIVERSAL_PROJECT_STORAGE_RULE.md"),
("00_CANON_RULES/PROCEDURAL_LKG_AND_ANTI_DRIFT_RULE.md",eden/"AppDev/#appDev Bible/AppDevRules/PROCEDURAL_LKG_AND_ANTI_DRIFT_RULE.md"),
("00_CANON_BIFROST_PROJECT_GOALS.txt",eden/"Temporary/AppDevCanon_2026-10-07/helpers/BIFROST_Project_Prompt_Package_v0.1/BIFROST_Project_Prompt_Package_v0.1/02_BIFROST_PROJECT_GOALS.txt"),
("01_ACTIVE_NATIVE_SOURCE",src),
("02_RAVEN_INTEGRATED_SOURCE",git),
("03_NATIVE_RELEASE_CANDIDATES",release),
("04_RUNTIME_NONSECRET",support/"runtime"),
("04_RUNTIME_NONSECRET/Incoming",support/"Incoming"),
("04_RUNTIME_NONSECRET/settings.json",support/"settings.json"),
("05_EXISTING_RECOVERY",back),
("06_LEGACY_OCT5_FULL_BACKUPS",legacy/"BIFROST"),
("06_LEGACY_OCT5_ENTITY_SPECIALIST",legacy/"EDEN_FULL_RECOVERY_2026-10-05/entities/specialist_BIFROST"),
("06_LEGACY_OCT5_ENTITY_APP",legacy/"EDEN_FULL_RECOVERY_2026-10-05/entities/eden-app_BIFROST"),
("07_RECOVERED_AUTHORITY",eden/"AppDev/#appDev Bible/Project Bibles/BIFROST_REBUILD_BACKUP"),
("08_RAVEN_CLOUD_HANDOFF",eden/"AppDev/#handoffs/BIFROST_RAVEN_CLOUD_NODE_2026-10-08"),
("09_EARLIER_EXPERIMENTAL",appback/"BIFROST-v0.5.1-private-experimental-recovery-candidate"),
("10_PROMPT_AND_UIX_REFERENCE/BIFROST_Project_Prompt_Package_v0.1.zip",eden/"AppDev/#app-assistants/appDev main/BIFROST_Project_Prompt_Package_v0.1.zip"),
("10_PROMPT_AND_UIX_REFERENCE/HEIMDALL_BIFROST_SKALD_UIUX_v0.20.0.zip",eden/"Temporary/AppDevCanon_2026-10-07/helpers/edenOS_M1-M3_v3.7.1_Recovery_Hotfix/edenOS/reference/HEIMDALL_BIFROST_SKALD_UIUX_v0.20.0.zip"),
("11_RECOVERED_BIBLE_EN",eden/"EDEN Initiative/EDEN_Master_Bibles_v1.0/BIBLES_EN/BIFROST_BIBLE_v1.0_EN.txt"),
("11_RECOVERED_BIBLE_SK",eden/"EDEN Initiative/EDEN_Master_Bibles_v1.0/BIBLES_SK/BIFROST_BIBLE_v1.0_SK.txt"),
("12_CURRENT_LAUNCH_AGENTS/eden.bifrost.headless.plist",h/"Library/LaunchAgents/eden.bifrost.headless.plist"),
("12_CURRENT_LAUNCH_AGENTS/eden.bifrost.raven-bridge.plist",h/"Library/LaunchAgents/eden.bifrost.raven-bridge.plist"),
("12_CURRENT_LAUNCH_AGENTS/org.eden.bifrost.core.plist",h/"Library/LaunchAgents/org.eden.bifrost.core.plist"),
("13_RAVEN_PWA_GIT_HISTORY/BIFROST_RAVEN_PWA_BRANCH_LATEST_20261009.bundle",appback/"BIFROST_RAVEN_PWA_BRANCH_LATEST_20261009.bundle"),
]
# After AppDev Releases flattening, include active BIFROST test candidates individually.
# Never collect the entire Releases folder (other Apps are not BIFROST backup sources).
sources.extend(("03_ACTIVE_BIFROST_TEST_CANDIDATES/"+item.name, item)
               for item in sorted((eden/"Releases").glob("BIFROST-*.app")))
skips={".DS_Store","__pycache__",".wrangler","node_modules",".git","error.log"}
def skip(p):
    return any(part in skips or part.endswith(".pyc") or part.endswith(".log")
               for part in p.parts)
def files_of(prefix,base):
    if base.is_symlink():
        return
    if base.is_file():
        if not skip(pathlib.Path(base.name)): yield prefix,base
        return
    for entry in sorted(base.rglob("*")):
        if entry.is_file() and not entry.is_symlink():
            rel=entry.relative_to(base)
            if not skip(rel):
                yield prefix+"/"+rel.as_posix(),entry
records=[]
seen=set()
for prefix,path in sources:
    if not path.exists():
        raise RuntimeError("Required recovery source missing: {} {}".format(prefix,path))
    for name,local in files_of(prefix,path):
        if name in seen: raise RuntimeError("Duplicate archive path "+name)
        seen.add(name)
        size=local.stat().st_size
        if size>200_000_000: raise RuntimeError("unexpectedly huge "+str(local))
        records.append((name,local,size))
if out.exists(): raise RuntimeError("refusing overwrite "+str(out))
category={}
with zipfile.ZipFile(out,"x",compression=zipfile.ZIP_DEFLATED,compresslevel=6,allowZip64=True) as archive:
    for name,path,size in records:
        archive.write(path,name)
        cat=name.split("/")[0]
        group=category.setdefault(cat,{"files":0,"raw_bytes":0})
        group["files"]+=1
        group["raw_bytes"]+=size
with zipfile.ZipFile(out) as z:
    bad=z.testzip()
    if bad: raise RuntimeError("archive corrupt "+bad)
    if len(z.namelist()) != len(records): raise RuntimeError("file count mismatch")
    for name,_,_ in records:
        if name not in z.namelist(): raise RuntimeError("missing "+name)
result={
 "name":out.name,
 "created":"2026-10-09",
 "archive_bytes":out.stat().st_size,
 "uncompressed_file_bytes":sum(x[2] for x in records),
 "files":len(records),
 "archive_sha256":hashlib.sha256(out.read_bytes()).hexdigest(),
 "categories":category,
 "exclusions":["Keychain, auth token, credentials, logs, caches, node_modules, .git internal working tree, unrelated EDEN Apps"],
 "git_history":"Existing full-history bundles in 05_EXISTING_RECOVERY plus current verified 19aa9ef Raven PWA Git bundle",
 "deployment_targets":{"macos_native":"BUILT_NOT_PHYSICALLY_ACCEPTED","macos_headless":"RUNNING_PARTIALLY_VERIFIED","windows_native":"SPECIFIED_ONLY","windows_headless":"SPECIFIED_ONLY","linux_native":"SPECIFIED_ONLY","linux_headless":"SPECIFIED_ONLY"},
 "pwa":{"local":"LIVE_LOOPBACK_TESTED","raven_remote":"LOCAL_SOURCE_TESTED_NOT_DEPLOYED","lan_authenticated":"SPECIFIED_NOT_IMPLEMENTED","offline_cache":"STATIC_ONLY_TESTED"},
 "kernel_dp01":{"source":"01_ACTIVE_NATIVE_SOURCE/core/portable_kernel.py",
                "state":"IMPLEMENTED_STATIC_AND_ISOLATED_ENVIRONMENT_TESTED",
                "full_scope":"UNVERIFIED",
                "portable_python39":"PASSED_ON_MAC",
                "sqlite_schema":1,
                "native":"BUILT_NOT_PHYSICALLY_ACCEPTED",
                "headless":"SOURCE_INTEGRATED_ISOLATED_TESTS_PASS",
                "pwa":"LOCAL_SOURCE_INTEGRATED_LIVE_DEPLOYMENT_PENDING",
                "remote_scanning":"DISABLED",
                "windows_linux":"SOURCE_ONLY_NOT_TESTED"},
 "remote_pairing":"NOT_PHYSICALLY_VERIFIED",
 "runtime_state":"snapshot only; running launchd and Caffeinate deliberately not modified",
 "scope_limit":"Complete discovered local BIFROST scoped material, not uncreated planned functionality nor full 161 MB EDEN Initiative",
}
manifest.write_text(json.dumps(result,indent=2,sort_keys=True)+"\n")
print("ARCHIVE",out)
print("HASH",result["archive_sha256"])
print("FILES",result["files"])
print("RAW_BYTES",result["uncompressed_file_bytes"])
print("ZIP_BYTES",result["archive_bytes"])
for key,value in category.items(): print("CATEGORY",key,value)
print("MANIFEST",manifest)
