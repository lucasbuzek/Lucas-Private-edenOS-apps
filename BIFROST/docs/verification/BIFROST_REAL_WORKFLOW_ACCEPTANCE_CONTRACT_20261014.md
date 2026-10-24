# BIFROST Master — Real-Workflow Acceptance Contract
Date: 2026-10-14
Authority: Lucas's explicit clarification that the workflow established across the last day and night is the model BIFROST must reproduce.
Status: CANONICAL PRODUCT REQUIREMENT; implementation and host integration require separate evidence.

## Governing principle
BIFROST must turn an established goal into continuous, evidence-driven execution across projects, files, specialist roles, providers, connected devices and workflows, with minimal unnecessary user intervention. Lucas establishes the goal and governing constraints once. "Continue", "Continue AUTO", or the established extended-goal directive means resume from existing authority and state, recover prior work, inspect actual state, identify gaps, perform the next safe useful actions, verify outcomes, persist results and continue. Do not repeatedly ask for established information, narrate progress instead of acting, restart from scratch, or stop after writing a plan. Continue until acceptance criteria are met or a genuine external gate prevents progress.

## The real workflow BIFROST must reproduce
1. Receive intent, scope, constraints, destination, specialist roles and expected end state. Separate durable canon from task-specific choices.
2. Recover context before asking: project bibles, prior work, canonical files, handoffs, issue/task history, connected repositories and device state.
3. Resolve the canonical project/root, LKG candidate, output location, dependencies, provider/account/device, existing deliverables and acceptance criteria.
4. Inspect before changing: source, artifacts, branch/commit history, installed tools, running processes, tests and previous evidence. Distinguish local source, remote branch, cloud task, built app, running process, physical-device result and release package.
5. Build an execution graph with dependencies, specialist ownership, inputs, deliverables and verification. Use established specialists as real delegates when available, not decorative mentions.
6. Choose capability and placement: native OS → installed app → mature library/CLI/service/API → authorized provider → new code for the actual gap. Consider privacy, offline state, device capability, usage and budget.
7. Execute against the actual connected device/repository/provider. Create or repair deliverables, run tools and advance independent work in parallel when safe. Never claim a provider or remote device was used without evidence.
8. Verify independently: read back artifacts, inspect paths/content/revisions, run tests/builds/smoke checks and domain acceptance. An outline is not a manuscript; generated source is not a build; a build is not runtime acceptance; submission is not completion.
9. Diagnose failures, change the cause, preserve evidence, retry within bounded budgets and verify again. Do not repeat a known failing action unchanged.
10. Persist task state, artifacts, project bible/handoff, revision, tests, unknowns and next actions. New chats/providers must resume without reconstructing the whole task.
11. Continue AUTO through safe, independent, unblocked work without a new prompt for each step. Stop only at completion, genuine authorization/credential/payment/identity/physical-device gates, unavailable providers without permitted fallback, or user constraints.
12. Report concise outcomes, exact paths, evidence, unknowns and required user action. Keep PASS/FAIL/UNKNOWN/SKIPPED/N/A and GENERATED/IMPLEMENTED/BUILT/TESTED/VERIFIED/RELEASED distinct.

## Apple Shortcuts / HEIMDALL integration contract
Apple Shortcuts is the supported Apple-device automation and handoff layer, following the existing HEIMDALL Assistant iOS implementation. Do not invent a second Apple integration architecture or duplicate domain logic.
- Canonical HEIMDALL project: `~/edenOS/Software Development/HEIMDALL Assistant IOS/`.
- Existing `HEIMDALL/HeimdallIntents.swift` defines App Intents and `HEIMDALLShortcuts: AppShortcutsProvider`; `ShortcutHandoff.swift` uses Apple's `shortcuts://x-callback-url/run-shortcut` and a `heimdall://shortcut-callback` return route. The app records jobs and uses a per-run callback verifier. Reuse and extend this established mechanism where suitable.
- BIFROST should expose a small, versioned, stable set of safe Master actions through HEIMDALL App Intents/App Shortcuts and user-owned Apple Shortcuts: status/health, recover project context, continue an already-authorized task, inspect task status, start a pre-approved workflow, cancel, and explain the last result. Add parameters/disambiguation and structured/spoken responses.
- A Shortcut is an entry point/orchestration bus, not the owner of BIFROST or specialist business logic. Each action calls the same authenticated BIFROST contract/task ledger as LCAS and native clients. No shadow task state or parallel business logic in Shortcut actions.
- Use the native app's current pending-request and callback model for local HEIMDALL workflows; a cross-device BIFROST action additionally needs a real authenticated endpoint, enrolled device identity, scoped expiring authorization, anti-replay, timeout, cancellation, revocation and durable audit receipt. A random callback verifier alone is not remote-device authentication.
- Preserve HEIMDALL's standalone local/offline capability. BIFROST remains optional for existing HEIMDALL actions; Siri/Shortcuts must not make HEIMDALL v1 depend on a running BIFROST service.
- Process user-selected images/files locally first under HEIMDALL canon. Do not silently upload raw attachments. Cloud reasoning is optional and only receives authorized, minimized context; preserve Apple's confirmation when transmission is required.
- Never claim an App Intent, Siri phrase, Shortcut, callback or physical Action Button is functional from source inspection or a successful build alone. Test the actual registered intent, shortcut execution, callback, returned result, denied permission, timeout/cancel and physical iPhone behavior.
- The Mac's Shortcuts app can provide its own automation entry points, but Mac and iPhone Shortcuts have different execution contexts and permissions. Define and test both; don't assume an iPhone shortcut can execute arbitrary Mac commands or vice versa.

