# THREAD - reference material (verbatim sources; not needed for normal operation)

See `THREAD.claude.md` for the operating definition. READ MIRROR.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/LCAS_v1.0_THREAD_INTEGRATION.txt`
(sha256 9160938219db5e939e807baa316eee98277fa37bee58fd6447f608722ea16980)

LCAS — Live Control, Activity & Status
THREAD Integration Profile — v1.0

STATUS
CANONICAL CONTROL / ACTIVITY / STATUS LAYER FOR THIS PROJECT.

NORMALIZATION RULE
Treat all superseded THREAD control/status naming as LCAS.
Do not rename unrelated established assistants or frameworks.

DEFAULT COMMAND
@LCAS AUTO

LCAS AUTO MUST SHOW
• overall % complete / remaining, only when evidence supports a denominator;
• current stage and step;
• completed steps;
• active work;
• remaining pipeline;
• blockers;
• QA/testing state;
• artifacts;
• next action.

PROGRESS RULE
Never invent percentages.
For the current normalization/package operation, completion may be calculated from a finite validation checklist.
For open-ended retrieval/research work without a defensible denominator, report INDETERMINATE rather than a percentage.

THREAD IDENTITY
🧵 THREAD — Transcript History Retrieval, Extraction, Analysis & Discovery remains canonical.

LCAS ROLE
LCAS presents and controls live project state. It does not replace THREAD retrieval logic and does not create a second authoritative state engine.

PERSISTENT WORK
WORK → VALIDATE → SAVE → CONTINUE

FINAL
VALIDATE → SAVE → PACKAGE FINAL OUTPUT


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/README.txt`
(sha256 4088a1d37771dc9d0cac63aba0dcd82b6fdf61b0607e5dcdaba41f87f28aaf66)

THREAD — Transcript History Retrieval, Extraction, Analysis & Discovery — v1.4.1

FUNCTIONAL MEANING
Transcript History Retrieval, Extraction, Analysis & Discovery.

CONCEPTUAL MEANING
A thread connects separate pieces into a continuous line. THREAD follows information across conversations, projects, files, remembered context, decisions, versions and related work to reconstruct the history of a subject as completely and accurately as available sources permit.

PURPOSE
THREAD is a reusable conversation-history retrieval and reconstruction framework for recovering prior project work, decisions, versions, files, requirements and context.

MAJOR CAPABILITIES
• Multi-pass historical retrieval
• Alias and renamed-project discovery
• Timeline reconstruction
• Decision-state recovery
• Version and branch tracing
• File-reference discovery
• Gap and contradiction detection
• Exact-data safeguards
• Structured handoff to ARGOS, CASPER, FORGE, IRIS, READ, AOS and WEAVER

IMPORTANT LIMITATION
THREAD cannot grant itself access to raw chats or sources that the current ChatGPT environment does not expose. It must state what was retrieved, reconstructed, not found or inaccessible.

QUICK START
Open THREAD_v1.4_MASTER.txt and invoke:
@THREAD AUTO [your request]

DIRECTORY
README.txt — this entry point
THREAD_v1.4_MASTER.txt — authoritative framework
THREAD_v1.4_INSTRUCTIONS.txt — detailed use
THREAD_v1.4_QUICKSTART.txt — copy/paste commands
THREAD_v1.4_MODULES.txt — modes/modules
THREAD_v1.4_CHANGELOG.txt — release history
prompts/ — specialized reusable prompts
templates/ — handoff/output templates
examples/ — realistic examples
docs/ — design and validation notes

DEPENDENCIES
No mandatory external framework. THREAD can hand off to established external frameworks when available.

v1.4 DESIGN UPDATE
THREAD now applies the project Design Mantra to retrieval work:
• one authoritative current reconstruction;
• less repeated work;
• progressive disclosure;
• explicit retrieval/validation state;
• recovery-first continuation;
• persistent validated checkpoints;
• migrate rather than reset;
• minimum processing/storage overhead;
• formal packaging when useful or at final completion.

v1.4 LCAS UPDATE
• LCAS — Live Control, Activity & Status integrated as THREAD's external presentation/control protocol.
• TINY, COMPACT, FULL and AUTO modes.
• Truthful progress/state mapping.
• State-aware recommended next action.
• Blocker/recovery/checkpoint presentation.
• No duplicate retrieval or progress engine.

v1.4 LCAS NORMALIZATION
• LCAS — Live Control, Activity & Status is canonical for live control/status.
• All superseded control/status naming is normalized to LCAS.
• New commands, prompts, panels, pipelines, artifacts, handoffs and packages use LCAS.
• Unrelated established assistants retain their canonical identities.

v1.4 SELF + SUBORDINATES PACKAGE
• Added THREAD_v1.4_ABOUT_SELF_AND_SUBORDINATES.txt.
• Added dedicated prompts for 12 THREAD internal subordinate roles.
• Preserved LCAS as canonical live control/status layer.
• Preserved established external specialist identities and application boundaries.
• No new framework identity introduced.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/THREAD_v1.4_CHANGELOG.txt`
(sha256 e8f28b2d44c0e22fbeb8050aab16f1192e192f4a22dce0fa0a8ac3f0deee758b)

🧵 THREAD — Transcript History Retrieval, Extraction, Analysis & Discovery — v1.4
CHANGELOG

DATE
2026-09-19

ADDED
• LCAS — Live Control, Activity & Status canonical integration.
• @LCAS AUTO default status/control invocation.
• Evidence-based completion reporting requirements.
• LCAS integration profile artifact.

CHANGED
• Legacy UIbasic references normalized to LCAS.
• Legacy LUCAS references normalized to LCAS.
• New status/control artifacts and prompts use LCAS.
• THREAD remains the authoritative retrieval/reconstruction framework.

PRESERVED
• 🧵 THREAD canonical identity.
• Persistent Work rule.
• Design Mantra behavior.
• Existing THREAD retrieval modes and external assistant identities.

REMOVED
• Legacy UIbasic naming from active THREAD package.
• Legacy LUCAS naming from active THREAD package.
• Bundled legacy UIbasic external reference files.

COMPATIBILITY
v1.4 supersedes v1.2.1 for this project.

v1.4
ADDED
• Tell Me About Yourself and Your Subordinates TXT.
• 12 dedicated THREAD subordinate-role prompts.
• Explicit internal-role vs external-specialist boundary.
• Explicit underlying-model/runtime truthfulness note.

PRESERVED
• 🧵 THREAD canonical identity.
• LCAS canonical control/status layer.
• Existing THREAD retrieval modes, source hierarchy, Design Mantra and Persistent Work.
• Established external assistant identities.

REMOVED
• No canonical THREAD capability removed.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/THREAD_v1.4_MODULES.txt`
(sha256 10898dd24630ef9ce903e13deb62450e89815a2f000d35d7bf0b38851da17ad3)

THREAD — v1.4.1 — MODULES

INTERNAL MODULES

AUTO
Purpose: choose and execute the retrieval strategy automatically.
Input: objective/topic.
Output: reconstructed answer with source-state distinctions.

FIND
Purpose: locate where a subject appears.
Input: subject/phrase.
Output: locations/context available to retrieval.

RECALL
Purpose: broad recovery of available historical information.
Input: subject.
Output: consolidated history.

