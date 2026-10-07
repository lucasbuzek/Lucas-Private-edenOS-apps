#!/usr/bin/env python3
"""Generate AppDevCanon/claude-helpers from _inputs helper packages + reconciled canon. Deterministic; source text embedded verbatim.
Only transport/runtime framing is added (header). No behavior of any helper is changed."""
import fnmatch, hashlib, json, os, re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
PK = os.path.join(ROOT, "_inputs", "app_assistants", "packages")
LOOSE = os.path.join(ROOT, "_inputs", "app_assistants", "loose")
REC = os.path.join(ROOT, "reconciled")
OUT = os.path.join(ROOT, "claude-helpers")
MARK = "RECONCILED 2026-10-07"
MAX_WORDS = 6000
REF_CAP = 250_000
SKIP = re.compile(r"(SHA256|MANIFEST|\.DS_Store|CHECKSUM|FILE_INDEX|INVENTORY_SHA)", re.I)


def sha(b):
    return hashlib.sha256(b).hexdigest()


def words(t):
    return len(t.split())


def walk(base):
    for dp, _, fs in os.walk(base):
        for f in sorted(fs):
            if f.endswith((".txt", ".md")) and not SKIP.search(f):
                yield os.path.join(dp, f)


def gather(src, pats):
    """src: ('P', pkgdir) | ('R', None) | ('L', None); pats fnmatch vs path relative to src root."""
    kind, d = src
    base = {"P": os.path.join(PK, d or ""), "R": REC, "L": LOOSE}[kind]
    out = []
    for p in walk(base):
        rel = os.path.relpath(p, base)
        if any(fnmatch.fnmatch(rel, pt) for pt in pats):
            out.append(p)
    return out


H = {}  # helper table: id -> dict


def add(id, display, expansion, kind, status, version, primary, reference=(), superseded=(), notes=(), tools="", invoke=None, parent="ForgeMASTER (governor); CONDUCTOR coordinates", sources_note=""):
    H[id] = dict(id=id, display=display, expansion=expansion, kind=kind, status=status, version=version, primary=list(primary), reference=list(reference),
                 superseded=list(superseded), notes=list(notes), tools=tools, invoke=invoke or "@%s" % id, parent=parent, sources_note=sources_note)


P = lambda d, *pats: (("P", d), list(pats))
R = lambda *pats: (("R", None), list(pats))
L = lambda *pats: (("L", None), list(pats))

# ---------------- governors / orchestration ----------------
add("FORGEMASTER", "ForgeMASTER", "Master AppDev Governor (in-chat governor; not an app/runtime)", "Governor", "ACTIVE (CANDIDATE v1.0, reconciled 2026-10-06)", "v1.0",
    [R("ForgeMASTER/v1.0/FORGEMASTER_MASTER_GOVERNOR.md", "ForgeMASTER/v1.0/CALLS_AND_ROUTING.md", "AppDevRules/FORGEMASTER_IN_CHAT_BOOTSTRAP.md")],
    [R("ForgeMASTER/v1.0/MIGRATION_AND_EVIDENCE.md", "AppDevRules/handoffClaude.md", "AppDevRules/handoffUNI.md", "AppDevRules/handoffCodex.md", "AppDevRules/WORKinCODEX.md", "AppDevRules/UNIVERSAL_REBUILD_BACKUP_RULE.md")],
    invoke="@forgemaster goal|extendedgoal|handofffull|backupfull|backuplocal|handoffCodex|handoffClaude", parent="(top of the AppDev stack)",
    notes=["In this Claude Project the bootstrap's 'resolve canon from GitHub' step is satisfied by the mirrored project docs (read mirror); on Mac-linked sessions Claude may additionally verify against GitHub/Mac via RDC+gh. Never invent ForgeMASTER from memory: if the mirrored definition is missing, report a bootstrap/access blocker.",
           "`handoffClaude` produces a self-contained package for a Claude WITHOUT this Project/bridge; inside this Project use the mirror directly.",
           "`handoffCodex`/`WORKinCODEX`: prepare handoff file, submit via `codex cloud exec` on the Mac; Lucas may authorize automatic submission (as on 2026-10-07); otherwise stop at the visible-Terminal Enter gate. Codex usage limits can return 429 - record and retry, do not run the workload locally.",
           "LCAS tiny UI is rendered as a compact status block in the reply and (for long work) the TaskCreate list; it never decides state."])
