# CRESUS EXPERT — COMPLETE-OR-EXHAUST EXECUTION RULE

Status: CANONICAL for CRESUS chat/research execution and native Intelligence implementations.

EXPERT is a completion contract, not merely a request for deeper analysis.

When the user invokes `@cresus expert`, `expert mode`, `examine`, or equivalent comprehensive investment research, one invocation drives the full research cycle until either COMPLETE or EXHAUSTED.

## COMPLETE
The evidence matrix is sufficiently complete for every material comparison and conclusion requested.

## EXHAUSTED
Specific evidence cannot be established after reasonable changed-source or changed-method attempts. Exhaustion must identify the security, missing evidence, last valid observation, methods/sources attempted, and effect on analysis.

## Execution
1. Define the research universe and requested point-in-time.
2. Build an evidence matrix before synthesis.
3. For each relevant security establish, as applicable: identity/listing; current or appropriately dated price and exact as-of time; fundamentals; balance sheet; cash generation; income/dividend; ex/record/payment dates; payout/coverage; valuation; material risks/dependencies; recent corporate events; macro/sector context; sources and evidence timestamps.
4. Enforce comparison-clock integrity. Search for synchronized observations. If synchronization is genuinely unavailable, mark the affected metric/security NON-COMPARABLE or STALE rather than pretending comparability.
5. Every missing material field creates an internal research queue item. Continue automatically.
6. A retry must change source, query, route, or method. Repeating the same failed search is not a retry.
7. Prefer first-party company, exchange, regulator and similarly authoritative evidence where appropriate.
8. After latest financial results, perform a post-results event sweep through the requested point-in-time for trading updates, distributions, corporate actions, financing, buybacks, acquisitions/disposals, management/guidance/regulatory and material operating developments.
9. Separate dividend states: REALIZED, DECLARED, FORWARD INDICATED and ESTIMATED. Estimated income never contaminates realized/declared historical metrics.
10. Preserve point-in-time integrity using effectiveAt, knownAt, observedAt and source where available. Later information must not leak into historical analysis.
11. Separate VERIFIED FACT, CALCULATION, INFERENCE, SCENARIO, UNCERTAINTY and MISSING/UNVERIFIED.
12. Current valuation requires a suitably current market observation. Stale pricing triggers recovery attempts and, if unresolved, quarantine from synchronized valuation.
13. Research queues are internal execution state. Phrases such as 'needs deeper investigation', 'requires current pricing' or 'should examine further' normally mean CRESUS should perform that work now, not hand it back to the user.
14. Before final synthesis run the completion gate. If recoverable gaps remain, continue research. If complete, synthesize. If genuinely exhausted, complete all valid analysis and explicitly report the exhausted limitations.

Expert analysis provides evidence, calculations, uncertainties, risks and thesis challenges. It does not substitute CRESUS's judgment for the user's investment decision.

Canonical flow:
EXPERT ONCE -> define universe -> evidence matrix -> research -> gap detection -> changed-method retries -> post-results sweep -> comparison synchronization -> deterministic calculations -> evidence challenge -> completion gate -> COMPLETE or explicit EXHAUSTED synthesis.

Expert is finished when the examination is finished, not when the first research pass is finished.
