# BIFROST provider/capability matrix — 2026-10-14

Purpose: make the MacBook optional as router/executor/storage host while preserving the established ZERO → LOCAL → ALPHA → BETA architecture. This matrix distinguishes source/test evidence from live connectivity. No provider is marked live-verified solely because its adapter or catalog entry exists.

## Current evidence-backed matrix

| Capability / provider | Declared route | Evidence | State now | Mac dependency | Next gate |
|---|---|---|---|---|---|
| RavenNest / Cloudflare Pages + D1 + Worker | `cloud.state.refresh`; lightweight authenticated routing, queue/status | Historical live deployment + heartbeat in 2026-10-10 evidence; current source tests pass | HISTORICALLY VERIFIED; current live health UNKNOWN | Can route without Mac if cloud deployment/auth are still healthy | Recheck live Pages/Worker/D1 health and device grant; do not add real execution to Worker |
| Raven `ai.infer` | bounded text inference with explicit consent | Worker tests pass; docs say provider unconfigured on 2026-10-10 | SOURCE-TESTED; LIVE PROVIDER UNKNOWN / previously NOT_CONFIGURED | Cloud inference can run without Mac once configured | Verify current secret/provider availability; inference remains not project execution |
| `github.repos.status` | read-only repository status | Catalog capability exists; historical GitHub token missing | NOT_CONFIGURED at last evidence; current auth UNKNOWN | Cloud-native when credentials/API available | Verify least-privilege GitHub connection; never print token |
| `codex.cloud.submit` via WORKinCODEX | submit bounded handoff to Codex Cloud | Guarded adapter + 12 WORKinCODEX tests and 32 Raven Python tests pass | ADAPTER SOURCE-TESTED; actual authenticated cloud submission UNKNOWN | Intended to run remote when real Codex cloud environment supports it; existing transport uses local CLI/attended context | Check login and supported submit/status flow; capture provider task ID and actual start state; no guessed environment IDs |
| `codex.cloud.status` | inspect existing task by validated ID | Catalog + adapter/test evidence | SOURCE-TESTED; live provider status UNKNOWN | May need local CLI context depending on current adapter | Verify real task lookup without creating/submitting work |
| GitHub Actions / CI | repository-defined build/test | Provider capability is part of established plan; no fresh run performed in this continuation | AVAILABLE AS ROUTE OPTION; connection/current quota UNKNOWN | Independent of Mac after repository/workflow exists | Pick a safe repo-defined workflow and prove remote run + artifact/status |
| Authorized MCP tools | app/service-specific declared actions | Existing ecosystem integrations, but no unified fresh inventory run here | PER-CONNECTOR UNKNOWN | Depends on server placement; prefer remote-capable service where compatible | Inventory exact server, capabilities, auth, scopes, health, and evidence |
| RDC / enrolled nodes | device/OS-specific actions | WORKinCODEX isolated-home setup tests pass; no device route execution in this run | TOOLING SOURCE-TESTED; REMOTE EXECUTION UNKNOWN | Mac needed only when selected node is Mac-specific; remote nodes may execute independently | Confirm enrolled node, explicit grant, task ID, postcondition evidence |
| BIFROST native + Headless | local registry, local/offline tools, future task ledger | 78 Python + 10 JS tests pass; prior check found headless endpoint not listening; provider adapters incomplete | SOURCE-TESTED; SERVICE HEALTH UNKNOWN; GENERAL EXECUTION NOT IMPLEMENTED | Local/offline path remains Mac-local unless another Node is enrolled | Implement capability resolver + durable task ledger; do not mark general execution ready |
| Oracle Cloud Always Free | optional persistent node/worker | Existing recovery files and prior VCN attempt only | LIVE TENANCY / INSTANCE UNKNOWN | Can remove Mac runtime dependency if a real eligible instance exists | Verify tenancy, region, instance, reachability, quota, and cost before using |
| HEIMDALL + Apple Shortcuts / Siri | iOS/macOS voice entry and result presentation | Shortcut contract/source exists; no shortcut installed/physical test evidenced | PHYSICAL ACCEPTANCE UNKNOWN | iPhone UI can initiate remote work; transport must not be Mac-loopback-only | Create/test Shortcut, remote pairing, spoken result, and offline behavior |

