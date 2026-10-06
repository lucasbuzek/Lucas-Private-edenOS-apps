# Build and run (macOS)
Prerequisites: full Xcode (opened once, license accepted, an iOS SDK installed), Homebrew. The builders install only missing declared tools (xcodegen; Blender only for asset work). Xcode is never installed for you.

1. Extract the zip. Right-click `VERIFY_ALL.command` > Open (first time), or in Terminal: `xattr -dr com.apple.quarantine . && chmod +x *.command Scripts/*.sh Tools/*.py`.
2. `VERIFY_ALL.command`: portable checks, Swift engine tests, project generation, simulator build and tests.
3. `BUILD_DANCE_FITNESS.command`: generate project, test, build simulator candidate, package + checksum. If everything passes it asks you to connect/unlock the iPhone; then it runs the DeviceSupport safety gate, builds with the project's own signing (team XZ4VRP5S5G, automatic), installs and launches.
4. `BUILD_ASSETS.command --technical-proof` (Blender): proves the bake/validate/export tooling on the Build 153 rig. Production characters need a legally acquired base (see UNRESOLVED_ITEMS U-01).
5. `BUILD_SWAYCORE_ENGINE.command`: engine tests only. `BUILD_ALL.command`: everything in order.
Results: `Build/report/LATEST_BUILD_REPORT.md`, logs in `Build/logs/<time>/`, previous verified outputs in `Build/LKG/`.
If a gate fails, send me that gate's log. A failure is evidence, not the end.
