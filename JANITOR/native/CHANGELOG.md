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
