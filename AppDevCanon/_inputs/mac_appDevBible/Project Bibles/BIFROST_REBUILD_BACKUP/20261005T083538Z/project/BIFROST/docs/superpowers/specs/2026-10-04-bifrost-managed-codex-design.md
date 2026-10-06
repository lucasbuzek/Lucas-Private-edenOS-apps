# BIFROST Managed Codex & Expert Execution Design

## Authority
ForgeMASTER remains the AppDev governor. BIFROST remains CONNECT · KEEP · RESOLVE. Specialist apps/helpers/assistants retain domain authority and functionality. Evidence determines state; UNKNOWN is not PASS. Existing implementation is extended, not replaced.

## Goal
Make developer/expert AI and compute capabilities usable by lay/non-technical users. The user states a goal and confirms consequential actions; BIFROST handles authentication, capability selection, session management, commands, local/cloud/hybrid execution, and returns results/evidence to the originating specialist.

## Capability-first rule
For each request, use an adequate deterministic/native capability first, then suitable native/local AI. When those do not suffice, BIFROST resolves an authorized connected capability. Engineering-capable specialists may use Codex. Loss of online/Codex capability degrades functionality rather than breaking unrelated local functions.

## One-time connection
BIFROST centrally observes and manages the supported ChatGPT/Codex authentication relationship. Normal use must not require API keys, repeated provider configuration, terminal commands, model selection, session IDs, or cloud-environment knowledge. Reauthentication is surfaced only when the underlying provider requires it or the user signs out.

## Session isolation
Every eligible app, assistant, and helper has a stable BIFROST execution identity and separate persistent Codex session/thread context. Sessions are never casually shared across specialists. Project/task sessions branch under the owning specialist and retain provenance. Existing suitable sessions are resumed before new ones are created.

## Execution routing
BIFROST resolves LOCAL, CLOUD, or HYBRID execution from declared capabilities and constraints. LOCAL is preferred for Mac-local files/apps, Xcode, Blender/CAD, attached devices, private/local-only resources, and physical verification. CLOUD is permitted for suitable delegated Codex work when authenticated and available. HYBRID may delegate suitable work to cloud and finish/verify locally. Availability is detected, never assumed.

## Layman confirmation contract
BIFROST prepares and issues technical commands itself. The user confirms intent/consequential boundaries in human language rather than copying commands. Confirmation is required for new permissions, installations, destructive changes, external/cloud data transfer where not already authorized, spending, publishing/deployment, and equivalent consequential actions. Routine operations within an already authorized task may continue without repeated prompts. Advanced/Expert surfaces may expose exact commands, sessions, logs, providers, and evidence.

## Request contract
A specialist submits a structured request containing: specialist identity; user goal; project/workspace identity; authority/context references; required capabilities; input/output references; privacy/locality constraints; cloud permission; interactive/consequential requirements. BIFROST resolves execution infrastructure, not domain correctness.

## Persistence
Persist only non-secret routing/session metadata needed to reconnect: specialist identity, project identity, provider, Codex thread/session identifiers, execution destination, workspace mapping, timestamps/state, and evidence references. Provider credentials/tokens remain owned by supported provider/macOS secure storage and never enter the repository.

## Evidence and safety
ForgeMASTER/FORGE continue to govern engineering evidence. BIFROST records truthful execution state and returns evidence to the requester. A process launch is not a health PASS. Failed/unavailable providers produce actionable state. Reconnect/resume precedes recreate. No candidate replaces LKG without required verification.

## Initial implementation boundary
Extend the recovered SwiftUI candidate without redesigning it. Add a Codex execution provider, persistent specialist-session registry, request/router models, confirmation policy, and Simple/Advanced/Expert UI state. First implementation uses the installed supported Codex CLI/app-server surfaces and detects Cloud availability. It must not depend on paid API keys or private ChatGPT endpoints.

## Acceptance
1. Existing BIFROST build/regression remains green.
2. ChatGPT-authenticated Codex is detected without exposing credentials.
3. Two specialists cannot receive the same implicit session context.
4. A known specialist/project resumes its saved session before creating another.
5. Offline/unavailable Codex reports degraded/unavailable without breaking native BIFROST.
6. Router distinguishes local/cloud/hybrid and never reports cloud available without evidence.
7. Consequential requests require a human-readable confirmation; ordinary read-only/routine requests do not repeatedly prompt.
8. Normal UI does not require terminal/API/model/session knowledge; Expert can expose execution details.
9. Tests cover persistence, isolation, routing, confirmation, unavailable provider, and resume behavior.
10. Physical Mac gate remains required before promotion.
