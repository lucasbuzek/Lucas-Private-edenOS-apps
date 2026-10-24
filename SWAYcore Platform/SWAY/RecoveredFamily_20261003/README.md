# SWAYcore — ONE CORE. MULTIPLE EXPERIENCES.

Reconstruction from the cold-start package (spec copies in `Docs/Spec/`).

## Run it (macOS with Xcode installed)
1. Extract. Double-click **`Build_SWAYcore_ALL.command`** (whole family) or a product builder:
   `Build_SWAYcore_Core` · `_DanceFitness` · `_SWAYZ` · `_KidDancers` · `_StudioManagement`
   (First run: right-click → Open if Gatekeeper warns. Or `chmod +x *.command`.)
2. The builder preflights the Mac (macOS/arch, Homebrew, Xcode, xcode-select, xcodebuild, xcrun, Swift, SDKs, Git),
   installs only genuinely missing declared tools (`xcodegen`, Blender cask) via idempotent `ensure_formula/ensure_cask`,
   runs static checks, Swift tests, **generates and validates the Blender characters**, generates Xcode projects,
   compiles, packages, verifies, and writes `Build/report/LATEST_BUILD_REPORT.md`.
3. Only when everything non-physical is done, it tells you to connect/unlock an iPhone/iPad.
4. Signing: copy `Config/Signing.local.xcconfig.template` → `Config/Signing.local.xcconfig`, set `DEVELOPMENT_TEAM`.

## Layout
`Packages/SWAYcoreKit` shared engine (movement, timing, matching, calibration, session, .swaypack, rig contract, authoring) ·
`Packages/SWAYAppKit` Apple-framework services + RealityKit character runtime · `Packages/SWAYStudioKit` studio operations ·
`Apps/*` four products (XcodeGen `project.yml`) · `Blender/` production pipeline · `Scripts/` builder library, verifier, packager ·
`Docs/` decisions, evidence states, LKG, physical acceptance.

Read `Docs/STATE_AND_EVIDENCE.md` first: it states exactly what is and is not proven.
