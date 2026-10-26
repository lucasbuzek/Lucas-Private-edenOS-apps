# AppleRAVEN v0.5.1 — independent local MCP tested package, 26 Oct 2026

**Canonical status: candidate only.** This document records a separate verified conversation artifact; the GitHub branch source is **not** falsely claimed to be synchronized with the v0.5.1 ZIP. Preserve main, prior candidate source, native Mac LKG and existing user installations. AppleRAVEN is Lucas's private dark Apple/Raven identity, not official EDEN/edenOS.

## Package
- Exact downloadable conversation artifact: `AppleRAVEN-private-v0.5.1-verified-MCP.zip`
- SHA-256: `6c53cfede9c43b94ab6dd087051548f4dae915a74d5fabd2a5111df25c9215ef`
- Contents: 25 source/tests/docs/identity files; 24 per-file hashes verified against `CHECKSUMS.sha256`; archive integrity passed.
- Independent fresh unzip, **69/69 Python regression tests PASS**.
- Fresh isolated HOME installer ran 69 tests and performed live MCP subprocess smoke: **21 tools, both modern 2026-07-28 and legacy 2025-06-18**. Configuration mode 0600; second installation refused overwrite.
- Installed `scripts/smoke_mcp.py` also runs standalone from outside the source working directory. A discovered earlier regression (hard-coded 20-tool count and missing standalone import path) was corrected and retested.

## Actual additive functionality / safety
1. New read-only `appleraven.models.verify_local` checks local Ollama GET `/api/tags` and LM Studio GET `/v1/models` for a **fixed per-profile approved route**. It transmits no prompt or credentials, refuses all remote/cloud providers, and does not assert that a model generation has occurred.
2. `model_bridge.py` installs a no-proxy opener; inherited HTTP(S)_PROXY cannot route local prompts off-device. External provider calls also bypass ambient proxy configuration. Existing fixed endpoint, no redirect, approval-gated cloud inference remains.
3. Installer tests staged package **before final promotion**, so protocol smoke failure does not publish an incomplete versioned target.
4. No user data moved, no cloud AI accounts authenticated, no Apple permissions granted, no background daemon or remote LAN exposure.

## Boundaries
- MacBook currently OFFLINE through connected Remote Desktop Commander, so physical Mac/iPhone, TCC, real Shortcuts/iCloud, secure home-LAN connection and AI account acceptance are **UNKNOWN**.
- Research folder has **391 current Dropbox entries**; full live website/source review remains incomplete. Filename matches and inventories are not complete due diligence.
- The v0.5.1 executable lives **only in the conversation ZIP**, not in this old GitHub source branch. Never build the old branch and call it 0.5.1.
- Next legitimate native step: on Mac recover live `#common` and original AppleRAVEN/LKG, inspect diff, install candidate side-by-side, perform client/provider + physical tests, then promote only after accepted evidence.

## No-clobber / custody
Only this evidence document was added to the existing protected GitHub candidate branch. No merge, source overwrite, GitHub release, plugin install or Apple account changes.
