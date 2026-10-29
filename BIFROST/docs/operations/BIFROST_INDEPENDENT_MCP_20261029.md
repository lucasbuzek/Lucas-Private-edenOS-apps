# BIFROST — independent authenticated remote MCP candidate (2026-10-29)

**Status:** SOURCE_IMPLEMENTED / AUTH_UNIT_TESTED_ISOLATED / NO_LIVE_REMOTE_CLIENT / NO_DEPLOYMENT / NO_LKG_PROMOTION. This is an optional network *representation* of existing BIFROST ShortNameCall capabilities, not another BIFROSTcore, executor, provider registry, HEIMDALL, or Mac service.

## Purpose and independence

- `headless/mcp_remote.py` is portable and has **no Mac, RDC, SwiftUI, native Apple or external BIFROST connection requirement**.
- Official Model Context Protocol **Python SDK v2** implements modern 2026-07-28 and legacy 2025 transports; this adapter DOES NOT hand-write a second protocol stack.
- `headless/mcp_remote_auth.py` validates OAuth bearer tokens through an owner-configured HTTPS RFC 7662 token-introspection provider with four-second timeout, no redirects, exact `iss`, `aud`, `bifrost:read` scope, client identity, subject and unexpired token. Failure denies.
- Only `bifrost.system.platform.read`, delegated to the established `headless/shortcalls.py`, is exposed. There is no shell, file write, account-management action, device pairing, profile export or background execution. This **does not implement all universal BIFROST capabilities**.
- Original `headless/mcp_bridge.py` stdio and `headless/server.py` loopback UI stay untouched and operationally separate. No replacement baseline, no new governor.

## Independent host prerequisites

Use a supported **independent Linux/Windows/macOS Python 3.11+ host**, or a separately authorized cloud service with a Python process. The official v2 SDK is an additional runtime dependency only for this optional representation (install and pin an audited 2.x release according to the deployment environment). It is not a dependency of existing deterministic local BIFROST actions.

A real OAuth authorization server/introspection service must already be provisioned by the owner. Its introspection payload MUST include `active: true`, exact `iss`, exact resource `aud`, `client_id`, `sub`, `scope: bifrost:read`, and bounded `exp`. Credential issuer registration, authorization UI and token issuance are **not** handled by this service.

Configure the runtime through an approved secret manager and these environment variables:

```text
BIFROST_MCP_ISSUER_URL=https://auth.example.net
BIFROST_MCP_RESOURCE_URL=https://bifrost.example.net/mcp
BIFROST_MCP_INTROSPECTION_URL=https://auth.example.net/oauth/introspect
BIFROST_MCP_OAUTH_CLIENT_ID=<approved resource-server client>
BIFROST_MCP_SECRET_FILE=<private existing OAuth client secret file>
BIFROST_MCP_BIND_HOST=127.0.0.1
BIFROST_MCP_PORT=8799
```

Placeholder URLs above **are examples**, not deployed destinations. On POSIX the secret file must be mode 0600 (or more restrictive). Never store its contents in Git, logs, a web page, shared Dropbox or a public env file.

After installing SDK v2 into an isolated environment and staging existing BIFROST source:

```sh
python3.11 -B headless/mcp_remote.py
```

The default bind is **127.0.0.1**; remote clients need an authorized TLS reverse proxy preserving the public Host/Origin and OAuth Authorization headers. Only a separately protected reverse-proxy environment may set `BIFROST_MCP_BIND_HOST=0.0.0.0` with `BIFROST_MCP_TRUSTED_REVERSE_PROXY=yes`. Place the actual cloud service behind firewall rules. Explicit browser origins may be set via `BIFROST_MCP_ALLOWED_ORIGINS` as comma-separated HTTPS origins. No public endpoint is registered automatically.

## Required tests before calling this a working remote MCP

1. Install official SDK v2 in the **independent** host, run the real MCP Inspector / SDK Client over HTTPS, perform `server/discover`, `tools/list`, and `bifrost.system.platform.read`; verify receipt and actual host identity, no Mac required.
2. Verify 401 unauthenticated, invalid token, expired token, wrong audience/scope, wrong owner/tenant, denied Host/Origin and introspection outage; test revocation and reconnection.
3. Check trusted TLS proxy headers, request size, output redaction, client retries, crash/restart and independent node persistence.
4. Record CI/build/runtime evidence; only then extend **existing** ShortNameCall grants with additional read-only/effectful actions and per-action owner permissions. Never interpret the test token verifier as user consent.
5. Reconcile native Mac/Apple and mobile implementations independently. Their connectivity must not gate a Linux/cloud BIFROST release.

