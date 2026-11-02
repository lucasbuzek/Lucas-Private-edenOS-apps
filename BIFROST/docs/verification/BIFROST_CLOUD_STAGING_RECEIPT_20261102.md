# BIFROST — Cloud/source staging verification receipt (2026-11-02)

**Status: STAGED — NOT A PRODUCT LAUNCH.** This document records only operations actually performed and read back. It is not proof of a working remote executor, enrolled device, Apple/Google login, multi-provider model runtime, dashboard, or physical-device acceptance.

## Authority and constraints

- Source of truth: existing [BIFROST Asana task](https://app.asana.com/1/1219873107425826/project/1219864291600755/task/1219890239198444), `BIFROST/core/shortcalls.v1.json`, `BIFROST/docs/architecture/BIFROST_CROSS_PLATFORM_PRODUCT_CONTRACT.md`, and `BIFROST/docs/decisions/BIFROST_FEDERATED_FREE_OSS_CONNECTIVITY_STRATEGY_20261014.md`.
- One BIFROST product; native/headless/web/cloud as representations of shared capabilities. No MacConnect dependency, extra menubar or extra independent executor. Do not redesign or replace the verified code.
- **Strict $0 hosting**: no trial, paid credit, subscription, or paid feature without Lucas's approval. Free services have hard usage/availability limits.
- Cloud/source implementation may continue without any device. Ask Lucas before **physical device acceptance**.
- Changes belong on existing `candidate/bifrost-one-app-status-20261101` branch; preserve main/LKG and unrelated files.

## GitHub source receipts

| Source | Change | Commit |
|---|---|---|
| `BIFROST/cloud/control-plane/schema.sql` | New conservative D1 state, with no stored credentials or executable shell payloads | `646dc96f9ca8058ac8188deb696ee77ad8e15acd` |
| `BIFROST/docs/research/MCP_EXTERNAL_REUSE_AUDIT_20261102.md` | Glama/GitHub/SourceForge pattern and risk matrix, archive limits, source-first decisions | `b317c0c9b18462193cd4f4d33f8e954d2bbb4e51` |
| `BIFROST/cloud/control-plane/worker.mjs` | Fail-closed isolated staging HTTP routes; typed read-only-capability dispatch metadata only | `62798c3e40cf50cb1b1e9579d660c77f35f894f8` |

## Cloudflare staging evidence

- Account used: existing owner-authorized RAVENsNEST Cloudflare account `d468143e61d414b11fed13f133732964`.
- Existing empty D1 database: `bifrost_control_staging`, UUID `4859cc87-f735-41f2-8c66-3e9eb6514aa4`.
- Applied nine SQL statements and **read back** five tables (`cloud_nodes`, `cloud_capabilities`, `cloud_tasks`, `cloud_receipts`, `cloud_audit`) and four explicit indexes. No nodes, tasks, or receipts were present.
- Uploaded new Worker script `bifrost-control-staging` with `worker.mjs` as main module, `2026-11-02` compatibility date, and a binding to that D1 database. Confirmed binding on readback. Upload etag `c82ea4fba6f90f8db60040cc3a1bc2f9c309b5bde12ed6e1413f32501d1c0d53`.
- Generated a random admin bearer token **only in the connected Cloudflare execution context** and stored as Worker secret `BIFROST_ADMIN_TOKEN`. The token value was **not saved to GitHub, Asana, output, or this receipt**; only the secret *name* was read back.
- Enabled the script's `workers.dev` subdomain; disabled preview deployments. No custom production route attached.
- Public live browser GET [health](https://bifrost-control-staging.lucasravensnest.workers.dev/health) returned:
  ```json
  {"service":"BIFROST","stage":"staging","ready":true,"deviceExecutionAvailable":false}
  ```
- Unauthenticated browser GET `/v1/status` returned:
  ```json
  {"ok":false,"code":"UNAUTHORIZED"}
  ```
- These two browser checks establish actual response *bodies*. Numerical HTTP status was not independently captured in the browser, nor was the protected endpoint tested with a valid secret.
- Original local JavaScript source was syntax-parsed before deployment. This does not substitute for integration/security testing.

## Implemented guardrails and current limits

- Public health reports staging only; `/v1/*` requires a configured bearer secret.
- `POST /v1/tasks` accepts a bounded strict typed JSON envelope (`actionId`, `nodeId`, `idempotencyKey`), with a database check for paired node, verified capability, read-only effect and no extra approval requirement. None currently exist.
- No direct shell, arbitrary command, filesystem tool, remote tunnel, credential broker, permissive execution, or model inference route was deployed.
- Source uses `lucas-owner` as **temporary single-owner staging label**, not verified OIDC principal or multiuser tenant model. Replace only with validated user identity and approval policy in an authorized later change.
- No device has been enrolled or tested. No task has been proven dispatched, leased, executed, cancelled in a real adapter, or externally receipted.
- Not operational: Google/Apple auth, quota-aware provider switcher, real Streamable HTTP MCP interoperability, provider/device adaptor, encrypted payload transport, revocation, persisted projects/memory/schedulers, unified web/native dashboard or rainbow menubar acceptance.
- The old `headless/mcp_bridge.py` already supports modern 2026 stateless `server/discover` and legacy transport; verify interoperability before adding a new bridge.

## Source-reuse research, scope, and open gaps

See [MCP external reuse audit](../research/MCP_EXTERNAL_REUSE_AUDIT_20261102.md) for examined code and URLs. Candidate reuse: Agency MCP (agent-template discovery), Master MCP (typed service/action registry), Nexus MCP (model provider adapters and failover patterns *but not its permissive executor*), IBM ContextForge (federation/auth), MCPHub (dashboard), mcp-use (MCP SDK/inspector), MeshCentral/Guacamole (device access patterns). Do not assume combined licences, maturity, or direct Worker compatibility.

Remaining archive research is **PARTIAL**, not full recovery: older Dropbox/Google Drive assets and wider Glama/GitHub/SourceForge catalog were not exhaustively source-reviewed. Avoid replacing known BIFROST features with duplicate applications.

## Release gates, in order

1. Use canonical BIFROST action IDs and identity policy; implement scoped user/provider auth, device enrollment and revoke/deny tests.
2. Prove a real remote MCP/provider adapter on a free authorized runtime; durable idempotent dispatch with correlated executor receipt and timeout/cancellation handling.
3. Build one existing BIFROST dashboard for nodes, capabilities, tools, projects/tasks, memory, schedules and health, not an independent product.
4. Verify browser and native interoperability, cold restart, offline/error cases, free-limit exhaustion and secret safety.
5. Request Lucas's explicit approval **before physical Mac/iPhone/Windows/Android acceptance**; preserve all existing UI/menubar/installer issues as open until independently verified.

**Asana readback:** Existing task `1219890239198444` received the staging deployment/live-HTTP receipt, was read back successfully, retained older notes, and remained incomplete. This is a provenance record, not a completed-task claim.
