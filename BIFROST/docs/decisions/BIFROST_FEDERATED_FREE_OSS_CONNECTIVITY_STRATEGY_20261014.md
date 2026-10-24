# BIFROST Federated Free/OSS Connectivity Strategy
Date: 2026-10-14
Authority: Lucas @conductor @argos extendedgoal. Existing Cloudflare, Oracle Cloud, and other free/open-source resources are part of the target ecosystem. Do not assume any cloud account or resource is provisioned/healthy until live evidence is collected.

## Goal
BIFROST is the connection registry and master governor across local Apple devices, HEIMDALL, GitHub, WORKinCODEX/Codex, MCP, RDC, local scripts, Cloudflare, Oracle Cloud, and compatible open-source services. Keep the local Mac as a build/runtime host, not a prerequisite for every workflow. iPhone voice control must continue through an authenticated transport when away from the Mac. Prefer offline/local operation and graceful degradation.

## Provider-neutral capability planes
1. **Edge ingress / secure relay:** Cloudflare Workers and Tunnel as candidate ingress/relay, subject to existing account/resource verification and free-plan quotas. Do not expose BIFROST Headless directly to the public Internet. Cloudflare is transport/edge, not the task authority.
2. **Always-on compute:** Oracle Cloud Always Free candidate for small Linux service, webhook receiver, scheduled reconciliation, and durable queue worker. Verify tenancy, region, actual capacity, current quotas, and costs before provisioning. Do not assume the previous `bifrost-zero-vcn` attempt succeeded or remains available.
3. **Durable state:** keep authoritative task ledger with local SQLite first and backups; consider Cloudflare D1/SQLite-backed Durable Objects or an OCI database only as explicitly configured replicas/remote state. Define conflict/reconciliation rules before multi-writer mode; never let two disconnected ledgers silently diverge.
4. **Queue / retries:** Cloudflare Queues or an OSS queue only after the task ledger and idempotency contract exist. Queue delivery is not execution evidence; each job needs immutable ID, dedupe key, lease/heartbeat, retry cap, cancellation, terminal state, and output/evidence references.
5. **Workflow engine:** start with the existing BIFROST Headless Python service and a typed capability registry. Evaluate self-hosted Activepieces/n8n for connector automation and Temporal for durable long-running workflows only if a real gap is demonstrated. These are candidate providers, not mandatory dependencies; check licenses and deployment costs before adoption.
6. **Open-source self-hosting:** prefer mature maintained projects and existing provider APIs before new code. Examples to evaluate only when needed: Caddy for reverse proxy/TLS, Tailscale or WireGuard for private device networking, PostgreSQL for multi-client shared state, and established queue/workflow tools. Do not install all by default.
7. **Secrets and identity:** per-device enrollment, short-lived tokens, least privilege, secrets held in OS keychain or provider secret store; no secrets in prompts, logs, repository, Shortcut text, or public status endpoints. Cloud resources must be private by default.
8. **Monitoring and quotas:** provider adapter publishes observed health, remaining quota, last successful check, rate-limit status and evidence timestamp. At configurable thresholds (including 99%), notify and propose alternate instance/provider. Create accounts, accept billing, change identity, or add paid resources only after Lucas's explicit approval.
9. **AI Toolkit:** inspect selected device and installed apps, recommend a minimal capability set, offer guided installation, verify versions and permissions, and record local/offline/online/hybrid support. Never silently install or enable services.

## Target topology
Apple Shortcuts/Siri → HEIMDALL voice entry → authenticated BIFROST ingress → policy router/task ledger → local/native tools OR selected provider adapter (Cloudflare/OCI/MCP/RDC/GitHub/Codex/OSS) → evidence/result store → HEIMDALL/Siri response. silentChatGPT is optional reasoning/escalation, never the execution authority. Local Mac operation must remain possible without cloud access; remote operation must not assume the Mac is online.

## Delivery order
A. Inventory and live-verify existing Cloudflare, Oracle, GitHub, MCP/RDC and local resources. Record VERIFIED / FAIL / UNKNOWN with timestamps; do not create accounts or provision resources yet.
B. Implement typed provider/capability registry and read-only health/status API.
C. Implement durable task ledger and authorization/idempotency state machine locally; test offline and recovery.
D. Implement one authenticated remote ingress adapter (choose Cloudflare OR OCI based on observed existing resources, cost, and constraints), with replay protection, request limits, explicit write approvals and no direct shell endpoint.
E. Add queue/retry and result callback only after the ledger is reliable.
F. Connect HEIMDALL macOS/iOS Shortcuts and silentChatGPT response path; verify physical devices independently.
G. Add secondary provider failover, usage monitoring, account/instance proposals and open-source workflow integrations incrementally.

