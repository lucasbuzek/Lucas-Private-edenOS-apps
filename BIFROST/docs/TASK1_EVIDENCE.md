# Task 1 integration evidence
Candidate only. No merge, installation replacement or LKG promotion. Task 2 is not implemented.

## Exact source
Branch: bifrost/task1-chatgpt-apple-20261005.
Implementation: 49182d1794af1268f6abc98eb0591b6a62b88777.
Baseline: 2c50f36b9be6f88b80c322355e60f52820295e52.
CI candidate: 55623a7d1540f8dd673b38f1f27de0a596b9682a (only runner labels changed).
Documentation-only commits after implementation do not change the application code.

## Authority and recovery
Current Task 1 AUTO handoff; recovered AppDev Bible and procedural LKG/anti-drift rules;
canonical Project Bibles/BIFROST.txt, RECONCILIATION_STATE.md and docs/PROJECT_STATE.md.
No genuine reconciled LKG was recovered. Original GitHub baseline provided a Python RDC
lifecycle adapter and four tests. First cloud run exposed its existing stopped/available
status regression; an explicit persisted stopped marker repairs it without changing ownership.
Recovered 13 original native Swift sources, project.yml and Oct 2 recovery/inventory evidence
read-only from the cold mirror. Preserved discovery, Keep Awake, JANITOR, remote lifecycle,
representations and complexity surfaces. Added ChatGPT linkage and changed three Keep Awake
bindings to explicit closures after an actual Swift 6 compiler crash, preserving behavior.
HEIMDALL's dirty local mirror was inspected read-only; its App Intent handles local translation,
and no authenticated BIFROST transport was found. No local implementation/build/product edits.
Implementation and verification use the isolated GitHub branch and cloud runners.
Reported Cloud task task_e_6ac37dd224388332a5dfbb40e647d73f was absent from recovered
branch/PR refs. No callable task-retrieval capability was available.

## Reuse and capability
Recovered BIFROST owns the native pane and private provider process. Complete app packages
bundle the Python runtime: ordinary users need no Python, Terminal, Homebrew, token generation,
JSON edits, MCP URL or ChatGPT.app. Enable discovers the bundled helper; official browser
login, native file picker and Apple Keychain handle authorization and selected files.
Official OpenAI SDK, Authlib, explicit macOS keyring backend and MCP SDK v1 supply mature
inference/OAuth/secret/MCP mechanisms. No OpenAI devkit or proprietary RDC code is copied.
Implemented text streaming, account/thread context, model discovery, inline files/images,
signed identity/consent validation, durable token rotation and local disconnect.
App restart clears chat history; login persists in Keychain. New chat preserves login.
Optional RDC remote MCP uses its documented endpoint with separate OAuth, initialized tool
catalog and exact authorized tool calls. The trusted parent must authorize arguments and
consequences. No automatic model tools, hosted SIWC MCP or Task 2 native server is introduced.
HEIMDALL AppIntent adapter compiles in the Apple package but refuses dispatch until an
authenticated authorizedRequest route is installed. Siri/Shortcuts/Action Button is not live.

## Actually supported OpenAI mechanism
Current official SIWC documentation supports local personal-project public clients with
dynamic registration, an issued client ID, PKCE/state/nonce and official browser login.
Candidate uses OAuth bearer tokens at public /v1/models and /v1/responses, store=false,
streaming and full local context. Identity-only scope never establishes inference readiness.
Actual account/model eligibility needs live login; commercial/hosted distribution requires
provider approval. ChatGPT-plan entitlement, API billing and Codex authentication remain separate.
Inline input_file/input_image uses compatible models. SIWC Files upload, hosted MCP/file search
and Code Interpreter are unsupported and unused. No passwords, cookies, app/Safari sessions
or Codex credentials are read. Exact official references: TASK1_SUPPORTED_INTERFACES.md.

## Verification and artifacts
Latest candidate: run 37365416128 on ubuntu-22.04 and arm64 macos-15.
https://github.com/lucasbuzek/Lucas-Private-edenOS-apps/actions/runs/37365416128
The prior repaired run 37364519671 remained unassigned on both latest-label pools across
repeated checks from 19:36 to 19:45 UTC, then was superseded by this explicit-runner attempt.
At the last check both jobs were queued with no runner assigned; latest results are UNKNOWN.
Required latest checks: 33 Python tests; 7 Apple tests; full native app; frozen helper;
clean wheel install; archive integrity; clean extracted app runtime.

