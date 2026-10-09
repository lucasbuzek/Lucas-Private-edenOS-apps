# CRESUS Cloudflare Intelligence Bridge — candidate

Additive adapter for the existing CRESUS PWA Worker, **not** a replacement Worker or a separate BIFROST service. The host must provide verified session identity, server-side per-user provider selection, and a protected route. Do not expose this module directly to the public Internet.

First login: show Codex Cloud, Cloudflare Workers AI, other providers and Skip; only configured/verified adapters may be connected. Settings must allow changes. No provider tokens in client storage. CRESUS owns all authoritative results.

Codex Cloud account-based dispatch is **not connected**: returns HTTP 501 and NOT_DISPATCHED. A ChatGPT account's included Codex allowance must not be silently converted to paid API billing. GitHub issue creation is not Codex execution.

Workers AI: bind AI and set CRESUS_WORKERS_AI_MODEL to a supported enabled model. This is an optional direct execution path, not an assertion of live market-data access.

The host must add authenticated persistence, rate limits, task state, source validation and end-to-end tests before deployment. Never allow arbitrary model-generated URLs, shell commands or financial trades. Run contract tests with `node --test CRESUS/cloudflare/intelligence-bridge.test.mjs`.

Evidence: source committed; test execution, Cloudflare deployment, Codex connector and physical PWA gates UNKNOWN.
