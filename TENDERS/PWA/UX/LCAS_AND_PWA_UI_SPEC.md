# TENDERS — Persistent LCAS and PWA UI Specification

## Separate surfaces
1. **In-chat LCAS:** compact status/control UI in TENDERS project conversations. It is not application code and does not govern procurement.
2. **TENDERS PWA UI:** real product interface with its own persisted workflow state, navigation, role-aware permissions and audit trail. It must not depend on LCAS.

## Design reference canon
Use HERMES and CRESUS as explicit UI references:
- HERMES operational reference: `/Users/lucas/edenOS/Software Development/HERMES/web/src/App.jsx` and `web/src/styles.css`. Reuse its compact responsive workspace shell, desktop sidebar/mobile bottom navigation, UIbasic status panel, AUTO/TINY/COMPACT/FULL depths, visible next action/blockers, local-first/recovery patterns, and explicit sync/error states where appropriate.
- CRESUS refinement reference: `/Users/lucas/edenOS/Software Development/CRESUS/platforms/web/canon/01_CRESUS_CANON.md` and `evidence/CRESUS_COMPONENT_CONVERGENCE_20261009.md`. Use its restrained premium hierarchy, visual restraint, and Simple/Expert as depths over the same underlying truth.
- Do not copy either app's domain data, name, identity, branding or unrelated features. TENDERS owns its procurement-native information architecture and visual identity.
- Combined direction: operational clarity from HERMES; refined restraint and hierarchy from CRESUS. Follow: “Small by default. Rich by composition. Familiar by default. More powerful by choice.”

## LCAS minimum contents
- Project: TENDERS — Procurement lifecycle.
- Current stage and verified evidence state; show UNKNOWN when evidence does not exist.
- Current focus/next actionable step.
- Blockers or approvals needed, only when present.
- Controls: Continue AUTO; Suggestions; Alternative approach; Evidence; Advanced.
- Optional phase checklist with compact states: PASS, FAIL, UNKNOWN, SKIPPED, N/A.

Controls must have real actions. Continue AUTO submits a focused continuation request. Suggestions asks for next high-value actions. Alternative approach requests an alternative without changing canon. Evidence requests supporting evidence/status. Advanced reveals deeper implementation detail. Do not present inert controls as functional or assert cross-chat persistence unsupported by the host.

## PWA navigation
Overview; Discover; Opportunities; Bid Workspace; Documents & Evidence; Contracts; Calendar; Research; Reports; Integrations; Settings. Use compact responsive navigation, one obvious primary action, clear states, progressive disclosure, and concise content. No large decorative hero or excessive vertical space.

## Product status panel
Implement a HERMES-UIbasic-inspired, in-product status panel independent of LCAS. Provide AUTO/TINY/COMPACT/FULL or equivalent detail depths; show current module/state, concise message, next recommended action, blockers, phase, QA and optional advanced pipeline detail. Auto mode adapts to current state without hiding important blockers. Remember presentation preference when appropriate. The panel is informational and reflects TENDERS's own governed state.

## CRESUS-informed visual language
Refined, authoritative, restrained and enduring. Use careful typography, neutral surfaces, consistent spacing, purposeful accent colour, and clear evidence/source presentation. Avoid neon, casino/trading gimmicks, faux-medieval styling, excessive gradients, oversized hero sections and developer-console aesthetics. Simple and Expert are different presentation depths over the same data and state.

## Status display
Use labels and text as well as colour. Every status links to its evidence and last verification time. Distinguish source freshness, local save, remote sync and workflow completion. Avoid a single misleading overall green/pass indicator when any required gate is unknown or failed.

## Interaction requirements
- Confirmation and review screens before consequential actions.
- Destructive operations require clear impact, confirmation and recovery path where possible.
- Accessible labels, keyboard navigation, focus management, contrast and reduced-motion support.
- Every async action has pending/success/failure outcomes; never show success before the result is returned.
- Offline mode identifies actions that are queued, local-only, unavailable or awaiting sync.
- Google integration screens disclose scopes and selected accounts/files; users can disconnect and inspect sync errors.
- Responsive layouts and touch targets must be verified on real target viewports.

## LCAS conversation control panel
The chat surface provides clickable controls for Continue AUTO, Suggestions, Alternative approach, Evidence and Advanced. LCAS remains presentation/control only and must not be embedded in source architecture, package, product data model or runtime.

