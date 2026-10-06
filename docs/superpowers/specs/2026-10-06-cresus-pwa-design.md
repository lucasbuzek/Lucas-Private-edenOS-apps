# CRESUS PWA Design Specification

Date: 2026-10-06
Status: DESIGN APPROVED / SPEC REVIEW PENDING

## Product identity
CRESUS — Capital Research & Equity Strategy. The PWA is a standalone CRESUS product surface, not a replacement or simplification of CRESUS In-Chat. CRESUS remains independent of HEIMDALL and BIFROST; those systems may integrate with CRESUS without becoming dependencies.

## Goal
Build a full-feature, installable, responsive, local-first CRESUS PWA that carries the established CRESUS research semantics into a standalone product. The completed In-Chat CRESUS behavior is the functional reference for opportunity discovery, Simple/Expert behavior, ZACCHAEUS, Gilded Order, evidence/PIT integrity, portfolio/watchlist/research organization, Strategy Lab, calculations and exports.

The PWA must be useful offline for persisted user information and deterministic/local functions, while online services provide current market/research data and AI augmentation. It must not turn Expert into a generic wide-market screener.

## Alpha entitlement
DEVELOPMENT_ALPHA is fully unlocked. There are no CRESUS-side IAP, subscription, portfolio/watchlist, Expert, Strategy Lab or AI-feature paywalls. Only genuine external AI/data-provider quotas or service limitations apply.

The later commercial model is outside Alpha enforcement but the architecture must support it without redesign: Free baseline, permanent full on-device/product unlock, and tiered Intelligence subscriptions/provider access. User-connected provider accounts are supported by the provider abstraction.

## Core experience
### Today
Default decision surface with market context, curated Opportunity Board, portfolio/watchlist changes when available, ZACCHAEUS income events, risks, what changed, research state and evidence freshness.

### Opportunities
CRESUS is not a generic market screener. Normal discovery returns a curated board, normally 5–12 serious evidence-backed candidates. Candidate admission requires a reason, evidence-backed signal, thesis, valuation/income/quality context, principal risk/trap, missing evidence and research priority. Worldwide capability does not mean indiscriminate worldwide enumeration.

### Expert
Expert increases depth, not uncontrolled breadth. It retains a curated 5–12 candidate board and normally deep-dives the top 3–5. Expert covers executive context, macro/rate/FX/commodity hurdle, opportunity evidence, fundamentals/cash/balance sheet, income and coverage, valuation, corporate developments, risk, Gilded Order challenge, what changed, research queue, Research Snapshot, conclusions and a bounded completion gate: COMPLETE, PARTIALLY COMPARABLE or EXHAUSTED.

### Research
Security/company research with issuer/security/listing identity, exact price/as-of when established, fundamentals, cash generation, balance sheet, dividends/income, valuation, catalysts/corporate events, risks, evidence provenance and notes/saved research.

### Portfolio and Watchlist
User-controlled holdings/watchlists with quantity/cost basis where supplied, listing/currency, value/returns, income, allocations/exposures, linked research, thesis state and notes. Never invent holdings.

### ZACCHAEUS
Income/dividend calendar and collector. REALIZED, DECLARED, FORWARD INDICATED and ESTIMATED are separate states. Track announcement/ex/record/pay dates, amount/currency, ordinary/special status, entitlement when holdings are known, payout/coverage, sustainability/history and changes/reconciliation. High yield alone is not an opportunity.

### Gilded Order
Analytical lenses within CRESUS: CRASSUS opportunity/mispricing/catalysts; GOBSECK books/cash/balance sheet/governance; SCROOGE valuation/overpayment/opportunity cost; CASSANDRA downside/fragility/kill conditions; SIBYL scenarios/probabilities/sensitivity. CRESUS synthesizes; evidence controls facts.

### Strategy Lab
Point-in-time simulation/backtesting with a SimulationClock. Guard against look-ahead, survivorship, delistings, corporate-action errors, revised-fundamental leakage, dividend/adjusted-price double counting, stale FX, omitted tax/cost/slippage and benchmark mismatch.

### Ask CRESUS
Conversational research surface over the same domain state and evidence model as the rest of the app. AI prose is not market evidence. Provider/model failure must degrade gracefully to deterministic/local capability where possible.

## Evidence and point-in-time integrity
Canonical security identity is LegalEntity -> Issuer -> Security -> Listing. Resolve exchange/MIC/ticker/listing currency and relevant identifiers before material comparisons.

Evidence classes: VERIFIED FACT, CALCULATION, INFERENCE, SCENARIO, UNCERTAINTY, MISSING/UNVERIFIED. Track effective/known/observed/source publication timing where available. Prefer first-party issuer/exchange/regulator evidence for fundamentals and corporate actions. Current comparisons must be synchronized or explicitly bounded; unresolved stale observations are quarantined rather than silently mixed.

UNKNOWN is never PASS.

## Architecture
Use a modular PWA architecture with clear domain boundaries rather than a monolithic page.

