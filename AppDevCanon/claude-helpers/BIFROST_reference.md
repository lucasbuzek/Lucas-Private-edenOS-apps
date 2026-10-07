# BIFROST - reference material (verbatim sources; not needed for normal operation)

See `BIFROST.claude.md` for the operating definition. READ MIRROR.


---
### SOURCE: `packages/BIFROST_Project_Prompt_Package_v0.1/BIFROST_Project_Prompt_Package_v0.1/prompts/subordinates/ARGOS_PROMPT.txt`
(sha256 347bfbc04a2f1ff989f971661694307d090a403465ee7db2e73c2625ef7265d7)

@ARGOS — BIFROST SUBORDINATE PROMPT — v0.1

ROLE
Act as BIFROST's research, verification, opposition and synthesis specialist.

INVESTIGATE → VERIFY → CHALLENGE → SYNTHESIZE → PEER REVIEW → PUBLISH.

Research relevant standards, architectures and current open-source implementations before custom engineering is proposed. Examine ERP, metadata/data catalogs, DMS/legal systems, workflow engines, databases, search/indexing, file metadata, provenance, identity, knowledge graphs and domain providers.

For every candidate assess:
functionality; architecture; license; API; data portability; local/offline deployment; maturity; maintenance; privacy/security; resource footprint; interoperability; replacement cost; lock-in risk.

Attempt to disprove proposed BIFROST architecture where evidence warrants it. Agreement is not evidence. Insufficient evidence is a valid result.

Deliver evidence-linked recommendations to CONDUCTOR/FORGE. Do not implement a competing architecture.


---
### SOURCE: `packages/BIFROST_Project_Prompt_Package_v0.1/BIFROST_Project_Prompt_Package_v0.1/prompts/subordinates/CASPER_PROMPT.txt`
(sha256 c60fc6057eba1c9d79e76c3f45281b908110a225b2f152e63bfb803bcf0cbc12)

@CASPER — BIFROST SUBORDINATE PROMPT — v0.1

ROLE
Maintain BIFROST's clear, authoritative human-readable documentation and technical handoffs.

Create/update as needed:
project overview; architecture; terminology; object model; provider model; API/provider SDK documentation; installation; quick-start; configuration; update/recovery; troubleshooting; privacy/data handling; migration/export; developer handoff; release notes.

Documentation must distinguish established behaviour, planned behaviour and research proposals.
Do not describe unimplemented features as working.
Use TXT for lightweight shipped instructions unless another format is specifically required.
Coordinate localization-ready source with LINGUA.


---
### SOURCE: `packages/BIFROST_Project_Prompt_Package_v0.1/BIFROST_Project_Prompt_Package_v0.1/prompts/subordinates/CONDUCTOR_PROMPT.txt`
(sha256 380decf7e133a7ffe6776b26614ca4bbb476a4cc59ddea27760f839754cda7ba)

@CONDUCTOR — BIFROST SUBORDINATE PROMPT — v0.1

ROLE
Orchestrate BIFROST development. Translate goals into traceable requirements, workstreams, tasks, dependencies, artifacts, tests, evidence and releases.

RULES
Preserve canonical BIFROST boundaries. Route specialist work rather than performing every discipline as a monolith. Prefer reusable capability/providers. Keep completion, verification and project health separate. Never invent evidence.

Maintain:
PROJECT_MANIFEST.json
BIFROST_CHAT_HISTORY.txt
stable IDs for requirements, decisions, changes, tasks, artifacts, tests, evidence, risks and releases.

Pipeline:
GOAL → REQUIREMENTS → RESEARCH → ARCHITECTURE → IMPLEMENTATION → TEST → OPPOSITION/REVIEW → CORRECTION → VERIFY → CHECKPOINT → PACKAGE.

Use @THREAD for historical reconciliation, @ARGOS for evidence/research, @FORGE for implementation, @CASPER for documentation, @IRIS for visual communication, @WEAVER for web surfaces and @LINGUA for localization.


---
### SOURCE: `packages/BIFROST_Project_Prompt_Package_v0.1/BIFROST_Project_Prompt_Package_v0.1/prompts/subordinates/FORGE_PROMPT.txt`
(sha256 c273e72071e7b43dec700dd5e7f7109167cfd691473182764f80a56fdf781ef1)

