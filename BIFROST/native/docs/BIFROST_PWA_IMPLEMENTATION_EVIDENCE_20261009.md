# BIFROST PWA Interconnect — implementation and evidence, October 9 2026

**Governance:** BIFROST CONNECT · KEEP · RESOLVE. Source/candidate is not a released product. Cross-platform native/Headless requirement remains six target variants, each separately gated; PWA is an additional universal representation/transport adapter.

## Implemented in current local Native/Headless project

- Local Headless install manifest `headless/manifest.webmanifest`, 192/512 PNG spectral icons and reproducible stdlib icon generator.
- Local `headless/sw.js` network-first navigation, anonymous offline fallback, strict static allowlist; API, mutation, authorization, session and user state remain uncached/network-only.
- Versioned read-only `GET /api/pwa/adapter` describes actual same-origin local Headless state interface, setup catalogue, confirm-before-stage local route and disabled remote installation.
- Local PWA menu section provides truthful local/remote/unverified/offline states, browser-supported install affordance and explicit Raven link. Dashboard fails closed when local Headless cannot be contacted; local-only operation still works without general Internet.
- Local server restricted to `127.0.0.1`; no new CORS/public bind/open proxy, no user approval bypass, no changes to live Caffeinate or remote bridge service.
- Existing Xcode bundle includes local PWA files through established `headless` resources group.

## Implemented in separate Raven source branch (not deployed)

- Raven remote PWA manifest, matching spectral icons, static-only worker with offline fallback, browser install affordance and CSP allowing own worker/manifest.
- Existing Raven authentication/Cloudflare Access, Node permissions and backend action allowlist remain authority. PWA installation itself does not grant any capability.
- Remote UI shows unavailable on failed API rather than retaining old success status; no cross-origin proxy or local Headless token transfer.
- Branch: `bifrost/raven-headless-observation-20261009`, isolated worktree. The running `eden.bifrost.raven-bridge` service and deployed Cloudflare ZERO remain unchanged.

## Evidence

- Isolated local Headless PWA static and adapter endpoints returned success with correct MIME/CSP: manifest, service worker, icons, offline page, read-only adapter.
- Chrome headless launched isolated local Headless, evaluated dashboard and observed `Local Node connected` from its actual API. Isolated service then stopped. Browser install, mobile install and LAN/remote trust remain unverified.
- Local Python suite **37/37** passed; local service worker cache harness **4/4** passed.
- Raven Python suite **27/27** passed; Raven worker cache harness **4/4** passed.
- Raven Edge **28/28** and Worker **3/3** tests passed.
- XcodeGen + Xcode macOS Debug/no-sign build passed, packaged PWA resources present.
- Remote PWA Cloudflare deployment, Access enrollment, actual iPhone/Android install, per-device grants, and direct secure LAN connection **NOT VERIFIED**.

## Physical acceptance gates (not promoted)

1. Browser installation flow verified on target macOS/Windows/Linux and mobile platforms; scope/offline lifecycle and upgrade.
2. iPhone/iPad Add to Home Screen, login/session invalidation, Access policy, revocation, multiuser privacy and denied/expired key tests.
3. Direct LAN transport implemented with mDNS/HTTPS/trusted device identity (rather than exposing `127.0.0.1`).
4. Self-hosted/BETA remote provider exchangeability, round-trip Node state/capabilities and action results through scoped permissions.
5. Full platform-specific native and independent Headless implementations and DP0.1 persistence kernel.

**State:** STATIC/LOCAL ENVIRONMENT PASS for PWA source candidate. PHYSICAL GATE OPEN. No release promotion.

## Local deployment addendum (2026-10-09)

Live Headless updated after validated pre-update runtime ZIP and no active Caffeinate assertion. Local HTTP served /api/pwa/adapter and PWA manifest/worker/offline/icons successfully; restarted Headless to PID 39009. RavenNest agent remained running; Cloudflare/Raven web deployment unchanged. Mobile/physical acceptance still pending.
