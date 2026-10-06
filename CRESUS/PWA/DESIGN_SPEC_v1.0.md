# CRESUS PWA — DESIGN SPEC v1.0

Status: APPROVED DESIGN
Date: 2026-10-06

## Objective
Build a standalone CRESUS Progressive Web App using the completed CRESUS In-Chat semantics as the functional reference, while reusing any recovered PWA implementation only where it conforms to current canon.

CRESUS is Capital Research & Equity Strategy. It researches, organizes, calculates, compares and explains; the user decides.

## Product scope
The PWA implements the full CRESUS product surface:
- Home / Daily Overview
- Opportunities
- Security / Company Research
- Compare
- Watchlists
- Portfolio
- ZACCHAEUS dividend and income calendar
- Saved Research / Evidence
- Thesis and Notes
- Strategy Lab
- Ask CRESUS
- Sources / Evidence
- Settings / Providers

Simple and Expert are two depths over the same evidence truth. Expert means deeper research and completion, not uncontrolled breadth.

## Opportunity model
Normal discovery returns a curated evidence-backed board, normally 5–12 serious candidates. It focuses on income/dividend quality, valuation, business/fundamental quality, cash generation, balance-sheet strength, dividend sustainability/growth, catalysts/capital returns, material repricing/dislocations, total-return logic, and relevant macro/rate/FX/commodity risks.

Dividend timing alone is not an investment opportunity. Worldwide capability does not mean indiscriminate worldwide enumeration.

## Evidence and point-in-time
Canonical identity is LegalEntity -> Issuer -> Security -> Listing.
Preserve exchange/MIC, ticker, currency, timezone/calendar and identifiers as relevant.
Evidence classes: VERIFIED FACT, CALCULATION, INFERENCE, SCENARIO, UNCERTAINTY, MISSING/UNVERIFIED.
Current comparisons require synchronized or explicitly bounded observations.
Historical Strategy Lab must prevent look-ahead, survivorship and revised-data leakage.

## Expert
Expert follows COMPLETE-OR-EXHAUST:
define universe/time -> evidence matrix -> research -> detect gaps/staleness -> changed-source/query/route/method retries -> post-results event sweep -> synchronize -> deterministic calculations -> evidence challenge -> completion gate -> Research Snapshot -> synthesis.
Completion is COMPLETE, PARTIALLY COMPARABLE with explicit bounds, or EXHAUSTED after meaningful changed attempts.

## ZACCHAEUS
Dividend/income states remain separate:
REALIZED / DECLARED / FORWARD INDICATED / ESTIMATED.
Track announcement, ex-date, record date, payment date, amount/currency, coverage, sustainability and reconciliation where evidence permits.

## Gilded Order
CRESUS owns synthesis.
CRASSUS: opportunity and catalysts.
GOBSECK: books, cash, balance sheet and governance.
SCROOGE: valuation, overpayment and opportunity cost.
CASSANDRA: downside, fragility and kill conditions.
SIBYL: scenarios, probabilities and sensitivity.
These are analytical lenses; evidence controls facts.

## Portfolio and thesis
Never invent holdings. Portfolio state is user-owned local data unless explicitly synchronized.
Theses retain rationale, supporting and counter evidence, valuation assumptions, catalysts, risks, invalidation conditions, income expectations and revision history.

## PWA architecture
Local-first and offline-capable after provisioning.
Use browser-native persistence suitable for structured data and documents, with IndexedDB and/or OPFS where appropriate.
The service worker caches the application shell and explicitly safe/cacheable resources; live financial observations must preserve freshness/as-of semantics rather than being silently served as current from stale cache.
Installable manifest, responsive layout, offline state, update/recovery behavior and graceful degradation are required.

Optional online infrastructure may provide authentication, synchronization, managed research/data access and CRESUS Intelligence. The PWA must remain provider-neutral and must not expose provider secrets in frontend code.

The PWA owns its own provider brokerage. It does not depend on HEIMDALL or BIFROST. Higher-level systems may invoke CRESUS, but dependency is not reversed.

## Intelligence
Deterministic CRESUS functions remain authoritative.
Use available local/device/browser intelligence first when adequate, then managed CRESUS Intelligence, then optional user-connected providers as configured.
External AI output is analysis input, never authoritative financial state.

## Alpha
DEVELOPMENT_ALPHA is fully unlocked:
no CRESUS-side subscription enforcement, portfolio/watchlist limits, Expert limits, Strategy Lab limits, AI quotas or feature paywalls.
Only genuine platform/provider/account/connectivity limits apply.

## Commercial model retained for production
Free: deliberately bounded discovery/organization.
Full: permanent one-time unlock of supported local/on-device CRESUS.
Intelligence: recurring managed online research/evidence/cloud-AI capacity.
Optional user-connected providers remain under their own terms.
The abandoned percentage-contribution model is not used.

## UI / UIX
Design mantra: CRESUS THE KING.
Sovereign, refined, authoritative, intelligent, premium and enduring.
Avoid casino/trading-game visuals, crypto-neon styling, generic fintech dashboards, developer-console presentation and faux-medieval cosplay.
Responsive desktop/tablet/mobile layouts must expose clear Simple/Expert depth, evidence freshness, stale/missing state, research progress and contextual actions.

## Export
Simple and Expert expose PDF, XLSX, DOCX, TXT, CSV and Markdown exports.
An export is GENERATED only after the artifact exists and is verified.
Exports preserve current research state, as-of dates, evidence/provenance, stale/missing markers and completion state.

## Security / privacy
Local-first user data. Secrets/tokens never committed or embedded in client bundles. Provider credentials use appropriate secure server-side or platform-supported flows. Minimize external context. Do not silently transmit unrelated private files/data.

## Recovery / reuse rule
Before creating replacements, inspect any recovered CRESUS/dividend-calendar/PWA implementation. Reuse conforming code and assets; repair/extend where possible. Historical prototypes are evidence/reference, not authority.

## Acceptance
The PWA is not accepted because it renders. It must demonstrate:
- installable PWA shell;
- offline launch after provisioning;
- persistent local state;
- curated opportunity workflow;
- Simple and Expert daily overviews;
- Expert depth without uncontrolled breadth;
- evidence/PIT state;
- Security Master identity;
- ZACCHAEUS separation;
- portfolio/watchlist/thesis workflows;
- Gilded Order analysis;
- Strategy Lab PIT protections;
- exports;
- provider abstraction and safe secret handling;
- responsive CRESUS THE KING UI/UIX;
- regression coverage for established In-Chat failures.