@FORGE — BIFROST SUBORDINATE PROMPT — v0.1

ROLE
Implement, integrate, test and package BIFROST engineering deliverables.

RULES
Build the smallest correct implementation that satisfies verified requirements.
Integrate existing capability before recreating it.
Avoid unnecessary dependencies, abstractions, duplicate services and UI.
Keep provider-specific code behind adapters.
Protect originals and user data.
Compile/test where applicable before claiming success.

FIRST TARGET
Implement DP0.1:
Object identity; metadata interfaces; Type Registry; Capability Registry; Representation; Location; Relationship; Provenance; Provider Registry; SQLite persistence; Filesystem Provider; search/index baseline; API.

Test at minimum:
- arbitrary directory discovery;
- metadata extraction without source modification;
- moved-file identity recovery where evidence supports it;
- duplicate/representation handling;
- provider replacement boundary;
- export/recovery of BIFROST state;
- malformed/unavailable provider handling.

Package reproducibly with installation, update, recovery and uninstall/cleanup instructions where relevant.


---
### SOURCE: `packages/BIFROST_Project_Prompt_Package_v0.1/BIFROST_Project_Prompt_Package_v0.1/prompts/subordinates/IRIS_PROMPT.txt`
(sha256 488b1c298500aba7cd1d203060ed24ce7296460585d09be93f926103b53ba423)

@IRIS — BIFROST SUBORDINATE PROMPT — v0.1

ROLE
Translate BIFROST architecture and information flows into clear visual communication.

Create diagrams for object/representation/location relationships, provider architecture, provenance, data flows, domain boundaries and deployment topology when visuals materially improve understanding.

Keep diagrams technically faithful to authoritative specifications. Do not invent components for visual symmetry. Distinguish canonical components, optional providers and external systems.

Favor simple layered diagrams with detail on demand.


---
### SOURCE: `packages/BIFROST_Project_Prompt_Package_v0.1/BIFROST_Project_Prompt_Package_v0.1/prompts/subordinates/LINGUA_PROMPT.txt`
(sha256 fd6473643f9f29b50d05e1f4f198d186d8ef41c2c5a67d1688f1a8fef3c8125a)

@LINGUA — BIFROST SUBORDINATE PROMPT — v0.1

ROLE
Own BIFROST localization/translation consistency.

English is the canonical/reference and universal fallback language. Slovak is the baseline second language.
Custom, Private and Experimental shipped user-facing interfaces and operational documentation should be EN/SK where practical.
Public/distributable releases are multilingual-by-design from one codebase, with locality-aware defaults and no language-specific forks.

Preserve technical identifiers, API names and schema keys unless localization is explicitly part of the contract. Maintain terminology consistency across UI, help, errors and documentation.


---
### SOURCE: `packages/BIFROST_Project_Prompt_Package_v0.1/BIFROST_Project_Prompt_Package_v0.1/prompts/subordinates/THREAD_PROMPT.txt`
(sha256 643406d08c02f22305b5151d888dffde349a2eba91105c9c602501f98ff3fb13)

@THREAD — BIFROST SUBORDINATE PROMPT — v0.1

ROLE
Recover and reconcile BIFROST project history and related edenOS decisions.

Search available project conversations, project files and authorized library context for BIFROST references and decisions that materially constrain current work.

Produce:
- established decisions;
- superseded decisions;
- unresolved questions;
- contradictions;
- dependencies on other EDEN applications;
- reusable prior work;
- provenance/source references where available.

Do not treat old history as automatically authoritative. Prefer the newest explicit decision when it clearly supersedes earlier work. Do not invent inaccessible history.

Return reconciled context to CONDUCTOR and relevant specialists before architectural redesign.


---
### SOURCE: `packages/BIFROST_Project_Prompt_Package_v0.1/BIFROST_Project_Prompt_Package_v0.1/prompts/subordinates/WEAVER_PROMPT.txt`
(sha256 9a507f7cf1676c3864d74bedac53f95b18344f410c18b8c77916f79b4aeb5aa3)

@WEAVER — BIFROST SUBORDINATE PROMPT — v0.1

ROLE
Design and implement justified browser/web surfaces for BIFROST.

Do not recreate HEIMDALL or specialist application UIs merely to give BIFROST its own interface.
Use web surfaces for administration, provider configuration, diagnostics, developer tooling, object inspection or documentation where they materially help.

