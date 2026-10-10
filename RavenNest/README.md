# RavenNest — online bridge and cloud coordinator

RavenNest is a **standalone online connector/provider** to EDEN/BIFROST, not the BIFROST application or Headless runtime.

**Canonical Mac source:** `~/edenOS/Software Development/Online Plugins & Connectors/RavenNest/`
**BIFROST native core:** `~/edenOS/Software Development/BIFROST/`

## Components

- `web/lucas-raven/`: Cloudflare Pages Raven mobile/web interface, Pages Functions API, D1 schema/migrations and tests.
- `workers/raven-cloud-node/`: independent, scheduled Cloudflare orchestration Worker and unit tests.
- `bifrost/`: optional Mac-side Raven provider adapter (legacy module name retained for compatibility).
- `catalog/`: capability permissions and parameter contract.
- `bifrostctl`, `bifrostctl.py`, `Raven *.command`: existing command interface and setup scripts.
- `launchd/`: the template for the separate Mac Raven bridge LaunchAgent.
- `docs/`: Raven architecture/evidence, including unique historical web previews in `docs/legacy/`.

The Mac bridge has **no authority over cloud jobs** that belong to `lucas-cloud`. Cloudflare owns coordination; provider services do authorized remote execution. Cloud AI provider credentials and physical mobile acceptance are not implied by the existence of a Worker.

The optional Mac bridge is protected by a **manual BIFROST GUI session owner**. It verifies that the owner PID belongs to a running `BIFROST.app` process and exits if that GUI terminates unexpectedly. No additional background watchdog, app login item, or hidden scheduler is installed.

## Source lineage

GitHub repository: `lucasbuzek/Lucas-Private-edenOS-apps`
Canonical Git branch: `ravennest/consolidated-20261010` (pre-consolidation history: `bifrost/cloud-ai-provider-20261009`)
Initial Git consolidation commit: `7a4b742b830a4c6c4b7c8dd3062b5b52e0277e5d` (current source follows the branch head)
Canonical Git tree: `63a5c2652885a6c06108f573e38d98712b9a2da2`

The canonical Git branch now uses `RavenNest/` and contains no `BIFROST/` subtree. Historical Raven development remains accessible through Git history. This folder is authoritative; do not recreate a second RavenNest source under BIFROST or Temporary.

See `docs/MAC_BRIDGE_MANUAL_CONTROL.txt` for the current local status, visible controls, emergency stop and manual-only policy.

## Run and test

The optional macOS launch agent `eden.bifrost.raven-bridge` is **STOPPED and DISABLED by default**. Its installed plist has `RunAtLoad=false` and `KeepAlive=false`. The legacy label and existing Keychain credentials are preserved. Only an explicit **BIFROST > Connections > Start Mac Bridge** confirmation can activate the local session. Stop in BIFROST disables the label again and boots it out. Cloudflare RavenNest operates independently while the Mac agent is off. The legacy `Raven 3 Run bridge.command` is informational and no longer starts an invisible process.

Use `./bifrostctl --help` for supported commands. Validation: `python3 -m unittest discover -s tests`, `node --test workers/raven-cloud-node/tests/*.test.mjs`, `node --test web/lucas-raven/tests/*.test.mjs`.

**Deployment state:** the Cloudflare Worker is deployed; the newer Pages/mobile authorization UI is not deployed. No external AI provider is connected. Do not treat tests alone as a functional user pairing test.
