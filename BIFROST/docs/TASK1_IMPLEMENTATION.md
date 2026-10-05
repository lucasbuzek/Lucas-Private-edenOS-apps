# Task 1 integration workstream
Authority: current Task 1 AUTO instruction; master Project Bible; RECONCILIATION_STATE.
Baseline: 2c50f36b9be6f88b80c322355e60f52820295e52. No reconciled LKG.
GitHub is the implementation workspace; mounted Swift backup is left intact.
The reported Cloud task is absent from branch/PR refs recovered on 2026-10-05.
Native BIFROST was subsequently recovered from the cold mirror into this candidate.
HEIMDALL's dirty mirror was inspected read-only; no authenticated BIFROST route was found.
See RECOVERED_NATIVE_SOURCE.md.

## Design and execution
Integrate a Python capability provider beside the recovered Python lifecycle adapter.
Use Authlib for OAuth/PKCE and signed ID token verification, Apple Keychain through
the explicit keyring macOS backend, official OpenAI SDK for Responses streaming,
and MCP SDK v1 for optional RDC OAuth/Streamable HTTP. No Task 2 server.
Local personal-project SIWC eligibility must be confirmed by official sign-in.
Do not reuse Codex credentials, sessions, cookies or client IDs.
Files use inline input_file/input_image, never SIWC Files upload.
History is managed locally, with no previous_response_id.
Embed the capability pane in recovered BIFROST. Core owns one bundled provider process
and stable in-memory thread, using private stdio. No network listener for HEIMDALL is invented. The existing trusted Core must own remote authorization.

## Plan
1. Commit behavioral tests and cloud verification workflow; observe RED.
2. Implement auth, keychain, attachment/history/stream, optional MCP adapter, stdio
   routing and consent boundaries. Verify cloud tests and baseline regression.
3. Build source/wheel package in cloud; verify clean install and capture dependencies.
4. Record exact evidence, failures and missing host/device gates; keep candidate separate.

Review focus: invalid OAuth state/identity; rejected file and size input; interrupted
stream; account change/history isolation; tool requests without exact authorization.
Native setup UI is implemented. HEIMDALL remains unavailable until its authenticated
route is recovered or supplied. Live account and physical Apple gates remain UNKNOWN.
