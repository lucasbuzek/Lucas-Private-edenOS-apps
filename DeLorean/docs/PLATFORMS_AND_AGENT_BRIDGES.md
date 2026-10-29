# DeLorean TimeMachine — Multi-client, multi-platform agentic and native architecture

Version: 0.2.5 candidate architecture correction · 2026-10-29
Product identity: **DeLorean TimeMachine** (unchanged; established clock/time-travel identity retained).

## Mission and topology

DeLorean is ONE product with:
1. **Portable agentic capability:** a discoverable skills + MCP interface for ChatGPT, other compliant agent hosts/assistants, and host-integrated workflows. No platform, single LLM vendor, or Cloudflare service is a mandatory gate.
2. **Local native clients and authorized on-device executors:** macOS, Windows, Linux, iOS/iPadOS, Android, and adaptable browser/web/PWA frontends are product TARGETS, not completed deliverables. Native UX on each platform and platform-specific backup/restore must be implemented, signed/installed and accepted independently.
3. **Shared client-neutral recovery core:** state, timeline, manifests, provenance, compare, backup planning, restore preview, integrity and rollback evidence. Portable Python stdio MCP is a working candidate for desktop OSes; encrypted engines and OS-native backup adapters are optional. Mobile OSes do not inherit desktop filesystem privileges.
4. **Existing connector bridge routing:** ChatGPT or any other host with authorized connector capabilities can execute provider operations through those *existing connector APIs* directly. The native app may also expose its own permissioned local stdio or supported remote MCP/HTTPS broker. A dedicated DeLorean remote MCP is OPTIONAL, not a universal dependency.

The phrase 'agentic plugin' describes the reusable behavior/capabilities across agent hosts. The specific installed **ChatGPT plugin** is one integration/distribution surface, not the product or the only operator.

## Routing contract — choose capability, not brand

For an operation, first discover available AUTHORIZED capabilities and real health, then route:
- Git history/source: existing GitHub connector; read or write only with actual repo grant and verified receipt.
- Google Drive/Dropbox/provider revision history: their existing connectors, within source-specific permission and retention rules. A revision record is not automatically a complete recoverable backup. Do not use Dropbox for EDEN AppDev source/backups contrary to the recovered Dropbox Lite Project Bible.
- Local project/app/device backup or restore: an ONLINE explicitly authorized native/desktop executor or DeLorean MCP; never pass invented file paths to a disconnected machine.
- Encrypted local/NAS/cloud backup: previously configured and tested Kopia/restic or appropriate native engine; credentials remain with that backend, not the model.
- Mobile recovery: only permissioned platform-native paired-device flows where supported; do NOT claim arbitrary iOS/Android device imaging or app-data extraction.
- PENELOPE: OPTIONAL reference and relationship specialist, not an agent-runtime or storage prerequisite.

The agent may coordinate independent cloud operations while a device is offline. An offline host blocks only operations needing that host. The product must remain useful offline on a provisioned native client. Cross-actor permission isolation, exact grants, user-visible approval for writes, non-destructive restore staging, proof by readback and rollback gates are mandatory.

## Canonical product platform matrix (target vs. evidence)

| Surface | Product target | Existing evidence | Gaps |
|---|---|---|---|
| ChatGPT | Agentic plugin and authorized connector orchestration | Existing private plugin v0.2.4 and current connected GitHub/Drive/Dropbox; source-level skill routing updated | No direct installed DeLorean backup MCP connection; ChatGPT live native execution unverified |
| Claude, Codex, Gemini, other MCP-aware hosts | Portable skills/MCP connection | stdio JSON-RPC source candidate, no vendor-specific assumptions | Actual host registration, host compatibility and end-to-end tools/call not accepted |
| macOS | Native app plus local executor | SwiftUI candidate source and portable Python fixture MCP | Original local source, build, signed app, Time Machine actual restore unverified |
| Windows | Native desktop app plus local executor | Portable Python MCP design and optional Kopia/restic Windows support | Windows executable, GUI, VSS/system-image integration, device restore and tests unverified |
| Linux | Native desktop app plus local executor | Python candidate runs and tests on isolated Linux sandbox | Production GUI, distro-native filesystem/boot recovery, packaged install and physical restore unverified |
| iOS/iPadOS | Native mobile companion, on-device capabilities subject to OS sandbox and consent | SwiftUI read-only catalog importer candidate | iOS binary, paired backup integration, write approval and physical restore unverified |
| Android | Native mobile companion and supported OS-owner/user data recovery | Design specification only | Android app/package, permission model, OEM-specific backup integration and physical restore unverified |
| Browser/PWA | Responsive timeline and remote authorized operations | Read-only offline HTML and MCP Apps UI candidate | Verified remote OAuth/broker, browser install/host interactions and device operation unverified |

Design system must be shared but adapted to native conventions/accessibility on every platform. Preserve original clock icon and DeLorean TimeMachine name. No generic placeholder logo, no forced Apple-only design, no invented launched mobile clients.

## Adapter/API contract (cross-host)

All agent surfaces use identity-scoped verbs: `discover_capabilities`, `list_devices`, `timeline`, `list_snapshots`, `compare`, `verify`, `backup_plan`, `backup_execute`, `restore_plan`, `restore_stage`, `restore_verify`, `rollback_plan` and source readback. Those are logical capabilities, not a claim of already registered shortNameCalls or real provider endpoints. Existing MCP methods retain their established names until a versioned migration.

Receipts include: `owner`, `provider`, `source_ref`, `device_id` (when authorized), `operation`, `approval`, `recorded_at`, `evidence_state`, `snapshot_hash_or_manifest`, `restore_target`, `test_result` and `rollback_ref` as applicable. Never put secrets, unredacted filesystem paths or unrelated tenants into an agent-visible shared timeline. `SUPPORTED` (in protocol) != `HOST_CONNECTED` != `DEVICE_TESTED` != `RECOVERABLE`.

## Deployment rules

Use stdio for on-device desktop MCP clients supporting process launch. Remote clients may use an existing permitted connector or an authorized, secured gateway supporting standard MCP Streamable HTTP and per-user auth, origin validation, TLS, scoped grants and approval. Local device availability is not required to query independent cloud providers. Do not install daemons, expose unauthenticated HTTP, bypass mobile sandboxes or automatically synchronize private archives.

## Acceptance gates

1. Preserve original DeLorean source, Project Bible, LKG, backups and existing private plugin ID; merge only source-backed gaps.
2. Test one real host invocation per target agent/client with authentic connector/tools/call readback; do not count plugin skill text as host connection.
3. Build/launch native app and perform real backup/restoration rehearsal independently for each OS family. Native complete-system recovery requires its own operating-system restoration acceptance.
4. Prove positive, negative, regression, owner isolation, corruption, offline/online transitions and real rollback; JANITOR cleanup only after accepted recovery.
5. RAVENsNEST can retain permissioned metadata/evidence; GitHub remains source history; cloud backup location is optional and provider-specific.

Source references: official MCP transport spec https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/docs/specification/2026-07-28/basic/transports/index.mdx ; Kopia supported desktop OS https://kopia.io/docs/installation/ .