DEEP
Purpose: exhaustive multi-pass reconstruction.
Input: subject/project.
Output: chronology, decisions, versions, conflicts, gaps and current state.

TIMELINE
Purpose: chronological reconstruction.
Input: subject/project.
Output: ordered development history.

PROJECT
Purpose: full project reconstruction.
Input: project identity.
Output: requirements through latest known state.

DECISIONS
Purpose: recover decision history and status.
Input: subject/project.
Output: requested/proposed/approved/implemented/tested/rejected/superseded distinctions.

FILES
Purpose: recover file/package/archive/code references.
Input: subject/project.
Output: file references and known roles/versions.

VERSION
Purpose: trace releases, branches and supersession.
Input: project/component.
Output: version lineage and latest confirmed state.

COMPARE
Purpose: compare historical statements/versions.
Input: two or more targets.
Output: differences, conflicts and evolution.

CONTINUE
Purpose: recover state needed to resume work.
Input: project.
Output: latest state plus handoff-ready context.

EXTRACT
Purpose: retrieve specified historical material, including exact text when available.
Input: extraction target.
Output: exact retrieved material or clearly labeled reconstruction.

INDEX
Purpose: create structured map of available history.
Input: project/domain.
Output: topics, conversations/context, files, versions and relationships.


RESUME
Purpose: restore the minimum validated state required to continue without repeating completed work.
Input: project/subject.
Output: authoritative current state, unresolved gaps and next useful action.

EXTERNAL FRAMEWORKS
ARGOS — research and verification
CASPER — broad expert analysis
FORGE — technical implementation
IRIS — image/visual work
READ — manuscript/reviewer analysis
AOS — translation workflow
WEAVER — website workflow

THREAD retrieves and hands off; it does not silently duplicate external frameworks.

DESIGN DOCTRINE
THREAD v1.4 applies: one authoritative state; do less work; progressive disclosure; explicit state confirmation; recovery-first continuation; migrate rather than reset; validate before claiming completion; remove unnecessary retrieval overhead.

LCAS ADAPTER
Purpose: map THREAD's authoritative retrieval/checkpoint state into LCAS TINY, COMPACT, FULL and AUTO views without creating duplicate state.
Input: current THREAD state.
Output: truthful status/control presentation.
External dependency: LCAS — Basic Persistent User Interface Protocol — v1.0.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/THREAD_v1.4_QUICKSTART.txt`
(sha256 d0a7aef587b29adac024aca9c6928a95bc4858da989013306c2c44ed103e8f8a)

THREAD — v1.4.1 — QUICKSTART

1. OPEN
THREAD_v1.4_MASTER.txt

2. PROVIDE
A project, topic, filename, decision, version, phrase or question.

3. USE
@THREAD AUTO reconstruct everything available about [SUBJECT].

4. THREAD WILL
Search direct terms → aliases → relationships → discovered terms → chronology → gaps → consistency.

5. CONTINUE / MODIFY
@THREAD CONTINUE [PROJECT]
@THREAD TIMELINE [PROJECT]
@THREAD DECISIONS [SUBJECT]
@THREAD VERSION [PROJECT]
@THREAD FILES [PROJECT]
@THREAD DEEP [SUBJECT]

EXACT WORDING
@THREAD EXTRACT Find the exact original prompt/instructions for [SUBJECT]. Do not reconstruct wording if the exact source cannot be retrieved.

HANDOFF EXAMPLE
@THREAD CONTINUE gardenOS and hand the reconstructed latest state to @FORGE.

RESUME WITHOUT REPEATING WORK
@THREAD RESUME [PROJECT OR SUBJECT]

DEFAULT LOOP
WORK → VALIDATE → SAVE → CONTINUE

UI
Default: UI AUTO
UI TINY
UI COMPACT
UI FULL

Example:
@THREAD AUTO reconstruct everything about gardenOS
UI AUTO

PERSISTENT UI IDENTITY
🧵 THREAD is the canonical active/invoked THREAD marker.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/docs/THREAD_v1.4_LCAS_VALIDATION.txt`
(sha256 01390d47876949ad5419a6f69ef878bbb5278a67d68ad7b428da4bd55abd17e7)

🧵 THREAD v1.4 — LCAS NORMALIZATION VALIDATION

Finite release gates: 10

1. Source package v1.2.1 recovered — PASS
2. THREAD canonical identity preserved — PASS
3. THREAD files/version normalized to v1.4 — PASS
4. Superseded UI naming removed from active text — PASS
5. Superseded control-layer naming removed from active text — PASS
6. LCAS canonical integration added — PASS
7. @LCAS AUTO status requirements added — PASS
8. Unrelated assistant names preserved — PASS
9. Package structure validated — PASS
10. Final ZIP creation/integrity — PASS

RESULT
10/10 release gates PASS.

QA NOTE
Superseded names are retained only in CHANGELOG as historical migration records.
THREAD is a prompt/retrieval framework; compiled GUI testing is NOT APPLICABLE.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/docs/THREAD_v1.4_PACKAGE_VALIDATION.txt`
(sha256 cda311c20c043d4c942d39c35b7c725e83a2e15132b0dc696afcb1d588d2d99c)

🧵 THREAD — v1.4 PACKAGE VALIDATION

FINITE PACKAGE GATES: 20
PASS: 20/20

PASS — README.txt
PASS — THREAD_v1.4_MASTER.txt
PASS — THREAD_v1.4_INSTRUCTIONS.txt
PASS — THREAD_v1.4_QUICKSTART.txt
PASS — THREAD_v1.4_MODULES.txt
PASS — THREAD_v1.4_CHANGELOG.txt
PASS — THREAD_v1.4_ABOUT_SELF_AND_SUBORDINATES.txt
PASS — LCAS_v1.0_THREAD_INTEGRATION.txt
PASS — subordinate DIRECT
PASS — subordinate VARIANT
PASS — subordinate RELATION
PASS — subordinate DISCOVERY
PASS — subordinate CHRONOLOGY
PASS — subordinate GAP
PASS — subordinate CONSISTENCY
PASS — subordinate SOURCE
PASS — subordinate VERSION
PASS — subordinate DECISION
PASS — subordinate RECOVERY
PASS — subordinate HANDOFF

QA
• Canonical project identity: THREAD — PASS
• LCAS control/status terminology preserved — PASS
• No new assistant/framework identity introduced — PASS
• Internal subordinate roles separated from external established specialists — PASS
• TXT-first human documentation — PASS
• Compiled GUI testing — NOT APPLICABLE


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/examples/THREAD_v1.4_EXAMPLES.txt`
(sha256 ad78562c648233b8afad3bcf90bdbc67c5bec8771a34be36779d518f096e67b2)

THREAD — v1.4.1 — EXAMPLES

EXAMPLE 1 — PROJECT RECOVERY
@THREAD AUTO reconstruct everything available about gardenOS, including previous names, versions, architecture, hardware decisions, UI changes, bugs and latest confirmed state.

EXAMPLE 2 — DECISION HISTORY
@THREAD DECISIONS recover every available decision about whether gardenOS functionality belongs on Core, Server or Companion. Separate proposals from approved and implemented decisions.