add("CONDUCTOR", "CONDUCTOR", "Coordinated Operations, Navigation, Delivery, Unified Control, Tracking, Oversight & Review", "Orchestrator", "ACTIVE", "v1.1 (+LCAS v1.0, helper hierarchy v1.0, branched development v1.0)",
    [R("CONDUCTOR/CONDUCTOR_MASTER_PROMPT_v1.1.txt", "CONDUCTOR/LCAS/LCAS_CANON_v1.0.txt", "CONDUCTOR/HELPERS/HELPER_HIERARCHY_v1.0.txt", "CONDUCTOR/UNIVERSAL_BRANCHED_DEVELOPMENT_v1.0.txt", "CONDUCTOR/BASELINES/*"),
     P("CONDUCTOR_IDENTITY_HELPERS_SUBORDINATES_v1.1", "*CONDUCTOR_ABOUT_ME_HELPERS_SUBORDINATES_v1.1.txt", "*SUBORDINATE_HANDOFF_TEMPLATE_v1.1.txt")],
    [P("CONDUCTOR_BRANCHED_HELPER_PACKAGE_v1.0", "*"), L("EDEN_BIFROST_CONDUCTOR_Modular_Ecosystem_Architecture.txt")],
    superseded=["CONDUCTOR_BRANCHED_HELPER_v1.0/PROMPTS/CONDUCTOR_MASTER_v1.0.txt (older master; v1.1 is current)"],
    parent="ForgeMASTER governs; CONDUCTOR = decide/govern/coordinate",
    notes=["LCAS = SEE & CONTROL: render as a compact status block; use TaskCreate/TaskUpdate for the persistent list. AOS (persistent autonomous pipelines) maps to: a running Claude session + Codex WORKinCODEX for heavy work + scheduled tasks for later work.",
           "Tiny subordinates (ANT BEE OWL FOX WREN MOTH MITE HARE FINCH GECKO) are narrow roles Claude adopts sequentially or via the Agent tool only when Lucas asks for subagents."])
add("UIBASIC", "UIbasic", "Persistent truthful operational UI (TINY / COMPACT / FULL / AUTO)", "Specialist (UI protocol)", "ACTIVE", "v1.0",
    [P("HERMES_Hiring_Employment_Research_Matching_Execution_System_v1.6", "*references/UIbasic_v1.0_MASTER.txt")], [],
    parent="CONDUCTOR/LCAS", notes=["Claude renders UIbasic as a compact status header in replies and the task list widget; it must not become a second progress engine."])
# ---------------- specialist helpers ----------------
add("APPLE", "APPLE", "Architecture, Product, Performance & Lean Engineering (APPLE Core Council)", "Specialist (review council)", "ACTIVE", "v2.2",
    [P("APPLE_Architecture_Product_Performance_Lean_Engineering_v2.2", "*PROMPTS/APPLE_Master_Prompt_v2.2.txt", "*ABOUT/APPLE_Tell_Me_About_Yourself_v2.2.txt", "*ABOUT/APPLE_My_Subordinates_v2.2.txt", "*INSTRUCTIONS/APPLE_Quickstart_v2.2.txt")],
    [L("APPLE_Core_Council_Roles_Meaning_Inspiration.txt"), P("APPLE_Architecture_Product_Performance_Lean_Engineering_v2.2", "*PROMPTS/*Subordinate*")],
    superseded=["MAMMON_25TH_RECOVERY_M5_v1.0/02_MAMMON_APPLE/APPLE_Master_v2.0.txt (v2.0, provenance)"],
    notes=["The Claude environment already offers an `@apple` skill ('run the APPLE Core Council review with KEEP/REMOVE/SIMPLIFY/ADAPT/REPLACE verdicts'). Keep it; this file is the authoritative definition it should mirror (see SUGGESTIONS S-APPLE-1).",
           "Council members are inspiration lenses, not impersonation of real people."])
add("ARGOS", "ARGOS", "Academic Research Governance, Opposition & Synthesis", "Specialist (research)", "ACTIVE", "v1.8",
    [P("ARGOS_Academic_Research_Governance_Opposition_and_Synthesis_v1.8_Package", "*prompts/ARGOS_v1.8_MASTER_PROMPT.txt", "*ARGOS_v1.8_ABOUT_AND_SUBORDINATES.txt", "*prompts/ARGOS_v1.8_INVOCATIONS.txt", "*ARGOS_v1.8_QUICKSTART.txt")],
    [P("ARGOS_Academic_Research_Governance_Opposition_and_Synthesis_v1.8_Package", "*")],
    tools="WebSearch/WebFetch for evidence, the deep-research skill (needs subagents), Docs/Artifact for publications.",
    notes=["Research must use real tools (WebSearch/WebFetch); never cite sources not actually retrieved. The 10-15 expert panel is a set of perspectives Claude adopts, not parallel instances."])
add("ARTEMIS", "ARTEMIS", "Asset Realization, Transformation, Engineering, Management & Integration System", "Specialist (asset production)", "ACTIVE", "v1.1",
    [P("ARTEMIS_Asset_Realization_Transformation_Engineering_Management_Integration_System_v1.1", "*")], [],
    tools="Bash/Write for asset pipelines; heavy production via Codex WORKinCODEX.")
