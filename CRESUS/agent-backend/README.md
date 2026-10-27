# CRESUS stateful backend candidate

Status: SOURCE CANDIDATE. NOT DEPLOYED, NOT AN APPROVED LKG, NO LIVE TRADING.

A dedicated Node 22 HTTP process, independent of Cloudflare Worker request lifetimes. The 2026-10-28 CRESUS backend proof includes authenticated REST, SQLite-persisted onboarding + audit, strict $5 limit, a read-only official Luno market quote research adapter, provider onboarding metadata and execution-denial endpoints. Research has evidence, instrument validation, quote freshness and market-status checks; no predictions, model-written trades, fill claims, card charge or broker connection.

**No user KYC data, CVVs, card numbers, passwords, OTPs, bank credentials or broker keys are stored or requested.** Onboarding states are explicitly USER_REPORTED, never provider-verified.

## Run

Use Node 22+: `npm test` and `npm run check`. Start using `CRESUS_BACKEND_TOKEN=<long-random-secret> node server.mjs` (set secret in your environment, not in git), then GET `http://127.0.0.1:4179/healthz`. API requires `Authorization: Bearer <secret>`.

Default DB is memory for development. For a persistent run set `CRESUS_DB_PATH=/path/to/staging.sqlite`. Production refuses starting without DB path; attach encrypted backed-up volume or upgrade to PostgreSQL first.

## Deployment design

CRESUS PWA on Cloudflare Access -> authenticated same-origin backend-for-frontend -> private Node agent service (Railway/Render/Fly.io or suitable container host), backed by PostgreSQL, with a durable workflow engine (Trigger.dev / Inngest / Temporal) for event triggers, retries, human approvals, and monitoring. **This source is only the verifiable orchestrator foundation**, not a production-ready autonomous AI agent. Native platform targets remain unchanged.

Keep the backend token strictly server-side, never in browser JS. The current private server token is a *service identity*, not an end-user authorization method; do not expose a multiuser service publicly until verified Access identity propagation and per-user isolation are implemented.

## $5 proof

EasyEquities: real equities/fractional purchases with manual guided order and card deposits documented; no verified public orders API. Luno: official read-only and order API for spot crypto; card availability is inconsistent across official help pages, and virtual cards are not guaranteed. First require real account KYC, virtual card issuer acceptance, fees, actual exchange rate, user transaction confirmation, provider minimums, and read-back of account balances/receipts. Every API route capable of creating a live trade is ABSENT / DENIED.

Never execute a financial order by AI-generated text or an unverified MCP tool result.
