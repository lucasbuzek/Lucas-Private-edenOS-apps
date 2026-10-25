# BIFROSTzeroRAVEN — one-click headless installer candidate

Unzip the complete folder on your Mac, then double-click `Install-BIFROST.command`.
Keep the script beside its bundled folders. Requires macOS and Python 3.10+.
If macOS blocks the downloaded script, inspect it and use the normal macOS
Open/security approval flow. This package does not bypass Gatekeeper or install Python.

The installer verifies bundled file hashes, copies the runtime to
`~/Library/Application Support/BIFROST/HeadlessRuntime`, registers
`~/Library/LaunchAgents/eden.bifrost.headless.plist`, starts the service and checks
its exact source/runtime identity before opening http://127.0.0.1:8798.
By default it starts only for this installation; **start at login is OFF**. An authorized installer built with the explicit `startAtLogin` option can enable login startup. It does not require the native macOS BIFROST application.
No cloud credentials, account pairing, native app installation or hostname changes.
Hashes detect damage; this is not a signed or notarized distribution.

An existing service, runtime folder, LaunchAgent or occupied port is preserved:
the installer stops instead of overwriting it. This first installer does not yet
perform upgrades. Failed installs retain runtime/logs for diagnosis and remove
only their newly created LaunchAgent; user preferences/storage are retained.
Log: `~/Library/Application Support/BIFROST/headless-install.log`.
To stop the installed service manually:

```sh
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/eden.bifrost.headless.plist"
```

Source: private BIFROST candidate PR #13. Complete platform functionality is not
established. Storage preview and existing Apple workflow controls are exposed;
transfers/sync, general durable execution and specialist integrations remain
incomplete. Apple workflows require actual macOS permissions and testing.
Portable regression tests and isolated HTTP smoke are separate from macOS
LaunchAgent acceptance. This installer has NOT been run on RavenAirM1/RavenNestM3.

## One-click installer builder

Double-click `Build-Installer.command` to configure and rebuild from this EXISTING source folder. The builder prompts for the local Web UI port, whether Headless should start at login (default NO), and whether to open the browser after installation. Invalid options fail closed. A noninteractive builder uses safe defaults. The **unsigned candidate ZIP and hash receipt are placed in `~/edenOS/Releases/`**, NOT installed into Software Development or Downloads. `Install-BIFROST.command` inside the generated ZIP is a separate explicit owner action, and its failures now propagate rather than being silently suppressed.
The builder requires Python 3.10+ and Node.js available locally. It runs the Python
and JavaScript regressions, generates missing icons, runs an isolated HTTP smoke,
then creates a uniquely named ZIP and SHA-256 receipt beside the source folder.
It verifies the archived file hashes before revealing the result in Finder.
It does not install, download dependencies, sign, notarize or publish anything.
Use `Install-BIFROST.command` inside the generated ZIP to install on a fresh Mac.