## Security and reliability gates
- No public unauthenticated shell, command runner, generic file read/write, or arbitrary MCP/RDC passthrough.
- Read/write/destructive capabilities separately declared. Require explicit user confirmation for destructive actions, account creation, billing, credential changes and deployment changes.
- At-least-once queues must be made safe with idempotency; never equate dispatch or model response with success.
- Local source/user data is canonical unless project policy explicitly chooses another authority. Cloud storage only carries minimum required state; never bulk-upload private projects/photos by default.
- Device unreachable/offline: continue supported local work, queue safe deferred requests, state what cannot run, and reconcile without duplicate execution.
- Free-tier quotas change; verify official docs and live account usage before designating a resource as free/available.

## Current evidence and boundaries
- Current BIFROST source was previously inspected: Headless is loopback-only, not always running, AI provider is unconfigured, remote setup execution disabled, and no general authenticated task API/ledger was found in that inspection.
- Prior Oracle Always Free/BIFROST ZERO attempt is a project lead, not proof of a live instance. Existing Raven/Cloudflare docs are historical evidence; live health must be rechecked.
- Mac BIFROST build succeeded; 78 Python and 10 JavaScript tests passed in the previous verification. No iOS/Mac Shortcuts have been installed or physically accepted yet.
- This strategy document is not proof that cloud resources were provisioned, configured, or tested.


## Superseding routing decision — Cloudflare Workers are routing/control-plane only
Date: 2026-10-14. Lucas clarified that Cloudflare Workers are sufficient for routing; do not assign them real project execution or coding-agent work. Preserve the existing RavenNest architecture and previously established provider suggestions instead of proposing a new generic cloud portfolio as if starting from zero.

### Correct responsibility split
- **Cloudflare Pages/Workers + RavenNest + D1:** lightweight authenticated edge ingress, request validation, identity/grant checks, capability lookup, route selection, enqueue/dequeue, heartbeats, job IDs, status polling, audit metadata, quota/health signals and result relay. Keep requests small and bounded. Worker execution is not a substitute for a coding agent or a project runtime.
- **Actual work:** route to the most capable already-authorized execution provider: WORKinCODEX/Codex Cloud for coding tasks when legitimate signed-in provider submission is available; GitHub Actions/CI for repo-defined jobs; an enrolled local/remote node for OS/device-specific tasks; an authorized MCP server/RDC host for its declared tools; specialist EDEN apps for their domains; optional model providers only for reasoning/inference. Each executor must return a provider job/task ID and independently observed results.
- **Oracle Cloud:** optional compute/node only if the existing Always Free tenancy and usable capacity are verified and a workload genuinely needs a persistent host. It is not required merely to route requests and must not become a competing BIFROST core.
- **Open-source/free candidates already relevant:** existing RavenNest, GitHub Actions/free CI where eligible, MCP, RDC, WORKinCODEX/Codex Cloud, local scripts/native tools, and optional provider adapters. Additional workflow engines or servers are conditional gap-fillers, not default installations. Keep the prior provider suggestion catalog and evaluate candidates against actual missing capability, license, quota, connectivity, privacy and maintenance burden.

### Existing live-evidence boundary
The 2026-10-10 `RAVEN_CLOUD_LIVE_EVIDENCE_20261010.md` establishes that `lucas-raven.pages.dev`, the `lucas-raven` D1 database, and the scheduled `raven-cloud-node` Worker were deployed and exercised at that timestamp; the Worker wrote a heartbeat into D1. It also records that GitHub token was not configured, AI provider execution was NOT_CONFIGURED at that timestamp, mobile enrollment/physical acceptance was UNKNOWN, and GitHub push failed due missing Git HTTPS credentials. Treat this as historical verified evidence, not a claim of current live health.

### Required route lifecycle
1. BIFROST Master converts intent into a typed capability request and risk class; the Worker must not invent the plan.
2. Raven authenticates the user/device, checks explicit grant and allowlisted capability, validates bounded parameters, records a task/action ID and routes it to a capable executor.
3. The executor performs the work; the Worker does not run arbitrary code, expose shell, or pretend a model answer is execution.
4. The provider returns its own task/job ID and observable state. Raven polls/relays status; BIFROST verifies outputs/postconditions and records an audit receipt.
5. If no eligible executor exists, return BLOCKED/UNAVAILABLE/UNKNOWN with the exact missing provider/account/permission. Do not replace execution with an inference answer.
6. Keep remote queue TTL/retry/idempotency bounded; add durable long-running workflow handling only where real executor requirements demand it.

### Next AUTO action
Recover the previously established provider list and inspect Raven's current capability catalog, auth/enrollment contracts, Cloud AI execution document, WORKinCODEX adapter, and Codex/CI integration evidence. Produce a capability-to-executor matrix and mark each connection VERIFIED / NOT_CONFIGURED / UNKNOWN based on actual current evidence. Then implement the smallest route-to-real-executor slice; do not expand Cloudflare Worker code into a fake general executor.