add("BIFROST", "BIFROST", "Local-first information & interoperability fabric of edenOS (CONNECT · KEEP · RESOLVE)", "App / specialist prompt package", "ACTIVE (v0.1 prompt package; app is in development)", "v0.1",
    [P("BIFROST_Project_Prompt_Package_v0.1", "*prompts/BIFROST_MASTER_PROMPT.txt", "*01_TELL_ME_ABOUT_YOURSELF.txt", "*02_BIFROST_PROJECT_GOALS.txt", "*README.txt")],
    [P("BIFROST_Project_Prompt_Package_v0.1", "*"), L("EDEN_BIFROST_CONDUCTOR_Modular_Ecosystem_Architecture.txt")],
    notes=["BIFROST implementation is a Swift app built via Codex/Mac; this definition guides development chats. See the BIFROST Project Bible if present in the canon."])
add("CAMEL", "CAMEL", "Cargo, Assets, Movement, Execution & Logistics", "App / helper", "ACTIVE", "v0.3.1 (naming reconciled)",
    [P("CAMEL_Cargo_Assets_Movement_Execution_Logistics_v0.3.1_Naming_Reconciled", "*prompts/CAMEL_MASTER_PROMPT.txt", "*CAMEL_About_EN.txt", "*README_EN.txt", "*MIGRATION_VERIFICATION.txt", "*prompts/*_PROMPT.txt")],
    [P("CAMEL_Cargo_Assets_Movement_Execution_Logistics_v0.3.1_Naming_Reconciled", "*")],
    superseded=["CAMEL v0.3 prompt package (pre naming reconciliation)"],
    notes=["No live fleet/tracking data in chat: planning/analysis only unless a provider is connected."])
add("CASPER", "CASPER the GhostWriter", "Creative Authoring, Storytelling, Publishing, Editing & Research", "Specialist (publication)", "ACTIVE", "v2.2 (corrected)",
    [P("CASPER_Creative_Authoring_Storytelling_Publishing_Editing_and_Research_v2.2_Corrected_Package", "*CASPER_v2.2_MASTER.txt", "*CASPER_v2.2_INSTRUCTIONS.txt", "*CASPER_v2.2_QUICKSTART.txt")],
    [P("CASPER_Creative_Authoring_Storytelling_Publishing_Editing_and_Research_v2.2_Corrected_Package", "*")],
    superseded=["CASPER v1.7, v2.0, v2.1, v2.2_Package (non-corrected)"],
    tools="Docs/Artifact for the publication graph; project files for canon.",
    notes=["Internal subordinates were migrated: CASPER.READ -> CASPER.AUDITOR (001), CASPER.THREAD -> CASPER.CORD (003). Shared EDEN READ and THREAD are separate helpers."])
add("CURATOR_HELPER", "CURATOR (assistant prompt package)", "Creative Understanding, Review, Asset Tagging, Organization & Retrieval", "App / helper", "ACTIVE", "v1.0 prompt package",
    [P("CURATOR_Assistant_Prompt_Package_v1.0", "*prompts/CURATOR_v1.0_MASTER.txt", "*CURATOR_v1.0_ABOUT_EN.txt", "*CURATOR_v1.0_MODULES.txt", "*prompts/subordinates/*")],
    [P("CURATOR_Assistant_Prompt_Package_v1.0", "*")], invoke="@CURATOR MASTER",
    notes=["The CURATOR macOS app itself (Swift) is a separate project built via Codex; see the CURATOR Project Bible in the canon. Media files live on the Mac: access only on Mac-linked sessions."])
add("GRANDMASTER", "EDEN Grandmaster (Research / Web / Field / Prototype workstreams)", "(expansion not recovered - RECOVERY_PENDING)", "Master prompt + workstream masters", "RECOVERY_PENDING (v0.1 handoff package)", "v0.1",
    [P("EDEN_Grandmaster_Research_Web_Field_Prototype_Handoff_v0.1", "*")], [], invoke="@GRANDMASTER",
    notes=["Only a v0.1 handoff package exists; GrandMasterRegister (GMR) is a catalogue, not this prompt. Do not treat it as ACTIVE canon without Lucas confirming."])
add("FORGE", "FORGE (EITRI persona)", "Full-stack Orchestration, Reliability, Generation & Engineering", "Specialist (engineering)", "ACTIVE (with naming conflict flagged)", "v2.0 (EITRI)",
    [P("FORGE_Full-stack_Orchestration_Reliability_Generation_and_Engineering_v2.0_Package_EITRI", "*FORGE_v2.0_MASTER.txt", "*FORGE_v2.0_INSTRUCTIONS.txt", "*FORGE_v2.0_QUICKSTART.txt", "*docs/FORGE_v2.0_EITRI_IDENTITY.txt", "*profiles/FORGE_v2.0_MODE_PROFILES.txt")],
    [P("FORGE_Full-stack_Orchestration_Reliability_Generation_and_Engineering_v2.0_Package_EITRI", "*")],
    superseded=["FORGE v1.7.1"],
    tools="Bash/Read/Write/Edit locally in the cloud container; Mac builds via RDC; heavy implementation via Codex WORKinCODEX.",
    notes=["Name collision: FORGE (engineering helper, this file) vs ForgeMASTER (governor) vs EITRIFactory (production executor) vs EITRI/EITRIMB (superseded governor, provenance). FORGE's 'EITRI persona' is an engineering persona only and has NO governor authority."])
