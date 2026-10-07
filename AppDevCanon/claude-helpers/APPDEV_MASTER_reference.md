# appDev MASTER (registry reconciliation handoff) - reference material (verbatim sources; not needed for normal operation)

See `APPDEV_MASTER.claude.md` for the operating definition. READ MIRROR.


---
### SOURCE: `packages/EDEN_Naming_Reconciliation_Handoff_v1.0_Package/EDEN_Naming_Reconciliation_Handoff_v1.0/EDEN_Naming_Reconciliation_Handoff_v1.0.txt`
(sha256 c232913c54836a0ab2ac906a33198c6da142954b37b0b4e325a4d90828a8d589)

EDEN / APPDEV — NAMING RECONCILIATION HANDOFF — v1.0 Owner: Lucas Buzek
Date: 2026-09-22 Target new chat: EDEN Naming Reconciliation

================================================================
STARTING INSTRUCTION
================================================================

@CONDUCTOR @ARGOS @THREAD

Continue from this handoff. Do NOT restart EDEN/AppDev product design.

MISSION: Resolve naming collisions, unresolved names, expansions,
identities, personalities, namespaces and parent/subordinate
relationships across the complete EDEN/AppDev ecosystem.

This is a NAMING + IDENTITY RECONCILIATION pass, not permission to
redesign working applications.

Use evidence first: 1. recover established names/expansions from
project/library/history; 2. newest explicit Lucas Buzek decision
overrides older conflict; 3. preserve historical names as
aliases/provenance; 4. never invent an expansion/personality merely
because a name suggests one; 5. same display name does NOT prove same
identity; 6. an established project must not be renamed merely to
eliminate a collision; 7. canonical IDs, namespaces and relationships
are preferred over destructive renaming; 8. distinguish APP / PRODUCT /
WORKSPACE / HELPER / FRAMEWORK / AGENT / SUBORDINATE / MODULE /
CAPABILITY / PROVIDER / INSTANCE-CONNECTION / ORCHESTRATOR / PROFILE /
ARTIFACT; 9. generic functions do not need artificial personalities; 10.
unresolved evidence remains UNRESOLVED.

Core naming rule: NAMES ARE LABELS; CANONICAL IDs DEFINE IDENTITY.

User-facing naming may be literary/poetic where appropriate: EVOCATIVE
TITLE → CLEAR FUNCTIONAL/GEOGRAPHIC/CULTURAL SUBTITLE → EXPLICIT
CONTENT/CAPABILITY. Internal IDs remain precise and functional.

================================================================ ROOT /
PLATFORM / SHARED SYSTEMS
================================================================

EDEN — Engineering, Development, Exploration & Nature TYPE: root
Initiative / Ecosystem identity STATUS: CANONICAL

edenOS TYPE: optional/future lightweight EDEN platform/distribution
STATUS: CANONICAL CONCEPT BOUNDARY: not EDEN itself.

BIFROST — EDEN Base App & Gateway TYPE: Application / Gateway ROLE:
CONNECT & KEEP AUTHORITY: canonical identity, metadata, representations,
locations, relationships, provenance, registries, capabilities,
providers, connections, persistence, interoperability,
package/install/update state. STATUS: CANONICAL

HEIMDALL TYPE: Application / Workspace system ROLE: ORGANIZE &
UNDERSTAND AUTHORITY: Workspaces and information composition. STATUS:
CANONICAL BOUNDARY: BIFROST must not recreate HEIMDALL Workspaces.

CONDUCTOR — Coordinated Operations, Navigation, Delivery, Unified
Control, Tracking, Oversight & Review TYPE: shared orchestrator /
intelligence fabric ROLE: DECIDE / COORDINATE STATUS: CANONICAL
BOUNDARY: Apps/Helpers do not recreate competing global orchestrators.

AOS TYPE: shared execution/orchestration framework ROLE: RUN / CONTINUE
substantial pipelines; sequencing, dependencies, recovery, QA,
checkpointing and production completion. STATUS: CANONICAL IDENTITY;
exact long-form expansion should be source-verified if needed rather
than invented.