**Local source evidence:** `mcp_remote_auth.py` Git blob `bae043c617cb8036ed276768c6e3d19f475e8ef9` exactly matched an isolated Python sandbox copy; six focused token security tests passed. `mcp_remote.py` Git blob `aab3f83f5dab532336d6cd27823200d69933228e` matched the isolated syntax-checked file. Official SDK itself was not installed in that sandbox; no actual SDK HTTP handshake, OAuth server, macOS, or production host was tested.

## External primary reference

- https://github.com/modelcontextprotocol/python-sdk/blob/main/docs/whats-new.md
- https://github.com/modelcontextprotocol/python-sdk/blob/main/docs/run/authorization.md
- https://github.com/modelcontextprotocol/python-sdk/blob/main/docs/run/deploy.md
- https://github.com/modelcontextprotocol/python-sdk/blob/main/docs_src/authorization/tutorial001.py


## Follow-up authentication regression receipt (2026-10-29)

The real introspection guard previously raised `ValueError` for a JSON `exp: NaN` value: Python's JSON decoder accepts this nonstandard constant, both expiry comparisons are false, and the subsequent integer conversion fails. The guard now rejects non-finite floating-point expiry values before conversion. The regression failed against the original source and passed after correction; all seven focused `test_mcp_remote_auth.py` tests passed on independent Linux Python. These tests use an introspection response fixture, not a live issuer or SDK HTTP server. Source fix commit `29fa2802b014da42ca373fef6dbc7475345a6640`; regression commit `3d49bd2ce36910b32b2d1d3f385108d75705acfa`; both saved files were read back byte-for-byte.

Hosting readback: the connected Vercel search for `bifrost` returned zero projects. The selected RAVENsNEST Cloudflare account's Workers inventory contained no BIFROST-named script. These scoped observations do not exclude another named deployment/account and do not prove endpoint availability. No deployment, permission change, live OAuth acceptance or LKG promotion was performed. SDK authorization documentation was independently read at upstream blob `fefd0ed34a362d2f43f0ce36cf346d9dc884d9dd`; HTTP authentication requires actual transport tests because in-memory clients bypass the HTTP authentication layer.

## 2026-10-29 independent stateless-HTTP correction and unresolved CI

- Official Python SDK v2 source `src/mcp/server/mcpserver/server.py` confirms the Streamable HTTP `stateless_http` argument defaults to `False`. The original draft service omitted it. Existing BIFROST `headless/mcp_remote.py` now explicitly sets `stateless_http=True` without adding any new server/runtime, commit `8758e8b1c390ad0ad5c9165c2bb3515d69dfb571`, blob `fb1915ffd000ead2913cf8f79833c182a17b7747` read back exactly.
- The original candidate branch contains a new source-contract regression `tests/test_mcp_remote_transport_contract.py`, commit `83a83e18bbcffa98c2db2bff42254b94f34831f4`, checking explicit stateless transport and request body/security settings. Existing candidate CI workflow includes this test by commit `e8d17c9f16736b33f89da0d7fa9e37f0093bda5f`. All exact GitHub source readbacks succeeded.
- GitHub Actions results are **FAIL/NOT TESTED**, not success: run 40893421781 and run 40893946426 each reported `conclusion=failure` and provided zero individual job steps. Job-log fetch for the former returned 404 BlobNotFound. Exact failure cause remains UNKNOWN and the source-contract test has **no confirmed CI execution receipt**. Do not treat code/text inspection as actual SDK HTTP/authorization acceptance.
- Remote Mac state independently checked via connected RDC accounts on 29 October: Lucas MacBook offline (45 hours last seen) and RAVENsNEST-linked MacBook offline (155 hours last seen). This blocks physical Mac tests only, not independent BIFROST cloud development. The local isolated Python runtime lacks the `mcp` SDK; no real SDK HTTP test was performed there.
- The independently hosted remote service still requires approved OAuth issuer/introspection, exact audience/client/owner grants and tenant-denial tests, TLS endpoint/client acceptance, durable job/action receipts, error/revocation/recovery and provider verification. No CI/test/host/production promotion, Mac installation or sharing/credential mutation performed. Preserve DRAFT and LKG.


## 2026-10-29 AUTO continuation: independent execution and OAuth reuse

### Executed verification

Pinned source/test blobs from candidate commit `1c251fa22292571c5daaecf9d091d0a2e95d82f5` were materialized and Git blob hashes checked. Independent Linux results: stdio bridge 3 PASS (including actual subprocess lifecycle/platform call and modern discovery/denial); ShortNameCalls 14 PASS / 1 physical-macOS SKIP; recursive WebArchive extractor 6 PASS on fixtures; stateless source-contract checks 3 PASS; OAuth validation and real loopback HTTPS introspection 16 PASS. Total **42 PASS / 1 physical-device SKIP**. This is a targeted suite, not the full repository or production acceptance. TLS tests use an ephemeral local certificate and test identities: successful POST, revocation on next request, no credential forwarding on redirects, HTTP failures, invalid/oversized JSON, certificate rejection and wrong grants. Source auth blob `76a8106f89d8b0b376fd868de2a5436fae3103f1` matched exactly.