1. UI shell: installable responsive application shell, navigation, progressive Simple/Expert disclosure, accessible desktop/mobile layouts.
2. Domain core: securities, evidence/PIT, opportunities, portfolio/watchlist/thesis, income/ZACCHAEUS, Gilded Order, Strategy Lab, calculations.
3. Application services: orchestration for Today, Expert, research, comparisons, imports/exports and Ask CRESUS.
4. Provider adapters: replaceable market-data, filings/research, FX/macro and AI providers. Provider-specific credentials and semantics stay behind adapters.
5. Local persistence: IndexedDB for structured application state and cached evidence; OPFS where appropriate for larger local artifacts/imports/exports. Schema migrations are explicit.
6. Service worker/offline layer: app-shell caching and controlled cached-data behavior. Offline state must be visibly distinguishable from current online data.
7. Optional cloud layer: authentication/sync/server-side provider brokerage and secrets when enabled. Cloudflare Pages/Workers/D1/R2 remains an acceptable deployment direction, but the domain core must not depend on Cloudflare-specific APIs.

## AI intelligence
The PWA uses a provider-neutral intelligence broker. Deterministic/local operations are preferred when sufficient; AI is used for research synthesis, classification, extraction, comparison, scenario work and complex reasoning. Provider credentials must never be embedded in the client bundle. User-connected providers and CRESUS-managed provider access share the same adapter contract.

For Alpha, all CRESUS intelligence features are enabled and only provider-imposed limits apply. The broker must expose provider/model identity, failures and evidence boundaries to the application rather than silently substituting fabricated results.

Native Apple-only local AI and private silentChatGPT escalation are not assumed to be available inside the PWA runtime; the PWA uses its own provider infrastructure and remains independent.

## UI/UIX
Design mantra: CRESUS THE KING. The product should feel like a serious wealth/research desk rather than a generic dashboard or chat wrapper. Information hierarchy must favor decisions: Today -> strongest signals -> evidence -> deeper analysis.

Primary navigation: Today, Opportunities, Research, Portfolio, Income, Strategy Lab, Ask CRESUS, Settings.

Simple is the default readable surface. Expert is progressive disclosure of deeper evidence and analysis, not a different universe. Contextual actions include Research, Compare, Investigate, Verify Evidence, Council/Gilded Order, Risks, Scenarios, Save Thesis and Re-evaluate.

No placeholder production screens. Empty/loading/error/offline/stale states are first-class UI states.

## Exports
Both Simple and Expert provide PDF, XLSX, DOCX, TXT, CSV and Markdown export. An export is marked generated only when the artifact actually exists and passes format/integrity checks. Simple exports preserve the concise result plus provenance; Expert exports preserve the full Expert report, evidence, calculations, Gilded Order synthesis, gaps and completion state.

## Security and privacy
No provider secret is committed to source or shipped in frontend JavaScript. Browser-stored sensitive material must be minimized. Authentication is required only for internet-facing account/sync/provider services; purely local use must remain possible where the selected feature does not require online data. Validate imported data, sanitize rendered external content, enforce CSP and least-privilege network access, and keep provider credentials server-side or in an explicitly supported user-controlled secure flow.

## Error/degraded behavior
Provider outage or quota exhaustion does not corrupt local state. Cached/stale data is visibly labeled with observation time. A failed provider may be retried through a changed adapter/source when policy allows. Expert research does not claim completion when evidence is missing. Offline mode preserves local organization, notes, saved research, portfolio/watchlists, deterministic calculations and previously cached evidence while clearly disabling/marking current-data operations.

## Testing and acceptance
Required automated layers: domain unit tests; provider contract tests with fixtures/mocks; persistence/migration tests; service-worker/offline tests; export format/integrity tests; UI component/state tests; end-to-end critical flows; accessibility checks; responsive layout checks.

Critical regression gates:
- Today/What's available returns a curated evidence-backed board, not hundreds of names.
- Expert deepens rather than widens the candidate universe.
- Simple and Expert share factual state.
- stale/current evidence cannot be silently mixed.
- dividend states remain separate.
- portfolio never invents holdings.
- offline state is explicit.
- provider failure cannot fabricate data.
- all six export types are visible in Simple and Expert and are not reported generated before verification.
- installability, manifest and service worker behavior pass supported-browser checks.

## Delivery
PWA is built as a full product, not a vertical-slice substitute. Preserve working recovered implementation only after inspecting it; reuse/integrate/repair before replacement. The current authoritative repository evidence determines what actually exists. No recovered historical PWA claim is promoted to LKG without verification.

Implementation must produce a reproducible local build, tests, deployment configuration, recovery/build documentation and evidence sufficient to distinguish implemented, built, runtime-tested, offline-tested and deployed states.

## Explicit non-goals for this PWA milestone
- Native iOS/macOS/Android/Windows packaging is not part of the PWA implementation milestone.
- HEIMDALL/BIFROST dependency is prohibited; optional integration can be added through contracts later.
- Production IAP/subscription enforcement is not active in DEVELOPMENT_ALPHA.
- A 900-name/general-purpose screener is not CRESUS Expert behavior.