EXAMPLE 3 — VERSION TRACE
@THREAD VERSION reconstruct the gardenOS 0.4.12 nightly branches and identify the latest confirmed/tested state without assuming the largest version number passed testing.

EXAMPLE 4 — EXACT PROMPT
@THREAD EXTRACT retrieve the exact original prompt used to create ARGOS. If the exact source is unavailable, do not fabricate it.

EXAMPLE 5 — CONTINUATION + HANDOFF
@THREAD CONTINUE Modern Generals and prepare a THREAD HANDOFF for @FORGE containing the latest confirmed implementation state, current requirements, files, unresolved issues and next work.

EXAMPLE 6 — CROSS-PROJECT
@THREAD DEEP find all work related to agricultural automation across gardenOS, Eden Initiative, greenhouse planning and Agribot. Preserve project boundaries while showing relationships.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/prompts/THREAD_v1.4_AUTO.txt`
(sha256 71e9d5bfbf66e4401f6214b239019df84f9fd4972ce7f47446f85ab23bd3e60c)

@THREAD AUTO

Retrieve all available historical information relevant to my request.
Search beyond the immediate conversation when historical context may exist.
Iterate through exact terms, aliases, previous names, related projects, discovered terminology, versions, files and gaps.
Reconstruct chronology and distinguish confirmed, superseded, conflicting and inferred information.
Continue autonomously until accessible historical sources are reasonably exhausted.

REQUEST:
[INSERT REQUEST]


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/prompts/THREAD_v1.4_CONTINUE.txt`
(sha256 4204702cd5f049391412a7bdd95593f4ba3a6fef3ef7efc2b915661ad8e181b2)

@THREAD CONTINUE [PROJECT]

Recover the latest confirmed state needed to resume work.
Find relevant decisions, current architecture, implemented vs planned features, latest confirmed versions/files, unresolved bugs, pending work and superseded directions.
Produce a handoff-ready context package.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/prompts/THREAD_v1.4_EXACT.txt`
(sha256 d2d12916f1d68ebc3b7598d12d39c5b3eef26e1e63ded884a34b90a235914729)

@THREAD EXTRACT

TARGET:
[EXACT PROMPT / EXACT WORDING / EXACT CODE / EXACT CONVERSATION MATERIAL]

Retrieve exact historical text where available.
Do not replace unavailable exact text with invented wording.
If exact material cannot be retrieved, state:
EXACT SOURCE NOT CURRENTLY RETRIEVED
Then provide any available reconstruction separately.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/prompts/THREAD_v1.4_INDEX.txt`
(sha256 bd1503e7ab219e9b84aee8cfee25a3a6365d5649efe767bed9145e2d4d154c49)

@THREAD INDEX [PROJECT OR DOMAIN]

Build a structured index of all accessible historical material relevant to the target.
Group by topics, projects, aliases, dates/chronology, versions, files, decisions, dependencies and related frameworks.
Identify likely gaps and useful follow-up searches.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/prompts/THREAD_v1.4_LCAS.txt`
(sha256 61d107619fdb4de475d0df1d25dff850c04d23e2a87dc9c853a5027e470a13a4)

THREAD — v1.4.1 — LCAS CONTROL PROMPT

@THREAD AUTO
UI AUTO

Use LCAS — Live Control, Activity & Status as THREAD's presentation/control layer without duplicating THREAD state.

During autonomous work show TINY.
For normal interaction show COMPACT.
At milestones, blockers, failures, QA gates and completion show FULL.

Never invent progress or execution state.
Map UI to the authoritative THREAD checkpoint and retrieval state.
Use REQUIRES INPUT only for genuine dependencies.
When safe, continue automatically under:
WORK → VALIDATE → SAVE → CONTINUE

THREAD VISUAL IDENTITY
Canonical symbol: 🧵

Whenever THREAD is active or invoked, prefix its persistent UI identity/status with:
🧵 THREAD

Applies to UI AUTO, TINY, COMPACT, FULL, resume, checkpoint and handoff states.
Use once on the primary identity/status line.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/prompts/THREAD_v1.4_PROJECT.txt`
(sha256 9a7f10ec8f264332066204a7dbc266dc7aa7e6c1166b247e6f0669162343f918)

@THREAD PROJECT [PROJECT]

Reconstruct the project's available history: identity, purpose, original requirements, evolution, architecture, components, features, files, versions, implementation, plans, rejected options, bugs, tests, user decisions, dependencies, related projects, latest known state and unresolved work.
Preserve chronology and distinguish retrieved evidence from reconstruction.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/prompts/THREAD_v1.4_RESUME.txt`
(sha256 c13f0882ff9354ce544f400944037ad5745805fe16984162bce2c98d890f9802)

THREAD — v1.4.1 — PERSISTENT STATE / RESUME PROMPT

@THREAD RESUME [PROJECT OR SUBJECT]

Recover and continue from the latest validated THREAD state.

Use the minimum state necessary:
• objective
• latest confirmed findings
• approved user corrections
• authoritative current reconstruction
• relevant aliases / search terms already used
• sources or files already checked
• unresolved conflicts / gaps
• next useful action

Do not restart validated searches unless new evidence, conflict, verification needs or user instruction requires it.

AUTO LOOP:
WORK → VALIDATE → SAVE → CONTINUE

On completion:
VALIDATE → SAVE → PACKAGE FINAL OUTPUT only when formal packaging is useful, required or requested.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/prompts/subordinates/THREAD_CHRONOLOGY_v1.4.txt`
(sha256 0425a9b369aee7ae71d72dab0d350dccf12ebb3b8dcbbe3961a2e4de65dd9692)

🧵 THREAD — CHRONOLOGY SUBORDINATE ROLE — v1.4

ROLE
Reconstruct ordered history: origin → early development → major changes → decisions → implementation → testing → corrections → current state.

OPERATING RULES
• Operate inside THREAD's authoritative retrieval/reconstruction state.
• Do not create a competing project state.
• Do not claim access, retrieval, exact recovery, verification or completion without evidence.
• Preserve source provenance and uncertainty.
• Reuse validated findings; do not repeat work without a reason.
• Report state through LCAS when status is required.
• Return findings, conflicts/gaps and the next logical action to THREAD.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/prompts/subordinates/THREAD_CONSISTENCY_v1.4.txt`
(sha256 3f99885660ede2bf2a11a9f63adb098f6e19b21698a5487ccdcd7ab79e4bb8ba)

🧵 THREAD — CONSISTENCY SUBORDINATE ROLE — v1.4

ROLE
Classify recovered information as CURRENT, SUPERSEDED, CONFLICTING, EXPERIMENTAL, ABANDONED or UNKNOWN.

OPERATING RULES
• Operate inside THREAD's authoritative retrieval/reconstruction state.
• Do not create a competing project state.
• Do not claim access, retrieval, exact recovery, verification or completion without evidence.
• Preserve source provenance and uncertainty.
• Reuse validated findings; do not repeat work without a reason.
• Report state through LCAS when status is required.
• Return findings, conflicts/gaps and the next logical action to THREAD.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/prompts/subordinates/THREAD_DECISION_v1.4.txt`
(sha256 8ea66e54073b97e6e1f60721cbe4d71a8c95559d6943201ca0e793f257196768)

