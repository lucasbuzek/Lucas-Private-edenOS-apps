#!/usr/bin/env python3
"""Build AppDevCanon/reconciled from _inputs per DECISIONS_2026-10-07.md. Deterministic; re-runnable."""
import hashlib, os, re, shutil
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
GH = os.path.join(ROOT, "_inputs", "appDevDocs_GH")
MAC = os.path.join(ROOT, "_inputs", "mac_appDevBible")
OUT = os.path.join(ROOT, "reconciled")
LOG = []
MARK = "RECONCILED 2026-10-07"


def sha(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()


def put(src, rel, why):
    dst = os.path.join(OUT, rel)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copyfile(src, dst)
    LOG.append((rel, os.path.relpath(src, ROOT), sha(src), why))


def provenance(src, kind, rel):
    dst = os.path.join(OUT, "_provenance", kind, rel)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copyfile(src, dst)
    LOG.append(("_provenance/%s/%s" % (kind, rel), os.path.relpath(src, ROOT), sha(src), "provenance copy (not canon)"))


def walk(base):
    for dp, _, fs in os.walk(base):
        for f in sorted(fs):
            if f != ".DS_Store":
                yield os.path.join(dp, f)


if os.path.exists(OUT):
    shutil.rmtree(OUT)
os.makedirs(OUT)

# 1) GH tree
GH_TAKE = []
for d in ["AppDevRules", "ForgeMASTER", "CONDUCTOR", "canon", "tests", "Project Bibles"]:
    for p in walk(os.path.join(GH, d)):
        GH_TAKE.append(os.path.relpath(p, GH))
GH_TAKE += ["05_CONTROL/APPDEV_CONTEXT_CONTINUITY_CANON_2026-10-03.md", "05_CONTROL/EDEN_PWA_CLOUD_ACCESS_IDENTITY_CANON_2026-09-28.md"]
identical = {"AppDevRules/00_CANONICAL_PROCEDURE_FIRST_RULE.md", "AppDevRules/WORKinCODEX.md"}
for rel in sorted(GH_TAKE):
    if rel == "AppDevRules/UNIVERSAL_PROJECT_STORAGE_RULE.md":
        continue
    if rel == "Project Bibles/CRESUS.txt":
        why = "GH 14159 B vs Mac 9582 B, same date 2026-10-03; GH fuller/structured -> GH; Mac kept as provenance"
    elif rel in identical:
        why = "identical in GH and Mac"
    else:
        why = "GH (newer reconciled commit, or direction unknown -> fuller GH text); GH-only files included"
    put(os.path.join(GH, rel), rel, why)

# Mac versions kept as provenance where they differ
for rel in ["AppDevRules/handoffClaude.md", "AppDevRules/UNIVERSAL_APP_INTEGRATION_HIERARCHY_RULE.md", "AppDevRules/silentChatGPT.md",
            "ForgeMASTER/v1.0/CALLS_AND_ROUTING.md", "ForgeMASTER/v1.0/MIGRATION_AND_EVIDENCE.md", "AppDevRules/handoffUNI.md",
            "AppDevRules/handoffCodex.md", "AppDevRules/handoffGPT.md", "AppDevRules/PROCEDURAL_LKG_AND_ANTI_DRIFT_RULE.md",
            "ForgeMASTER/v1.0/FORGEMASTER_MASTER_GOVERNOR.md", "Project Bibles/SWAYcore.txt", "Project Bibles/Modern Generals Native.txt"]:
    p = os.path.join(MAC, rel)
    if os.path.exists(p) and sha(p) != sha(os.path.join(GH, rel)):
        provenance(p, "mac", rel)
provenance(os.path.join(MAC, "Project Bibles/CRESUS_REBUILD_BACKUP/CRESUS_PROJECT_BIBLE.txt"), "mac", "Project Bibles/CRESUS_PROJECT_BIBLE.txt")
provenance(os.path.join(GH, "AppDevRules/UNIVERSAL_PROJECT_STORAGE_RULE.md"), "gh", "AppDevRules/UNIVERSAL_PROJECT_STORAGE_RULE.md")
provenance(os.path.join(MAC, "APPDEV_BIBLE.txt"), "mac", "APPDEV_BIBLE.txt")
provenance(os.path.join(MAC, "APPDEV_BIBLE.pre-overhaul.backup.md"), "mac", "APPDEV_BIBLE.pre-overhaul.backup.md")
provenance(os.path.join(MAC, "README.md"), "mac", "README.md")
provenance(os.path.join(GH, "README.txt"), "gh", "README.txt")

# 2) Mac wins / Mac-only
put(os.path.join(MAC, "AppDevRules/UNIVERSAL_PROJECT_STORAGE_RULE.md"), "AppDevRules/UNIVERSAL_PROJECT_STORAGE_RULE.md",
    "Mac newer (2026-10-06 23:59); matches real ~/edenOS/AppDev layout")
for rel in ["GMR.txt", "DESIGN_MANTRA.txt", "namingRules.txt"]:
    put(os.path.join(MAC, rel), rel, "Mac-only canon")
for rel in ["Project Bibles/HEIMDALL iOS.txt", "Project Bibles/PENELOPE.txt", "Project Bibles/edenOS Embedded.txt"]:
    put(os.path.join(MAC, rel), rel, "Mac-only Project Bible")

# 3) Superseded governor -> provenance
for base in ["EITRIMB", "EITRIMB_Development_Readiness_DropIn_v1.0"]:
    for p in walk(os.path.join(GH, base)):
        provenance(p, "superseded", os.path.join(base, os.path.relpath(p, os.path.join(GH, base))))

# 4) APPDEV_BIBLE.md merge
md = open(os.path.join(MAC, "APPDEV_BIBLE.md"), encoding="utf-8").read().rstrip("\n")
txt = open(os.path.join(MAC, "APPDEV_BIBLE.txt"), encoding="utf-8").read()
i = txt.index("## Thin-governor execution update")
note = ("\n\n<!-- %s: sections below existed only in APPDEV_BIBLE.txt (2026-10-01); merged verbatim per Lucas decision 1. "
        "Where they say EITRIMB, read: EITRIMB is superseded; ForgeMASTER is the SOLE AppDev governor (EITRIMB retained as provenance). -->\n\n" % MARK)
open(os.path.join(OUT, "APPDEV_BIBLE.md"), "w", encoding="utf-8").write(md + note + txt[i:].rstrip("\n") + "\n")
LOG.append(("APPDEV_BIBLE.md", "_inputs/mac_appDevBible/APPDEV_BIBLE.md + sections of APPDEV_BIBLE.txt from line %d" % (txt[:i].count("\n") + 1),
            sha(os.path.join(MAC, "APPDEV_BIBLE.md")) + " + " + sha(os.path.join(MAC, "APPDEV_BIBLE.txt")), "merge per decision 1"))

# 5) Amendments
ROUTE = ("\n> **%s - Claude/gh route, surface-dependent (Lucas decision 2026-10-06/07):** `gh` on Lucas's Mac IS authorized (logged in as lucasbuzek; scopes repo/gist/read:org). "
         "Where a Claude session is linked to the Mac (Claude desktop app / Claude Code session with Remote Desktop Commander present), Claude reaches the Mac through RDC and uses `gh` and the `codex` CLI there; Claude's own GitHub connector does NOT reach Lucas's private repos. "
         "Claude in the browser or the iPhone app has NO Mac/RDC/GitHub access (previously the only Claude surfaces used): there Claude works only from the Claude Project's mirrored files and supplied attachments. "
         "The ChatGPT-connector statement above remains valid for ChatGPT sessions. The newest explicit user decision outranks the older line.\n" % MARK)
targets = {
    "AppDevRules/WORKinCODEX.md": [r"^The Mac is the control/submission surface\.", r"^Lucas's Mac has no assumed GitHub connection\."],
    "AppDevRules/handoffCodex.md": [r"^Lucas's Mac has NO assumed GitHub connection\."],
    "AppDevRules/handoffGPT.md": [r"^Lucas's Mac has NO assumed GitHub connection\."],
    "AppDevRules/UNIVERSAL_REBUILD_BACKUP_RULE.md": [r"^Lucas's Mac has NO assumed GitHub connection\.", r"^1\. Persist remote global/project canon through ChatGPT", r"^MAC AND GITHUB ARE INDEPENDENT STORES\."],
}
amended = []
for rel, pats in targets.items():
    p = os.path.join(OUT, rel)
    out, n = [], 0
    for ln in open(p, encoding="utf-8").read().split("\n"):
        out.append(ln)
        if any(re.match(pt, ln) for pt in pats):
            out.append(ROUTE)
            n += 1
    open(p, "w", encoding="utf-8").write("\n".join(out))
    amended.append((rel, n))

HC = ("\n\n## In-project Claude (claude.ai Project 'edenOS App Development') - %s\n"
      "The no-access assumption above was true when Claude was used only in the browser and the iPhone app, and it still is on those surfaces: there is no Mac, Remote Desktop Commander, `gh` or private-repo access, "
      "so Claude works from the mirrored AppDev canon and helper definitions in the Claude Project files plus whatever is attached, and any handoff for such a session must be self-contained. "
      "Where the Project session is linked to Lucas's MacBook (Claude desktop app / Claude Code; Remote Desktop Commander tools present), Claude additionally has the Mac files, `gh` as lucasbuzek and the `codex` CLI, "
      "and follows WORKinCODEX / ForgeMASTER directly without needing a self-contained package. Claude's own GitHub connector does NOT reach the private repos on any surface. "
      "Decide by the tools actually present in the session, never by assumption.\n" % MARK)
open(os.path.join(OUT, "AppDevRules/handoffClaude.md"), "a", encoding="utf-8").write(HC)
amended.append(("AppDevRules/handoffClaude.md", 1))

mg = os.path.join(OUT, "Project Bibles/Modern Generals Native.txt")
s = open(mg, encoding="utf-8").read()
s2 = re.sub(r"(Governor: EITRI[^\n]*\n)", lambda m: m.group(1) + "[" + MARK + ": superseded by ForgeMASTER (sole AppDev governor); EITRI/EITRIMB retained as provenance]\n", s, count=1)
amended.append(("Project Bibles/Modern Generals Native.txt", 1 if s2 != s else 0))
open(mg, "w", encoding="utf-8").write(s2)

# 5b) Web/Browser Bridge rule: Mac-only AppDevRule hidden at the end of a mislabeled file (full appDev MASTER handoff + this rule appended)
wb_src = os.path.join(ROOT, "_inputs", "app_assistants", "loose", "AppDevRules_Web_Browser_Bridge_Canon_v1.1.txt")
wb = open(wb_src, encoding="utf-8").read()
k = wb.index("APPDEVRULE\n— WEB / BROWSER BRIDGE SHARED CAPABILITY")
k = wb.rfind("=" * 20, 0, k)
body = wb[k:].lstrip("= \n")
hdr = ("# WEB / BROWSER BRIDGE - SHARED CAPABILITY RULE (AppDevRule, Mac-only canon)\n\n"
       "<!-- %s: extracted verbatim from the tail of Mac file `appDev main/AppDevRules_Web_Browser_Bridge_Canon_v1.1.txt` (24228 B), "
       "whose first 460 lines are a copy of the appDev MASTER reconciliation handoff. Source sha256 %s. Status: Mac-only canon, not yet in GitHub. -->\n\n" % (MARK, sha(wb_src)))
os.makedirs(os.path.join(OUT, "AppDevRules"), exist_ok=True)
open(os.path.join(OUT, "AppDevRules/WEB_BROWSER_BRIDGE_CAPABILITY_RULE.md"), "w", encoding="utf-8").write(hdr + body.rstrip("\n") + "\n")
LOG.append(("AppDevRules/WEB_BROWSER_BRIDGE_CAPABILITY_RULE.md", os.path.relpath(wb_src, ROOT) + " (tail from 'APPDEVRULE' marker)", sha(wb_src), "Mac-only AppDevRule extracted from mislabeled file"))

# 6) README, log, manifest
readme = """# AppDev Canon - Reconciled Set (2026-10-07)

READ MIRROR. GitHub `lucasbuzek/Lucas-private-appDevDocs` remains the canonical persistence (ForgeMASTER). Edits go to GitHub first, then re-mirror to the Mac (`~/edenOS/AppDev/#appDev Bible`) and the Claude Project. See `RECONCILIATION_LOG.md` for per-file source, reason and input hashes and `MANIFEST.sha256` for output hashes.

Authority order: newest explicit user decision -> current frozen EDEN/AppDev canon -> newest project-specific canon -> verified evidence -> older implementation/provenance.
Governor: ForgeMASTER is the sole AppDev governor. EITRI/EITRIMB are provenance (`_provenance/superseded/`).
Evidence ladder: GENERATED != IMPLEMENTED != BUILT != TESTED != VERIFIED != RELEASED. UNKNOWN != PASS.
Amendments are marked `RECONCILED 2026-10-07` (gh route for Mac/Claude; in-project Claude note; stale governor flag).
Out of scope: TOME book material and project backup records (not canon).

Layout: root (APPDEV_BIBLE.md, GMR.txt, DESIGN_MANTRA.txt, namingRules.txt) | AppDevRules/ | ForgeMASTER/v1.0/ | CONDUCTOR/ | canon/ | tests/ | Project Bibles/ | 05_CONTROL/ | _provenance/{mac,gh,superseded}/ (not canon).
"""
open(os.path.join(OUT, "README.md"), "w", encoding="utf-8").write(readme)
with open(os.path.join(OUT, "RECONCILIATION_LOG.md"), "w", encoding="utf-8") as lf:
    lf.write("# Reconciliation log (generated by tools/build_reconciled.py)\n\n| Output | Source | Input sha256 | Reason |\n|---|---|---|---|\n")
    for rel, src, h, why in LOG:
        lf.write("| `%s` | `%s` | `%s` | %s |\n" % (rel, src, h, why))
    lf.write("\n## Amendments applied (marker `%s`)\n" % MARK)
    for rel, n in amended:
        lf.write("- `%s`: %d insertion(s)\n" % (rel, n))
with open(os.path.join(OUT, "MANIFEST.sha256"), "w") as mf:
    for p in sorted(walk(OUT)):
        if os.path.basename(p) != "MANIFEST.sha256":
            mf.write("%s  %s\n" % (sha(p), os.path.relpath(p, OUT)))
print("built; log rows:", len(LOG), "amendments:", amended)
