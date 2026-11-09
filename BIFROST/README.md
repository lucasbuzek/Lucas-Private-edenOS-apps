# BIFROST

**Bridged Intelligence Fabric for Routing, Orchestration, Services & Tasks**  
**CONNECT · KEEP · RESOLVE**

BIFROST is EDEN's **user-local endpoint access and local environment management app**, not an agentic orchestration engine, cloud fleet governor, universal AI gateway, ChatGPT-only client, MacConnect component, or Remote Desktop Commander dependency. The 2026-11-09 owner correction controls the current scope; the acronym and historic source are preserved.

## 2026-11-09 current functional boundary

**IN:** local user interface; local endpoint discovery/pairing; device capabilities, files, apps, services, networking and peripherals; approved terminal/desktop/browser access; independent opt-in Headless; diagnostics, local security and permissions, offline operation and verifiable receipts.

**OUT:** model/LLM routing; AI/RAG/knowledge-memory; multi-agent planning; cross-device, cross-user and cloud orchestration; global connector registries, global project/task scheduling and autonomous remote provisioning. These functions belong to the separate agentic orchestration environment (RAVENaIntelligence), never to the BIFROST installed default.

**Compatibility:** existing BIFROST local and remote interface code stays in its candidate branch for audit and safe migration. Do not delete source, promote LKG or imply working cloud/device connections from a documentation change. See `docs/architecture/BIFROST_CROSS_PLATFORM_PRODUCT_CONTRACT.md` for the current-owner addendum and historical requirements.

## Product surfaces

- **Native Mac app:** one user-facing BIFROST app with workspace and rainbow status menu, both observing the same Headless state (candidate in PR #28).
- **Headless:** an independently permissioned local background service, deliberately opt-in. It does not become another user-facing BIFROST app.
- **Web/PWA:** local representation of the Headless API. The existing Python tests presently report missing PNG icon assets in the GitHub checkout.
- **BIFROSTbridge:** endpoint-facing, owner-scoped interface for approved local capabilities (local IPC and optional authenticated MCP/HTTP/A2A transport). Existing remote MCP tests cover platform read and read-only discovery; they do not prove live device integration or universal federation.
- **External intelligence and cloud:** RAVENaIntelligence owns advanced intelligence, model selection, multi-agent workflows and cross-endpoint/cloud orchestration. Its authenticated callers may use BIFROST as a local executor/access boundary; global agent/cloud code is not a BIFROST product feature. Existing cloud staging source remains historical/candidate until separately reconciled.

MCP is the tool interface. Agent-to-agent handoffs and cloud vendor execution must use each provider's **actual authenticated API/runner contract**; do not fake Codex, Antigravity, or other agents as generic MCP executors.

## Ownership boundaries

BIFROST owns **local** endpoint identity, discovery, permissions, capability exposure, explicit local actions, operational state, setup, diagnostics, Keep Awake and truthful receipts. BIFROSTbridge is the endpoint connector; it does not own the global MCP/A2A/user/cloud registry. RAVENaIntelligence is the separate advanced agentic environment; CONDUCTOR retains cross-domain coordination and ForgeMASTER engineering governance. HEIMDALL owns workspaces/voice, ELYSIUM its portal, JANITOR maintenance and specialist apps their own domains. Legacy remote desktop tools remain optional adapters.

## Current engineering state

- The working source is a **GitHub candidate**, not a released installed build or promoted last-known-good product. A physical Mac compile, signed packaging, spectral icon rendering, and interaction acceptance are separate.
- Keep Awake duration selection is a single explicit action against the verified BIFROST Headless endpoint; external caffeinate processes cannot be stopped as a side effect.
- Cloudflare, hosted intelligence and universal orchestration are external owner domains, not BIFROST release gates. Existing cloud staging and remote MCP prototypes are not accepted production integration with RAVENaIntelligence.
- Existing installed BIFROST Menu helper copies are not automatically deleted; migration to the one-app design must be owner-approved after testing.

See docs/ONE_APP_CANDIDATE_20261101.md for acceptance, migration and exact remaining gates.

## Evidence discipline

**GENERATED ≠ IMPLEMENTED ≠ BUILT ≠ TESTED ≠ VERIFIED ≠ RELEASED.**  
**UNKNOWN ≠ PASS.** Preserve the existing last-known-good installation and source history until acceptance.
