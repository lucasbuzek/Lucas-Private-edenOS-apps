# JANITOR native macOS 0.2.14 — visual evidence and pending physical gate

Scope: current standalone JANITOR app only. Existing FORGE/CONDUCTOR canon applies, no BIFROST dependency.

Observed by rendering the maintained SwiftUI view tree in an actual native AppKit-hosted NSWindow (offscreen, not screen-capture of the launched app):
- 0.2.12/0.2.13 original: header and inspector content under unified titlebar, low-contrast specialist icons, Settings/footer over long Developer lists, sidebar labels rendered black on dark offscreen NSOutlineView material.
- 0.2.14 repair: preserve 52-pt top content clearance, use clearly colored blue specialist icons, physically stack scrollable List and pinned Settings/footer, and explicitly adapt sidebar foreground to light/dark ColorScheme rather than relying on native List default ink. Homebrew and simulator actions stay in Developer; simulator deletion stays Expert-only.
- Light/dark AppKit-hosted screenshots are stored under ~/edenOS/Software Development/JANITOR/evidence/PHYSICAL_GATE_20261009/appkit-light-0.2.14.png and appkit-dark-0.2.14-contrast.png.
- The hosted previews are evidence for contents/layout only; they are NOT proof of the actual on-screen titlebar, operating system traffic lights, click actions, animations, resizing or TCC permissions.

Executed on connected macOS Xcode 27 toolchain:
- 56/56 Python regression PASS; targeted UI contracts 24/24 PASS.
- Swift runtime regression PASS; NSHostingView + Model/System Check integration PASS.
- Universal native release compilation for arm64 and x86_64 PASS.
- ZIP integrity, clean extraction, copied plist and executable binary parity, signed built and extracted app, staged-vs-Releases ZIP parity PASS.
- Application launched on Apple Silicon and PID observed (no click-through).
- ZIP SHA256: 77c449881d311f90426020beb979ba646c9e60745bfb5f24541910db777b974c.
- Source recovery backup verified from clean extraction:
  ~/edenOS/AppDev/#App Backups/Apps/JANITOR/JANITOR_NATIVE_0.2.14_VISUAL_SOURCE_20261009.zip
- Candidate is directly in flat ~/edenOS/Releases/ with @App macOS / §Built / §Test / §Unverified Finder tags.

Physical gate: UNKNOWN. RDC command shell has no authorized screen capture (screencapture failed), Accessibility reported disabled and was unable to inspect a GUI window. Physical user click on actual toolbar/sidebar and screenshot still required. Intel physical runtime UNKNOWN. Windows physical runtime UNKNOWN.
Previous 0.2.12 and 0.2.13 candidates remain recoverable, 0.2.12 currently observed running; do not move running app. Earlier verified LKG preserved. No Products promotion and no default-branch merge.

Manual visual/click gate for user:
1. Open 0.2.14 app in Releases.
2. Confirm top toolbar/traffic lights share one line, content clears toolbar, Developer rows align and fit.
3. Toggle Inspector; expand/collapse Developer, switch Standard/Advanced/Expert.
4. Verify Settings is pinned and scrolling does not paint tools under it in light/dark appearances.
5. Check Homebrew preview is read-only; cleanup requires confirmation.
6. Verify unavailable-simulator deletion appears Expert-only and requires destructive confirmation; cancel without executing.
7. Run System Check, ensure evidence-based states; Recovery entries accessible.
Physical acceptance must be separately recorded with proof; UNKNOWN != PASS.
