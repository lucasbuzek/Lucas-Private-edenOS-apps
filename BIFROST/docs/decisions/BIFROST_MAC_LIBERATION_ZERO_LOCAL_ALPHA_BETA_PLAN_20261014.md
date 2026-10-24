# BIFROST — Mac liberation and four-target execution plan
Date: 2026-10-14
Authority: recovered canon in `docs/architecture/BIFROST_CAPABILITY_ARCHITECTURE_RECOVERY_2026-10-07.txt`; user's clarification that the goal is to liberate the MacBook from being the mandatory router, executor, storage host, and application host for projects.

## Canonical decision
There are four already-established versions/targets of the same BIFROST capability fabric: ZERO → LOCAL → ALPHA → BETA. These are additive stages, not four competing products. Preserve the current workflow and improve it first; do not redesign from scratch. BIFROST owns CONNECT · KEEP · RESOLVE. CONDUCTOR reasons/orchestrates; HEIMDALL composes Workspaces; specialist Apps own domain work/data; authoritative executors perform tasks. Cloudflare Workers are a lightweight routing/control plane only. They are not the coding agent, project runtime, bulk storage, or actual-work executor.

## What “liberate the MacBook” means
MacBook remains one authorized endpoint/development device, not the single point of failure. Work must be routable to an appropriate capable provider/node and projects should use their canonical repositories/storage, with results flowing back to the initiating UI. Do not simply move all work to another single server. Separate routing, reasoning, execution, durable state/storage, and presentation.

## Four established stages (recovered canon)
### ZERO — adapt current workflow now
Keep ChatGPT/CONDUCTOR, Codex/WORKinCODEX, Claude where available, GitHub, MCP, RDC, existing scripts, Apple Shortcuts, and project apps. Automate prompt/context handoff, session/task identity, project/path selection, provider submission, status polling, build/test invocation, result return and evidence capture using existing legitimate connectors/CLIs/APIs. ZERO must deliver useful improvement without waiting for the full BIFROST Native Bridge or requiring the Mac to relay every request. If a provider supports cloud execution directly, submit there; if a task needs a specific device, route directly to that enrolled device.
### LOCAL — native/direct execution and interaction
BIFROST Node with native service/headless/API, capability registry, device trust/presence, Bonjour/Network.framework on LAN, local IPC, MCP stdio/localhost where appropriate, and app-focused Remote App Surfaces. Use the lowest sufficient route: same-process/local → localhost/IPC → direct LAN → remote transport. Local/offline work should function without Cloudflare or Internet when the capability itself is local.
### ALPHA — Cloudflare-assisted remote routing
Reuse the existing RavenNest/Cloudflare Pages + D1 + Worker work. Workers authenticate/validate bounded requests, check grants, assign IDs, route/enqueue, record lightweight metadata/heartbeats, poll/relay status and return results. Keep Cloudflare work lightweight. Actual work goes to an authorized capable executor such as a cloud coding agent, GitHub Actions, an enrolled device/node, or scoped MCP/RDC provider. Pages/D1/Workers do not imply a coding executor exists. Keep AI text inference separate from project execution.
### BETA — provider-independent/self-hosted remote routing
Keep the same BIFROST contracts while allowing a private/self-hosted transport/relay/compute provider to replace Cloudflare. Oracle Cloud Always Free may be one optional host if existing tenancy/capacity is verified; it is not required just to route requests. Reuse existing open-source/provider candidates only where they fill a proven gap. Apps/HEIMDALL must not need to change when transport provider changes.

## Functional planes and placement
1. **Voice/UI:** Siri + Apple Shortcuts, HEIMDALL, BIFROST Web/Garden of EDEN; can run on the iPhone or any supported browser/device.
2. **Reasoning/plan:** CONDUCTOR and configured model providers; optional and replaceable. A model response is not execution evidence.
3. **Routing/registry:** BIFROST plus RavenNest/Cloudflare edge when remote routing is needed; bounded control plane only.
4. **Execution:** cloud coding agents/WORKinCODEX where genuine cloud submission is supported, GitHub Actions/CI, authorized MCP/RDC tools, enrolled device nodes, specialist EDEN apps, or explicitly authorized scripts. Route to the provider that can actually perform the task.
5. **Authoritative project data:** GitHub/source repo for code; each specialist app owns its data; large files remain with the selected canonical storage/provider. Mac-local paths must not be assumed accessible from remote executors. Pass scoped repository/artifact references rather than moving entire projects by default.
6. **Task metadata/evidence:** Raven D1 can be a remote lightweight queue/metadata store within verified limits; BIFROST local state and/or explicitly selected durable store keeps authoritative task records. Avoid multi-writer split-brain; define task IDs, idempotency, leases, status, output references and reconciliation.

