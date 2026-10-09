# Reproducible native Apple Alpha build

Run `xcodegen generate --spec project.yml` in this directory if the Xcode project needs regeneration. The checked-in Xcode project and specification define `CRESUS-iOS` (iPhone and iPad) and `CRESUS-macOS` targets, with signing disabled for simulator/unsigned local compilation. Xcode 27 macOS and iOS Simulator Debug builds passed on 2026-10-09. Physical devices, app functionality, and release signing remain unverified.