add("HERMES", "HERMES", "Hiring, Employment, Research, Matching & Execution System", "App / helper", "ACTIVE", "v1.6",
    [P("HERMES_Hiring_Employment_Research_Matching_Execution_System_v1.6", "*prompts/HERMES_MASTER_v1.6.txt", "*HERMES_ABOUT_AND_SUBORDINATES_v1.6.txt", "*HERMES_QUICKSTART_v1.6.txt", "*docs/HERMES_SUBORDINATE_REGISTRY_v1.6.txt")],
    [P("HERMES_Hiring_Employment_Research_Matching_Execution_System_v1.6", "*")],
    superseded=["HERMES App prompt package v0.1.0, HERMES v1.5 package"],
    tools="Indeed connector (search jobs, company data, resume) when connected; WebSearch/WebFetch; Docs for tailored documents. Never submit applications without explicit user approval.",
    notes=["The v1.6 package still contains HERMES_MASTER_v1.4.txt next to the v1.6 master prompt (kept as reference)."])
add("IRIS", "IRIS", "Intelligent Realism & Image Synthesis", "Specialist (visual)", "ACTIVE", "v1.8",
    [P("IRIS_Intelligent_Realism_and_Image_Synthesis_v1.8_Package", "*IRIS_v1.8_MASTER.txt", "*IRIS_v1.8_ABOUT_IRIS_AND_SUBORDINATES.txt", "*IRIS_v1.8_INSTRUCTIONS.txt", "*IRIS_v1.8_QUICKSTART.txt", "*prompts/IRIS_v1.8_MASTER_PROMPT.txt")],
    [P("IRIS_Intelligent_Realism_and_Image_Synthesis_v1.8_Package", "*"), P("EDEN_Name_Migration_002_IRIS_FORGE_to_FOUNDRY", "*")],
    superseded=["IRIS v1.6, v1.7"],
    notes=["LIMITATION: Claude has no image-generation tool here. IRIS in Claude = research-grounded art direction, prompt/spec writing, SVG/diagram work and forensic QA of images Lucas supplies; actual rendering needs an external generator."])
add("LINGUA", "LINGUA", "Language Interpretation, Nuance, Glossary & Unified Adaptation", "App / helper", "ACTIVE", "v1.6",
    [P("LINGUA_Language_Interpretation_Nuance_Glossary_and_Unified_Adaptation_v1.6", "*LINGUA_v1.6_MASTER_PROMPT.txt", "*LINGUA_v1.6_MASTER.txt", "*LINGUA_v1.6_ABOUT_SELF_AND_SUBORDINATES.txt", "*LINGUA_v1.6_SUBORDINATE_PROMPTS.txt", "*LINGUA_v1.6_PROJECT_INSTRUCTIONS.txt", "*LINGUA_v1.6_QUICKSTART.txt")],
    [P("LINGUA_Language_Interpretation_Nuance_Glossary_and_Unified_Adaptation_v1.6", "*")], tools="Translation card widget for short passages; project files for glossaries.")
add("MIRROR", "MIRROR", "Multidisciplinary Independent Review, Ranking, Observation & Reference", "Specialist (review)", "ACTIVE", "v1.5 (final corrected)",
    [P("MIRROR_Multidisciplinary_Independent_Review_Ranking_Observation_and_Reference_v1.5_Final_Corrected_Package", "*prompts/MIRROR_v1.5_MASTER_PROMPT.txt", "*MIRROR_v1.5_ABOUT_AND_SUBORDINATES.txt", "*MIRROR_v1.5_INSTRUCTIONS.txt", "*MIRROR_v1.5_QUICKSTART.txt")],
    [P("MIRROR_Multidisciplinary_Independent_Review_Ranking_Observation_and_Reference_v1.5_Final_Corrected_Package", "*")],
    superseded=["MIRROR v1.4, v1.5_Package (non-final), MIRROR_FORGE cross-platform v0.1.0 (app packaging, provenance)"],
    notes=["Simulated reviewer/reader panels are modeling techniques, never real human surveys."])
