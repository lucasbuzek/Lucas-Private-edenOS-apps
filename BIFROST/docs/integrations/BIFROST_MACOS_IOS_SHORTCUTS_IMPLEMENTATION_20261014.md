# BIFROST Master — macOS and iOS Shortcuts implementation contract
Date: 2026-10-14
Authority: Lucas's @forgemaster AUTO request; universal silentChatGPT canon.
Canonical BIFROST root: ~/edenOS/Software Development/BIFROST/
HEIMDALL root: ~/edenOS/Software Development/HEIMDALL Assistant IOS/
Status: workflow specification saved; Shortcuts app cannot create shortcuts through its supported CLI, so actual shortcut creation/physical acceptance is still pending.

## Goal
Use Apple Shortcuts as the cross-device entry surface for BIFROST/HEIMDALL workflows. Use the Apple-supported silentChatGPT path, not ChatGPT app UI automation, website automation, copy/paste, or an assumed API. Keep native/local work first, reduce context before model escalation, validate responses, and never misrepresent a model answer as an executed BIFROST task.

## Shortcut A — iOS voice entry
Name: HEIMDALL Voice — silentChatGPT
Siri phrase: “Hey Siri, HEIMDALL Voice — silentChatGPT”
Actions in order:
1. Dictate Text — prompt: “What should HEIMDALL do?”
2. Text — insert the Dictated Text variable into the request wrapper below.
3. Use Model — select Extension Model, then ChatGPT; pass the Text output as input. Keep the action's actual response variable.
4. Speak Text — speak that response variable.
5. Show Result — display the same response.
Optional: add a confirmation before any action that would change data or send sensitive content. Never automatically transmit raw photos/documents/secrets.

## Shortcut B — macOS entry
Name: BIFROST Voice — silentChatGPT
Siri phrase: “Hey Siri, BIFROST Voice — silentChatGPT”
Actions in order:
1. Dictate Text (or Ask for Input if voice dictation is unavailable) — prompt: “What should BIFROST do?”
2. Text — wrap the dictated input using the request wrapper below.
3. Use Model → Extension Model → ChatGPT — pass the Text output and capture the actual response.
4. Speak Text — speak the response.
5. Show Result — display the response for inspection.
6. Optional local status action: Run Shell Script with /bin/zsh to run the BIFROST health helper only after it is installed and the local Headless service has been explicitly started. This is a status check, not a task executor. Do not silently enable launch-at-login, background services or RavenNest.
Use separate Mac and iOS shortcuts: their available actions, permissions and runtime contexts differ. iCloud sync can be used if Apple exposes the shortcut as compatible, but verify each device independently.

## Request wrapper for the Text action
You are silentChatGPT, a bounded reasoning helper invoked by HEIMDALL/BIFROST. Process the user's current request only. Respect the user's established EDEN/AppDev canon and the local-first policy. Do not claim you inspected files, called a provider, executed a workflow, changed a device, created an account, or verified a result unless an actual authorized tool/action supplied evidence. If the request requires BIFROST's connected providers, persistent task ledger, repository/device operations, or current in-chat tools that are unavailable to this Shortcut action, say so plainly and return the next concrete handoff instruction. Separate recommendations from completed actions. Preserve user intent and required destination paths, minimize unnecessary explanation, and format the answer for speech plus on-screen review. Do not expose credentials, secrets, or unrelated context. User's spoken request: [insert Dictated Text variable]

## What this does and does not do
- It uses the configured Apple ChatGPT extension to return a response without opening ChatGPT's UI.
- It is not an unrestricted OpenAI API, and a consumer subscription does not create arbitrary API access.
- It does not automatically inject the request into this existing ChatGPT/BIFROST chat, access the conversation's tools/connectors, or guarantee persistent conversation history.
- It does not remotely execute BIFROST tasks. A returned model response is untrusted reasoning input, not execution evidence.
- BIFROST Headless is loopback-only and currently is not always running. Do not make a Shortcut claim the local service is available without checking. Its current API has status/control/kernel endpoints, not a general authorized task-execution endpoint.
- The actual task execution layer still needs an authenticated adapter into BIFROST's persistent task ledger/provider runtime before the Shortcut can be described as a JARVIS-style execution surface.