## Autonomy and safety
Observe → recover context → reconcile authority → plan dependencies → assess risk → preview where useful/consequential → authorize if required → execute → inspect postconditions → record evidence → recover/replan → continue.
Automatic means low-friction continuation within established authority, not permission bypass. Destructive operations, external publication, payments, account creation/switching, permission changes, sensitive data transfer and irreversible actions require appropriate approval. At quota thresholds, warn and use only a compatible already-authorized provider if privacy, capability and budget policy allow. Never evade rate limits, silently create accounts or broaden data sharing.

## Persistent state contract
Every task/workflow needs stable IDs, canonical project/goal, authority and constraints, dependency graph, provider/node, state transitions, checkpoint/resume cursor, timestamps, actual operation/result, artifact paths and hashes where useful, test/build evidence, retry/failure history, approvals, rollback reference and next safe action. Credentials never enter the ledger.
Distinguish intent accepted/context recovered/plan prepared; proposed/authorized/submitted/started/completed; generated/implemented/built/tested/verified/released; discovered/available/installed/configured/connected/healthy/active; and PASS/FAIL/UNKNOWN/SKIPPED/N/A. If actual state cannot be observed, mark UNKNOWN and choose the next evidence-producing action.

## Architecture consequence
BIFROST Master is Lucas's in-chat governor and continuity layer, absorbing CONDUCTOR's orchestration role without competing masters. BIFROST owns connectivity, provider/capability/node resolution, task continuity, policy and evidence. HEIMDALL remains the Apple/workspace specialist and primary Apple-facing integration. Siri and Shortcuts are entry surfaces. LCAS is presentation/control, not evidence engine. Specialist apps retain their domains and standalone behavior. MCP/RDC/GitHub/WORKinCODEX/RavenNest/scripts are adapters, not assumed capabilities.

## Acceptance test
Give BIFROST an established multi-project goal, then only say "Continue AUTO." It recovers context, inspects actual state, discovers existing tools/specialists, executes dependent work, verifies artifacts, diagnoses and repairs a failure, persists handoffs and continues. Restart the interface mid-task and verify resume. Deny a permission, disconnect a provider, simulate quota pressure and repeat a request to verify safe denial, permitted fallback, duplicate prevention and recovery. Run the same task from in-chat and an Apple Shortcut and confirm one authoritative state.
Ready for meaningful end-to-end testing requires a real authorized provider and actual project artifacts, persistent resume, real verification, bounded recovery, safety gates and truthful reporting. A unit suite, build, static PWA, architecture document or unbound Siri intent alone does not satisfy it.

## Continuation
Treat this contract as binding with the EDEN/AppDev canon and JARVIS master audit. Continue from actual state, preserve LKG, don't recreate project trees, don't stop at documentation and don't claim completion without evidence.


## Immediate user-priority shortcut milestone — 2026-10-14
Lucas clarified that the immediate need is not the full BIFROST Siri integration. He wants to invoke Siri to run HEIMDALL, dictate instructions, have ChatGPT handle them, receive the response aloud through Siri/voice, and ultimately direct/monitor the ChatGPT iOS app working in the existing BIFROST Master conversation.
The HEIMDALL implementation reference and setup/acceptance guide is `~/edenOS/Software Development/HEIMDALL Assistant IOS/docs/HEIMDALL_BIFROST_VOICE_BRIDGE_SHORTCUT_20261014.md`.
Important boundary: a ChatGPT Voice Mode shortcut opens the actual ChatGPT app for spoken interaction but may start a new conversation; Apple's Shortcuts Use Model/ChatGPT extension returns an answer but is not the same as submitting work to the existing BIFROST Master chat with its connected tools. Do not claim the full target is achieved until the exact existing-thread submission and response monitoring are supported and physically verified. The current Mac session cannot install an iPhone Shortcut. The HEIMDALL iOS Simulator build passed, but no production source was changed and no physical Siri/Shortcut acceptance has yet passed.
