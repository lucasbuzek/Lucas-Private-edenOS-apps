# BIFROST Master — Extended Goal and In-Chat Acceptance Contract
Date: 2026-10-14
Status: AUTHORITY ADDENDUM / IMPLEMENTATION REQUIRED / NOT A RELEASE CLAIM

## Product intent
BIFROST Master is the in-chat master governor for app intelligence, connectivity, and project orchestration. It absorbs CONDUCTOR's user-facing helper role and exceeds it in connective capability, while preserving specialist authority and the deterministic BIFROST core.

Canonical product identity remains BIFROST — CONNECT · KEEP · RESOLVE. This is one product/codebase with configurable Official and Lucas Custom/Private profiles. HEIMDALL is callable from chat for workspace and workflow management; it is a subordinate specialist, not a competing governor. LCAS is the persistent in-chat presentation/control surface, not an independent execution engine.

## Authority and execution boundaries
- BIFROST owns capability discovery, connection state, provider selection, authorized routing, lifecycle orchestration, quota awareness, task/session continuity, and postcondition verification.
- Specialist providers and device-side scripts own their execution and native artifacts. BIFROST delegates; it does not fabricate files/images or claim that delegated work succeeded without evidence.
- GitHub and the authorized Mac workspace are sources to reconcile, not interchangeable copies. Preserve LKG and rollback.
- Existing capability first: native OS → existing app/service → mature library/CLI/protocol → provider → custom code only for remaining gaps.
- Deterministic/native workflows remain usable when AI or CONDUCTOR is unavailable.
- CONNECTED, REGISTERED, DISCOVERED, SUBMITTED, RUNNING, BUILT, TESTED, VERIFIED and RELEASED are distinct evidence states. UNKNOWN is not PASS.

## Required in-chat behavior
1. Persistent LCAS panel/controls for BIFROST Master: live connection health, active tasks, pending handoffs, provider readiness, quota warnings, and the last verified action result. Each value must identify its evidence source and freshness.
2. Natural-language intent interpretation and typed capability resolution. Resolve the target provider, account identity, environment, device, project domain, and execution mode (local/cloud/hybrid) before action.
3. Manage WORKinCODEX/Codex Cloud handoffs end-to-end: validate handoff source and scope; submit; verify a new task ID; retain task/session identity; monitor pending/running/blocked/completed/failed states; inspect deliverables; return evidence; continue the next safe gate.
4. Coordinate GitHub, MCP, RDC, connected devices, native apps, scripts, providers, and authorized runs using replaceable adapters. RDC remains a replaceable provider, not a permanent architecture dependency.
5. Maintain a persistent provider/capability registry and task/project ledger with provenance, timestamps, authority, account identity labels (never credentials), source revision, result, and recovery pointers.
6. Quota and rate-limit awareness: detect approaching limits before submission, warn at 99% and earlier when provider behavior warrants it, avoid blind retries, and prepare an alternate authorized instance/identity. Offer account creation to the user when required; never create accounts, accept terms, change billing, or handle verification challenges without user action.
7. Initial setup suggests useful account/provider choices based on selected devices and workflows. Save the chosen setup approach as Markdown in BIFROST's project root on the connected device. No credential material in that record.
8. AI Toolkit: prepare a selected device for work by discovering installed applications and available native capability first, then offering a balanced Recommended setup plus Lean / Full / Custom. Use installed applications for guided/automated workflows; never silently install software.
9. HEIMDALL is callable for project workspace organization, domain routing, and workflow coordination. Preserve existing project locations and domain authority; do not duplicate project trees.
10. All consequential actions use explicit permission/confirmation appropriate to impact. Provider errors, stale state, quota limits, unavailable devices, and incomplete evidence are surfaced truthfully.

## Readiness gate
BIFROST Master is ready for testing only after:
- In-chat controls are real and wired to authoritative state; no decorative/fake buttons.
- Provider and account identity are explicit and secrets remain in native credential stores/provider auth.
- All tool actions have typed schemas, permission boundaries, timeouts, cancellation/retry policy, and observable postconditions.
- A deterministic no-AI mode passes.
- Handoff lifecycle, task polling, duplicate submission prevention, quota threshold, rate-limit handling, alternate instance selection, and safe user escalation have automated tests.
- Device loss, provider loss, expired authorization, stale status, offline behavior, and recovery have negative tests.
- Local native/PWA tests and cloud integration tests pass; package/source revision and checksums are recorded.
- ChatGPT host integration and actual iPhone/Mac in-chat acceptance are separately tested. A local macOS build alone is not proof of in-chat integration.

## Current verified evidence as of this addendum
- Mac source path: /Users/lucas/edenOS/Software Development/BIFROST
- Python tests: 78 passed.
- Node tests: 10 passed.
- PWA smoke: static assets, read-only adapter, unauthorized-action denial, host denial, no unsafe proxy, isolated runtime teardown all passed.
- Native macOS Xcode Debug build: BUILD SUCCEEDED (arm64, macOS target).
- These are local baseline gates only. They do not prove BIFROST Master or ChatGPT in-chat integration is complete.
- Codex Cloud CLI on the connected Mac currently reports “Not signed in”; cloud task execution from that CLI is therefore unavailable until the existing authorized account session is restored. Do not silently switch accounts or create a new one.

## Continuation order
Reconcile the cloud branch and local recovered source against this addendum; inspect the existing Codex Cloud candidate and its test evidence; implement the missing in-chat host integration and provider adapters in the canonical GitHub workspace; preserve all existing verified functionality; run regression, package, and physical acceptance gates. Do not stop at this addendum or a dashboard-only implementation.


## JARVIS north-star authority update — 2026-10-14
The user's ultimate Lucas Private goal is an EDEN-native personal automation/intelligence system inspired by JARVIS, with Apple Siri as the preferred everyday interface wherever supported. The full recovered analysis, omissions, target operating model, security/autonomy rules, roadmap and test gates are recorded in `docs/decisions/BIFROST_JARVIS_MASTER_AUDIT_AND_EXTENDED_GOAL_20261014.md`. That file reconciles the new goal with the established BIFROST / CONDUCTOR / HEIMDALL / LCAS / PENELOPE and provider-neutral architecture. It is an authority addendum, not evidence that these capabilities are already implemented.