LCAS — Live Control, Activity & Status TYPE: shared status/control
system ROLE: SEE / CONTROL STATUS: CANONICAL SUPERSEDES: UIbasic
BOUNDARY: truthful observation/control/status, not orchestration
intelligence.

GrandMasterRegister TYPE: authoritative registry ARTIFACT, not
App/Helper KEEPER: BIFROST STATUS: CANONICAL

================================================================
ESTABLISHED APPLICATIONS / PRODUCTS
================================================================

HERMES — Hiring, Employment, Research, Matching & Execution System TYPE:
Application DOMAIN: jobs/opportunities, employment/careers,
freelance/contracts/projects, tenders/procurement/business
opportunities, opportunity-linked recruitment/hiring. STATUS: CANONICAL
BOUNDARY: finance truth → MONETA; awarded logistics execution → CAMEL.

MONETA TYPE: Application DOMAIN: financial state/semantics STATUS:
CANONICAL SUBORDINATES: LEDGER — accounting MERCURY — transactions
ALLOCATE — budgeting / forecasting VAULT — treasury MARGIN —
profitability NUNTIUS — financial reporting PATRON — funding RECEIPT —
financial documents TRIBUTE — tax

CAMEL — Cargo, Assets, Movement, Execution & Logistics TYPE: Application
STATUS: CANONICAL SUBORDINATES: CARAVAN — dispatch / movements / jobs /
routes DROVER — fleet / resources / maintenance CARGO — loads /
consignments / capacity BEACON — tracking / ETA / exceptions WAYFARER —
driver / field execution

SKALD — StoryKeeper: Archive, Lifestyle & Delivery TYPE: Application
DOMAIN: media/content collection, management, consumption and delivery
STATUS: CANONICAL BOUNDARY: CASPER creates/edits/publishes; SKALD
manages/consumes/delivers.

CURATOR TYPE: Application DOMAIN: professional photography/media
management STATUS: CANONICAL RULE: integrate Lightroom/Bridge and mature
capabilities before recreating.

CASPER the GhostWriter — Creative Authoring, Storytelling, Publishing,
Editing & Research TYPE: Application / dedicated publication Workspace
DOMAIN: publication creation/editing/research/state STATUS: CANONICAL
SUBORDINATES: QUILL — Quality, Unity, Imagination, Language & Literature
LORE — Literature, Origins, Research & Evidence VERITY — Verification,
Evidence, Reliability, Integrity, Truth & Yield ARCH — Architecture,
Rhythm, Coherence & Hierarchy MYTH — Mythology, Yielded-worldbuilding,
Texture & History MUSE — Motivation, Understanding, Speech & Evolution
THREAD — Timeline, History, Relationships, Events, Alignment & Detail
DRAFT — Development, Revision, Architecture, Flow & Tension SCRIBE —
Syntax, Clarity, Readability, Integrity, Brevity & Editing ECHO —
Evaluation, Comparison, Harmony & Overlap READ — Reader Experience
Assessment & Diagnostics PULSE — Positioning, User-market, Launch,
Strategy & Evaluation IMPRINT — Identity, Metadata, Publication, Rights,
Identifiers, Navigation & Tracking PRESS — Production, Release, Export,
Standards & Specifications

LINGUA TYPE: Application / localization domain DOMAIN: translation,
localization, language coverage/providers STATUS: CANONICAL NAMING NOTE:
literary coverage-pack labels are user-facing; precise internal IDs
remain.

THEMIS TYPE: legal/compliance Application STATUS: CANONICAL SUBORDINATE
CONCEPTS: COVENANT CLAUSE OBLIGO JURIS LEXICON MANDATE COMPLY Exact
expansions/roles should be preserved from authoritative THEMIS sources;
do not fabricate missing expansions.

HESPERA TYPE: Application DOMAIN: agriculture / growing STATUS:
CANONICAL

HESTIA TYPE: Product / physical local-first growing-control system
RELATIONSHIP: operated with/through HESPERA STATUS: CANONICAL LEGACY
PROVENANCE: GardenOS / GardenOScore

NANDI TYPE: agricultural helper/agriBot / field robotics-mobility
platform STATUS: CANONICAL identity; confirm exact classification
wording during reconciliation.

