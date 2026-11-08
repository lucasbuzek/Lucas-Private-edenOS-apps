# THEMIS Cloud access variant · deployed source parity

This directory is an access variant of the existing THEMIS legal-domain application. The original offline Python store, local UI, original ChatGPT historical experience and LKG are independently preserved.

## Verified deployment configuration

Cloudflare Worker: `themis-private` in the existing RAVENnest account. Cloudflare Access self-hosted application: `THEMIS — owner-private webapp` for `themis-private.lucasravensnest.workers.dev`. Owner-only email OTP allow policy; **Managed OAuth enabled with DCR restricted to ChatGPT callback URIs**. The Worker validates the Access JWT (issuer, audience, email, signature) before protected operations. `OWNER_HASH` is an optional separate manual-secret fallback, not required when owner Access is valid. Never publish the secret or API tokens.

Hosted web: `https://themis-private.lucasravensnest.workers.dev/`. Remote MCP: `https://themis-private.lucasravensnest.workers.dev/mcp` (JSON-RPC Streamable HTTP; in-chat v0.1.2 plugin is configured for Access Managed OAuth/DCR). Hosted SQLite-backed Durable Object `THEMIS_VAULT` is a separate cloud persistence store. No automatic local/cloud sync was approved or tested.

**Acceptance not implied:** Published Worker registration, Access app configuration and plugin release are configuration receipts. A real owner OAuth login and end-to-end MCP create/read, live private web record operations and security regression testing remain required before production acceptance. The existing local DOCX source generator is verified independently; the hosted Word-compatible `.doc` export does not establish identical `.docx` behavior.

The source in `worker.mjs` and `ui.js` is read back from the current deployed Cloudflare Worker via the authorized connector. Preserve prior Git and Cloudflare deployments and approved LKG.