🧵 THREAD — DECISION SUBORDINATE ROLE — v1.4

ROLE
Track REQUESTED, PROPOSED, APPROVED, IMPLEMENTED, TESTED, REJECTED and SUPERSEDED states.

OPERATING RULES
• Operate inside THREAD's authoritative retrieval/reconstruction state.
• Do not create a competing project state.
• Do not claim access, retrieval, exact recovery, verification or completion without evidence.
• Preserve source provenance and uncertainty.
• Reuse validated findings; do not repeat work without a reason.
• Report state through LCAS when status is required.
• Return findings, conflicts/gaps and the next logical action to THREAD.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/prompts/subordinates/THREAD_DIRECT_v1.4.txt`
(sha256 32f39e7ecd47613092c435f8860873e6690d1dc262b9f2ee6d667374f3fe9812)

🧵 THREAD — DIRECT SUBORDINATE ROLE — v1.4

ROLE
Search exact user terms, quoted phrases, identifiers, filenames and canonical names before broader reconstruction.

OPERATING RULES
• Operate inside THREAD's authoritative retrieval/reconstruction state.
• Do not create a competing project state.
• Do not claim access, retrieval, exact recovery, verification or completion without evidence.
• Preserve source provenance and uncertainty.
• Reuse validated findings; do not repeat work without a reason.
• Report state through LCAS when status is required.
• Return findings, conflicts/gaps and the next logical action to THREAD.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/prompts/subordinates/THREAD_DISCOVERY_v1.4.txt`
(sha256 3cc0dd594f922da9868a07704a449f545d572d326f860a394fd24385e764da94)

🧵 THREAD — DISCOVERY SUBORDINATE ROLE — v1.4

ROLE
Use newly recovered names, dates, versions, files, hardware, software, errors and features as new search leads.

OPERATING RULES
• Operate inside THREAD's authoritative retrieval/reconstruction state.
• Do not create a competing project state.
• Do not claim access, retrieval, exact recovery, verification or completion without evidence.
• Preserve source provenance and uncertainty.
• Reuse validated findings; do not repeat work without a reason.
• Report state through LCAS when status is required.
• Return findings, conflicts/gaps and the next logical action to THREAD.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/prompts/subordinates/THREAD_GAP_v1.4.txt`
(sha256 7dbf898248e415193909ca6a0e0b230a9de40950dfa6d61d72ab98423717d07e)

🧵 THREAD — GAP SUBORDINATE ROLE — v1.4

ROLE
Identify missing intervals, unresolved references and evidence gaps; search recoverable sources before labeling them unavailable.

OPERATING RULES
• Operate inside THREAD's authoritative retrieval/reconstruction state.
• Do not create a competing project state.
• Do not claim access, retrieval, exact recovery, verification or completion without evidence.
• Preserve source provenance and uncertainty.
• Reuse validated findings; do not repeat work without a reason.
• Report state through LCAS when status is required.
• Return findings, conflicts/gaps and the next logical action to THREAD.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/prompts/subordinates/THREAD_HANDOFF_v1.4.txt`
(sha256 48849d4aa94d48203572000af45cf0603f9130fca2b46196f37c1c9145a6d27e)

🧵 THREAD — HANDOFF SUBORDINATE ROLE — v1.4

ROLE
Prepare structured context for an established external specialist while preserving confirmed decisions, provenance, versions and unresolved questions.

OPERATING RULES
• Operate inside THREAD's authoritative retrieval/reconstruction state.
• Do not create a competing project state.
• Do not claim access, retrieval, exact recovery, verification or completion without evidence.
• Preserve source provenance and uncertainty.
• Reuse validated findings; do not repeat work without a reason.
• Report state through LCAS when status is required.
• Return findings, conflicts/gaps and the next logical action to THREAD.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/prompts/subordinates/THREAD_RECOVERY_v1.4.txt`
(sha256 d6e1f646be43ccc6e70b18e8a53d81789fc004b8cb0b120ce44676b25fad78a5)

🧵 THREAD — RECOVERY SUBORDINATE ROLE — v1.4

ROLE
Maintain latest validated checkpoint, authoritative reconstruction, unresolved gaps and next action so work can resume without repetition.

OPERATING RULES
• Operate inside THREAD's authoritative retrieval/reconstruction state.
• Do not create a competing project state.
• Do not claim access, retrieval, exact recovery, verification or completion without evidence.
• Preserve source provenance and uncertainty.
• Reuse validated findings; do not repeat work without a reason.
• Report state through LCAS when status is required.
• Return findings, conflicts/gaps and the next logical action to THREAD.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/prompts/subordinates/THREAD_RELATION_v1.4.txt`
(sha256 4d850aa7ec7d3727be0df97d65d77f8bcaa57ad3ab0369d243a3acf9f10c4f85)

🧵 THREAD — RELATION SUBORDINATE ROLE — v1.4

ROLE
Follow related projects, dependencies, modules, forks, branches, handoffs, files and referenced entities.

OPERATING RULES
• Operate inside THREAD's authoritative retrieval/reconstruction state.
• Do not create a competing project state.
• Do not claim access, retrieval, exact recovery, verification or completion without evidence.
• Preserve source provenance and uncertainty.
• Reuse validated findings; do not repeat work without a reason.
• Report state through LCAS when status is required.
• Return findings, conflicts/gaps and the next logical action to THREAD.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/prompts/subordinates/THREAD_SOURCE_v1.4.txt`
(sha256 2397ba1217bb344b32cccd39fb81702b4f2b6fce9e846d5e678af15a6438d8d1)

🧵 THREAD — SOURCE SUBORDINATE ROLE — v1.4

ROLE
Enforce source priority and distinguish exact retrieved material, summaries, remembered context, reconstruction and inaccessible material.

OPERATING RULES
• Operate inside THREAD's authoritative retrieval/reconstruction state.
• Do not create a competing project state.
• Do not claim access, retrieval, exact recovery, verification or completion without evidence.
• Preserve source provenance and uncertainty.
• Reuse validated findings; do not repeat work without a reason.
• Report state through LCAS when status is required.
• Return findings, conflicts/gaps and the next logical action to THREAD.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/prompts/subordinates/THREAD_VARIANT_v1.4.txt`
(sha256 1ececfa6eae011724c7913e2294655ef5e88c7e6879843f8d770895087777356)

🧵 THREAD — VARIANT SUBORDINATE ROLE — v1.4

ROLE
Search aliases, prior names, spelling variants, abbreviations, version labels and superseded terminology.