PROMETHEUS TYPE: companion standalone Engineering App/Workspace STATUS:
CANONICAL NAME; discipline mapping/expansion UNRESOLVED DO NOT GUESS
Mechanical vs Electrical/Electronic assignment.

DAEDALUS TYPE: companion standalone Engineering App/Workspace STATUS:
CANONICAL NAME; discipline mapping/expansion UNRESOLVED DO NOT GUESS
Mechanical vs Electrical/Electronic assignment.

cloud9 TYPE: personal Digital Home Base candidate App/Product STATUS:
IDENTITY EXISTS; TYPE/BOUNDARY UNRESOLVED COLLISION/BOUNDARY: BIFROST /
HEIMDALL / SKALD.

================================================================ SHARED
HELPERS / FRAMEWORKS / SPECIALISTS
================================================================

ARGOS — Academic Research Governance, Opposition & Synthesis TYPE:
multidisciplinary research/evidence framework ESTABLISHED VERSION: v1.7
STATUS: CANONICAL PIPELINE: DEFINE → ACQUIRE → VERIFY → REASON → OPPOSE
→ SYNTHESIZE → PEER REVIEW → REVISE → PUBLISH DYNAMIC SPECIALIST PANEL:
Principal Investigator Primary Domain Expert Adjacent-Discipline Expert
Research Methodologist Statistician/Data Scientist Literature & Source
Specialist Evidence Quality Appraiser Replication & Reproducibility
Specialist Skeptical Reviewer / Red Team Competing-Hypotheses Analyst
Systems Scientist Applied Engineering / Implementation Specialist
Ethics, Safety & Societal Impact Reviewer Scientific Editor / Peer
Reviewer Publication Architect

ARTEMIS — Asset Realization, Transformation, Engineering, Management &
Integration System TYPE: autonomous asset-production framework/domain
owner STATUS: CANONICAL RELATIONSHIPS: ARGOS →
research/reference/factual validation IRIS → visual
generation/transformation/visual QA FORGE → deterministic
processing/conversion/automation/integration AOS → long-running
sequencing/checkpoint/recovery

IRIS TYPE: visual/image intelligence framework STATUS: CANONICAL
SUBORDINATES / MODULE NAMES: PLANNER RESEARCH SCAN VISUAL_DNA PROVENANCE
LOCK CONTINUITY FIDELITY_LOCK STYLE_REFERENCE COMPILER FORGE FUSION
CALIBRATION TEXT_MARKINGS DOCUMENT WEB COMPARE PANEL QA REDTEAM VARIANTS
BATCH NOTE: IRIS.FORGE collides by display name with EDEN.FORGE.

FORGE TYPE: software/technical/deterministic implementation +
verification framework STATUS: CANONICAL DOMAIN: scripts, conversion,
automation, config integration, pipelines, validation tools, manifests,
package integration.

ORACLE TYPE: analytics / modelling / forecasting / simulation framework
STATUS: CANONICAL HISTORICAL: old finance ownership superseded by MONETA
SUBORDINATES: ORACLE.DATA STATISTICIAN MODELLER FORECASTER SCENARIO
OPTIMIZER SIMULATOR VISUALIZER INTERPRETER VALIDATOR

THREAD TYPE: wider-system history/context/genealogy/provenance
specialist STATUS: CANONICAL identity BOUNDARY: distinct from
CASPER.THREAD unless evidence establishes a representation relationship.

WEAVER — Web Experience Architecture, Validation, Engineering & Reach
TYPE: web specialist framework STATUS: CANONICAL DOMAIN: website
design/development/optimization/SEO. KNOWN COLLIDING SUBORDINATE NAMES
from project history: SCOUT BEACON PULSE Exact WEAVER subordinate
registry should be source-recovered before altering names.

READ TYPE: audience/reader/document experience evaluation framework
STATUS: CANONICAL COLLISION: CASPER.READ representation/name.

MIRROR FAMILY TYPE: review/evaluation family STATUS: CANONICAL
SUBORDINATES: PRISM SCOPE LENS PARALLAX FOCUS SPECTRA SIGNAL SHADOW
FIELD ECHO

