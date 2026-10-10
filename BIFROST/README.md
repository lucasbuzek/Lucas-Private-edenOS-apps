# BIFROST — CONNECT · KEEP · RESOLVE

**Canonical native source:** `~/edenOS/Software Development/BIFROST/`  
**Installed private development App:** `~/Applications/BIFROST.app`  
**Independent online connector:** `~/edenOS/Software Development/Online Plugins & Connectors/RavenNest/`

BIFROST is a local/native control interface, provider/capability registry and optional standalone Headless service. It is not the cloud AI computation host. Cloudflare RavenNest owns the online coordination plane; optional local Mac connections require explicit manual approval. Cloudflare remains independent if BIFROST or the Mac is offline.

## Local RavenNest safety

- Mac RavenNest launch-agent label: `eden.bifrost.raven-bridge`.
- **Default: STOPPED and DISABLED.** `RunAtLoad=false`, `KeepAlive=false`.
- BIFROST menu bar / Connections / Settings: inspect status, **Start Mac Bridge…** (with confirmation), **Stop Mac Bridge**.
- Manual session is attached to BIFROST's live process PID. On ordinary quit the Mac bridge stops. If the GUI unexpectedly exits, the Python loop detects the missing owner and terminates.
- The legacy standalone click-to-run command is informational only. Do not silently start background services, turn on login items, or install watchers.
- Cloudflare Pages status is separate from local RavenNest bridge status. A reachable gateway does not prove external AI providers are configured.

## Build and verify

Run `xcodegen generate --spec project.yml` and build the `BIFROST` macOS scheme in Xcode. Python tests: `python3 -B -m unittest discover -s tests -q`; JavaScript tests: `node --test tests/*.mjs`. UI clicking and genuine Mac bridge activation remain physical acceptance gates; do not treat a compilation or a test as product release proof.

BIFROST's Headless service, if explicitly started, remains independent of the GUI and follows its own lifecycle. RavenNest is never automatically coupled to Headless, Caffeinate, RDC or BIFROST installation.

**Status:** private development build, not an official/public release. The installed App is ad-hoc signed for local use. Do not promote it over a verified LKG without physical testing.