Earlier exact revision e3d9a5f3e85f9fdfc3cf4ed41738c512176ff50f:
run 37363555908 SUCCESS, Python 30 tests / 0 failures, Apple 5 tests / 0 failures,
full unsigned arm64 native build, frozen runtime status preflight, plutil lint,
ZIP integrity and launch of helper from fresh extracted archive PASS.
https://github.com/lucasbuzek/Lucas-Private-edenOS-apps/actions/runs/37363555908
Source/wheel artifact 11367930651; outer artifact SHA256
76434dd8332511fe8f4e89fcd5963948e169da5cbbb3c6caa3198475ed10e73d.
Native artifact 11367109724 (24,964,288 bytes); outer artifact SHA256
ae2d488e05751ad7985921a57a333502159d5be0acfeed1b10389419abb58dd7.
These artifacts predate review repairs and are recovery evidence, not the final candidate.
Source artifact: https://github.com/lucasbuzek/Lucas-Private-edenOS-apps/actions/runs/37363555908/artifacts/11367930651
Native artifact: https://github.com/lucasbuzek/Lucas-Private-edenOS-apps/actions/runs/37363555908/artifacts/11367109724
Runner labels verified: https://docs.github.com/en/actions/reference/runners/github-hosted-runners
Each native archive contains TASK1_BUILD.json, third-party notices and its app-ZIP SHA256SUMS.

## Review and repairs
Read-only independent review identified three Important and two Minor findings: draft loss,
no full-context recovery, unbounded helper blocking, no attachment clearing and encoded
budget below four advertised full-size files. All five were repaired. Follow-up review of
49182d1 found no new Critical or Important findings, conditional on exact-revision verification.
Repairs capture/preserve edited drafts, expose New chat/Clear files, classify known context
errors and allow 64 MiB encoded context. Monotonic deadlines bound nonblocking pipe writes
and reads; only the owned helper is killed. Next explicit request starts a fresh helper.
Interrupted operations are never replayed automatically. Tests exercise full-size input,
context reset, SDK context rejection, write backpressure, missing output and restart.

## Failure history
Initial RED: missing new provider module and existing lifecycle status regression.
Security RED: wrong OAuth issuer and incomplete inference scope; repaired and cloud-green.
PyInstaller whole-MCP collection imported an optional CLI requiring typer; narrowed to mature
client/shared modules. Live Swift IPC stalled on count-based pipe reads; single bounded read
repaired it. Frozen preflight newline repaired. Swift 6 IRGen crashed on recovered actor-bound
Keep Awake setters; explicit closures produced a successful full build.
Review regression run 37364053255 observed Swift RED (missing timeout API); Python job was
queued before cancellation, so its RED outcome was not observed. Failures remain in Actions.

## Genuine unavailable dependencies and UNKNOWN gates
Historical Cloud implementation and authenticated HEIMDALL BIFROST route were not recovered
after refs, path, repository and source inspection. Without a trust route, iPhone requests
cannot safely dispatch Mac capabilities. New native hosting to substitute is outside Task 1.
Latest cloud runners have not yet been assigned at the recorded check.
Live OAuth/account/model eligibility, Keychain/refresh/security prompts, model file acceptance,
RDC account/device authorization and actual tool effects remain UNKNOWN until interactive tests.
Native UI and existing-product regression, signing/notarization/Gatekeeper, physical iPhone/iPad
Siri/Shortcuts/Action Button and Intel/universal packaging remain UNKNOWN. Missing gates are
never counted as PASS. No genuine LKG is replaced.

## Exact continuation and rollback
In a fresh separate checkout of this branch, from BIFROST:
```sh
./BuildTask1.command
```
Requires developer Xcode command-line selection, Python 3.11+ and XcodeGen; ordinary users
receive the bundled app and do not run this command. Follow TASK1_MAC_GATE.md's full matrix.
Verify checksums in isolated staging, sign/notarize app and nested helper with authorized
Apple identities before release. Preserve existing installation/data. Recover the authenticated
HEIMDALL route, link Apple package, install authorizedRequest and register the AppIntent while
preserving local translation. Physical testing must authenticate origin and authorize Mac actions.
Rollback: discard candidate checkout or return to baseline
2c50f36b9be6f88b80c322355e60f52820295e52. Reconciliation branch and cold mirrors are untouched.
Disconnect clears candidate credentials; official ChatGPT settings manage provider grant revocation.
