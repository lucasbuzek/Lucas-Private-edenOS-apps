# BIFROST

**Bridged Intelligence Fabric for Routing, Orchestration, Services & Tasks**  
**CONNECT · KEEP · RESOLVE**

BIFROST is EDEN's provider-neutral connective product, not a ChatGPT-only client, Cloudflare-specific gateway, MacConnect component, or permanent dependency on any remote desktop provider.

## Product surfaces

- **Native Mac app:** one user-facing BIFROST app with workspace and rainbow status menu, both observing the same Headless state (candidate in PR #28).
- **Headless:** an independently permissioned local background service, deliberately opt-in. It does not become another user-facing BIFROST app.
- **Web/PWA:** local representation of the Headless API. The existing Python tests presently report missing PNG icon assets in the GitHub checkout.
- **Remote MCP:** optional Streamable HTTP adapter with fail-closed OAuth introspection. The currently implemented remote tools are platform read and read-only capability discovery. A manifest-mapped capability is not automatically a verified live provider.
- **Future cloud and other runtimes:** external cloud infrastructure, persistent task/project/memory storage, scheduler, multi-endpoint execution and agent interoperability require independent provider adapters, policies and receipts. They are not marked operational merely because contracts or examples exist.

MCP is the tool interface. Agent-to-agent handoffs and cloud vendor execution must use each provider's **actual authenticated API/runner contract**; do not fake Codex, Antigravity, or other agents as generic MCP executors.

## Ownership boundaries

BIFROST owns connective identities, provider/capability resolution, transport, observable state, and safe dispatch contracts. CONDUCTOR owns higher orchestration; FORGE performs reviewed build/test/package steps; HEIMDALL owns presentation; specialist apps retain their own domain authority. Legacy remote desktop utilities remain independent optional providers or test fixtures, not bootstrap requirements.

## Current engineering state

- The working source is a **GitHub candidate**, not a released installed build or promoted last-known-good product. A physical Mac compile, signed packaging, spectral icon rendering, and interaction acceptance are separate.
- Keep Awake duration selection is a single explicit action against the verified BIFROST Headless endpoint; external caffeinate processes cannot be stopped as a side effect.
- Cloudflare inventory or an unrelated Worker does not constitute BIFROST deployment. No authenticated cloud orchestration mesh, hosted persistent memory or universal cross-vendor agent dispatcher has been accepted.
- Existing installed BIFROST Menu helper copies are not automatically deleted; migration to the one-app design must be owner-approved after testing.

See docs/ONE_APP_CANDIDATE_20261101.md for acceptance, migration and exact remaining gates.

## Evidence discipline

**GENERATED ≠ IMPLEMENTED ≠ BUILT ≠ TESTED ≠ VERIFIED ≠ RELEASED.**  
**UNKNOWN ≠ PASS.** Preserve the existing last-known-good installation and source history until acceptance.
