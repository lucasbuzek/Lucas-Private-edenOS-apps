# SUGGESTIONS AND FIXES — Claude in-chat helpers (2026-10-07)

Status: PROPOSALS, not canon. Helper text was embedded verbatim; nothing below has been applied to any source. Lucas decides.
Evidence: `tools/build_claude_helpers.py` run 2026-10-07 — 25 helpers, max 4130 main words, 0 missing sources. Counts from grep over `claude-helpers/*.claude.md`.

| ID | Helper | Finding | Evidence | Sev | Proposed fix | Decides |
|---|---|---|---|---|---|---|
| S1 | all | Original wording assumes ChatGPT transport (ChatGPT, Custom GPT, Project upload, Canvas, Python tool). Left untouched; each Claude file carries a mapping header. | Every `*.claude.md` matches ChatGPT/GPT/Canvas/Python-tool patterns | P2 | Keep mapping header; later, a canon edit pass to neutral "in-chat" wording, GitHub first | Lucas |
| S2 | THREAD | Most ChatGPT-specific (8 ChatGPT mentions): searches "previous ChatGPT work". In Claude it must use conversation_search/recent_chats/project_search and say plainly when a source is inaccessible. | grep count; adaptation note in generator | P1 | Adopted in Claude file as note; rewrite source wording | Lucas |
| S3 | FORGEMASTER, ELYSIUM, LINGUA, MAMMON, GRANDMASTER | Extra ChatGPT references (4–5) beyond baseline — "entirely in ChatGPT" style statements. | grep counts | P2 | Read as "in-chat"; neutralise at source | Lucas |
| S4 | FORGE / EITRI | Naming conflict: FORGE persona is EITRI, but EITRI/EITRIMB governor is SUPERSEDED by ForgeMASTER. | Registry status "ACTIVE (with naming conflict flagged)" | P1 | Rename persona or add explicit "persona only, not governor" line at source | Lucas |
| S5 | Modern Generals Native Bible | Stale header "Governor: EITRI — The Master Builder Governor v0.2.0". | `reconciled/Project Bibles/Modern Generals Native.txt:4` | P1 | Replace with "Governor: ForgeMASTER" in GitHub | Lucas |
| S6 | GRANDMASTER | Expansion not recovered; v0.1 handoff only. Must not be invented. | Registry RECOVERY_PENDING | P2 | Supply the expansion/source if it exists | Lucas |
| S7 | SKALD | Only a single design-intro document exists. | Registry RECOVERY_PENDING | P2 | Provide full prompt package or keep as design intro | Lucas |
| S8 | MONETA | Two versions: in-chat protocol v1.0 vs UIX experimental package v1.7. Reference file is large (~19k words). | Registry words 2129/18955 | P2 | Decide which is active for in-chat use | Lucas |
| S9 | ARGOS, MIRROR, IRIS, MONETA, HERMES | Large reference overflow files (8k–19k words) — slow to load in a chat. | Registry word counts | P3 | Load main file by default; read `_reference.md` only on demand | Claude (default) |
| S10 | LCAS / UIbasic | No native widget in the old canon; in Claude they map to the task list and compact status blocks. | Generator preamble | P3 | Keep mapping; confirm look | Lucas |
| S11 | Panels / subordinates | Council helpers (APPLE, MIRROR, READ) describe multiple parallel members; in one chat they are simulated sequentially, not parallel instances. | Design of single-chat runtime | P3 | State this on first use | Claude (default) |
| S12 | Canon storage | Reconciled canon contradicts older "reference, don't duplicate" text. Resolved by the 2026-10-07 user decision: Project copies are a read mirror, GitHub canonical. | RECONCILIATION_LOG.md | P2 | Edit FORGEMASTER_IN_CHAT_BOOTSTRAP wording at source | Lucas |
| S13 | Sync | GitHub, Mac and the reconciled set are not yet synchronized. Needs approval before pushing to `Lucas-private-appDevDocs`. | DECISIONS_2026-10-07.md | P1 | Review branch `appdev-canon-reconcile-20261007`, then approve push/sync | Lucas |
