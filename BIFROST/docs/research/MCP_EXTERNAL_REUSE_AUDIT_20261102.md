# BIFROST — external MCP/agent reuse audit (2026-11-02)
Status: **PARTIAL_RESEARCH**, SOURCE_READ for the linked projects; **NOT_INSTALLED**, **NOT_CONNECTED**, **NOT_END_TO_END_VERIFIED**.
Authority: [existing BIFROST Asana task](https://app.asana.com/1/1219873107425826/project/1219864291600755/task/1219890239198444), BIFROST core/shortcalls.v1.json, docs/architecture/BIFROST_CROSS_PLATFORM_PRODUCT_CONTRACT.md, docs/decisions/BIFROST_FEDERATED_FREE_OSS_CONNECTIVITY_STRATEGY_20261014.md. No replacement architecture.

## Locked owner requirements (2026-11-02)
- RAVENsNEST Cloudflare control plane first; **strict $0**, no trials/credits/paid upgrades without consent.
- Continue cloud and source work independent of offline Macs. Ask Lucas before physical device acceptance.
- BIFROST remains one independent identity: native, headless, web and cloud representations, one capability authority.
- No MacConnect dependency or duplicate governor, native executor, app, menu or public unauthenticated shell.

## Primary source review
| Candidate | Direct source / evidence | Runtime and license | Fit; decision | Known gap |
|---|---|---|---|---|
| npupko Agency MCP | https://glama.ai/mcp/servers/npupko/agency-mcp-server ; https://github.com/npupko/agency-mcp-server ; inspected src/index.ts | MIT, Node.js stdio, dynamic git clone/pull of agent-template repo | **ADAPT_PATTERN** lazy, searchable specialist agent discovery on demand | Not an execution provider or durable cloud service. Template provenance/version pinning, review before dynamic pull. Default git auto-update cannot run inside Workers. |
| Raindancer118 Master MCP | https://glama.ai/mcp/servers/Raindancer118/master-mcp ; https://github.com/Raindancer118/master-mcp ; inspected src/index.ts | TypeScript/Node stdio, credentials in env; exact license needs independent LICENSE inspection | **ADAPT_PATTERN** typed \`list_services\` / \`list_actions\` / \`execute_action\`; instance routing and parameter Zod validation | Many effectful admin actions. Published source marks destructive calls but no universally enforced second-party approval at execute_action handler. Do not expose directly to public cloud. |
| 10-gaurav-01 Nexus MCP | https://glama.ai/mcp/servers/10-gaurav-01/nexus-mcp ; https://github.com/10-gaurav-01/nexus-mcp ; read router.ts, sandbox.ts, plan-executor.ts | MIT, Node stdio/local dashboard, remote model API optional | **CANDIDATE_ADAPTERS** multiple model providers, quota/rate-limit failover, councils and DAG concepts. No auto-install | Shell allowlist is not a sandbox (python/node can execute code); path check uses startsWith without segment boundary; plan registry in memory and no known cancel. Never import unreviewed executor or treat in-memory plan as durable. Account switching must respect terms and user-granted identity. |
| IBM ContextForge | https://github.com/IBM/mcp-context-forge ; inspected README/docs | Apache-2.0, Python/FastAPI, SQLite possible; persistent Docker/Python host | **PRIORITY_EXTERNAL_BACKEND** for mature MCP/A2A/API federation, scopes, auth, admin observability | Not a drop-in Cloudflare Worker. Requires verified always-free persistent host and memory/capacity profile before deployment. No installation evidence. |
| MCPHub | https://github.com/samanhappy/mcphub ; inspected README/docs | Apache-2.0, Node>=22, Docker recommended, PostgreSQL production | **PRIORITY_UX_REFERENCE** for one gateway dashboard, per-user OAuth, lazy discovery, credentials, monitoring | Not Worker-only; hosting/runtime cost within $0 unverified. Do not add competing BIFROST frontend. |
| mcp-use | https://github.com/mcp-use/mcp-use ; inspected README/docs | MIT, TS/Python SDK and Inspector, Node runtime | **CANDIDATE_SDK** for typed MCP Apps and ChatGPT/Claude interop tests, inspector | Framework is not a complete orchestration platform. Verify actual compatible transport/version before incorporating. |
| Ankka MCP Gateway | https://github.com/ankka-ai/ankka-mcp-gateway ; inspected README | Apache-2.0; Cloudflare Access/MCP Portal | **INVESTIGATE** Cloudflare-native scoped source/tool allowlists | New/unproven (0 stars at inspection); depends on Cloudflare account features and provisioning; no BIFROST deployment. Not primary established donor. |
| MeshCentral | https://github.com/Ylianst/MeshCentral ; https://sourceforge.net/projects/meshcentral.mirror/ | Apache-2.0, Node backend, desktop/terminal/file agents | **PRIORITY_DEVICE_REFERENCE** for genuine multi-OS remote management, separate from gateway | SourceForge entry is a GitHub mirror. Persistent host + device consent still required. |
| Apache Guacamole | https://guacamole.apache.org/ ; https://sourceforge.net/projects/guacamole/ | Apache-2.0; web gateway to existing RDP/VNC/SSH | **OPTIONAL_REMOTE_DESKTOP** if supported remote protocol exists | Does not replace device agents, file/process management or secure native pairing by itself. |
| Glama directory/hosting | https://glama.ai/mcp/faq ; https://glama.ai/mcp/hosting | Free search, hosted deployments paid as of inspection | **DISCOVERY_ONLY** under current strict $0 | Do not choose hosted deployment or paid gateway without approval. |

## Existing BIFROST evidence and non-regression
- Existing candidate branch: \`candidate/bifrost-one-app-status-20261101\`. \`headless/mcp_bridge.py\` **already includes a modern 2026-07-28 stateless \`server/discover\` path plus legacy 2025 support**. Older inventory calling it legacy-only is stale. Preserve and verify interoperability.
- \`core/shortcalls.v1.json\` is the canonical typed action catalogue. No importing arbitrary \`command\` strings or remote client tool IDs as executable instructions.
- \`headless/task_ledger.py\` persists *local read-only observations*. Do not misrepresent it as remote dispatch or broaden it silently.
- \`headless/orchestration.py\` owns approved Shortcuts/Automator paths. No second OS executor.
- \`cloud/control-plane/schema.sql\` is routing metadata only; it creates no remote authorization, credentials, paired devices or completed actions.

## Cloud cost/implementation evidence
- Authorized account: RAVENsNEST \`lucasravensnest@gmail.com\`, Cloudflare account \`d468143e61d414b11fed13f133732964\`.
- \`bifrost_control_staging\` D1 \`4859cc87-f735-41f2-8c66-3e9eb6514aa4\` verified **empty before** applying this schema; no BIFROST Worker was present at inspection.
- Cloudflare D1 Workers Free includes finite no-overage daily limits (5M reads / 100K writes / day; 5GB total; 10 databases), which **fail when exceeded** rather than authorizing a paid plan. Current total D1 count observed: 6. Source: https://developers.cloudflare.com/d1/platform/pricing/
- Durable Objects with SQLite backend can be used on Workers Free, but use hibernating sockets if approved. Do not silently enable paid Workers, Containers, hosting or third-party API calls.

## Missing verification / release gates
1. **Original archives:** disparate 386/391-file old snapshots and 7,855-item broader Dropbox inventory were NOT all text-extracted or upstream-audited. Continue original-URL/code/license retrieval for relevant parts of \`AI MCP tool\`.
2. **Security:** real OIDC/Access identity and separately authenticated devices, scopes, grants, replay protection, approvals, cancellation, revocation, rate/size limits, negative auth tests.
3. **Cloud:** deploy Worker with D1 binding and owner-authenticated endpoints, explicitly **not** a general code execution endpoint; test durable task lifecycle and encrypted payload policy.
4. **Execution:** integrate a proven independent executor (approved provider or device node), return provider job ID, verified receipts; cloud dispatch != action completion.
5. **UX:** single BIFROST web/native interface, rainbow menubar icon and unified Keep Awake, AI routing, projects/tasks/schedules/memory.
6. **Cost:** confirm each chosen hosting/runtime/provider is within strict $0 at deployment time.
7. **Physical:** only after Lucas approves device tests; offline Mac does not block source/cloud work.

This is a source-first engineering ledger; it is not a claim that research is exhaustive or BIFROST has launched.
