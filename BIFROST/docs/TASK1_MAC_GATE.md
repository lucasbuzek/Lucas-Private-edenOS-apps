# Task 1 candidate continuation

Branch: bifrost/task1-chatgpt-apple-20261005.
Baseline: 2c50f36b9be6f88b80c322355e60f52820295e52.
Source revision is recorded in the candidate's TASK1_BUILD.json and Actions checkout log.
No historical LKG has been reconciled. No candidate is promoted.

## Developer continuation
Use a separate checkout; preserve the existing installation/data and cold mirror.
Run from the repository's BIFROST directory:

```sh
./BuildTask1.command
```

Build preflight requires Xcode command-line selection, Python 3.11+ and XcodeGen.
This is the developer build gate. Ordinary users receive the app containing its runtime;
they do not run this command, install Python, choose package managers or edit config.
The cloud Actions artifact contains an unsigned arm64 native candidate ZIP.
Unzip into an isolated staging folder and open BIFROST.app only after checksum verification.
Sign and notarize the app plus nested frozen helper/libraries with the project's authorized
Apple identity before release. Do not replace the current app or promote this candidate yet.
Intel/universal builds have not been verified.

## Required physical gates — UNKNOWN until executed
1. Open BIFROST and regress existing discovery, Keep Awake, JANITOR, lifecycle and UI.
2. Select ChatGPT -> Enable ChatGPT -> Continue with ChatGPT. Confirm official browser
   authorization and only required Apple prompts. No ChatGPT.app is needed.
3. Confirm genuine account/model eligibility; identity-only/declined access never means ready.
4. Send two chat turns, observe streaming and remembered context across native navigation.
   Force disconnect/interruption and confirm partial output is not a successful response.
   Type a new draft during streaming and confirm it remains. Clear unwanted attachments.
   Fill a conversation, choose New chat and continue without signing out.
   Suspend the owned helper: verify bounded timeout and restart on the next explicit
   request. Interrupted tool operations must never be automatically replayed.
5. Attach each supported file type using the picker; confirm model acceptance and permissions.
6. Restart app: official login remains protected in Keychain; current chat history resets.
   Test refresh, denial, locked Keychain and reconnect without overwriting valid credentials.
7. Optionally connect RDC in the disclosure. Official RDC browser OAuth must succeed;
   list actual tools/devices. A managed process alone is not MCP readiness.
8. Authorize a specific Mac operation through BIFROST's trusted Core and verify actual effect.
   No arbitrary tool requests from an iPhone or model receive implicit authorization.
9. HEIMDALL transport is unavailable in the recovered implementation. Recover/extend its
   existing authenticated BIFROST route, link Apple package, install authorizedRequest,
   and register AskBifrostChatGPTIntent in HEIMDALL's Shortcuts/Siri/Action Button surface.
   Preserve its local translation flow. Physical iPhone/iPad tests then verify originating
   identity, Mac authorization, returned response and unavailable/offline behavior.

## Genuine dependency gap
GitHub BIFROST/Sources and HEIMDALL paths returned 404 before native recovery.
The BIFROST mirror was subsequently recovered into this branch. HEIMDALL was inspected
read-only in its dirty local mirror and no network BIFROST route exists there.
No HEIMDALL repository was found via the connector name search.
The reported 48-file Cloud task is absent from recovered branch/PR refs; task retrieval
is not an available callable capability in this session. Its Core/trust transport cannot
be inferred. Implementing a new native RDC/MCP host to substitute would be Task 2.
Recover that implementation/authorized transport before making the Siri route live.

## Rollback
The original reconciliation branch and Mac mirrors are untouched. Switch back to baseline
or discard the isolated candidate checkout. Keep the current app/data. To disconnect only
this candidate's ChatGPT connection, use Disconnect; provider authorization can be managed
in official ChatGPT settings. No original LKG is replaced.
