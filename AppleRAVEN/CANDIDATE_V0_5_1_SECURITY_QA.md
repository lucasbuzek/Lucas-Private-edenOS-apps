# AppleRAVEN v0.5.1 private candidate — source and security test receipt

2026-10-26: Latest runnable source remains a **ChatGPT-conversation ZIP**, not an installed Mac application or a synced GitHub code tree. Do **not** confuse this GitHub document with a source promotion. The existing Mac Project Bible, source, working-tree changes and LKG must be examined before any merge/install.

## Exact validated artifact

- File: `AppleRAVEN-private-v0.5.1-security-hardened.zip`
- SHA-256: `99009fea873c973129ea5f56e89927e7fa9038592289153723be784121319230`
- Distribution: existing conversation attachment; not a public package, not uploaded to GitHub.
- Contents: **26** source/config/asset/test files, no caches.
- Fresh extracted ZIP checksum manifest: **PASS**.
- Python stdlib unit tests: **71/71 PASS**.
- Isolated install/startup: **PASS**, reported **21 MCP tools**, modern `2026-07-28` plus legacy `2025-06-18` support; fresh config permissions **0600**; repeat install refused without overwriting.

## Corrected defect

Prior source advertised several effectful native capabilities as `readOnlyHint: true`, an unsafe semantic contract for autonomous MCP hosts. This candidate marks Shortcuts execution, native app activation, hash-pinned AppleScript, Automator, approved SSH connection, Screen Sharing UI handoff and AI model generation as **not read-only**. Script/workflow/Shortcut actions are potentially destructive; network-reaching capabilities disclose `openWorldHint`. The modern MCP path also rejects calls without `clientInfo` or `clientCapabilities` metadata. New regression tests cover both conditions.

## Scope retained

Lucas-private midnight Apple + raven identity. Standalone local stdio MCP; BIFROST/EDEN is not required. Profile-bound device, Bonjour/mDNS discovery, native Apple tools and per-account model adapters stay subject to actual owner permissions. No credential, cloud, Apple TCC or device change was performed while packaging/testing this candidate.

## Unverified physical/release gates

Connected Mac RDC instances were **OFFLINE** in this execution. No native Shortcuts, iMessage, iCloud, Photos, actual app control, trusted device pairing, live model-provider authentication, or physical iPhone/M1/M3 acceptance is claimed. The broader 391-file Dropbox research remains incomplete. GitHub branch contains older AppleRAVEN source and is **not synchronized** with ZIP; do not call this an accepted LKG or release.

Next: reconcile local source/LKG, synchronize candidate source without clobber, test native macOS operation and actual provider login; then promote only after functional acceptance.
