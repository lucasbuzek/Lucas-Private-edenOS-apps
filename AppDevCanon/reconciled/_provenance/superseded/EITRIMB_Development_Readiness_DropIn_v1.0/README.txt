EITRIMB — DEVELOPMENT READINESS DROP-IN — v1.0

PURPOSE
Optional starter/update workflow for EITRI — The Master Builder (EITRIMB).
It does not replace EITRI governance, EDC/IAC, specialist authority, CONDUCTOR, FORGE, AppDevRules, project canon, or evidence-gated state.

MODES
STARTER — establish enough definition to begin implementation safely.
UPDATE — inject into an existing project, recover current truth, identify gaps, and issue only required corrective work.
AUDIT — inspect readiness without changing implementation.
FEATURE — apply the workflow only to a new feature/workstream.

INVOCATION
@EITRIMB STARTER
@EITRIMB UPDATE
@EITRIMB AUDIT
@EITRIMB FEATURE <scope>

AUTO may be appended when autonomous execution is authorized.

OUTPUT
1. Readiness snapshot.
2. Missing/ambiguous requirements.
3. Safety/recovery findings.
4. Architecture/ownership conflicts.
5. Language/toolchain preflight requirements.
6. EDC/IAC updates or generated specialist work orders where needed.
7. Evidence-backed readiness state.
8. Next executable action.

RULE
This package is additive and drop-in. Existing authoritative project canon wins over generic defaults.
