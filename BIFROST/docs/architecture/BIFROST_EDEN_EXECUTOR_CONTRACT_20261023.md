# EDEN EXECUTOR — BIFROST Local Action Capability
Date: 2026-10-23
Status: OWNER REQUIREMENT RECOVERED / RESEARCH VERIFIED / NEW GUI EXECUTION UNIMPLEMENTED
Authority: Existing BIFROST project under ~/edenOS/Software Development/BIFROST/
Scope: Lucas Custom/Private macOS first; other device/platform adapters separately gated.

## Identity and custody
EDEN EXECUTOR is a BIFROSTcore-local execution capability, exposed through existing BIFROST native app, independent headless service, menu and approved portable shortNameCall dispatcher. It is not a new governor, project master, duplicated headless daemon, duplicate BIFROST UI or universally privileged service.
BIFROST owns routing, target-device identity, permission-bound capability resolution and receipts. EXECUTOR invokes approved local operations. CONDUCTOR plans/co-ordinates; ForgeMASTER owns engineering changes and release gates; HEIMDALL presents. Offline local tasks remain usable without RDC/remote AI; optional RDC stays a transport, account connector and recovery route, not runtime dependency.
Do not replace the current graphical UI with an older/rejected BIFROST presentation. Never start headless, Menu, provider login, browser or background daemon automatically without established approval.

## Recovered implementation — reuse
Existing: headless/orchestration.py; headless/shortcalls.py; core/shortcalls.v1.json; headless/task_ledger.py; Sources/BifrostNativeWorkflowRunner.swift; Sources/BifrostAppIntents.swift; Sources/BifrostPermissionCenter.swift; tests/test_shortcalls.py and tests/test_orchestration.py.
Currently native selection confirms exact installed Shortcuts/Automator workflows. Headless is loopback only with local session/explicit request gates; arbitrary shell and arbitrary URL execution are NOT present in its approved orchestration contract.
No authorization to weaken current checks, accept free-form shell commands, import and execute legacy workflows, bypass privacy prompts, read raw account secrets or substitute unapproved tools. Online Plugins & Connectors remain separate provider adapters.

## Verified Mac evidence — 2026-10-23
RDC6 online to Lucas-MacBook.local, agent v0.3.0; 32% remote calls remaining at initial check. Prior RDC5 account must not be mistaken for this live profile.
macOS 27.0.1 Apple silicon; /usr/bin/shortcuts, /usr/bin/automator, /usr/bin/osascript, /usr/bin/safaridriver present. No CLI executables found on PATH for Hammerspoon, cliclick or Peekaboo; this does not prove no bundles outside PATH.
Existing BIFROST actions bifrost.system.platform.read and bifrost.automation.catalog.read executed with effectsVerified true. Existing discovery found 33 Shortcuts and 3 Automator workflows. Tests: test_shortcalls.py 8/8 and test_orchestration.py 7/7 PASS, including denied unauthorized request cases.
Read-only /usr/bin/osascript JavaScript ApplicationServices AXIsProcessTrusted() returned false FOR THAT PROCESS. It does not establish whether the installed BIFROST app or a separately granted future executable has Accessibility trust.
No browser or GUI workflow physically tested; no new RDC account created; no provider 2FA/OAuth handled; no new executable/app release produced.

## Capability ladder and routing
1. Native deterministic: Apple Shortcuts, App Intents, AppleScript/JXA, Automator and published app APIs. Reuse existing BIFROST adapters and exact verified scripts, not arbitrary shell strings.
2. Structured GUI: supported macOS AXUIElement actions with explicit Accessibility grant; inspect app/window/element state and check postconditions. Prefer element identity over screen coordinates.
3. Visual fallback: optional separately reviewed Peekaboo and/or cliclick for screenshot-based operations when AX metadata incomplete; opt-in Screen Recording/Accessibility and interactive desktop session required.
4. Recurrent workflows: optional Hammerspoon, LaunchAgents and local triggers only for exact registered reviewed workflows with explicit lifecycle controls.
5. Browser: owner-approved Safari/default-browser user session, provider-supported APIs or a bounded browser adapter where permitted. No Chrome. Embedded WKWebView provider login is not presumed supported. Credential autofill/2FA and sign-up are owner controlled.
6. Remote providers: optional RDC/SSH/Bonjour/approved remote transports, routing by verified target identity and connectivity; never use undocumented vendor APIs to evade provider quotas.

