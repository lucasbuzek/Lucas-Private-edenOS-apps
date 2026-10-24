# BIFROST Master — @conductor @argos solution decision
Date: 2026-10-14
Scope: actionable remediation based on current project inspection.

## Finding
Current BIFROST is not yet an execution-capable master governor. The macOS SwiftUI app builds, but its own dashboard says AI provider is not configured and provider adapters are not connected to Headless. Headless has loopback-only health/state, setup staging, preferences, caffeinate, Codex cloud task observation, and kernel read/search. It has no generic authorized task submission, cancellation, event stream, or result ledger. RavenNest/mobile pairing is explicitly unverified. Therefore a Shortcut that sends dictated text to a model cannot truthfully execute arbitrary BIFROST tasks yet.

## Decision — deliver a safe vertical slice first
1. Shortcuts as thin surfaces: separate BIFROST Voice — silentChatGPT on macOS and HEIMDALL Voice — silentChatGPT on iOS. Actions: Dictate Text (macOS can use Ask for Input fallback) → bounded Text wrapper → Use Model configured to Extension Model/ChatGPT → capture actual response → Speak Text → Show Result. Create and configure in Apple's Shortcuts UI; CLI only lists/runs/views/signs shortcuts, and GUI scripting is blocked by Accessibility permission in this session.
2. Read-only BIFROST status first: add a dedicated read-only task/status capability backed by current local state, not a free-form shell command. Return typed JSON with schema, task id, state, timestamps, and explicit UNKNOWN for unobservable providers. The shortcut may speak that status only after an authenticated BIFROST query succeeds.
3. Task ledger before task execution: SQLite-backed durable task ledger with immutable IDs, requested intent, originating device, authorization, provider/instance, state, timestamps, output references, error, and evidence. State transitions: received → classified → awaiting-approval or authorized → dispatched → running → succeeded/failed/cancelled/unknown. Never convert model text into an executable command directly.
4. Capability registry and policy router: route to native/local tools first; only use MCP/RDC/GitHub/Codex/provider when connected, authorized, and verified. Each adapter declares read/write/destructive, required scopes, cancellation support, idempotency, and evidence. Unknown capability = report unsupported, not hallucinate execution.
5. Shortcuts bridge API: add a narrow authenticated, loopback-only bridge for task submit/status/cancel, with per-install pairing, one-time nonce, replay protection, payload size limits, explicit confirmation for writes, and no token returned by a public endpoint. iOS cannot reach a Mac loopback address; remote iOS use requires a separately authenticated remote provider/pairing transport, never simply exposing the local API to the LAN/Internet.
6. Response callback: HEIMDALL named Shortcut callback must return the actual bounded model response and typed status; per-job callback token, expiry, replay rejection, cancel/error handling. Keep local/offline HEIMDALL functionality independent.
7. Monitoring and instance capacity: collect real provider usage/quota signals where provider supports them; warn at configurable thresholds, propose a new instance/account only when quota facts are observed, and require user authorization for account creation/login/billing. Never auto-create accounts or guess identifiers.
8. AI Toolkit: separate device-preparation workflow (inspect device and installed apps; recommend a minimal set; guide installation and verify versions) from BIFROST task execution. Never install everything by default.
9. Acceptance: Mac and iPhone are separate PASS/FAIL/UNKNOWN. Test Siri invocation, dictated text, model response, actual speech/display, local status, authorization, provider unavailable, offline mode, cancellation, duplicate/replayed callback, long request, privacy, and an explicitly confirmed write. Mark as implemented only after actual device evidence.

## Evidence from current inspection
- macOS BIFROST Xcode project generation and Debug build succeeded.
- Python tests 78 passed; JavaScript tests 10 passed.
- shortcuts list showed no BIFROST/HEIMDALL/silentChatGPT shortcut installed.
- Headless health was not listening on localhost:8798 at check time.
- Headless source identifies AI provider as not configured and remote setup execution disabled.
- No shortcut was created and no iPhone was tested. Existing docs are specifications, not execution evidence.
