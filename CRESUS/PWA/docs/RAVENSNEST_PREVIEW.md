# CRESUS — RAVENnest Protected Preview

**Current status:** Deployed via Cloudflare API on 2026-10-28 as an isolated protected preview, **not accepted production**.

## Product authority and source

- CRESUS Project Bible is product authority, in the original CRESUS Dropbox folder and private appDevDocs.
- Preserve standalone local original `Software Development/CRESUS/platforms/web/` source and its unique unmerged changes. This branch is a non-destructive Git candidate from `fix/cresus-canonical-root-versions-20261016`.
- The original production Worker in the other Cloudflare account is **not** modified or copied into RAVENnest.
- Standard and Advanced/Expert share the same authentication, D1 records and five canonical execution modes. The Advanced/Expert workbench is **not** a separate financial engine or a new broker.
- Provider bridges in this PWA support Cloudflare Workers AI, optional Gemini and Anthropic. The full CRESUS Project Bible also calls for OpenAI, Mistral, native Apple AI and additional provider adapters, which are **not falsely listed as deployed**.

## New isolated environment

- Cloudflare account **RAVENnest**, Worker: `cresus-ravensnest-preview`
- Protected hostname: `https://cresus-ravensnest-preview.lucasravensnest.workers.dev`
- Access application: `CRESUS · RAVENnest private preview`, OTP identity provider, owner-only preview policy. Access AUD is pinned in the config.
- New isolated D1: `cresus_ravensnest_preview`, original six application tables.
- Workers AI bound, no paid upstream AI credentials copied.
- Source file `wrangler.ravensnest-preview.toml` is checked in for reproducible Wrangler deployment; run from `CRESUS/PWA/` with `npx wrangler deploy --config wrangler.ravensnest-preview.toml` after local test/backup checks.
- Initial Cloudflare deployment used a source-equivalent Worker module upload with an inline static asset adapter because the in-chat API cannot run Wrangler. Original PWA HTML/JS/CSS/service worker/manifest/icon bytes were embedded from this branch, with private no-store headers. A future Wrangler deploy uses Workers' official Static Assets binding from the same source.

## Tests before release

1. Original PWA tests and `node --check` in Node 22, plus Standard/Expert UI source contract tests.
2. Unauthenticated external GET for `/`, `/api/me`, `/api/intelligence`, `/styles.css` must redirect to Access. Test negative identity denial.
3. Browser owner login through Access, authenticated GET `/api/me`, real `/api/intelligence` selection and one inference, reload and verify independent D1 persistence.
4. Verify mobile Safari/Web App, keyboard navigation, responsive Expert workbench, real user-owned portfolio/evidence data limitations, visible error states.
5. Compare original local-only changes and screenshots to the candidate. Source acceptance and owner visual approval before promoting.
6. Backup D1 and keep the old primary production script / exact versions untouched. Never merge or apply trading branches from other CRESUS development automatically.

No consumer Gmail login token, OAuth cookie or OTP is imported from the Cloudflare administration connector. Tailscale is not a prerequisite to reach the public Access-protected PWA. The exposed Worker is a private preview, not verified for live brokerage or financial transactions.


## 2026-10-29 source reconciliation + durable Watchlist candidate

- GitHub draft PR #24 is stacked on PR #23, not merged. Cloudflare isolated RAVENnest preview Worker version `3ec761f7-f7c0-4e22-b137-1d8f0dc91833` active 100%; original Primary `cresus-agent` v`b7d240d5-a914-4e20-862a-f34fe41351ea` remains unchanged.
- Restored original Dropbox `platforms/web/src/worker.js` Expert research-routing contract in `src/research.js`, reconciled with GitHub provider-choice flow; no old files overwritten. The original Dropbox Worker has `webResearch()` but the earlier PR #23 worker omitted it. Original Dropbox intent remains source evidence.
- Cloudflare Web Search API is **billable via AI Gateway credits or provider keys**, not an entitlement to cost-free live financial evidence. `CRESUS_WEB_SEARCH_ENABLED = "false"` in this PREVIEW and in Wrangler config. Do not flip without explicit charge/credential authorization. Inference continues via configured free Workers AI quota when available; no inference was performed during verification.
- Real, per-user, authenticated D1 Watchlist API and mobile/desktop dialog implemented. Records explicitly include ticker, optional MIC/currency/ISIN/name/notes; no live prices/holdings are inferred. No portfolio transactions, fills, execution or brokers added.
- `migrations/0004_watchlist_entries.sql` was actually applied to **isolated preview database only** using two successful, idempotent SQL statements, read back table present; table currently contains 0 records. Keep separate original Primary D1; backup before applying to any non-empty accepted database. Do not blindly replay unrelated migration files on the production DB.
- CI https://github.com/lucasbuzek/Lucas-Private-edenOS-apps/actions/runs/40834050677: 39/39 PWA tests and 7/7 provider bridge tests pass; includes real SQLite-backed test JWT, owner/member isolation, duplicate/invalid identifiers, cross-origin mutation denial, source-routing with unverified evidence and billing-safe search default.
- External unauthenticated browser: root, /api/watchlist, /api/me, /styles.css all returned `login_required`. NO signed-in owner browser acceptance or live inference/save+reload yet. Physical iOS/desktop design and full local Dropbox/LKG reconciliation remain open.

### Source/prior-art coverage limitations
- Dropbox AI MCP tool research archive link resolves to a public-edit linked folder; no security sharing changes were made. Initial recursive listing returned 600 items but **had_more=true**; no exhaustive claim.
- Research references include official SEC EDGAR free XBRL/filing APIs (US filers only, obey fair access), LiteLLM's independently hosted multi-provider gateway (separate server and operational cost), Ghostfolio portfolio/account workflows (AGPL-3.0, Node/Postgres/Redis stack, not a drop-in Worker), Portfolio Performance native reporting, and relevant Glama finance MCP entries. These are alternative working references, not imported into CRESUS or proof of live integrations.
- Substantive missing CRESUS product milestones: durable portfolio/position lot, corporate actions, real income/calendar, data-provider entitlements, worldwide security identity and temporal evidence ledger, complete Expert evidence retrieval, and full native platform builds.

**Never claim that an authenticated product user or mobile browser has accepted this candidate based on CI or Access login-required responses alone.**
