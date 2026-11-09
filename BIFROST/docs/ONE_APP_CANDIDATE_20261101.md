# BIFROST single-app + remote MCP candidate (2026-11-01)

This is a **candidate**, not a Mac-installed build, LKG promotion, or cloud deployment.

## What is integrated

- XcodeGen builds **one user-facing BIFROST.app** (bundle eden.private.bifrost). Its normal window and colorful bridge status item share BifrostSystem.headless, not two independently initialized clients.
- The status item reopens the actual app window; there is no menu-helper app-location selector.
- Keep Awake duration buttons in the window and status menu call the same BIFROST Headless action. The live status item distinguishes BIFROST-owned Keep Awake and registered-but-unreachable Headless. The countdown is shown in menu/window.
- Headless remains a separately managed, **opt-in background launchd service**, so its work survives a window or app quit. The UI cannot silently start or stop another owner's Headless or caffeinate process.
- The optional OAuth-protected remote Streamable HTTP MCP server offers the already-authorized platform-read tool plus a read-only capability catalogue. The latter reuses shortcalls.resolve and marks **executor mapped ≠ runtime verified**. It grants no arbitrary command, provider login, job submission, or access to contract-only actions.
- The BIFROST core remains provider-neutral: no dependency on a single AI chat provider, Cloudflare, RDC, or MacConnect.

## Source and migration

The older MenuController/BIFROSTMenuControllerApp.swift source remains in history as a recovery reference but is **not a built target** in project.yml. Existing, separately installed BIFROST Menu bundles are **not automatically terminated or deleted**. At physical acceptance, explicitly quit the old menu helper before testing the new status item; inspect installed copies before approving an uninstall. No destructive migration is authorized here.

The existing authenticated MCP entrypoint is still optional and not hosted. A Cloudflare Worker, provider-specific adapter, remote task execution plane, multi-agent dispatcher, schedules, durable memory, and unified web chat/workspace are **not** made operational by this candidate. They require explicit adapter contracts, identity/policy, persistent storage, actual providers, and acceptance receipts. MCP connects tools; it does not by itself turn hosted Codex/Antigravity/etc. into callable remote execution endpoints.

## Required acceptance before promotion

1. On macOS 15+: generate the Xcode project using xcodegen and build the BIFROST scheme without code signing.
2. Confirm **one installed app**, one menu item, visibly multicolor rainbow arc (not a template/monochrome symbol), live Headless and Keep Awake status, and successful window reopen after closing the window. Screen capture is required for visual sign-off.
3. With BIFROST Headless stopped, choose a timed duration once: it should start **only the verified BIFROST service** and activate the selected duration. Verify countdown, natural expiry, stop, restart, offline/unreachable states, and unrelated caffeinate isolation.
4. Run the Python regressions, including capability discovery negative cases and the full BIFROST suite; exercise browser/PWA and physical Mac smoke tests separately.
5. For remote MCP, provision an owner-approved OAuth issuer, correct /mcp resource audience and private introspection secret, and HTTPS reverse proxy; then verify unauthenticated denial and authenticated discovery/platform read using a real client. **Do not deploy an unauthenticated cloud endpoint.**
6. Only then consider signing, packaging, explicit legacy-helper retirement, deployment, and LKG promotion.

Build/test/visual/authentication gates are distinct. Passing source or simulated tests does not prove a live Mac status item, cloud agent, provider connection, or executed workflow.
