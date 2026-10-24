# BIFROST PWA / Interconnect Adapter — Canonical product addendum

Status: **REQUIRED PRODUCT REPRESENTATION** (2026-10-09 user decision), **STATIC PWA IMPLEMENTATION CANDIDATE** and cross-device integration **NOT VERIFIED**.

## Identity and placement

BIFROST is CONNECT · KEEP · RESOLVE. Its Web/PWA is a first-class, *installable capability/representation adapter* over the same BIFROST Node/Headless/Provider contracts, not a seventh independent core and not HEIMDALL's Workspace engine. The six desktop/Headless deployment variants remain required: macOS, Windows and Linux × native and independent Headless.

Two existing surfaces provide the incremental first implementation:

- **BIFROST local PWA** served over loopback by Headless: truthful, same-origin state, setup visibility and already-authorized controls. Installable shell from the local service; no LAN/public exposure or independently privileged service.
- **RavenNest remote PWA** (Lucas Private's optional ALPHA provider): existing authenticated Cloudflare Web representation, displaying authorized remote Node capability state and bounded actions. No direct calls from the remote page to the local loopback service; no arbitrary shell execution. Cloudflare Access/iPhone pairing and secure per-device grants must be separately verified before claiming remote setup control.

Both use compatible UI identity, mobile-safe layouts, isolated PWA cache and manifest/install lifecycle; **the transport/provider is replaceable**. A separate self-hosted/BETA adapter and direct authenticated LAN/LOCAL transport must use the same capability schemas. Do not fork domain logic or cache another authoritative database in browsers.

## Route and trust negotiation

1. Same process / local IPC, when inside a native App.
2. **Same-origin** Headless local API for the local PWA (loopback only).
3. Validated, enrolled Node on LAN using HTTPS / proven secure transport and permissions, when implemented.
4. Authenticated optional remote-provider PWA (RavenNest/Cloudflare ALPHA, or self-hosted BETA).
5. If untrusted/unreachable/offline: report UNAVAILABLE, display cached *static interface/help only*, do not claim device status/health or queue changes as completed.

A PWA's installed state is *not* device trust, authentication, authorization or proof that actions can execute. Adapter capability discovery returns typed availability, consequence and supported method; only the authoritative Node or specialist App may perform domain actions.

Cross-origin access is **explicit navigation or authorized federation**, not a browser proxy. Never work around mixed-content/private-network restrictions with open CORS, local-server public binds, undocumented tokens or third-party script injection. Remote↔local state shares typed contracts and separately scoped device identity, *not* direct session-token forwarding.

## PWA capability contract (planned portable design)

Node descriptor fields where supported: `nodeId`, `representationId`, `transport` (loopback | lan | remote), `apiVersion`, `capabilities[]` with action IDs, input/output schema, read/write effect, availability, owner, consequence level, permissions and deep/web links. `auth`: platform pairing + per-device grants + confirmation for consequential actions; **not implemented by present local UI**.

App/Headless discovery: `BIFROST.getRepresentations() → [native, headless, webPWA, remote]`; `BIFROST.resolve(capability, policy) → approved provider/Node/transport`; invoke only through allowlisted typed endpoints with verified postconditions. PWA can link/embed the lowest sufficient specialist representation when authorized; it does not become the specialist data owner.

## Offline/cache security

Service workers are allowed to cache *only allowlisted static* JS/CSS, icon/manifest and the deliberately anonymous offline page; **never cache** `/api/*`, authentication/callback/session URLs, POST responses, user/device/action lists, provider credentials, task IDs, private data or runtime state. Navigation is network-first. Offline fallback is explanatory, **not an offline copy of the last trusted state**. Do not silently retry state-changing requests after reconnection. Registration only on a secure context (HTTPS/localhost) and under appropriate CSP.

Raven mobile installation is a separate browser install/physical gate and cannot be claimed from a generated manifest. iOS supports Add to Home Screen for compatible PWAs; installed status and platform OS limitations must be checked in practice. Existing shared operator key/URL fragment is legacy and not a per-device permission scheme.

## Platform/distribution matrix

| Surface | Availability target | Current evidence |
|---|---|---|
| macOS local Headless PWA | Loopback dashboard; installable from supported Mac browser; same Headless API | Foundation/source gate, install/physical gate not verified |
| Windows native + Headless / local PWA | Same BIFROST contracts; OS-appropriate service/GUI, local Web PWA served by Windows Headless | Contract only |
| Linux native + Headless / local PWA | Same BIFROST contracts; OS-appropriate service/GUI, local Web PWA served by Linux Headless | Contract only |
| Cross-device PWA (mobile/browser) | Authenticated LAN/remote transport, Node discovery/representation resolver | Raven source candidate; direct LAN/auth grant incomplete |
| iPhone/iPad | Add-to-Home-Screen/browser, user-authenticated BIFROST remote App Surface | Physical install/pair/access not verified |
| Android | Browser/PWA Web entry, optional platform native representation | PWA browser acceptance not verified |

One App/Headless product per OS, one portable core, PWA representation shared logically. Distribution presets Lucas Private, Slindokuhle Private, Family/Friends and Official configure branding/provider defaults separately from generic transport/capability contracts. ZERO/LOCAL/ALPHA/BETA are deployment stages, not separate incompatible products.

## Evidence and acceptance

Reference and requirement are AUTHORITY, not implementation. PWA static foundation acceptance requires correct manifest names, icons, scope/start URL; SW registers and offline fallback loads from cache; no API/action/auth endpoint can be cached; network requests, status and buttons fail closed; CSP permits worker and manifest but not unsafe cross-origin requests; browser installability physically checked. Native and Headless continue independently.

Remote interconnect acceptance additionally requires real iPhone/Android session, enrolled device, Access checks, per-device grant and revocation, concrete capability execution with audit ID/result and explicit negative/denial/offline tests. Current phase **does not** meet that gate.

## Source authority

- AppDev Bible / Universal App Integration & Hierarchy
- BIFROST_CAPABILITY_ARCHITECTURE_RECOVERY_2026-10-07.txt §§3–5, 7, 10–20, 22–24.
- BIFROST_CROSS_PLATFORM_PRODUCT_CONTRACT.md (six variants)
- Latest explicit user request (2026-10-09): PWA as adapter/interconnect.