add("MONETA", "MONETA", "Monetary Operations, Navigation, Evaluation, Treasury & Accounting", "Domain governor (finance)", "ACTIVE (in-chat protocol v1.0; v1.7 UIX experimental package)", "in-chat v1.0 / package v1.7",
    [R("canon/MONETA_IN_CHAT_OPERATING_PROTOCOL_v1.0.txt", "canon/MONETA_B0_FUNCTION_REGISTRY_v1.0.txt")],
    [R("tests/MONETA_B0_REFERENCE_WORKFLOW_TESTS_v1.0.txt"),
     P("MONETA_Monetary_Operations_Navigation_Evaluation_Treasury_and_Accounting_v1.7_UIX_EXPERIMENTAL", "*05_PROMPTS/MONETA_MASTER_PROMPT_v1.5.txt", "*00_README/MONETA_TELL_ME_ABOUT_YOURSELF_AND_SUBORDINATES_v1.5.txt", "*01_MASTER/*", "*20_COMPANIES/*", "*00_README/APPDEV_ALIGNMENT_v1.4.txt", "*70_TRACEABILITY/*", "*30_SUBORDINATES/*")],
    superseded=["MONETA v1.5 experimental package"], invoke="@MONETA AUTO",
    tools="Bash/python for calculations (always compute, never estimate); Supabase for PWA data; financial data stays local/private - no financial figures in shared artifacts without Lucas's say-so.",
    notes=["Development order IN-CHAT -> PWA -> APP. In-chat financial results need verification by computation; Claude is not a licensed advisor."])
add("ELYSIUM", "ELYSIUM (Personal + Business suite)", "Integrated personal/household and professional/company economic environment", "Suite (in-chat)", "ACTIVE (in-chat canon v1.0)", "v1.0",
    [R("canon/ELYSIUM_IN_CHAT_SUITE_CANON_v1.0.txt")], [], invoke="@ELYSIUM",
    notes=["Canon says 'entirely in ChatGPT'; in this Project read that as 'entirely in-chat' (Claude). Suite members include MONETA; plugin/capability discovery maps to Claude connectors (Indeed, Supabase, Cloudflare, etc.)."])
add("ORACLE", "ORACLE", "Analytics Intelligence (generalized analytics & quantitative intelligence)", "App / helper (experimental)", "ACTIVE (experimental)", "v0.1",
    [P("ORACLE_Analytics_Intelligence_v0.1_Experimental", "*")], [], tools="Bash python for real analysis; dataviz skill for charts; chart widget for small charts.")
add("READ", "READ", "Reader Experience Assessment Directorate", "Specialist (audience review)", "ACTIVE", "v1.5",
    [P("READ_Reader_Experience_Assessment_Directorate_v1.5_Package", "*READ_v1.5_MASTER.txt", "*prompts/READ_v1.5_MASTER_PROMPT.txt", "*READ_v1.5_ABOUT_AND_SUBORDINATES.txt", "*READ_v1.5_INSTRUCTIONS.txt")],
    [P("READ_Reader_Experience_Assessment_Directorate_v1.5_Package", "*")], superseded=["READ v1.4"],
    notes=["Simulated reader panels are not market research. Subordinates were renamed in v1.5 (LORE->SHORTSPAN, THREAD->BOOKMARK, MIRROR->TWINLIKENESS, SCOPE->READSIDEBYSIDE, PRISM->READROUNDtable, QUILL->SCRIBELET)."])
add("SKALD", "SKALD", "StoryKeeper: Archive, Lifestyle & Delivery", "App / helper (design intro only)", "RECOVERY_PENDING (single 'Tell me about yourself' document)", "v1.0",
    [P("SKALD_Tell_Me_About_Yourself_v1.0", "*")], [], notes=["No master prompt recovered - do not invent one."])
add("THREAD", "THREAD", "Transcript, History, Retrieval, Extraction, Analysis & Discovery", "Specialist (history/continuity)", "ACTIVE", "v1.4 (master header v1.4.1)",
    [P("THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package", "*THREAD_v1.4_MASTER.txt", "*THREAD_v1.4_INSTRUCTIONS.txt", "*THREAD_v1.4_ABOUT_SELF_AND_SUBORDINATES.txt")],
    [P("THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package", "*"), L("EDEN_THREAD_Comprehensive_Identity_Function_Register_STAGING_v1.0.txt")],
    tools="claude.ai conversation_search / recent_chats / read_conversation (past chats), Projects project_search, memory files; ForgeMASTER `@thread auto` uses these.",
    notes=["CLAUDE ADAPTATION: the original searches 'previous ChatGPT work'. In Claude, THREAD searches claude.ai chats via conversation_search/recent_chats/read_conversation, the Project docs via project_search, and Claude memory; it must say plainly when a source (e.g. old ChatGPT history) is inaccessible and never pretend it was searched."])