Added `tests/test_mcp_remote_auth_https.py` in commit `196976d30a455be7b7af9f31da835f02e73cdc76`, verified readback blob `e50f1f95c194d54252d255c9bae44efa5975eb30`. Added six actual SDK HTTP boundary tests in `tests/test_mcp_remote_http.py`, commit `ba3f890f4c7f632fcd2a6caa0c166bf34bd21104`, readback blob `d7e5fb56ef801b1a50b53f50c1f7dba407c00595`. The latter launch the SDK listener and actual platform dispatcher, using a fixture identity; they do not implement or prove a production OAuth issuer. **These six tests have NOT executed:** SDK unavailable locally. Required mode `BIFROST_REQUIRE_MCP_SDK=1` correctly fails on missing SDK; optional local mode explicitly skips. Existing CI now installs official `mcp==2.3.0` and requires this suite, commit `1c251fa22292571c5daaecf9d091d0a2e95d82f5`, exact workflow readback confirmed.

### CI availability is a separate gate

Run `40880401160` at earlier commit `74cd1bf...` failed with `runner_id: 0`, empty runner name and zero steps. Job log returned 404 BlobNotFound. Latest run `40901991422` at `1c251fa...` also reports failure; job `123546473699` has no step results. Root cause (account limits, service availability or other condition) is UNKNOWN. No test success is inferred and no billing/runner/account setting was changed. Both available local Python runtimes lack SDK/HTTP dependencies; default and explicit PyPI index checks returned no matching distribution in this environment. This is not a claim that upstream SDK does not exist.

### External implementation review, not a new internal reuse candidate

Official Python SDK release **v2.3.0** exists, tag commit `2118f14f8a19bc158d8a1cf90af58d85d187f849`. Read release notes, `pyproject.toml`, `docs/run/deploy.md`, `docs/client/transports.md`, authorization docs and actual `src/mcp/server/mcpserver/server.py` (release blob `99b5a56c0af7dca25f94aa0731c462a9918ec15d`). Current API accepts the adapter's Streamable HTTP flags. Important correction to broad wording above: modern 2026-07-28 requests are inherently sessionless; `stateless_http=True` controls the legacy leg. HTTP tests are necessary because in-memory client tests bypass HTTP authorization. Python SDK reuse is retained; no competing hand-written protocol server is justified.

Cloudflare's external `workers-oauth-provider` reviewed through README, package metadata (1.2.4; blob `4696eee9ce95ef941e1094e299a3739082b313f9`), actual MIT license (`LICENSE.txt`, blob `728fb8923413d23dd588873a85371b229df8887c`), resource-server docs (`c0c37c9384531e777f9d9c8fd06a55b97dde1826`), consent docs (`e991e8d8040aa6e72c6930b48dd3164a727a71f7`) and MCP discovery docs (`f93c204bb2183670052d704521c22aea4673f320`). Its recommended split authorization/resource Workers validate via Service Binding. That binding is **not a public RFC7662 introspection endpoint** for the Python adapter. Its resource `requiredScopes` advertises requested scopes; the handler must enforce operation-specific scopes/ownership. Sign-in and consent remain application responsibilities; no automatic privileged grant to a DCR client's self-asserted name. These are reviewed external options, not installed or fully audited dependencies.

Current RAVENsNEST Access inventory returned seven other apps including LucasFirst and FORGEduino; no BIFROST-specific application established by this query. Existing app grants must not be repurposed implicitly. Vercel project-name search `bifrost` returned zero. No new deployment, issuer registration, shared secret, permission change, endpoint acceptance or LKG promotion performed.

Primary links: https://github.com/modelcontextprotocol/python-sdk/releases/tag/v2.3.0 ; https://github.com/modelcontextprotocol/python-sdk/blob/v2.3.0/docs/run/deploy.md ; https://github.com/cloudflare/workers-oauth-provider/blob/main/docs/resource-servers.md ; https://github.com/cloudflare/workers-oauth-provider/blob/main/docs/consent-page.md .

Remaining: execute actual SDK HTTP suite on a functioning dependency-enabled runner; provision/verify BIFROST-specific issuer/resource/client consent and HTTPS; demonstrate real remote client tool call and revocation; then extend verified provider/storage/executor actions. Physical Apple acceptance stays separate. Archive fixture tests do not parse the unavailable original archive corpus or close fullresearch coverage.
