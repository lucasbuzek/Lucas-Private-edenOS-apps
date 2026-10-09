# RavenNest remote PWA — optional BIFROST interconnect adapter

**Branch candidate; not pushed, not deployed.** Reconciled October 9 2026 to BIFROST PWA and AppDev Bible canon.

RavenNest is an optional authenticated remote transport/provider and remote BIFROST Web representation. Its PWA **does not** replace the six required desktop/native and independent Headless platform targets or the portable BIFROST core. It also does not replace HEIMDALL Workspaces or specialist App authority.

Current source extension in `web/lucas-raven/public/`:

- `manifest.webmanifest`, matching 192/512 spectral icon PNGs, installable browser metadata and Apple touch icon.
- `sw.js` with network-first navigation, anonymous offline fallback, cache-limited public static resources, API/action/auth-session requests never cached.
- `offline.html` explicitly states Node status/actions cannot be verified or queued offline.
- `index.html`, `app.js` expose a browser PWA install control and preserve existing Raven Access/pairing; loss of API connectivity marks live status unverified and disables controls.
- `_headers` allows same-origin service workers/manifests under restrictive CSP.

**Forbidden assumptions:** installable ≠ physically installed, browser pairing ≠ device-specific scoped access, Cloudflare online ≠ authenticated capability execution, source committed ≠ deployed. Never forward localhost tokens or add CORS proxy. Remote execution and setup require per-device grants/confirmation; not implemented here.

**Verification:** Python bridge 27 tests; 28 Edge and 3 Cloud Worker tests; service worker 4 static security tests (source). Real iPhone installation, Access enrollment, per-device grant/revocation, offline browser operation and Cloudflare deployment pending. Local Headless PWA tested with Chrome isolated service; Raven PWA has not been deployed to a physical mobile/browser session.

Project authority: `~/edenOS/Projects/EDEN Apps/BIFROST/docs/BIFROST_PWA_INTERCONNECT_CONTRACT.md` and `BIFROST_CROSS_PLATFORM_PRODUCT_CONTRACT.md`.

No push or cloud deployment without further authorization and verification.
