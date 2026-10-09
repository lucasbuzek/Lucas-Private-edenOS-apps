# JANITOR 0.2.12 — compact toolbar and left-aligned tool rows

User-supplied visual evidence: 0.2.11 titlebar appeared detached from the left sidebar; expanded Developer tool labels indented and wrapped.

Narrow repair, standalone JANITOR:
- Move toolbar from detail HSplitView to full NavigationSplitView and apply .windowToolbarStyle(.unifiedCompact) in JANITORApp; editor toolbar role minimizes redundant title.
- Use explicit collapsible section rows with one aligned grid for category and nested commands. Reuse existing Model.sidebarIsExpanded / setSidebarExpanded; preserve all action IDs, levels, safety confirmations.
- Shorten visible tool labels without changing semantics (Dev leftovers, Choose dev folder, Homebrew preview/cleanup, unavailable sims preview/removal).
- Version: 0.2.12-candidate.

On connected Apple Silicon Mac:
- Focused UI contract 20/20 PASS; full Python regression 52/52 PASS.
- Direct Swift native runtime PASS, SwiftUI-host + System Check integration PASS.
- Universal macOS arm64 + x86_64 release build PASS; codesign PASS.
- Finder tags verified on flat Releases candidates (@App macOS, §Built, §Test/§Unverified); build intermediates stored in Temporary.
- ZIP clean extraction, binary/plist byte parity, signed app and launched process PASS.
- Candidate ZIP sha256: 83e00747add762db7e63564646335586051c2d10f3d0534bd7c99c964115edf6.
- Source backup JANITOR_NATIVE_0.2.12_TOOLBAR_SOURCE_20261009.zip clean extracted and parity checked.
- Physical visual titlebar/click acceptance UNKNOWN pending screen inspection by user. No Products or LKG promotion.
- Original BIFROST Git worktree and main unchanged.
