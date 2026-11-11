# PUBLISHER — isolated self-deployment candidate

**Status:** staged, unmerged, unreleased. The existing canonical `Software Development/PUBLISHER` source, Project Bible, Git dirty state and accepted LKG were **not** available from authenticated remote execution. This directory is a non-authoritative handoff artifact and must never replace an existing PUBLISHER source tree blindly.

## Verified candidate capabilities
- Standalone Node.js (>=20) MCP via JSON-RPC stdio (`node server.mjs`), with 6 tools.
- Remote HTTPS Streamable MCP Worker (`worker.mjs`) with authentication, same-origin browser portal, JSON-RPC initialize/tools/list/tools/call, and admin self-deployment preflight.
- Cloudflare account/Worker inventory, isolated *new* preview Worker upload via official multipart REST API, and live verification; no overwrite unless separately confirmed by environment and tool arguments.
- Netlify existing-site inspection and ZIP deployment API with explicit `PUBLISHER_APPROVED_PROD_SITE_ID` plus per-call approval. Netlify ZIP deploy can affect production.
- macOS SwiftUI/WKWebView candidate with HTTPS navigation, regular/private data stores, selected provider quick links, and handoff to Apple's Passwords application, **not** arbitrary vault extraction.

## Local test
`npm test` runs positive and negative transport/security tests. `node server.mjs` starts stdio MCP. MCP messages are newline-delimited JSON objects.

## Credentials
- `PUBLISHER_CF_API_TOKEN`: scoped Cloudflare Workers Scripts permissions on the specifically approved account.
- `PUBLISHER_TOKEN_HASH`: SHA-256 hex of the admin preview access token, not the token itself. The access key is never committed.
- `PUBLISHER_PREVIEW_ACCESS_TOKEN`: actual preview Bearer token for post-deployment verification, kept out of tool arguments.
- `PUBLISHER_NETLIFY_API_TOKEN`: scoped Netlify API credential.
- `PUBLISHER_APPROVED_UPDATE_WORKER`: exact existing worker name if an approved update is permitted.
- `PUBLISHER_APPROVED_PROD_SITE_ID`: exact production Netlify site ID if a production deploy is explicitly approved.

Use Apple Keychain or an authorized secrets manager to store credentials. Never put passwords/tokens in project files, Git history or model prompts. Access to the Apple Passwords app is a supported user-facing operation, not a capability to silently read its records. No browser automation bypasses 2FA or CAPTCHA.

## Self-deployment flow
1. Verify the **original** Project Bible and LKG; compare these candidate changes and preserve the one authoritative project master.
2. Provision a least-privilege Cloudflare API token and separately generated admin preview key. Confirm exact Cloudflare account ID.
3. Start `node server.mjs`; call `publisher.self_deploy.preview` with `{ "account_id": "<verified-id>", "name": "publisher-preview-candidate" }`.
4. Read Cloudflare deployment receipt and derive actual workers.dev URL from provider, not by guessing.
5. Call `publisher.self_deploy.verify` with exact verified URL; test unauthenticated 401, authorized MCP initialize and tools/list, same-origin browser UI.
6. Do not promote to production or merge until native app compilation, real WebKit logins, provider token/permission negative tests, restore/rollback and Project Bible gates pass.

## Scope deliberately NOT claimed
This candidate is not a complete publishing suite: EPUB/KDP production delivery, store setup, financial processing, multi-account profiles, browser persistence, release automation, packaging/signing, user acceptance and physical Mac integration are not verified. It is a functional MCP-based self-deploy seed, not an accepted product, and does not supersede any historical PUBLISHER functions.