Apply responsive, accessible, lightweight design. Use stable BIFROST APIs rather than bypassing provider contracts. Validate content, navigation and functionality before packaging.


---
### SOURCE: `loose/EDEN_BIFROST_CONDUCTOR_Modular_Ecosystem_Architecture.txt`
(sha256 9e1ce5d43f0b0baaa31b168ddb98cc4ae984d5d69d5cf412d8a52b0c6b5f4382)

EDEN — BIFROST / CONDUCTOR Modular Ecosystem

UI/UX & System Architecture Consolidation

STATUS: Consolidated implementation reference from the current
EDEN/AppDev architecture discussion.

1. Core principle

EDEN is a modular capability ecosystem. BIFROST manages identity,
discovery, relationships, availability, providers, placement,
representations, catalogs and system state; it does not bundle every
possible provider. Apps retain domain authority. CONDUCTOR provides
orchestration and intelligence.

AI reasons; deterministic services execute. Use the lowest sufficient
capability and best available authorized provider. Optimize the EDEN
assembly, not merely an individual device.

2. Human-readable identity

Canonical chain: EDEN → Node → App / Capability → Workflow /
Representation

BIFROST maintains canonical identities and human-friendly names/aliases.
Bonjour, BIFROST, CONDUCTOR, Siri, Shortcuts, remote access and portals
should resolve the same identity model.

3. Capability-first UX

Providers are architectural objects, but normal users primarily see:
Capability → current supplier → alternatives.

Advanced exposes providers/configuration. Expert/Developer exposes
adapters, versions, contracts, dependencies, manifests, provenance, logs
and diagnostics.

4. Provider management

BIFROST ships provider-management capability, not all providers.

It maintains: - Capability Registry — what EDEN needs/can do. - Provider
Catalogs — what could provide it. - Provider Inventory — what actually
exists. - Provider Configuration — what the user wants. - Provider
Resolver — what should provide it now.

States must distinguish SUPPORTED, AVAILABLE, DETECTED, INSTALLED,
CONFIGURED, CONNECTED, HEALTHY, ACTIVE, DISABLED, DEGRADED, UPDATE
AVAILABLE and UNSUPPORTED/UNAVAILABLE. Known, desired, installed and
working are never conflated.

5. Updateable typed catalogs

Catalogs update independently of BIFROST releases. Types may include
Apps, Providers, Integrations, Capability definitions, Themes, Language
packs and Workflow templates.

Sources may include EDEN Stable/Core, EDEN Experimental, platform
catalogs, Lucas Private, Slindokuhle/organizational, local development
and optional trusted third-party/community sources.

Catalogs can be enabled, disabled, refreshed, pinned and updated.
Entries preserve provenance/trust. Catalog metadata can describe
acquisition, but never gains arbitrary execution authority.

6. Provider metadata

Where applicable: identity/version, capabilities, platforms/hardware,
resource requirements, acquisition method, dependencies, permissions,
privacy/network characteristics, local/cloud/hybrid status,
cost/licensing, compatibility, representations, configuration schema,
health checks, update channel, disable/uninstall behavior,
shared-host/standalone behavior and alternatives.

7. Install → Setup → Streamline

INSTALL → sensible profile/device default → EDEN SETUP → discover
Nodes/software/providers/user intent → configure required capabilities →
use EDEN → STREAMLINE when useful.

INSTALL/RECOMMENDED = balanced. LEAN = minimum sufficient. FULL = broad
appropriate capability availability without downloading everything.
CUSTOM = explicit control.

Profiles are initial policies, not permanent editions.

8. Streamline

Streamline analyzes PENELOPE dependency/provenance information + BIFROST
actual state + desired state + user intent + Node capabilities +
workflow dependencies.

Recommendations can be KEEP, DISABLE, REMOVE, REPLACE, INSTALL ON
DEMAND, MOVE TO ANOTHER NODE or DON’T SUGGEST AGAIN.

Streamline proposes; it does not silently remove. Changes must explain
consequences and be reversible where technically possible.

9. Protected user intent

Components may carry intent: AUTOMATIC, KEEP, PREFERRED, FALLBACK,
EXPERIMENTAL, ON-DEMAND, DON’T USE.

Manual/Expert choices take precedence over automated recommendations.

10. Desired state vs actual state

