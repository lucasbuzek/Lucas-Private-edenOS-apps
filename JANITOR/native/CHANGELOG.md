# Changelog

## 0.1.1 — safety repair (from Oct 6 physical-run evidence)
- FIX: Exact Duplicates ran on the whole home folder because one analysis root was shared across modes and persisted. Roots are now per mode; the old shared key is discarded on launch.
- FIX: duplicate/media/similar-name scans refuse the home folder (or above) and fall back to Movies, Music, Pictures, Downloads.
- FIX: duplicate/media/similar scans never enter managed trees: hidden dirs, ~/Library, Git/project trees, backup/LKG folders, content-addressed stores (objects/blobs), '#review...' folders and the quarantine root.
- FIX: duplicate candidates carry their kept copy; delete/quarantine are refused when the kept copy is missing, changed in size, or also selected.
- FIX: quarantining items already inside the quarantine root is refused.
- FIX: size measurement no longer truncates at depth 8 (it undercounted and mislabelled roots PARTIAL); PARTIAL now means the time budget was hit.
- FIX: Build Families / Dependency Discovery refuse a home-folder root; Choose What to Scan on the home folder is listing-only.
- CHANGE: removal reports state that sizes come from the scan and show an approximate free-space delta; unmeasured roots show a dash instead of 'Zero KB'.
- CHANGE: unreadable roots (e.g. Trash) explain the Full Disk Access requirement.

## native 0.2.0 (2026-10-07) - §Built §Unverified
- Disclosure levels Simple / Advanced / Expert (sidebar switch) plus per-feature "More options" expanders.
- Sections: Clean, Organize, Full Crew (all levels, read-only), Recovery, Developer (Advanced+), Tools (Advanced+).
- Simple groups candidates by category; unique non-safe files cannot be bulk-selected there. Permanent delete is Expert-only.
- Safety guards unchanged at every level. Not yet done: optional labels/Smart Folders step, Intel build, Windows editions on this layout.
- Version track: native app numbering is separate from the script lineage (script LKG v0.1.1 / candidate v0.9.0).

## 0.2.1
- Favorites: pin any section to a Favorites group at the top of the sidebar (star in toolbar, right-click in sidebar). Sidebar otherwise unchanged. Favorites never bypass level gating.
- State: Built/Unverified (not yet built at time of writing).

## 0.2.10-candidate — 2026-10-09 (not promoted)
- FIX: Match retained Model.Mode Developer disclosure contract to the existing active Advanced-level sidebar.
- FIX: Reject File Provider/protected/quarantine broad roots before creating any quarantine directory; preserve the original local file when refused.
- FIX: Read runtime version from the actual app bundle rather than hard-coding 0.2.1 in reports/recovery manifests.
- FIX: Replace obsolete placeholder-generating macOS builder with a wrapper that packages authoritative native sources using the existing build engine; refuse release overwrite.
- FIX: Update existing build engine to parse versioned plist reliably.
- TEST: 46 Python regression tests, native Swift filesystem recovery regression and SwiftUI-host/System Check integration smoke passed.
- PACKAGE: ARM64 + Intel x86_64 build; signed; ZIP SHA256 and clean extraction/executable parity verified.
- PHYSICAL: GUI click-through remains UNKNOWN (macOS assistive-access denial -25211 and screen capture unavailable). Intel physical runtime UNKNOWN; Windows physical runtime UNKNOWN.
- STATE: candidate in Releases; no LKG or Products promotion.

## 0.2.11-candidate — 2026-10-09 (EDEN UI refinement; NOT PROMOTED)
- UI: Homebrew preview/run and unavailable Xcode simulator preview/removal are Developer tools in both the current Finder-style shell and retained legacy view; actual native maintenance actions, preview and confirmation gates are unchanged. Simulator removal stays Expert-only.
- UI: Give standalone JANITOR its own amber paintbrush identity matching the existing EDEN/BIFROST JANITOR accent, improve sidebar width/two-line labels and selected-item emphasis, add an honest on-demand/local-first footer.
- UI: System Check header and cards use restrained EDEN-style semantic accents. Do not imply health or completed checks without SystemInspector evidence.
- TEST: 50/50 Python tests, native Swift runtime and SwiftUI host/System Check smoke passed; universal ARM64+x86_64 build, package verification and application launch passed.
- PHYSICAL: screenshot/Accessibility gates remain UNKNOWN; no LKG or Products promotion. Previous 0.2.10 candidate and earlier baselines remain recoverable.

## 0.2.12-candidate — 2026-10-09 (compact toolbar and navigation; NOT PROMOTED)
- UI: Move the interface/inspector/settings toolbar to the full NavigationSplitView and apply native macOS unified-compact toolbar styling. The window keeps standard close/minimize/zoom controls.
- UI: Replace automatic nested DisclosureGroup indentation with aligned native buttons, preserving stored per-group expansion and the same command IDs; use compact single-line labels with modest scaling when needed.
- UI: Shorten Developer, Maintenance, Media, Full Crew and cloud tool labels without changing their actions or confirmation gates. Homebrew/simulator actions remain under Developer with simulator deletion Expert-only.
- EVIDENCE: 52/52 Python regression tests; direct Swift runtime + SwiftUI hosting/System Check PASS; universal Apple Silicon/Intel macOS build and clean ZIP extraction/signature/hash/byte parity PASS; launch observed.
- PHYSICAL: visual titlebar alignment and click-through acceptance remain UNKNOWN pending user inspection of actual native window. LKG preserved, no Products promotion.


## 0.2.13-candidate — 2026-10-09 (visual acceptance refinement; not promoted)
- Observed from an AppKit-hosted render of JANITOR's real FinderShell: System Check heading and Inspector title entered the unified toolbar region; collapsed-section icons had insufficient light-mode contrast; Settings was occluded by the pinned status footer.
- Repaired: 52-pt content clearance below unified toolbar for detail/Inspector, legible blue specialist icons, one pinned Settings row above the local-first footer, consistent contrast for simulator action icon.
- Extended static UI contracts for new layout, action continuity and permission requirements. Existing engine actions, protections and LKG remain unchanged.
- AppKit-hosted layout render is evidence of view-tree appearance, **not** on-screen GUI click-through or a physical acceptance gate. Screen capture/accessibility TCC remains unavailable from remote shell. Do not promote based on render alone.


## 0.2.14-candidate — 2026-10-09 (sidebar fixed controls + dark contrast)
- AppKit-hosted 1100x760 dark appearance preview exposed black text on dark List/sidebar material; physical production behavior still UNKNOWN. Explicit adaptive SwiftUI Color.primary/secondary now applied to sidebar labels and section headings.
- Replace List.safeAreaInset overpainting with a real VStack: scrollable List above pinned Settings and local-first status. Long Developer tool lists no longer draw beneath fixed controls.
- Preserve command action identifiers, Expert-only destructive confirmations and Inspector. Static, native runtime, visual-host and physical gates remain distinct.
- Visual correction during 0.2.14 candidate: sidebar labels use explicit light/dark-aware ink and muted text colors because AppKit-hosted dark List material did not reliably propagate semantic Color.primary.
