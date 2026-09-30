JANITOR — Justified Analysis, Navigation, Inspection, Tidying, Optimization & Recovery

PRIVATE — Lucas / EXPERIMENTAL

PROJECT GOAL
Standalone deterministic cleanup, storage, file/media organization, maintenance and recovery application. Preserve useful CleanMyMac-class capabilities without resident bloat, fake optimization, unsafe deletion, telemetry, or mandatory EDEN/cloud/AI dependencies.

CURRENT CANDIDATE
v0.9.0-mode-separation-cloud-photos-candidate

AUTHORITATIVE USER MODES
1. STANDARD — everyday maintenance
2. DEVELOPER — projects, builds, toolchains and development cleanup
3. MEDIA — Photos, video and media storage
4. FULL CREW — advanced inspection and recovery

PLATFORM ORDER
Script behavioral reference -> macOS native -> iOS/iPadOS native -> Windows native -> other platforms.

AI RULE
Native AI is optional reasoning/classification assistance. Deterministic OS services execute actions. AI OFF remains functional.

CLOUD RULE
Quarantine follows storage ownership. Provider-managed items stay inside the same provider root when quarantined or consolidated/archived. JANITOR must not force-download cloud-only content as a quarantine fallback.

PHOTOS RULE
.photoslibrary internals are PROTECTED. JANITOR may analyze storage read-only, but must not directly delete Photos originals or database content.

STATE TRUTH
Historical physically evidenced CLI LKG: v0.1.1
v0.7.2 Quick Scan/script launch: physical PASS evidence
v0.7.4-v0.7.6 quarantine branches: physical FAIL evidence
v0.8.1 Full Scan: physical FAIL; hung at Home summary for ~2 hours
v0.9.0: static/fixture PASS; physical Mac UNKNOWN/PENDING
RELEASE: NOT RELEASED

SAFETY
ANALYZE -> PREVIEW -> CONFIRM -> ACT/QUARANTINE -> VERIFY -> RESTORE
UNKNOWN != JUNK.
Similarity never authorizes deletion.
No resident daemon/service/scheduler/telemetry.

RECOVER BEFORE REDESIGN.
See PROJECT_STATE.txt, RECOVERY.txt, TEST_STATUS.txt and CHANGELOG.txt.
