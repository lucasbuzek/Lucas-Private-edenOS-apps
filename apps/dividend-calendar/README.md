# Dividend Calendar — Investment Strategy Intelligence

Status: Private Experimental v0.1
Current target: standalone local-first research application with optional EDEN bridges.

## Mission
Track dividend events and investigate dividend-oriented investment strategies using total-return evidence rather than headline yield.

## Authority boundaries
- App: dividend-event normalization, calendar UX, portfolio income calendar, strategy-lab domain workflow.
- MAMMON: economic/investment strategy synthesis.
- MONETA: authoritative financial semantics/state when connected.
- ORACLE: quantitative modelling, statistics, forecasting and optimization.
- ARGOS: source verification, evidence quality, opposition and research synthesis.
- CHRONOS: date/timeline semantics.
- BIFROST: provider discovery/connection.
- CONDUCTOR: orchestration.
- FORGE: implementation/build/test/package.
- HERMES: only opportunity/pursuit workflows where applicable.

BRIDGED != DEPENDENT. Core functionality remains usable without EDEN services.

## v0.1 vertical slice
1. Ingest normalized dividend events from fixture/provider adapters.
2. Distinguish declared/announced events from estimates.
3. Show declaration, ex, record and payment dates.
4. Calculate trailing indicated yield only when price/dividend inputs are sourced.
5. Maintain dividend history and detect cuts/omissions/growth.
6. Run deterministic strategy experiments including transaction-cost and tax assumptions.
7. Report price return, dividend return and total return separately.
8. Preserve source/provenance and as-of timestamps.

## Provider candidates
- SEC EDGAR/XBRL for issuer filings/fundamentals.
- Alpha Vantage for declared/historical dividends and adjusted price history.
- Financial Modeling Prep for market-wide dividend calendar.
Provider adapters are replaceable and no vendor is authoritative by architecture.

## Safety / research posture
Outputs are research analytics, not automatic trade instructions. Dividend capture is experimental and must include price adjustment, taxes, spreads/fees and slippage assumptions. No live brokerage execution in v0.1.