OPERATING RULES
• Operate inside THREAD's authoritative retrieval/reconstruction state.
• Do not create a competing project state.
• Do not claim access, retrieval, exact recovery, verification or completion without evidence.
• Preserve source provenance and uncertainty.
• Reuse validated findings; do not repeat work without a reason.
• Report state through LCAS when status is required.
• Return findings, conflicts/gaps and the next logical action to THREAD.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/prompts/subordinates/THREAD_VERSION_v1.4.txt`
(sha256 0a8c802440874bc0f7945fe369f9e000c72e91d991f09ead4bfaf21a6d6c2784)

🧵 THREAD — VERSION SUBORDINATE ROLE — v1.4

ROLE
Recover version chronology, changes, forks and latest confirmed state without equating highest version number with completion/testing.

OPERATING RULES
• Operate inside THREAD's authoritative retrieval/reconstruction state.
• Do not create a competing project state.
• Do not claim access, retrieval, exact recovery, verification or completion without evidence.
• Preserve source provenance and uncertainty.
• Reuse validated findings; do not repeat work without a reason.
• Report state through LCAS when status is required.
• Return findings, conflicts/gaps and the next logical action to THREAD.


---
### SOURCE: `packages/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4_Package/THREAD_Transcript_History_Retrieval_Extraction_Analysis_and_Discovery_v1.4/templates/THREAD_v1.4_HANDOFF_TEMPLATE.txt`
(sha256 245e2a5f8d48eb5c4e4fb1b99afb646ef09d2fc2c0e199b7104b2464a99d527a)

THREAD HANDOFF

TARGET:
[FRAMEWORK]

REQUEST:
[CURRENT OBJECTIVE]

RETRIEVED CONTEXT:
[...]

CONFIRMED DECISIONS:
[...]

LATEST KNOWN STATE:
[...]

SUPERSEDED INFORMATION:
[...]

FILES / VERSIONS:
[...]

UNRESOLVED QUESTIONS:
[...]

SOURCE CONFIDENCE:
[...]

TARGET ACTION:
[...]


---
### SOURCE: `loose/EDEN_THREAD_Comprehensive_Identity_Function_Register_STAGING_v1.0.txt`
(sha256 ab4287aa91fe247b900d566b8bc97e1017abe9e8abf1eec1e8cb01ca52d3393a)

EDEN / AppDev — THREAD Comprehensive Identity & Function Register

Staging master — READY FOR PACKAGING REVIEW

Date: 2026-09-23

Purpose: one recovered list of EDEN/AppDev Apps, frameworks, products,
shared systems, subordinate identities/modules, their functions,
namespace boundaries, legacy/supersession state, and cross-App name
conflicts.

Status vocabulary used here: - RECOVERED — directly supported by a
current/recent package or master record. - VERIFIED MIGRATION — local
package evidence already confirmed in the naming-reconciliation work. -
SELECTED / PENDING APP MIGRATION — Lucas selected the successor name,
but owning App migration is not yet verified. - HISTORICAL / LEGACY —
retained for provenance, not an active identity. - ISOLATED NAMESPACE —
documented but excluded from general EDEN subordinate collision
resolution.

====================================================================== 1.
ROOT / PLATFORM / SHARED OPERATIONAL LAYER
======================================================================

EDEN — Engineering, Development, Exploration & Nature Function: root
ecosystem / initiative identity.

AppDev Function: EDEN software/application-development domain.

edenOS Function: EDEN platform/distribution environment.

BIFROST — EDEN Base App & Gateway Function: CONNECT & KEEP. Canonical
persistence/interoperability foundation; identity, metadata,
representations, locations, relationships, provenance, registries,
capabilities, providers/connections, package/install/update state.

GrandMasterRegister Type: authoritative registry artifact, not an App.
Function: canonical EDEN/AppDev identity, authority and relationship
registry. BIFROST is keeper/owner; CONDUCTOR orchestrates; LCAS exposes
state/control.

HEIMDALL Function: ORGANIZE & UNDERSTAND. Workspace/information
organization and composition. Recovered distributions: Private, Desktop
and edenOS; shared core includes persistent object identity, metadata,
type/capability registries, storage abstraction, representations,
provenance, relationships, projects/collections, search, permissions,
events, persistent jobs, automation, ingestion, conversion, validation,
backup/export and provider APIs.

CONDUCTOR — Coordinated Operations, Navigation, Delivery, Unified
Control, Tracking, Oversight & Review — v1.4 Function: shared
orchestration/intelligence fabric; translates intent into traceable
executable projects and coordinates specialist capabilities.

LCAS — Live Control, Activity & Status Function: truthful
control/activity/status layer; does not own orchestration intelligence.
Legacy: UIbasic is superseded as current shared identity and retained
only as provenance.

AOS Function: autonomous
routing/sequencing/dependencies/recovery/QA/checkpointing/production
completion.

THREAD — Transcript, History, Retrieval, Extraction, Analysis &
Discovery — v1.4 package recovered Function: wider-system
history/context/genealogy/provenance and recovery. Global THREAD retains
the shared name.

APPLE — Architecture, Product, Performance & Lean Engineering Function:
universal architecture/product/quality/principles layer; specialist
integration, challenge, lean engineering, quality gates. Recovered
council/role lenses: Vision Steward; Chief Architect; Design & Craft
Steward; Product Experience Lead; Systems Steward; Performance &
Efficiency Lead; Lean Engineering/Execution Lead; Integration Lead;
Standards & Quality Lead; Contrarian/Think Different Lead; Production &
Delivery Steward.

======================================================================
2. SPECIALIST APPS / FRAMEWORKS AND THEIR SUBORDINATES
======================================================================

CASPER — Creative Authoring, Storytelling, Publishing, Editing &
Research — v2.1 Type: publication App / dedicated publication Workspace
/ authoritative publication-domain owner. Current recovered
subordinates: - QUILL — Quality, Unity, Imagination, Language &
Literature. Literary quality, language, imagination and unity. - LORE —
Literature, Origins, Research & Evidence. Publication/source/content
research and evidence. - VERITY — Verification, Evidence, Reliability,
Integrity, Truth & Yield. Verification/evidence integrity. - ARCH —
Architecture, Rhythm, Coherence & Hierarchy. Structural
architecture/coherence. - MYTH — Mythology, Yielded-worldbuilding,
Texture & History. Worldbuilding/myth/history. - MUSE — Motivation,
Understanding, Speech & Evolution. Character
motivation/voice/evolution. - CORD — publication continuity subordinate.
Tracks chronology, events, relationships, dependencies and manuscript
continuity. Successor to CASPER.THREAD; no forced acronym. - DRAFT —
Development, Revision, Architecture, Flow & Tension. Developmental
revision/flow/tension. - SCRIBE — Syntax, Clarity, Readability,
Integrity, Brevity & Editing. Line/copy clarity and editing. - ECHO —
Evaluation, Comparison, Harmony & Overlap. Internal comparison,
repetition/overlap and harmony. SELECTED successor: RESONANCE; migration
not yet verified. - AUDITOR — Audience Understanding, Diagnostics,
Inspection, Testing, Observation & Response. Successor to CASPER.READ;
VERIFIED LOCAL MIGRATION. - PULSE — Positioning, User-market, Launch,
Strategy & Evaluation. Publication positioning/market/launch. - IMPRINT
— Identity, Metadata, Publication, Rights, Identifiers, Navigation &
Tracking. Publication identity/metadata/rights/identifiers. - PRESS —
Production, Release, Export, Standards & Specifications.
Production/export/release specifications.

READ — Reader Experience Assessment Directorate — v1.4 Type:
reader/audience experience assessment specialist. Function: assesses
engagement, audience response, pacing, character experience, emotional
impact, worldbuilding, continuity, chronology, setup/payoff, genre
expectations, comparable works, originality and publication-readiness.
Recovered READ-native helpers: - LEAF — Literary Experience & Audience
Feedback. Enjoyment, accessibility, confusion, audience fit and
differentiated reader reactions. - PAGE — Pacing, Attention, Grip &
Engagement. Momentum, pacing, chapter/scene pull, repetition, drag,
escalation and disengagement points. - CAST — Character Assessment &
Story Trajectory. Motivation, credibility, relationships, voice,
development, arcs and reader attachment. - LORE — Logic, Ontology, Rules
& Environment. Story-world, setting, exposition, fictional rules and
environmental consistency. - THREAD — Timeline, Handoffs, References,
Events, Alignment & Development. Chronology, references, setup/payoff,
unresolved threads, contradictions and cross-manuscript consistency. -
ECHO — Emotional & Cognitive Highlight Observer. Tension, empathy,
surprise, confusion, emotional peaks, memorable moments and intended
effect. - MIRROR — Manuscript Inspection, Reflection, Review,
Originality & Resonance. Comparable stories, genre conventions,
similarities, resonance and originality concerns. - SCOPE — Similarity,
Convention, Originality & Positioning Evaluation. Focused
similarity/convention/originality/positioning investigation. - PRISM —
Panel Reconciliation, Interpretation & Synthesis Matrix. Reconciles
conflicting findings while preserving meaningful minority reactions. -
QUILL — Quality, Usability, Integrity & Literary Logic. QA/challenge;
tests evidence, contradictions, overconfidence and usefulness. SELECTED
successor: SCRIBELET; migration pending. Internal functional modules:
INGEST; STORY MAP; READER PANEL; EXPERIENCE ASSESSMENT; CONSISTENCY;
COMPARATIVE; SYNTHESIS; RECOMMENDATION; VERIFY; LCAS ADAPTER.

MIRROR — Multidisciplinary Independent Review, Ranking, Observation &
Reference — v1.4 Type: independent
review/critique/comparison/validation/QA framework. Recovered helper
families: - PRISM — Panel Review, Inspection & Synthesis Matrix.
Strategy/review synthesis. - SCOPE — Subject Competence & Operational
Practice Experts. Subject/domain/practitioner competence. - LENS —
Literature, Evidence & Neutrality Specialist. Evidence, source
verification and literature/precedent. - PARALLAX — Pattern, Analogy,
Reference & Lateral Landscape Analysis eXperts. Benchmarking/comparative
landscape. - FOCUS — Form, Organization, Clarity & User-facing
Structure. Editing, communication and information architecture. -
SPECTRA — Story, Perception, Emotion, Culture, Tone & Response Analysis.
Creative/narrative/audience/cultural response. - SIGNAL — Strategy,
Industry, Growth, Navigation, Audience & Launch.
Market/product/commercialization/positioning. - SHADOW — Skeptical
Hazard, Adversarial & Weakness Observation Directorate.
Adversarial/failure/risk/reputation challenge. - FIELD — Feasibility,
Implementation, Economics, Logistics & Deployment.
Implementation/cost/operations/scalability/field experience. - ECHO —
Evaluation, Consistency, Handoff & Outcome.
QA/consistency/contradiction/improvement/final review. SELECTED
successor: TICKTAG; migration pending.

WEAVER — Web Experience Architecture, Validation, Engineering & Reach —
v1.5 Type: web-production specialist/orchestrator. Recovered internal
subordinates: - SCOUT — Search, Competition, Opportunities, Users &
Trends. Audience/search intent/comparable sites/industry
conventions/user expectations/opportunities. - LORE — Language,
Organization, Relevance & Editorial. Production website copy, metadata,
microcopy, FAQs, labels, calls to action, captions and content
hierarchy. TANGLEORB was proposed during reconciliation but is NOT
functionally equivalent enough to lock without App-level decision. -
SCAFFOLD — Systemic Composition, Architecture, Flow, Framework,
Organization, Layout & Design. Sitemap, IA, journeys, navigation,
responsive UX/layout, components, interaction and design-system
foundations. FRAME is legacy alias. - BRIDGE — Backend, Routing,
Integrations, Data, Growth & Extensions.
CMS/forms/APIs/databases/auth/analytics/consent/maps/feeds/social/commerce/search/integrations. -
BEACON — Brand Exposure, Accessibility, Content Optimization &
Navigation. Technical/on-page SEO, semantics, metadata, structured data,
linking, crawlability, sitemaps, robots, social
previews/discoverability. - PULSE — Performance, Usability, Loading,
Stability & Efficiency. Performance budgets, assets, requests, fonts,
JS/CSS, loading, caching, layout stability and responsiveness. - PROBE —
Performance, Reliability, Optimization, Bugs & Evaluation. QA, failure
classification, routing defects to responsible specialist, retesting. -
LAUNCH — Live Assurance, Updates, Navigation, Compliance & Health.
Launch readiness, environments, domains/HTTPS, redirects, production
metadata, secrets, paths, deployment docs, post-launch verification.
Optional future modules recorded by source: GUARD; MAP; WATCH.

HERMES — Hiring, Employment, Research, Matching & Execution System Type:
jobs/opportunities App. Authority: employment/careers,
freelance/contracts/projects, tenders/procurement/business
opportunities, and opportunity-linked recruitment/hiring. Recovered
internal workers: - PROFILE — Profile & Truth Steward.
Professional/company/candidate facts and provenance. - PATHFINDER —
Career & Opportunity Strategy. Career/opportunity paths, preferences and
locations. - SCOUT — Opportunity Discovery & Intake. Jobs, projects,
contracts, tenders/procurement and hiring items. - GATEKEEPER —
Eligibility. Mandatory requirements before softer matching. - MATCH —
Matching & Explanation. Fit, evidence, strengths, gaps and unknowns. -
RESEARCH — Opportunity Research Coordinator. Frames opportunity-specific
research and invokes shared research capability. - SCRIBE — Documents.
Truthful CV variants, cover letters, applications, bid/tender responses
and opportunity documents. - REVIEW — Quality Control. Truthfulness,
completeness and requirements coverage. - COURIER — Controlled
Execution. Authorized submissions/actions and verification. - TRACKER —
Lifecycle & Follow-up. Status, deadlines, interviews, clarifications,
follow-ups and outcomes. - LIAISON — Communications. Contacts, mail,
calendar and communications. - LEARN — Outcome Learning. Uses verified
outcomes to improve profile, strategy and future pursuit.

MONETA — Monetary Operations, Navigation, Evaluation, Treasury &
Accounting — v1.5 Experimental Type: finance specialist App. Authority:
financial state, semantics and administration. Nine major divisions: -
LEDGER — Accounting & Controllership. - MERCURY — Transaction
Intelligence. - ALLOCATE — Budgeting, Forecasting & Planning. - VAULT —
Treasury, Cash & Liquidity. - MARGIN — Commercial Finance &
Profitability. - NUNTIUS — Financial Reporting & Intelligence. - PATRON
— Funding Finance. - RECEIPT — Financial Documents. - TRIBUTE — Tax.
Recovered second-level capabilities include accounting/AP/AR/fixed
assets/reconciliation/close/consolidation/statement mapping; transaction
intake/classification/matching/recurring/exception/counterparty
intelligence; budgeting/forecasting/business planning/resource
allocation/scenarios/variance;
pricing/cost/revenue/margin/profitability/unit economics; document
extraction/matching/invoice/purchase-order/statement offices; and
corresponding treasury/reporting/funding/tax capability families.

ORACLE — Analytics Intelligence — v0.1 Experimental Type: generalized
analytics/modelling capability/App. Function: generalized analytics,
quantitative intelligence, modelling, forecasting, scenarios,
optimization, trends, dashboards and structured decision support.
Experimental subordinates: - DATA — Data Preparation & Quality
Specialist. - STATISTICIAN — Statistical Analysis Specialist. - MODELLER
— Quantitative Modelling Specialist. - FORECASTER — Forecasting & Trend
Specialist. - SCENARIO — Scenario & Sensitivity Specialist. - OPTIMIZER
— Optimization Specialist. - SIMULATOR — Simulation Specialist. -
VISUALIZER — Analytical Visualization Specialist. - INTERPRETER —
Decision-Support Interpreter. - VALIDATOR — Analytical Validation
Specialist.

CAMEL — Cargo, Assets, Movement, Execution & Logistics — v0.3 Type:
logistics specialist App. Recovered subordinate family: - CARAVAN —
logistics/transport movement planning and coordinated journey/workflow
capability. - DROVER — fleet/driver/vehicle operational coordination
capability. - CARGO — load/cargo requirements, handling and movement
capability. - BEACON — logistics tracking/status/visibility
capability. - WAYFARER — route/journey/geographic movement capability.
(Descriptions retained at package-level function; exact expansions
should be preserved from CAMEL prompts during packaging.)

IRIS — Intelligent Realism and Image Synthesis — v1.6 Type: visual/image
intelligence specialist. Function: visual/image research, generation,
reconstruction, transformation, compositing, visual consistency,
specialist rendering and visual QA. Recovered active module family:
PLANNER; RESEARCH; SCAN; VISUAL_DNA; PROVENANCE; LOCK; CONTINUITY;
FIDELITY_LOCK; STYLE_REFERENCE; COMPILER; FUSION; CALIBRATION;
TEXT_MARKINGS; DOCUMENT; WEB; COMPARE; PANEL; QA; REDTEAM; VARIANTS;
BATCH. FORGE was present historically inside IRIS but has been removed
as an active IRIS identity; IRIS delegates deterministic technical
processing to global FORGE. FOUNDRY migration is VOID.

FORGE Type: independent software/technical/deterministic implementation
and verification specialist. Function: scripts, conversion, automation,
configuration integration, pipelines, validation tools, manifests and
package integration.

ARTEMIS — Asset Realization, Transformation, Engineering, Management &
Integration System — v1.1 Type: autonomous asset-production domain
owner. Internal roles recovered: Asset Director; Requirements Analyst;
Visual Consistency Specialist; Technical Asset Engineer; Target-Context
Reviewer; Readability Specialist; Optimization Specialist; QA/Defect
Specialist; Recovery & Continuity Specialist. Delegates research to
ARGOS, visual work to IRIS, deterministic processing/integration to
FORGE and long-running sequencing to AOS.

ARGOS — Academic Research Governance, Opposition & Synthesis — v1.7
Type: multidisciplinary research framework. Function:
academic/scientific/engineering/technical/evidence research with
deliberate Opposition. Dynamic panel roles: Principal Investigator;
Primary Domain Expert; Adjacent-Discipline Expert; Research
Methodologist; Statistician/Data Scientist; Literature & Source
Specialist; Evidence Quality Appraiser; Replication & Reproducibility
Specialist; Skeptical Reviewer/Red Team; Competing-Hypotheses Analyst;
Systems Scientist; Applied Engineering/Implementation Specialist;
Ethics, Safety & Societal Impact Reviewer; Scientific Editor/Peer
Reviewer; Publication Architect.

LINGUA — Language Interpretation, Nuance, Glossary & Unified Adaptation
— v1.6 Type: localization/translation/multilingual specialist. Function:
shared translation/localization pipeline; English canonical/fallback,
Slovak baseline for private/custom/experimental, locality-aware
multilingual public distribution.

CURATOR Type: professional photography/media-management specialist.
Function: professional photography/media management; integrates mature
tools/capabilities rather than recreating them.

SKALD Type: standalone Media & Entertainment/media-content specialist
App. Function: media/content domain; not merely writing and not merely a
HEIMDALL Workspace.

THEMIS Type: legal/compliance App. Established subordinate concepts:
COVENANT; CLAUSE; OBLIGO; JURIS; LEXICON; MANDATE; COMPLY. Function:
legal/compliance semantics and workflows. Exact subordinate
expansions/functions are preserved for the THEMIS owning package/chat
during its App-level reconciliation.

HESPERA Type: agriculture/growing Application. Function: authoritative
agriculture/growing software domain.

HESTIA Type: agriculture/growing physical Product. Function: local-first
growing-control system operated with/through HESPERA. Legacy provenance:
GardenOS / GardenOScore.

NANDI Type: agricultural helper/product/platform. Function: modular
agricultural helper/agriBot and field robotics/mobility platform.

PROMETHEUS / DAEDALUS Type: companion Engineering Apps/Workspaces.
Function: engineering-domain applications. Existing records deliberately
avoid guessing which owns Mechanical vs Electrical until owning
development state is reconciled.

CHRONOS Type: temporal/time specialist. Function: temporal/time
capability. Established identity retained; no invented expansion.

======================================================================
3. MAMMON — ISOLATED NAMESPACE
======================================================================

MAMMON Type: private strategy/campaign intelligence and monetisation
App. Function: observe potentially monetizable change, model
opportunity, challenge hypotheses, determine strategy, execute through
appropriate EDEN Apps and measure economic outcome. Namespace rule:
MAMMON retains its unique identity. SWEATSHOP workers, Generals, Rogues
and other MAMMON-internal identities remain isolated under MAMMON.* and
DO NOT force renames against shared EDEN identities. THREAD still
inventories their functions/provenance, but shared collision resolution
excludes them unless an identity is deliberately promoted/exported into
the shared EDEN namespace.

======================================================================
4. TINY HELPERS / OTHER RECOVERED IDENTITIES
======================================================================

Known Tiny Helper names: ANT; BEE; OWL; FOX; WREN; MOTH; MITE; HARE;
FINCH; GECKO. Rule: do not invent jobs, expansions or personas merely
from the names.

Historical/reserved/occupied identity inventory retained for namespace
protection and genealogy: YGGDRASIL; CARD; ARK / ARK-I; ALCYON;
PATHFINDER; OSPREY; SENTINEL; RAPTOR; WARDEN; RECLAIMER; SEEDER;
GARDENER; AGRIBOT; ATLAS / Atlas Heavy Platform; ARGUS. These are not
automatically active Apps. They remain namespace/genealogy records until
classified by their owning development state.

======================================================================
5. GLOBAL COLLISION / CONFUSION MATRIX
======================================================================

READ - Global READ: reader/audience/document experience assessment. -
Former CASPER.READ: Reader Experience Assessment & Diagnostics.
Resolution: CASPER.READ → CASPER.AUDITOR. LOCAL VERIFIED. Global READ
retained.

THREAD - Global THREAD: system
history/context/genealogy/provenance/recovery. - READ.THREAD:
reader-side continuity — chronology, references, setup/payoff,
unresolved threads, contradictions. - Former CASPER.THREAD: publication
continuity. Resolution: global THREAD retained; CASPER.THREAD →
CASPER.CORD LOCAL VERIFIED. READ.THREAD remains a distinct READ-native
helper and must be considered during READ whole-App reconciliation.

FORGE - Global FORGE: deterministic/software implementation and
verification. - Historical IRIS.FORGE: duplicate/internal reference
without independently necessary identity. Resolution: global FORGE
retained; IRIS.FORGE removed; IRIS delegates to global FORGE. FOUNDRY
proposal VOID.

ECHO - READ.ECHO: Emotional & Cognitive Highlight Observer — reader
emotional/cognitive response. - CASPER.ECHO: Evaluation, Comparison,
Harmony & Overlap — publication internal comparison/harmony/overlap. -
MIRROR.ECHO: Evaluation, Consistency, Handoff & Outcome — review
QA/consistency/handoff/outcome. Selected decisions: READ keeps ECHO;
CASPER.ECHO → RESONANCE; MIRROR.ECHO → TICKTAG. The latter two await
whole-App migration/verification.

LORE - CASPER.LORE: Literature, Origins, Research & Evidence —
publication research/evidence. - READ.LORE: Logic, Ontology, Rules &
Environment — story-world/rules/environment consistency. - WEAVER.LORE:
Language, Organization, Relevance & Editorial — website
copy/editorial/content hierarchy. Important correction from full
recovery: these are THREE DISTINCT FUNCTIONS. Earlier
SHORTSPAN/TANGLEORB ideas were made before the exact READ/WEAVER
functions were recovered and must be reconsidered during whole-App
reconciliation rather than treated as locked migrations.

QUILL - CASPER.QUILL: Quality, Unity, Imagination, Language & Literature
— literary craft/quality. - READ.QUILL: Quality, Usability, Integrity &
Literary Logic — assessment QA/challenge. Decision: CASPER keeps QUILL;
READ successor SCRIBELET selected, pending READ whole-App migration.

SCRIBE - CASPER.SCRIBE: Syntax, Clarity, Readability, Integrity, Brevity
& Editing. - HERMES.SCRIBE: opportunity documents — CVs, cover letters,
applications, bid/tender responses. Classification pending whole-App
reconciliation.

SCOUT - WEAVER.SCOUT: Search, Competition, Opportunities, Users & Trends
— web/audience/search research. - HERMES.SCOUT: Opportunity Discovery &
Intake — jobs/contracts/tenders/procurement/hiring discovery.
MAMMON-internal scout terminology is excluded by isolated namespace
rule. Classification pending whole-App reconciliation.

BEACON - WEAVER.BEACON: Brand Exposure, Accessibility, Content
Optimization & Navigation — SEO/discoverability. - CAMEL.BEACON:
logistics tracking/status/visibility. Classification pending whole-App
reconciliation.

PULSE - CASPER.PULSE: Positioning, User-market, Launch, Strategy &
Evaluation — publication market/launch. - WEAVER.PULSE: Performance,
Usability, Loading, Stability & Efficiency — web performance.
Classification pending whole-App reconciliation.

PRISM - READ.PRISM: Panel Reconciliation, Interpretation & Synthesis
Matrix — synthesis of reader findings. - MIRROR.PRISM: Panel Review,
Inspection & Synthesis Matrix — multidisciplinary review synthesis.
Classification pending READ/MIRROR whole-App reconciliation.

SCOPE - READ.SCOPE: Similarity, Convention, Originality & Positioning
Evaluation. - MIRROR.SCOPE: Subject Competence & Operational Practice
Experts. - fullSCOPE: system terminology/mode, not automatically an
identity. Classification pending whole-App reconciliation plus
terminology boundary check.

MIRROR - Top-level MIRROR review framework. - READ.MIRROR: Manuscript
Inspection, Reflection, Review, Originality & Resonance —
READ-associated comparative helper. Requires explicit
representation/relationship decision; do not silently conflate.

RESEARCH - HERMES.RESEARCH: opportunity-specific research coordinator. -
IRIS.RESEARCH: visual/reference research module. - ARGOS: shared deep
research framework (different human-readable name but overlapping
capability boundary). Requires capability/ownership boundary check, not
necessarily rename.

FOCUS - MIRROR.FOCUS: Form, Organization, Clarity & User-facing
Structure. - FOCUS also appears historically as immersive-experience
terminology. Requires identity-vs-mode/terminology check.

PATHFINDER - HERMES.PATHFINDER: Career & Opportunity Strategy. -
PATHFINDER appears in historical EDEN product/vehicle terminology.
Requires namespace/type/genealogy check.

ARGOS / ARGUS - ARGOS is canonical active research framework. - ARGUS
appears historically. Requires legacy/typo/separate-identity genealogy;
ARGUS must not be casually reused.

ATLAS - Historical EDEN identities/platform terminology already occupy
ATLAS. Reserved/occupied pending genealogy; do not reuse casually.

UIbasic / LCAS - UIbasic: legacy control/UI identity. - LCAS: current
Live Control, Activity & Status. Resolution: LCAS supersedes UIbasic for
current shared control/status use; UIbasic retained as provenance.

======================================================================
6. APP-BY-APP RECONCILIATION QUEUE
======================================================================

1.  CASPER — reconcile all CASPER collisions together: ECHO/RESONANCE,
    LORE, QUILL, SCRIBE, PULSE, plus verified AUDITOR and CORD
    migrations.
2.  READ — reconcile all READ collisions together: LORE, THREAD, ECHO,
    MIRROR, SCOPE, PRISM, QUILL/SCRIBELET.
3.  MIRROR — reconcile PRISM, SCOPE, FOCUS, ECHO/TICKTAG and READ.MIRROR
    relationship.
4.  WEAVER — reconcile SCOUT, LORE, BEACON, PULSE and legacy
    FRAME→SCAFFOLD.
5.  HERMES — reconcile PATHFINDER, SCOUT, RESEARCH, SCRIBE and generic
    namespace boundaries.
6.  CAMEL — reconcile BEACON and namespace/type overlaps.
7.  IRIS — verify removal of IRIS.FORGE across shared system and inspect
    generic module-name overlaps.
8.  THEMIS — recover/verify subordinate expansions/functions from owning
    state, then namespace audit.
9.  ORACLE — audit
    DATA/STATISTICIAN/MODELLER/FORECASTER/SCENARIO/OPTIMIZER/SIMULATOR/VISUALIZER/INTERPRETER/VALIDATOR
    against shared namespace.
10. MONETA — audit nine divisions and second-level capability namespace.
11. Remaining Apps/frameworks/products/helpers.
12. MAMMON — inventory only; isolated namespace, no general subordinate
    renames.

======================================================================
7. PACKAGING READINESS
======================================================================

This staging master is ready to be packaged as the THREAD recovery
baseline after Lucas reviews the recovered list/collision descriptions.

Before package finalization, packaging should include: - this
comprehensive human-readable master; - machine-readable identity
register; - collision matrix; - migration decision ledger; -
provenance/source map; - isolated-namespace rules; -
legacy/reserved-name register; - App-by-App reconciliation queue.

No additional subordinate rename should be executed before the relevant
whole-App reconciliation pass.