## Verification run 2026-10-14
- BIFROST Python: 78 PASS.
- BIFROST JavaScript: 10 PASS.
- RavenNest Python: 32 PASS.
- RavenNest Pages JavaScript: 36 PASS.
- RavenNest Cloud Worker JavaScript: 12 PASS.
- WORKinCODEX Python: 12 PASS.
- Total: 180 source test cases PASS.
- BACKUFULL snapshot `~/edenOS/Backups/BIFROST/BACKUFULL_20261014`: 162 files checksum-verified after including test evidence; source snapshots preserve five BIFROST symlinks.

These are code-level test results. They do not prove current cloud health, credential validity, provider execution, Mac-independent task completion, or physical iPhone acceptance.

## Mac-liberation routing policy
1. Resolve request → required capability and risk → eligible provider/node → authorization → submit → provider task ID → poll/observe → verify result/postcondition → receipt.
2. Prefer direct provider-to-executor routing when supported. Do not make the Mac relay requests that the iPhone/Cloudflare can safely submit directly to a remote executor.
3. Cloudflare Workers perform routing, validation, queue/status and relay only; no project coding or bulk storage.
4. Store source in the canonical GitHub/project repository and outputs in declared artifact storage. D1 holds small task metadata only. Do not assume remote workers can read Mac-local paths; submit repository refs or approved artifacts.
5. If the selected provider is not configured, return `BLOCKED` or `UNKNOWN` with the exact missing dependency. A model response, queue receipt, heartbeat, or HTTP 200 is not task success.
6. Keep device-specific tasks on their required enrolled node. Mac may be an executor when necessary, but must not be the mandatory router for all work.


## Live checks performed after matrix creation — 2026-10-14
- `https://lucas-raven.pages.dev/` returned HTTP 200 from the MacBook at check time. This proves Pages reachability only; it does not prove authenticated Worker/D1 routes or executor health.
- `gh auth status`: no GitHub host logged in on this MacBook at check time.
- `codex login status`: Codex reports not logged in on this MacBook at check time.
- `wrangler` CLI was not on PATH; no Cloudflare account/deployment inspection performed from CLI.
- BIFROST Headless `127.0.0.1:8798/api/health`: connection refused; service was not running at check time.
- Oracle tenancy/instance and physical iPhone/Shortcuts were not checked in this pass.

Consequences: do not attempt unattended Codex cloud submission through this Mac until its legitimate login/provider path is established. Do not treat the reachable Pages site as proof of an active remote executor. Next lowest-risk progress is verify an existing supported cloud executor through its own authenticated channel, or use a repository-owned GitHub workflow after the user authorizes GitHub login; no credentials were requested, created, or changed.


## Live gateway recheck — 2026-10-14 07:44 SAST
- `https://lucas-raven.pages.dev/` returned HTTP 200.
- `https://lucas-raven.pages.dev/api/health` returned HTTP 200.
- Unauthenticated `GET /api/state` returned HTTP 401.
- Unauthenticated `GET /api/catalog` returned HTTP 401.
- This confirms the current public Pages API health response and anonymous rejection. It does not prove an authenticated owner session, D1/cron Worker health, cloud provider configuration, node enrollment, or execution.
- GitHub connector confirms current private repo branch heads: native-consolidated `d9c0e0539694d7d1885f6d45cbe10df2fd484cef`; Task 1 `48f611dbe627a6f96f8874a875d52233874ea316`; Task 2 `cb8bca61a9d28498f226ab2073059cb9f67c1872`; ZERO gateway `367341148d4cafd59777156fe5565845e120ee83`. See `../operations/CURRENT_PROJECT_AUDIT_20261014.md`; branches are divergent candidates, not proof of an LKG.