## HEIMDALL app handoff
HEIMDALL already supports running a named installed Shortcut with text input and returns through heimdall://shortcut-callback, using per-job callback authorization. Create a companion Shortcut named exactly silentChatGPT that accepts Shortcut Input, uses the same bounded wrapper and Use Model action, validates/labels its output, and returns the actual output through the callback URL supplied by HEIMDALL. Do not hard-code a callback token. Test success/error/cancel and stale/replayed callback rejection. Do not create a second workflow engine inside Shortcuts.

## Installation/acceptance procedure
1. On the Mac, open Shortcuts and create BIFROST Voice — silentChatGPT using the action sequence above. Ensure Use Model is configured to Extension Model → ChatGPT.
2. Invoke it on the Mac with Siri or from Shortcuts. Verify the spoken request, exact returned response, visible response and privacy prompts.
3. On iPhone, create HEIMDALL Voice — silentChatGPT; if the Mac version syncs via iCloud, still verify the action availability and configuration on iOS. Invoke through Siri while unlocked.
4. Test no network, extension unavailable, cancel, long dictation, malformed model output, and a sensitive/destructive request. Ensure no silent file upload or external mutation.
5. Test the HEIMDALL app's existing named-Shortcut handoff and callback on a physical iPhone.
6. Mark each platform PASS/FAIL/UNKNOWN separately. Do not claim ready because the guide exists or the app builds.

## Current environment evidence
- Mac shortcuts list works; the supported CLI exposes run, list, view, and sign, but no shortcut-create/import subcommand.
- macOS Shortcuts GUI automation through System Events was blocked by Accessibility permission; no permission was changed.
- BIFROST Python suite: 78 tests passed on 2026-10-14.
- BIFROST Headless was not listening on 127.0.0.1:8798 at the time of the health check; README says the service is explicitly started, not silently enabled.
- HEIMDALL source already has HEIMDALLShortcuts AppShortcutsProvider and ShortcutHandoff; source existence is not physical acceptance.
- No new shortcut was installed on the Mac or iPhone during this run. The next device-side gate is to create the two Shortcuts in Apple's UI, then verify the real model extension and HEIMDALL callback.


## Verification update — 2026-10-14 05:41 local
- BIFROST project generation: `xcodegen generate --spec project.yml` succeeded.
- BIFROST macOS Debug build: `xcodebuild ... CODE_SIGNING_ALLOWED=NO build` succeeded (`** BUILD SUCCEEDED **`). This is build evidence only, not shortcut/runtime acceptance.
- Python tests: 78 passed, 0 failed.
- JavaScript tests: 10 passed, 0 failed.
- `shortcuts list` shows no shortcut named BIFROST, HEIMDALL or silentChatGPT. No new shortcut is installed. The BIFROST directory has no `.git` directory, so no Git status/commit is available from that path; do not imply version-control persistence.
- BIFROST Headless health endpoint was not listening at the time checked. Existing runtime has no general authorized task-execution endpoint; do not route arbitrary voice commands to mutating actions.
- macOS Shortcuts UI creation is blocked in this session because System Events lacks Accessibility permission; no permissions were changed. Remaining gate: create the action sequences in Shortcuts UI on Mac/iPhone and verify each platform physically.


## 2026-10-22 — Lucas clarification: Apple-system bootstrap and lightweight BIFROSTzero

Newest owner requirement, additive to the existing product canon: BIFROST on MacBook Air must be capable of preparing/installing BIFROST on the owner's MacBook Pro M3 through Apple-supplied system facilities. Target RDC, Homebrew, third-party remote agent, Cloudflare or an already installed BIFROST instance must NOT be prerequisites for that first Apple-to-Apple bootstrap. Current authorized RDC is an engineering access path, not the required production bootstrap dependency.