add("WEAVER", "WEAVER", "Web Experience Architecture, Validation, Engineering & Reach", "Specialist (web)", "ACTIVE", "v1.6",
    [P("WEAVER_Web_Experience_Architecture_Validation_Engineering_and_Reach_v1.6_Package", "*WEAVER_v1.6_MASTER.txt", "*WEAVER_v1.6_TELL_ME_ABOUT_YOURSELF_AND_SUBORDINATES.txt", "*WEAVER_v1.6_SUBORDINATE_REGISTRY.txt", "*WEAVER_v1.6_INSTRUCTIONS.txt", "*WEAVER_v1.6_QUICKSTART.txt")],
    [P("WEAVER_Web_Experience_Architecture_Validation_Engineering_and_Reach_v1.6_Package", "*")], superseded=["WEAVER v1.5"],
    tools="Artifact tool for sites/PWAs; deploy from GitHub (no local node_modules) per Lucas's PWA preference; Cloudflare/Supabase connectors; Codex for heavy builds.")
add("MAMMON", "MAMMON", "Money Acquisition, Monetisation, Making Ends Meet Operations Network", "Strategy helper", "ACTIVE (v0.1 handoff; strategy only - does not replace HERMES/MONETA)", "v0.1",
    [P("MAMMON_v0.1_HANDOFF_PACKAGE", "*")], [P("MAMMON_25TH_RECOVERY_M5_v1.0", "00_CONTROL/README.txt", "00_CONTROL/RECOVERY_LEDGER.txt", "00_CONTROL/PROVENANCE_MAP.txt")],
    notes=["Income/opportunity value-realization strategy only; HERMES owns jobs, MONETA owns finance."])
add("APPDEV_MASTER", "appDev MASTER (registry reconciliation handoff)", "Canonical EDEN/AppDev master registry of Apps, Products, Workspaces, Helpers, Agents, Modules, Capabilities, Providers", "Reconciliation handoff", "ACTIVE reference (procedure/identity decisions)", "v1.0",
    [L("APPDEV_MASTER_v1.0_HANDOFF.txt")], [P("EDEN_Naming_Reconciliation_Handoff_v1.0_Package", "*")], parent="ForgeMASTER / GrandMasterRegister (GMR)",
    notes=["This is a one-time reconciliation handoff for a ChatGPT chat; the actual catalogue authority is GMR (see reconciled/GMR.txt). Keep as identity-decision reference."])

# ---------------- provenance-only (registry rows, no .claude.md) ----------------
PROV = [
    ("EITRIMB / EITRI", "EITRI — Master Builder (EITRIMB)", "SUPERSEDED", "superseded by ForgeMASTER as parallel governor; provenance in reconciled/_provenance/superseded/ and Mac #app-assistants (EITRIMB.txt, LKG-pre-overhaul, handoffs, v0.1.0 zip)"),
    ("AppDev Core Principles v1.1", "Core principles package", "PROVENANCE", "older private canon; current authority = reconciled APPDEV_BIBLE.md + AppDevRules"),
    ("EDEN AppDev Active Canon v1.8 / Lucas Private Rules Recovery Candidate v1.8 / edenOSrules(_v1.2)", "older private rule sets", "PROVENANCE", "superseded by the reconciled AppDev canon; keep for history"),
    ("EDEN AppDev Assistant Ecosystem v0.3", "ecosystem inventory + authority map", "PROVENANCE (authority-map still useful)", "docs/01_ECOSYSTEM_INVENTORY.txt and docs/25_CURRENT_AUTHORITY_MAP.txt feed the registry roles"),
    ("EDEN Personal Grand Backup v2.0", "personal grand backup", "PROVENANCE", "private/personal data: not mirrored into the shared project docs"),
    ("edenOS Core Architecture Reference v0.1 / edenOS M1-M3 v3.7.1 Recovery Hotfix", "edenOS vision/core design", "PROVENANCE", "reference for edenOS vision docs"),
    ("MIRROR_FORGE Cross-Platform v0.1.0", "MIRROR app packaging", "PROVENANCE", "app/package source, not a helper definition"),
    ("CURATOR_Private v1.0-uix-experimental source / CURATOR v0.5-alpha.edenpkg", "CURATOR app source/packages", "PROVENANCE", "app source; see CURATOR Project Bible"),
    ("AOS", "autonomous/sequential workflow and synchronized production pipeline", "RECOVERY_PENDING", "named in APPLE/WEAVER/ECOSYSTEM docs and APPLE AOS subordinate prompt, but no AOS master definition was found in the staged packages"),
    ("PENELOPE", "source continuity & fragmented-version reconciliation", "ACTIVE (Project Bible)", "see reconciled/Project Bibles/PENELOPE.txt"),
    ("HEIMDALL", "ORGANIZE & UNDERSTAND workspace app", "ACTIVE (Project Bible)", "see reconciled/Project Bibles/HEIMDALL iOS.txt"),
    ("THEMIS / CHRONOS / PROMETHEUS / JANITOR", "domain apps named in the authority map", "RECOVERY_PENDING (no helper definition staged)", "do not invent definitions"),
]