APPLE TYPE: universal principles / quality layer STATUS: CANONICAL CORE
COUNCIL: VISION STEWARD CHIEF ARCHITECT DESIGN & CRAFT STEWARD PRODUCT
EXPERIENCE LEAD SYSTEMS STEWARD PERFORMANCE & EFFICIENCY LEAD LEAN
ENGINEERING / EXECUTION LEAD INTEGRATION LEAD STANDARDS & QUALITY LEAD
CONTRARIAN / THINK DIFFERENT LEAD PRODUCTION & DELIVERY STEWARD DYNAMIC
SPECIALIST BENCH: HARDWARE TECHNOLOGY OPERATIONS & MANUFACTURABILITY
SERVICES & ECOSYSTEM PRIVACY & SECURITY ACCESSIBILITY & INCLUSIVE
EXPERIENCE RELIABILITY & FAILURE DEVELOPER EXPERIENCE / TOOLING FUTURE
TECHNOLOGIES / SKUNKWORKS EVIDENCE / PROVENANCE MIGRATION / LIFECYCLE
DOMAIN-SPECIFIC EXPERTS

CHRONOS TYPE: temporal/time specialist STATUS: NAME/IDENTITY
ESTABLISHED; expansion UNRESOLVED.

================================================================ HERMES
SUBORDINATE WORKER PIPELINE
================================================================

PROFILE → PATHFINDER → SCOUT → GATEKEEPER → MATCH → RESEARCH → SCRIBE →
REVIEW → COURIER → TRACKER → LIAISON → LEARN

Do not assume every worker needs an acronym expansion/personality.
Collisions include HERMES.SCOUT and HERMES.SCRIBE.

================================================================ KNOWN
TINY HELPERS — UNRESOLVED
================================================================

ANT BEE OWL FOX WREN MOTH MITE HARE FINCH GECKO

STATUS: Names are known. TYPE = unresolved unless recovered source
establishes it. EXPANSION = UNKNOWN. ROLE = UNKNOWN. PERSONALITY =
UNKNOWN. ACTION = recover source evidence; do not infer from animal
names.

================================================================ KNOWN
NAME COLLISIONS
================================================================

THREAD: EDEN.THREAD CASPER.THREAD READ.THREAD (historically referenced;
verify current source)

READ: EDEN.READ CASPER.READ

MIRROR: EDEN.MIRROR family READ.MIRROR

PRISM: MIRROR.PRISM READ.PRISM

SCOPE: MIRROR.SCOPE READ.SCOPE

ECHO: MIRROR.ECHO CASPER.ECHO READ.ECHO

LORE: CASPER.LORE READ.LORE

QUILL: CASPER.QUILL READ.QUILL

SCRIBE: CASPER.SCRIBE HERMES.SCRIBE

SCOUT: HERMES.SCOUT WEAVER.SCOUT

BEACON: CAMEL.BEACON WEAVER.BEACON

PULSE: CASPER.PULSE WEAVER.PULSE

FORGE: EDEN.FORGE IRIS.FORGE

RECONCILIATION CHOICE FOR EACH COLLISION: A — independent domain
specialists sharing a display label; B — namespaced
representations/adapters of one shared specialist; C — historical
duplicate(s) to consolidate/supersede.

Do not choose A/B/C without evidence.

================================================================ KNOWN
SUPERSESSION / LEGACY
================================================================

UIbasic → superseded_by → LCAS SOLAR → superseded_by → THREAD
(historical helper lineage; verify source) GardenOS / GardenOScore →
HESPERA / HESTIA lineage ORACLE historical finance ownership → MONETA
“My EDEN” → provenance wording, not competing canonical product

================================================================
PROFILES / PERSONALITY LAYER
================================================================

LucasPersonalGrandMaster Canonical ID: eden.profile.lucas.personal TYPE:
personal interaction/inspiration/operating profile. Do not flatten
inspirations into one artificial persona.

Family Canonical ID: eden.profile.family STYLE: gentle, caring,
supportive, patient, protective, clear, encouraging, calm.

Friends Canonical ID: eden.profile.friends STYLE: informal, familiar,
collaborative, humorous, adventurous, loyal; serious immediately when
needed.

RULE: Interaction profiles may change expression, never truth, evidence,
safety, capability or authoritative responsibility.

Not every entity needs personality. Allowed: personality = NONE
personality = UNRESOLVED