BIFROST explicitly separates catalog knowledge, desired state, actual
state, health, consumers, alternatives and recommended action.
Catalogued or installed never means functional.

11. EDEN assembly / Node placement

Nodes have roles rather than identical configurations. Example: -
MacBook Air: primary host/development/broad provider set. - iPhone:
universal control surface/Siri/Shortcuts/mobile capabilities. - Garden
Node: HESTIA/hardware/sensors/automation. - NAS:
storage/backup/services.

Capabilities may be consumed from another Node subject to availability,
latency, privacy, offline requirements, permissions and policy.

12. Deterministic BIFROST Planner

Desired State → Capability Resolver → Provider Resolver → Placement
Resolver → Dependency Resolver → ChangeSet → Preview → Authorization →
Transaction → Verification.

CONDUCTOR may reason about why. The deterministic Planner calculates
what actually changes.

13. Universal ChangeSet

Use one ChangeSet model for install, update, setup, Streamline, provider
changes, placement/migration, shared-host surrender, standalone retake,
repair and uninstall.

Significant changes receive a human-readable preview before execution.

14. Policy layer

Inputs: User Intent + Profile Policy + EDEN Policy + Node Policy +
App/Capability Requirements → BIFROST Planner.

Lucas Private examples: prefer adequate native Apple capabilities;
prefer local/offline operation; preserve development/experimental tools;
Siri participates wherever supported; avoid unnecessary duplication;
preserve explicit manual/Expert choices.

Policy never silently grants permissions.

15. “Why?” explanations

Every recommendation should be explainable: why keep it, why suggest it,
what uses it, what breaks if disabled, and which fallback paths exist.
CONDUCTOR exposes the same explanation conversationally.

16. Simulation

Planner supports dry-run impact analysis, e.g. removing OpenAI, NAS
offline, removing BIFROST, offline Garden Node, moving SKALD. No state
changes occur.

17. BIFROST management UX

Garden of EDEN remains the personal front door. Garden ≠ BIFROST.

Suggested BIFROST areas: MY EDEN | CAPABILITIES | AUTOMATIONS | MANAGE
Developer Mode adds DEVELOPER.

My EDEN: Nodes, Apps, assembly, meaningful attention. Capabilities: what
EDEN can do, current supplier, alternatives. Automations: EDEN
workflows, Shortcuts, AppleScript, Automator, cross-App automation.
Manage: Apps, providers, catalogs, updates, storage, access, Streamline,
recovery. Developer: manifests, instances, ports, raw contracts, logs,
diagnostics, release channels, provenance, APIs.

18. Consistent component management

Where appropriate, Apps/providers/Nodes/workflows/integrations share:
Overview | Used By | Alternatives | Configuration | Access | Updates |
Activity.

19. Garden of EDEN UX

Garden emphasizes action rather than infrastructure: continue projects,
recent Apps, attention, CONDUCTOR suggestions and a simple “Lucas’s EDEN
· Ready” entry into BIFROST management. Versions, provider counts, PIDs,
ports, manifests and raw JSON remain management/developer information
unless attention is required.

20. Capability discovery

“Add capability” searches capabilities first rather than requiring
provider names. BIFROST presents compatible options and consequences.
This is capability discovery, not an advertising marketplace.

21. CONDUCTOR

CONDUCTOR is EDEN’s provider-neutral orchestration/intelligence fabric.
Apps expose structured capabilities, actions, entities, events and
results. BIFROST keeps identity, availability, providers, locations,
relationships and representations.

Structured requests execute without unnecessary AI.
Ambiguous/planning/reasoning-intensive requests may use an available
intelligence provider. Deterministic services perform auditable
execution.

22. Siri — Lucas Private

Siri participates throughout EDEN wherever Apple exposes an appropriate
integration point. Relevant Apple surfaces/providers include Siri, App
Intents, Shortcuts, Spotlight, AppleScript, Automator, Apple/local
intelligence/Foundation Models and appropriate native capabilities.

Siri can participate in invocation, voice interaction, entity
resolution, parameter gathering, results, workflows, system actions,
navigation, management requests, Streamline queries and explanations.
Consequential actions remain subject to authorization/confirmation.

23. Apple/EDEN entities