PREAMBLE = """> **READ MIRROR - GitHub `lucasbuzek/Lucas-private-appDevDocs` and the Mac `~/edenOS/AppDev` are canonical.** Generated 2026-10-07 by `AppDevCanon/tools/build_claude_helpers.py`; the section "ORIGINAL DEFINITION" below is the helper's own text, embedded verbatim and unmodified. Only this framing header is Claude-specific.

## How to run it in Claude (claude.ai Project "edenOS App Development")
- **Invoke** with `{invoke}` (as in its own commands). Claude adopts the role in-chat; Lucas's current instruction always wins.
- **Governance:** {parent}. Specialists own their domain; evidence determines state: GENERATED != IMPLEMENTED != BUILT != TESTED != VERIFIED != RELEASED; UNKNOWN != PASS. Canonical procedure first (AppDevRules/00_CANONICAL_PROCEDURE_FIRST_RULE).
- **Panels/subordinates** described in the definition are perspectives Claude adopts sequentially in one chat (single-chat simulation), not parallel running instances, unless Lucas explicitly asks for subagents.
- **Tools - decide by what is actually present, never by assumption:** Project docs (always, for the canon mirror); web search/fetch; Bash/Read/Write/Edit in the cloud container; Artifact (hosted pages, typed docs/decks/sheets); the task list widget (LCAS/UIbasic style progress); Claude memory. {tools}
- **Mac-linked sessions only** (Claude desktop app / Claude Code with Remote Desktop Commander tools present): Mac files, `gh` as lucasbuzek, `codex` CLI. **Browser and iPhone-app sessions have none of these** - work from the mirrored Project files and say so. Claude's own GitHub connector does not reach the private repos on any surface.
- **Heavy work** (builds, large implementation, long autonomous pipelines) is offloaded to Cloud Codex via WORKinCODEX (handoff file -> `codex cloud exec --env lucas-Private-edenOS-apps`); run locally only when really necessary. Lucas may authorize automatic submission; otherwise stop at the Terminal Enter gate.
"""

ISMS = [("ChatGPT", r"ChatGPT"), ("GPT/Custom GPT", r"\bGPTs?\b|Custom GPT"), ("Project files/instructions upload", r"Project (instructions|files|knowledge)|upload(ed)? (the )?(file|package|zip)"),
        ("browsing", r"\bbrows(e|ing)\b"), ("Python/Data Analysis tool", r"Advanced Data Analysis|Code Interpreter|Python tool"), ("Canvas", r"\bCanvas\b"),
        ("prior-chat history", r"previous (ChatGPT|chats?|conversations?)|conversation history")]


def read(p):
    return open(p, encoding="utf-8", errors="replace").read()


def collect(entries):
    seen, out = set(), []
    for (src, pats) in entries:
        for p in gather(src, pats):
            if p not in seen:
                seen.add(p)
                out.append(p)
    return out


def disp(p):
    for base, tag in ((REC, "reconciled/"), (PK, "packages/"), (LOOSE, "loose/")):
        if p.startswith(base):
            return tag + os.path.relpath(p, base)
    return p


os.makedirs(OUT, exist_ok=True)
for f in os.listdir(OUT):
    os.remove(os.path.join(OUT, f))
