# Codex connection evidence — 2026-10-08

## Verified public integration options
- OpenAI Sign in with ChatGPT supports OAuth PKCE and eligible ChatGPT-plan inference through Responses API for approved/eligible applications; eligibility and client registration are not automatic. https://developers.openai.com/siwc/quickstart
- Codex app-server can use the eligible OAuth access token via Responses API, but it is a child process and cannot run *inside* Cloudflare Workers. https://developers.openai.com/siwc/token-sharing-open-source/codex-app-server
- OpenAI Agents API provides a managed Codex harness, but model and sandbox usage are billed at API rates. https://developers.openai.com/api/docs/guides/agents-api/overview
- Neither route is evidence that a Worker can submit tasks directly to the ChatGPT Codex Cloud task UI using included subscription tasks.

## CRESUS decision
Keep Cloudflare Workers as the user-facing authenticated bridge and provider router. Do not fabricate an account-based Codex Cloud connector, automate undocumented endpoints, or silently bill paid API. Keep the Codex provider unavailable until an approved OAuth client and eligible invocation route or a documented cloud task interface are demonstrated. The existing Workers AI, Gemini, and Anthropic adapters remain available per-user.

## Evidence gates
1. Obtain and verify an authorized ChatGPT sign-in client registration and allowed plan-usage scopes for this private/closed-test PWA.
2. Perform consent and token exchange using supported PKCE and backend token storage; never expose refresh tokens to browser JavaScript.
3. Demonstrate an eligible inference request without paid API billing; if a cloud Codex task interface is required, verify that separately.
4. Implement per-user usage, task lifecycle, result integrity and expiry/revocation handling.
5. Only then enable Codex selection and perform real PWA end-to-end testing.

Status: documented integration path, not yet authenticated, deployed or connected.
