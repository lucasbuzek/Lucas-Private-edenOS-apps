# CRESUS — Trading extension candidate (2026-10-28)
Status: FEATURE BRANCH / UNDEPLOYED / NOT AN ACCEPTED LKG.
Owner request explicitly adds Guided Trading and Automated Trading; this is an intentional expansion of the 2026-10-03 Project Bible section 2, which previously prohibited trading-bot/broker features. Preserve all unrelated canon, CRESUS THE KING identity, native targets, Simple/Expert, ZACCHAEUS, Gilded Order and Strategy Lab.

## Implemented scope
- Authenticated /api/trading/status, /preview, /paper, /automation/check.
- Guided manual paper-order drafting, deterministic guards and idempotent paper record storage.
- Trigger rule evaluation with quotation freshness and evidence checks. No timer/cron or auto order execution.
- **No live broker order submission, no API keys, no automatic trading loop, no claims of simulated fills or profits.**
- Quote/limit price is manually entered, explicitly unverified and not claimed to be live market data.
- D1 additive migration 0004 required for persistent paper order history; do NOT apply to production before staging backup and full test.

## Mandatory future gates for genuine automated and guided live execution
1. Reconcile source with newer Dropbox non-Git PWA; current deployed Worker v10/Cloudflare data/Access login; compare GitHub candidate.
2. Audit every third-party MCP's source, license, maintenance, auth, data accuracy, jurisdiction, exchange and instrument coverage. Never send wallet signing keys or brokerage passwords to unvetted services.
3. Build provider-neutral READ-ONLY market adapters with market calendar, MIC/ISIN, FX, source observed/published timestamps; verify entitlements/terms. Conflicting or stale evidence blocks execution.
4. Implement broker-specific connector only for verified authorized account, permission scopes, paper/sandbox first, regulator/terms review, step-up auth, human approval for guided live orders.
5. Independent risk engine: buying power/holdings from broker, position/exposure, notional, liquidity, stale data, price collars, idempotency, partial fills, slippage, fees, corporate actions, trading halts, settlement and FX; global kill switch and independent audit log.
6. Automated trading requires strategy allowlists, explicit user-enabled scope/budget, broker simulation proof, rollback, scheduling, monitoring and emergency disable. No leverage or derivatives as default.
7. Platform UI and Cloudflare Access physical login/denial, D1 backup+migration rehearsal, replay tests, native app regression, accepted LKG receipt before release.

## MCP discovery catalog
See trading-providers.json. Catalog inclusion != installed or authorized. Research data tools are not broker execution tools.

## Test
node --test test/trading.test.mjs
Existing test suite: npm test (requires Node version supporting node:sqlite).

## Canonical provenance
- Historical native branch: dev/cresus-cross-platform-v0.2 at apps/cresus/
- PWA branch chain: dev/cresus-pwa -> dev/cresus-cloudflare-intelligence-bridge -> feature/cresus-persistent-workspace-rail-20261016 -> fix/cresus-canonical-root-versions-20261016 (base for this feature)
- Dropbox local PWA source diverges from GitHub; this feature branch does not replace it.
- Project Bible: Lucas-private-appDevDocs/Project Bibles/CRESUS.txt