registry = []
for hid, h in H.items():
    prim = collect(h["primary"])
    prim_set = set(prim)
    ref = [p for p in collect(h["reference"]) if p not in prim_set]
    # if the primary is too long, move the largest primary to reference
    prim_sorted = sorted(prim, key=lambda p: -len(read(p)))
    while prim and sum(words(read(p)) for p in prim) > MAX_WORDS and len(prim) > 1:
        big = prim_sorted.pop(0)
        prim.remove(big)
        ref.insert(0, big)
    missing = [pt for (src, pats) in h["primary"] for pt in pats if not gather(src, [pt])]
    body_prim = "".join("\n\n---\n### SOURCE: `%s`\n(sha256 %s)\n\n%s\n" % (disp(p), sha(open(p, "rb").read()), read(p).rstrip()) for p in prim)
    isms = {}
    allp = "\n".join(read(p) for p in prim)
    for label, rx in ISMS:
        n = len(re.findall(rx, allp))
        if n:
            isms[label] = n
    notes = "\n".join("- " + n for n in h["notes"]) or "- (none beyond the runtime mapping above)"
    tp = "; ".join("%s x%d" % kv for kv in isms.items()) or "none detected"
    head = ("# %s - Claude in-chat definition\n\n**Name:** %s  \n**Expansion:** %s  \n**Kind:** %s  \n**Status (GMR vocabulary, proposed from evidence):** %s  \n**Version used:** %s  \n**Superseded/omitted versions:** %s  \n"
            % (h["display"], h["display"], h["expansion"], h["kind"], h["status"], h["version"], "; ".join(h["superseded"]) or "none"))
    head += "\n" + PREAMBLE.format(invoke=h["invoke"], parent=h["parent"], tools=("**Helper-specific tools:** " + h["tools"]) if h["tools"] else "")
    head += "\n### Claude adaptation notes and LIMITATIONS\n" + notes + "\n\n### Transport assumptions detected in the original (ChatGPT-era wording left untouched)\n" + tp + "\nRead each as its Claude equivalent: ChatGPT -> Claude; Custom GPT / Project upload -> this Claude Project's files; browsing -> WebSearch/WebFetch; Python tool -> Bash/Read/Write; previous chats -> conversation_search/recent_chats/read_conversation and project_search; Canvas -> Artifact.\n"
    if missing:
        head += "\n**RECOVERY_PENDING: expected source(s) not found:** " + ", ".join(missing) + "\n"
    doc = head + "\n\n## ORIGINAL DEFINITION (verbatim)\n" + body_prim
    open(os.path.join(OUT, "%s.claude.md" % hid), "w", encoding="utf-8").write(doc)
    ref_words = 0
    if ref:
        parts, used = [], 0
        omitted = []
        for p in ref:
            t = read(p)
            if used + len(t) > REF_CAP:
                omitted.append(disp(p))
                continue
            used += len(t)
            parts.append("\n\n---\n### SOURCE: `%s`\n(sha256 %s)\n\n%s\n" % (disp(p), sha(open(p, "rb").read()), t.rstrip()))
        rdoc = "# %s - reference material (verbatim sources; not needed for normal operation)\n\nSee `%s.claude.md` for the operating definition. READ MIRROR.\n" % (h["display"], hid)
        if omitted:
            rdoc += "\n**Omitted for size (%d files; still in the Mac/GitHub sources):** %s\n" % (len(omitted), ", ".join(omitted[:60]))
        rdoc += "".join(parts)
        open(os.path.join(OUT, "%s_reference.md" % hid), "w", encoding="utf-8").write(rdoc)
        ref_words = words(rdoc)
    registry.append(dict(id=hid, name=h["display"], expansion=h["expansion"], kind=h["kind"], status=h["status"], version=h["version"], superseded_or_omitted=h["superseded"],
                         primary_sources=[disp(p) for p in prim], reference_sources=[disp(p) for p in ref], claude_file="claude-helpers/%s.claude.md" % hid,
                         words_main=words(doc), words_reference=ref_words, transport_assumptions=isms, missing_sources=missing, governed_by=h["parent"]))

# registry outputs
with open(os.path.join(ROOT, "claude-helpers", "helper_registry.json"), "w", encoding="utf-8") as f:
    json.dump(dict(generated="2026-10-07", note="Proposed from evidence; GMR (reconciled/GMR.txt) remains the catalogue authority. Statuses use GMR vocabulary.", helpers=registry,
                   provenance_only=[dict(name=a, expansion_or_role=b, status=c, note=d) for a, b, c, d in PROV]), f, indent=2, ensure_ascii=False)
md = ["# HELPER REGISTRY (Claude in-chat) - generated 2026-10-07\n",
      "Proposed from evidence; **GMR remains the catalogue authority** (`reconciled/GMR.txt`): TYPE != CAPABILITY != PROVIDER != INSTANCE != REPRESENTATION != WORKSPACE; UNRESOLVED != PERMISSION TO INVENT. Expansions below are only those stated in the sources (or the package folder names); anything else is RECOVERY_PENDING.\n",
      "| ID | Name | Expansion | Kind | Status | Version | Words (main/ref) | Claude file |", "|---|---|---|---|---|---|---|---|"]
for r in registry:
    md.append("| %s | %s | %s | %s | %s | %s | %d / %d | `%s` |" % (r["id"], r["name"], r["expansion"], r["kind"], r["status"], r["version"], r["words_main"], r["words_reference"], os.path.basename(r["claude_file"])))
md += ["\n## Provenance / superseded / recovery-pending (no Claude definition generated)\n", "| Item | Role | Status | Note |", "|---|---|---|---|"]
for a, b, c, d in PROV:
    md.append("| %s | %s | %s | %s |" % (a, b, c, d))
md += ["\n## Superseded/omitted versions per helper\n"]
for r in registry:
    if r["superseded_or_omitted"]:
        md.append("- **%s:** %s" % (r["id"], "; ".join(r["superseded_or_omitted"])))
md += ["\n## Missing sources\n"] + ["- **%s:** %s" % (r["id"], ", ".join(r["missing_sources"])) for r in registry if r["missing_sources"]] + ([] if any(r["missing_sources"] for r in registry) else ["- none"])
open(os.path.join(ROOT, "claude-helpers", "HELPER_REGISTRY.md"), "w", encoding="utf-8").write("\n".join(md) + "\n")
print("helpers:", len(registry), "main words max:", max(r["words_main"] for r in registry), "missing:", [(r["id"], r["missing_sources"]) for r in registry if r["missing_sources"]])
