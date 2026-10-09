# JANITOR v0.9.0 full-function audit
Date: 2026-10-01
Governor: EITRI v0.2.0
Mode: AUDIT

RESULT
v0.9.0 is NOT function-complete and is NOT promoted to LKG.

EVIDENCE
- Exact packaged v0.9.0 source audited.
- macOS core: 82 functions; bash syntax PASS.
- Windows core: 37 functions; static parity FAIL.
- Fixture PASS: local quarantine/restore, Safe Clean, Developer Quick build-family quarantine, same-provider cloud quarantine, same-provider archive/consolidate move, Photos footprint/protection analysis, bounded Full Scan.
- Physical Mac PASS: v0.9.0 launch and top-level mode menu.
- Physical Mac FAIL/defect evidence: Cloud Storage has no Scan action; Running Processes is an unclassified raw ps dump; Project Discovery entered ~/Documents although Documents is iCloud-managed.

CRITICAL FAILURES
1. Storage-provider ownership is not resolved before every scan. cloud_root_for_path misses redirected/symlinked ~/Documents.
2. Project Discovery says bounded depth 6 but its find has no -maxdepth 6.
3. Cloud Storage jumps directly to Q/C/D exact-path actions; no Scan -> Review stage exists.
4. Quick Scan is not truly bounded; it uses unbounded du on Downloads, Logs, Caches and developer stores.
5. Exact Duplicates and Similar Names are unbounded/provider-unaware. Exact Duplicates may hash cloud-managed content.
6. FULL CREW process/background/remnant features are raw inventory surfaces, not the described classified/actionable implementation.
7. Photos support is protected filesystem footprint analysis only; no Photos.app/native resident-vs-cloud analysis or safe reclaim.
8. Windows source inside the v0.9.0 ZIP is stale: reports v0.7.2, lacks Standard/Developer/Media/Full Crew separation, Maintenance is still status-only, and Discover-Projects references undefined Project-Root and Project-Kind functions.

AUTHORITATIVE STATE
- Historical physical LKG: v0.1.1.
- v0.9.0 launch/menu: PHYSICAL PASS.
- v0.9.0 behavioral baseline: FAIL / NOT PROMOTED.
- Native macOS app work must wait for script behavioral contract PASS.

RECTIFICATION ORDER
1. One storage-owner resolver for LOCAL / ICLOUD / FILE_PROVIDER / EXTERNAL / NETWORK / PHOTOS_LIBRARY / PROTECTED.
2. Provider ownership before every traversal/action, including Desktop/Documents redirection.
3. Enforce depth/time bounds across all scans.
4. Cloud: Scan -> Review -> Quarantine / Consolidate / Delete.
5. FULL CREW: classify Apple/macOS protected vs installed-app vs user/developer vs unknown.
6. Do not label raw support-root listings as remnants without ownership correlation.
7. Keep Photos function honestly labeled filesystem footprint until native Photos integration exists.
8. Apple-first milestone: macOS script -> macOS native -> iOS/iPadOS; Windows follows after Apple behavioral contract.
