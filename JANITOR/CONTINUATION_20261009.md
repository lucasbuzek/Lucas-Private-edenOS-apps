# JANITOR AUTO — 2026-10-09 continuation candidate

Authority: original active JANITOR source on connected Mac; preserve project LKG.
Baseline: 0.2.9-candidate; commit efb455aee2a3da3e655511395c0c50217421c18e.

Verified repairs:
- Developer disclosure is Advanced in Model contract, consistent with active Finder-style sidebar.
- Quarantine destination preflight now occurs before any directory creation; synthetic File Provider fixture is refused with original preserved.
- Native version is resolved from the signed bundle Info.plist.
- Historical inline-placeholder macOS builder was replaced with a wrapper over actual native JANITOR source; existing builder engine retained and plist version parsing repaired.
- Current source version: 0.2.10-candidate.

Evidence on connected Mac:
~/edenOS/Software Development/JANITOR/evidence/MAXEFFORT_20261009
Native Swift runtime regression PASS, SwiftUI host + model/System Check smoke PASS.
Python regression 46/46 PASS. Bash/Zsh builder syntax PASS.
Universal macOS ARM64 + x86_64 compile PASS.
Bundle signature, ZIP archive integrity, SHA256, clean extraction and executable byte parity PASS.
Native GUI program started, process observed PASS.
ZIP SHA256: b745baaff603837c89616fda8ab71a85d4d4dc9de3c8e318c6986b69e3dd0917.
Native source backup: ~/edenOS/AppDev/#App Backups/Apps/JANITOR/JANITOR_NATIVE_0.2.10_CANDIDATE_SOURCE_20261009.zip (clean restore verified).
Candidate location: ~/edenOS/Releases/JANITOR/0.2.10-candidate-native-arm64-x86_64/.

PHYSICAL GUI: UNKNOWN, because remote Mac denies Accessibility automation (-25211) and screencapture cannot capture display.
Physical Intel/Windows: UNKNOWN. Do not infer PASS from cross-compilation.
LKG: PRESERVED. No Products promotion. No merge into main.
