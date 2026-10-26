# EITRI Deliverable Contract — STANDARD

## Intent
Deliver a working first vertical slice for Dividend Calendar — Investment Strategy Intelligence.

## Acceptance criteria
- Canonical dividend-event schema with source provenance and event status.
- Provider interface supporting fixture data immediately and external adapters later.
- Deterministic calendar queries by ex-date and payment-date windows.
- Dividend quality metrics: growth history, cut/omission flags, payout/cash coverage fields when sourced.
- Strategy Lab separates price return, dividend cash return, costs/tax assumptions and total return.
- Backtests prohibit look-ahead use of events not known by the simulated decision timestamp.
- Results retain assumptions, benchmark identifier and data provenance.
- Unit tests cover date/status normalization, dividend calculations and a dividend-capture friction case.
- Local-first storage boundary documented.
- No automatic brokerage/order execution.

## IAC
```json
{
  "id": "dividend-calendar-v0.1",
  "state": "IMPLEMENTING",
  "runtime": "portable-core",
  "required": [
    "canonical-dividend-event",
    "provenance",
    "calendar-query",
    "strategy-lab",
    "friction-aware-backtest",
    "tests"
  ],
  "optional_bridges": ["MAMMON","MONETA","ORACLE","ARGOS","CHRONOS","BIFROST"],
  "forbidden_assumptions": [
    "highest-yield-is-best",
    "dividend-is-free-return",
    "estimated-event-equals-declared-event",
    "future-information-in-backtest"
  ]
}
```
