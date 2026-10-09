# JANITOR UI refinement — 2026-10-09

User evidence: Homebrew cleanup and unavailable Xcode simulators were displayed under Maintenance; both belong to Developer. Existing BIFROST/EDEN app screenshots supplied as styling reference, not a reason to host JANITOR in BIFROST.

Changes to actual standalone SwiftUI JANITOR:
- Moved Homebrew preview, Homebrew cleanup confirmation, unavailable-simulator preview and simulator removal to Developer. Simulator deletion remains Expert-only. Existing Maint.brew, Maint.simulators and confirmation gates are retained.
- Removed those actions from CleanView and replicated them in legacy DeveloperView for source continuity.
- Introduced standalone JANITOR identity using existing EDEN Janitor gold accent, centered icon, expanded navigation width with two-line tool names, local/on-demand footer, and a restrained System Check header/cards. No placeholder health numbers, no server/background dependencies.
- Native version 0.2.11-candidate (previous 0.2.10 remains unpromoted LKG reference; older actual LKG preserved).
- Automated evidence: 50/50 Python regression; direct native Swift runtime PASS; NSHostingView and model/System Check runtime PASS; macOS ARM64 + Intel x86_64 compiled.
- Package integrity: clean extracted binary and Info.plist byte parity, codesign and ZIP checks PASS.
- SHA-256 ZIP: 413f574ba4e0e8e5208e793d16daa4014789c679d2d7332b2c63c6c943815f98
- New app launched and process observed on Apple Silicon Mac; UI visual/click gate remains UNKNOWN because Accessibility/screen capture denied. Intel physical execution UNKNOWN.
- Release archive cleanup: 0.2.9 recovered from independently created quarantine (verified SHA); 0.2.10 moved to recoverable quarantine with hashes; four historical LKG/CLI release folders plus 0.2.11 candidate retained.
- Source backup: ~/edenOS/AppDev/#App Backups/Apps/JANITOR/JANITOR_NATIVE_0.2.11_UIX_SOURCE_20261009.zip (clean extraction and source parity PASS).
- Active evidence: ~/edenOS/Software Development/JANITOR/evidence/MAXEFFORT_20261009/.
- No Products promotion. No default-branch merge. Original BIFROST worktree untouched.