Appropriate entities may include EDEN, Node, App, Capability, Workspace,
Project, Workflow, Device, Document, Media, Vehicle, Opportunity and
App-owned domain entities. BIFROST supplies identity/resolution;
specialist Apps retain domain semantics.

24. System exposure

Potential exposure scopes: PRIVATE, DEVICE, EDEN, LAN, REMOTE, PORTAL,
PUBLIC.

Policy may derive participation in Siri, Spotlight, Shortcuts, Widgets,
LAN discovery, remote representations and public representations. Do not
expose the whole EDEN graph indiscriminately.

Discovery ≠ Authentication ≠ Identity ≠ Authorization ≠ Execution.

25. Results

Actions support, where appropriate: STRUCTURED RESULT —
machines/workflows. DISPLAY RESULT — Garden/App/UI. SPOKEN RESULT —
Siri/voice.

Apps return canonical structured meaning; representation layers adapt
presentation.

26. Events / proactive assistance

Event → App/BIFROST → CONDUCTOR → rule/workflow →
notification/action/attention item.

Examples include delivery changes, opportunities, financial attention,
project conflicts, Node availability, resumable work and update
approvals.

27. Workflow portability

Workflows primarily describe intent and required capabilities rather
than hard-coded providers. The same workflow may resolve through
different compatible providers on different EDEN assemblies.

28. Native Apple infrastructure

Do not recreate native infrastructure unnecessarily: Bonjour/mDNS → LAN
discovery. Spotlight → Apple content/entity discovery. Siri →
conversational/system interaction. Shortcuts → automation composition.
AppleScript/Automator → Mac workflow/application automation. BIFROST →
EDEN identity/availability/relationships/provider resolution. CONDUCTOR
→ orchestration/reasoning.

29. Provider fallback

Fallback is capability-based, not a fixed provider ladder: Request →
required capabilities → BIFROST discovery → CONDUCTOR policy → lowest
sufficient available authorized provider.

Providers can include deterministic EDEN services, Siri/system
assistants, local intelligence, remote intelligence, specialist
providers and human interaction.

30. Release profiles

Lucas Private/Experimental: broadest applicable catalog/integration
support, development/experimental adapters and diagnostics; Apple-native
integration first-class. Family/Friends: same contracts, simpler
presentation; compatible native assistant integrations where authorized.
Slindokuhle/organizational: same architecture with organization/device
policy and authorized representations. Public/cross-platform: no Siri
dependency; native assistants/local models/external AI/deterministic
interaction can use the same provider architecture.

No assistant or AI provider is mandatory to EDEN.

31. Shared host and broadcast

Standalone by capability. Shared-hosted by BIFROST when available.
Surrender is reversible. Domain authority never moves.

The active host owns broadcast. The App owns identity/capability
description. BIFROST may publish authorized representations locally, on
LAN, remotely, through portals or publicly using appropriate providers.

HOST + BROADCAST/RESOLVE are complementary parts of Shared Host.

32. Health UX

Normal health is capability-oriented: Photography — Ready Media — Ready
Development — Ready Garden — Garden Node offline

Process-level details such as PIDs/ports primarily belong in Developer
diagnostics.

33. FORGE verification

Generated ≠ Saved ≠ Verified ≠ Consolidated ≠ Released.

Catalog presence is not PASS. A route is not PASS. A “Running” card is
not PASS. A Siri phrase appearing is not PASS.

Verify actual capability. Apple integrations where applicable should
progress through contract, App Intent/entity, Shortcuts, Spotlight, Siri
end-to-end, permission/denial, offline/degraded and physical-device
testing.

34. Consolidated principles

BIFROST manages the modular ecosystem rather than bundling the universe.
Apps own domain work. HEIMDALL composes/presents experiences. CONDUCTOR
orchestrates/reasons. PENELOPE preserves identity/provenance/continuity
of source/project families. Providers implement capabilities. Nodes
provide execution locations/resources. Catalogs describe what may be
available. Policy/protected intent constrain choices. The deterministic
Planner calculates safe changes. ChangeSets preview/execute changes
transactionally. Garden presents useful human experience. Developer
views expose machinery. Siri participates throughout Lucas Private
wherever technically appropriate, while EDEN remains provider-neutral
and portable.

Universal identity. Native experience. Themeable personality. Shared
capability. No UI fork.

Small by default. Rich by composition. Modular underneath. Simple on
surface.
