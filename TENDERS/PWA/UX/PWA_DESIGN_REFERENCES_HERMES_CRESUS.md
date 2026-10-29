# TENDERS PWA — UI Reference Canon: HERMES + CRESUS

Status: reference paths and source files inspected on the Mac on 2026-10-14. This is a design-reference decision, not a claim that TENDERS UI has been implemented.

## HERMES — operational workspace and status presentation
Reference: `/Users/lucas/edenOS/Software Development/HERMES/web/src/App.jsx` and `web/src/styles.css`.
- Compact dark desktop navigation and responsive bottom navigation on mobile.
- Clear workspace header and compact content area; no oversized hero.
- Persistent, collapsible UIbasic status panel: current module/state, explanation, next action, blockers, phase/QA and advanced detail.
- AUTO / TINY / COMPACT / FULL presentation depths, adapting detail to the current state without hiding blockers.
- Opportunity cards, search/filter, visible status and rationale.
- Local-first/browser-only fallback, explicit connection/sync/error state, and recovery paths.
- Export/import and protection of local data during remote connection or migration.
- Touch-friendly mobile controls, safe-area handling and reduced-motion support.
- Evidence-led status: suggested, prepared, approved and externally completed remain distinct.

Do not copy HERMES employment-specific fields, brand identity, colours or mixed job/tender model.

## CRESUS — premium visual restraint and presentation depth
References: `/Users/lucas/edenOS/Software Development/CRESUS/platforms/web/canon/01_CRESUS_CANON.md` and `evidence/CRESUS_COMPONENT_CONVERGENCE_20261009.md`.
- Refined, confident, authoritative and enduring presentation; restrained surfaces and typography rather than neon/gimmicky effects.
- Strong information hierarchy and considered whitespace without excessive vertical bulk.
- Simple and Expert are depths over the same underlying facts and state, never separate truth models.
- Evidence and source/provider state visible where relevant; uncertainty remains uncertainty.
- Clear research/evidence organisation; software informs, user makes consequential decisions.

Do not copy finance-specific navigation, identity or investment semantics.

## Combined TENDERS direction
HERMES supplies operational shell/status patterns, responsive navigation and local-first/recovery behaviour. CRESUS supplies visual restraint, hierarchy and presentation-depth principles. TENDERS owns its brand, procurement-native domain model and workflow.

Design mantra: **Small by default. Rich by composition. Familiar by default. More powerful by choice.**

## TENDERS information architecture
Overview; Discover; Opportunities; Bid Workspace; Documents & Evidence; Contracts; Calendar; Research; Reports; Integrations; Settings. Research exposes ARGOS as optional extended research only when requested. Google integrations expose account, scopes, sync state and revocation controls.

## LCAS and product status are different
Chat LCAS is a compact conversation status/control panel only. The PWA has its own HERMES-UIbasic-inspired product status panel and its own governed workflow state. Do not embed LCAS in the PWA.

## Required interactions and acceptance
- AUTO/TINY/COMPACT/FULL or equivalent status detail; current state, next action and blockers remain visible.
- One obvious primary action per view; quieter secondary actions; no decorative hero waste.
- Status links to evidence and last verification time; no misleading success colour when gates are unknown/failed.
- Confirmation for external submission, binding declarations, signatures, financial transactions and contract changes.
- Designed empty/loading/offline/stale/sync-conflict/error states.
- Accessible labels, keyboard navigation, focus management, contrast, reduced motion and responsive desktop/tablet/mobile layouts.
- Use existing reusable patterns where licensing and dependencies permit; do not modify HERMES or CRESUS as part of TENDERS work.
- Capture reference revision where available and verify status panel, navigation, local recovery and responsive flows in TENDERS before release.