Registry personality dimensions: 1. Functional identity 2. Conceptual
metaphor 3. Behavioral personality 4. Interaction profile 5.
Inspiration/provenance

================================================================
CANONICAL RESPONSIBILITY BOUNDARIES TO PRESERVE
================================================================

HERMES → CAMEL → MONETA opportunity/pursuit/award → operational
logistics execution/delivery → financial truth.

CURATOR / IRIS / ARTEMIS CURATOR = manage professional media IRIS =
understand/create/transform visual material ARTEMIS =
realize/validate/integrate project assets.

CASPER / SKALD CASPER = create/edit/publish SKALD =
collect/manage/consume/deliver.

HESPERA / HESTIA / NANDI HESPERA = agriculture software/domain App
HESTIA = growing-control Product NANDI = agricultural robotics/mobility.

ARGOS / ORACLE / PROMETHEUS-DAEDALUS / FORGE ARGOS =
investigate/verify/challenge evidence ORACLE = model/analyse/simulate
PROMETHEUS/DAEDALUS = engineer/design FORGE = implement/build/integrate
deterministic/software results.

================================================================
RECONCILIATION OUTPUT REQUIRED FROM NEW CHAT
================================================================

Build ONE canonical reconciliation table with one row per identity:

CANONICAL ID DISPLAY NAME EXPANSION TYPE PARENT ROLE AUTHORITY
PERSONALITY/METAPHOR COLLIDES WITH RELATIONSHIP TO COLLISION STATUS
PROVENANCE CONFIDENCE ACTION

Then produce:

1.  CANONICAL NAMES — no issue.
2.  NAMESPACED COLLISIONS — same display name intentionally retained.
3.  REPRESENTATIONS — subordinate view of shared specialist.
4.  RENAMES REQUIRED — only where evidence/user decision makes this
    necessary.
5.  SUPERSEDED / LEGACY ALIASES.
6.  UNRESOLVED NAMES / EXPANSIONS / PERSONALITIES.
7.  DUPLICATE FUNCTIONALITY / AUTHORITY conflicts.
8.  MISSING SOURCE EVIDENCE.
9.  Proposed canonical IDs for every established identity.
10. GrandMasterRegister update DELTA — do not overwrite until Lucas
    approves.

PRIORITY INVESTIGATIONS: CASPER.ECHO ↔ READ.ECHO ↔ MIRROR.ECHO
CASPER.READ ↔ EDEN.READ READ.MIRROR ↔ EDEN.MIRROR READ.PRISM ↔
MIRROR.PRISM READ.SCOPE ↔ MIRROR.SCOPE CASPER.QUILL ↔ READ.QUILL
CASPER.LORE ↔ READ.LORE HERMES.SCRIBE ↔ CASPER.SCRIBE HERMES.SCOUT ↔
WEAVER.SCOUT CAMEL.BEACON ↔ WEAVER.BEACON CASPER.PULSE ↔ WEAVER.PULSE
EDEN.FORGE ↔ IRIS.FORGE

SOURCE RECOVERY PRIORITY: CHRONOS PROMETHEUS DAEDALUS Tiny Helpers
WEAVER subordinate registry READ subordinate registry THEMIS subordinate
expansions cloud9 classification/boundary

FINAL RULE: Do not optimize for a prettier list. Optimize for an
unambiguous, recoverable, evolvable EDEN identity graph.


---
### SOURCE: `packages/EDEN_Naming_Reconciliation_Handoff_v1.0_Package/EDEN_Naming_Reconciliation_Handoff_v1.0/QUICKSTART.txt`
(sha256 dc3c1bb9980d5c0a340bb63d5e24ded0e8c4c51dc285fd16bcf5f22b872f03db)

EDEN NAMING RECONCILIATION — NEW CHAT QUICK START

Upload/open EDEN_Naming_Reconciliation_Handoff_v1.0.txt and send:

@CONDUCTOR @ARGOS @THREAD AUTO Load the handoff as authoritative
starting context. Recover source evidence for unresolved/colliding
identities. Do not redesign Apps. Create the complete canonical identity
table, collision analysis, source-recovery queue and proposed
GrandMasterRegister DELTA. Do not rename established identities without
evidence or my approval.