## Command model
Every action requires stable ID, origin, actor, target device, selected capability/adapter, argument schema, classification (READ/LOCAL_WRITE/GUI/EXTERNAL/ACCOUNT/SENSITIVE), exact scope, consent requirement, time limit, side-effect receipt, postcondition and rollback/recovery notes. Default DENY for unknown actions, devices or sources.
Expose statuses REQUESTED, APPROVED, RUNNING, PROCESS_EXIT, EFFECT_VERIFIED, DENIED, FAILED and UNKNOWN separately. Exit code 0 is not proof that an external side effect completed.
Actions are batched locally after ONE authorized device dispatch when safe. Local progress/retries/condition checks should not require a fresh RDC remote call for every step. Cost reduction is legitimate batching/offline execution, not circumventing vendor quotas or session/auth restrictions.
Security: loopback by default; externally reachable dispatch requires owner-authorized authenticated pairing. No permanent Full Disk Access or Accessibility default requirement, no silent TCC elevation, no ambient credentials, no provider quota bypass. Separate permissions per device/site/action/account. Scrub logs and screenshots for secrets. Preserve auditable cancel/revocation.

## Initial owner use-case: RDC registration and subsequent actions
Preflight: exact RDC6 existing identity, allowance, existing device pairing, supported registration URL and provider terms, Safari/default browser state, GUI authorization status; distinguish existing-account connection from new-account enrollment.
Plan task -> user approves targeted GUI scope -> open only approved official account route in approved browser -> assist navigation/form filling with consent -> owner completes email verification, passwords and 2FA -> verify actual account/device receipt from provider -> record identity and safe connections in existing BIFROST routing -> carry out approved subsequent tasks through native local executor.
Do not invent new account, skip verification, create many accounts to evade free-tier limits, copy tokens or expose account credentials. This workflow remains NOT PHYSICALLY VERIFIED.

## Research shortlist as of 2026-10-23
Apple Shortcuts CLI and Automator: first-party, present locally, established integration.
Apple native Accessibility AXUIElement: implementation API, conditional user permission; not a bypass.
Peekaboo (https://github.com/openclaw/Peekaboo): optional open-source CLI/MCP with screenshot, accessibility and GUI actions; not installed/approved yet.
Hammerspoon (https://github.com/Hammerspoon/hammerspoon): optional MIT-licensed Lua desktop automation; not installed/approved yet.
cliclick (https://github.com/BlueM/cliclick): optional CLI mouse/keyboard fallback, coordinate-fragile; not installed/approved yet.
Consider source/license/security review before any dependency install. Third-party screenshots/vision or cloud APIs must be separately approved.

## Incremental implementation and evidence gates
Slice A (DONE/VERIFIED): recover canonical source and run existing local read-only dispatch, catalog and adversarial HTTP tests.
Slice B (NEXT): extend existing BIFROST capability registry with read-only EXECUTOR preflight (device identity, available backends, relevant per-process permission results, no new OS prompts); test through native/headless and return a truth-labeled receipt.
Slice C: AppleScript/AX structured local action against an isolated benign test window, denied-permission and wrong-target tests; preserve current Shortcuts/Automator protections.
Slice D: select and review ONE optional GUI adapter if necessary; install/enable only with user consent; prove visual observation -> action -> postcondition on a non-sensitive fixture.
Slice E: owner-guided RDC sign-up / connection-assisted workflow, keeping provider MFA and credentials in user control. Verify result before any account state is recorded.
Slice F: batch/replay/timeout/cancel/recover actions via BIFROST queue and local task receipts; offline and device-reconnect regression; independent later iOS/M3 Pro adapters.
No creation of a separate project source, automatic provider sign-ups, executable installation, publishing or LKG promotion is implied by this requirements contract.

## Known constraints
RDC remote call quota is finite; previous intermittent device-not-online/link eligibility errors and blocked shell operations were observed historically. RDC tool surface has not established general graphical control. Provider/browser auth and MFA may be manual. macOS TCC/Accessibility and Screen Recording grants remain OS- and app-specific; iOS full-device GUI automation is more restricted than macOS. Avoid speculative UNIVERSAL automation claims.
