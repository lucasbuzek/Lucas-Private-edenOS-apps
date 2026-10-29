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
