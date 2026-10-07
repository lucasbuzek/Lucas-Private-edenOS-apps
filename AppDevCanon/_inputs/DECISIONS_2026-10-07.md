# Lucas decisions for AppDev canon reconciliation (2026-10-07, Africa/Johannesburg)

00:51 "They need to work within here and not needed to be referenced every time remotely, they need to be copied in files for whole project folder to apply here" (Claude Project "edenOS App Development").
00:53 "It needs to be reconciled first."
01:21 "Reconcile, apply for all conversations in edenOS app development; Locate all in chat helpers; adapt for Claude in-chat use (offer suggestions or fixes to their functionality)" — approval of Claude's proposals below.
01:22 "Any hard work needs be offloaded to codex WORKinCODEX."

Approved proposals (from CANON_RECONCILIATION_2026-10-07.md):
1. APPDEV_BIBLE: merge — keep APPDEV_BIBLE.md (2026-10-06) structure, add the three 2026-10-01 sections that exist only in APPDEV_BIBLE.txt (Thin-governor execution update; Universal deliverable evidence rule; AUTO execution enforcement), reconciled against ForgeMASTER as sole governor.
2. WORKinCODEX / GitHub route: amend to newest user decision (2026-10-06): `gh` CLI on Lucas's Mac is authorized (lucasbuzek); Claude reaches the Mac via Remote Desktop Commander; Claude's own GitHub connector does not reach the private repos; ChatGPT's connector route remains valid for ChatGPT.
3. handoffClaude: keep for standalone Claude packages; add an in-project note — Claude inside the claude.ai Project "edenOS App Development" has RDC → Mac → gh/codex and follows WORKinCODEX/ForgeMASTER directly.
4. Copy vs reference: Claude Project copies are a READ MIRROR with source path + SHA-256 per file; GitHub (lucasbuzek/Lucas-private-appDevDocs) stays canonical; edits go to GitHub first, then re-mirror to Mac and Claude Project.
5. Per-file direction: take GH where GH has the newer reconciled commit; take GH (fuller text) where direction is unknown and keep Mac condensed text as provenance; take MAC for UNIVERSAL_PROJECT_STORAGE_RULE.md (matches real ~/edenOS/AppDev layout); bring Mac-only canon (APPDEV_BIBLE, GMR, DESIGN_MANTRA, namingRules, HEIMDALL/PENELOPE/edenOS Embedded/CRESUS Bibles) into the canonical set; ForgeMASTER wins over EITRI/EITRIMB (provenance only).

Clarification (Lucas, 2026-10-07 04:48): "It didn't have access before, only in browser and iPhone app." => The old no-access assumption for Claude was correct for the browser and iPhone-app surfaces and remains correct there. Access (Mac via Remote Desktop Commander, gh, codex) exists only on Mac-linked sessions (Claude desktop app / Claude Code). Canon amendments are therefore SURFACE-DEPENDENT, decided by tools actually present. This is also why canon is mirrored into the Claude Project files: browser/iPhone sessions can only use the mirror.