Use supported existing Apple facilities for each real task: Bonjour/Network.framework discovery, owner-authorized macOS Remote Login/SSH and SFTP for authenticated device inspection/transfer, system installation/signature verification for a reviewed eligible package, and existing native Shortcuts/App Intents/Automator/AppleScript/Services/Share/Siri/Apple Intelligence integrations as appropriate. A fresh Mac without any enabled authorized remote-access path requires an owner-attended Apple first-trust step; discovery and shared Apple Account/iCloud membership do not grant remote installation rights. AirDrop/Share can supply an attended bootstrap where remote login is absent; do not claim transfer equals installation or expose a public shell. Exact implementation must check target model/architecture/OS, package identity and hashes/signing, selected components, existing installation/data, target-side authorization, installed health and rollback. Do not install on the MacBook Pro during source repair without the separate existing installation gate.

AI TOOLKIT retains its established device-preparation/tool-model catalog responsibility. BIFROST selects and coordinates its existing capabilities, showing native-first Recommended/Lean/Full/Custom choices and actual device compatibility, without duplicating the toolkit or silently installing every available component. Existing setup_manager.py is only an archive importer/stager; its presence does not satisfy deployment/bootstrap.

BIFROSTzero on iPhone/iPad is intended as a lightweight browser/WebKit/PWA-facing control experience with multiple independently persisted provider/user identities, command/intent input, authorized routing and result return. It must be useful without requiring the Mac as universal router. The iOS native implementation, when needed, should be a thin WebKit shell/system-action adapter: use per-profile WKWebsiteDataStore containers plus App Intents, Shortcuts, Siri and permitted native features. Retain an independent PWA/browser surface where supported; do not assume a PWA alone can create native App Intents, arbitrary isolated WKWebView stores, macOS Automator workflows or system privileges. Reuse installed a-Shell only for its supported authorized actions; it is an optional adapter, not proof of unrestricted iOS shell/daemon/background access. Discover relevant platform features and use those that serve the selected task; do not require every Apple feature or enable all permissions.

Provider website workspaces for ChatGPT/Claude/Gemini/Codex are distinct from executable provider adapters and from silentChatGPT. Website profile sign-in is not API/tool/task authority. Each supported command route needs exact provider/account target, scoped consent, real supported submission/response mechanism, task/session correlation, error/cancel handling and a checked returned result. Recover actual provider capabilities rather than inferring browser automation or shared tool authority from login. Unsupported routes must not appear as connected executable controls.

Preserve the current shared AppDevRules/silentChatGPT.md literally: originating app deterministic/local capability -> native Apple intelligence where adequate -> Shortcuts Use Model / configured ChatGPT extension only when needed -> minimum necessary context -> result to originating app -> deterministic validation and authorized execution. This route does not require an embedded ChatGPT website, arbitrary OpenAI API access, or access to this chat's tools. An explicit provider browser workspace remains a separate capability; it does not replace silentChatGPT.

Read-only engineering observations this session: M1 repair host exposes Apple ssh/scp/sftp, shortcuts, automator, osascript, installer, dns-sd, codesign and spctl tools at their standard paths. This proves presence only. Current `shortcuts list` returned no BIFROST/silentChatGPT/toolkit-named shortcut. A bounded native Bonjour SSH browse returned no captured target advertisement; absence does not establish that the MacBook Pro is offline. No remote trust, enrollment, installation, Shortcut creation, privacy grant or provider login was changed. Supplied ChatGPT share URL https://chatgpt.com/share/6ad9489d-2e3c-83e9-a410-a14080230985 could not be fetched in this environment; its contents are UNREAD and were not used as evidence. This entry records the owner's instruction and implementation boundaries, NOT completed functionality.