## Required route contract
A request must carry a stable task ID, capability ID, project/repository identity, bounded inputs/context references, risk class, originating device, explicit grant/authorization, selected executor, and requested postconditions. Executor response must include provider task ID, observable state, output/artifact references, timestamps and error/evidence. Statuses: RECEIVED, CLASSIFIED, AWAITING_APPROVAL, DISPATCHED, RUNNING, SUCCEEDED, FAILED, CANCELLED, BLOCKED, UNKNOWN. Never report success from a model answer, a queued task, a heartbeat, or a successful HTTP request alone.

## Existing-resource reconciliation (don't reset to zero)
- RavenNest Cloudflare Pages/D1/Worker: deployed and heartbeat exercised in historical evidence dated 2026-10-10; recheck current health before marking current VERIFIED.
- Raven cloud AI candidate: Worker deployed historically, Pages UI/API candidate not deployed, external AI provider NOT_CONFIGURED; harmless `cloud.state.refresh` task succeeded, but no AI provider call proven. Inference only; not a coding executor.
- WORKinCODEX: installed project with tests and recovery evidence; provider submission still depends on real authenticated/signed-in Codex path. Distinguish cloud environment prepared, signed in, submitted, started, accepted and verified.
- Oracle: project/recovery material exists; prior BIFROST ZERO tenancy/VCN attempt is not proof of a live compute instance. Verify live account/instance/region/capacity first.
- BIFROST: current macOS build and previous test suites passed, but its local headless endpoint was not listening at previous check and generic task execution/provider adapters are not complete.
- HEIMDALL: source has named Shortcut handoff/callback architecture; physical device callback acceptance remains UNKNOWN.

## AUTO implementation order
1. **Recover existing capability catalog:** merge BIFROST and Raven `catalog/capabilities.v1.json`, `bifrostctl`, `node_state`, `remote_provider`, `workincodex`, Raven bridge, WORKinCODEX project state and existing HEIMDALL shortcut handoff into one evidence-backed matrix. Do not invent a fifth architecture.
2. **Prove ZERO workflow:** choose one harmless existing task; record origin → provider submission → provider task ID → status/result → evidence receipt, without Mac acting as mandatory router when a direct cloud/provider path exists.
3. **Activate ALPHA routing only:** recheck Cloudflare live health and auth/enrollment; keep Worker limited to route/status. Implement an adapter only for an executor with actual documented, authorized submission/status API. If Codex Cloud lacks a supported API path, use the legitimate existing WORKinCODEX flow and report the required attended step rather than simulating it.
4. **Reduce Mac dependency:** move routing/queue/monitoring to Raven/cloud relay where safe; run project tasks on provider-owned cloud agents or CI where possible; use Mac only for tasks requiring macOS/native apps, local data or physical device. Keep local BIFROST path for offline/direct work.
5. **Separate storage:** make GitHub and specialist owners canonical for source/data; publish builds/artifacts to declared artifact storage; use Cloudflare D1 only for small job metadata/queue records, not large project files. Never bulk-upload private files/photos without explicit approval.
6. **BETA fallback:** only after ZERO/LOCAL/ALPHA acceptance, verify the existing Oracle tenancy and implement provider-neutral transport adapter if remote sovereignty/failover is needed.
7. **Voice:** finish the Mac/iOS Shortcuts and HEIMDALL callback only after the task/status path can return real typed results.

## Acceptance gates
- Mac offline/unavailable: cloud-routable task can still be submitted and monitored if provider supports it; no dependence on Mac for routing or storage.
- Mac required task: route to Mac node only when capability says macOS/native app/local data is required; if unavailable, queue or block truthfully.
- Provider unavailable: choose a compatible alternate only if policy allows; otherwise BLOCKED/UNKNOWN with reason.
- Retry/replay: no duplicate write or job due to idempotency key and state ledger.
- Result: real artifact/status/postcondition checked by an independent verifier.
- Security: per-device identity, least privilege, scoped project access, no public shell, no free-form model-to-command execution, approvals for destructive actions and account/billing changes.
- Four targets reported separately: ZERO/LOCAL/ALPHA/BETA with PASS/FAIL/UNKNOWN; do not infer later-stage readiness from earlier-stage evidence.

## Immediate next deliverable
Create the evidence-backed provider/capability matrix from existing files and run the current RavenNest/BIFROST/WORKinCODEX tests with a correctly invoked runner. Then wire one route to one real executor. This is the smallest useful vertical slice toward removing the Mac as mandatory router/executor/storage host.
