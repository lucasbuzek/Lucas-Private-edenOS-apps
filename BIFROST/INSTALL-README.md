# BIFROSTzeroRAVEN — one-click headless installer candidate

Unzip the complete folder on your Mac, then double-click `Install-BIFROST.command`.
Keep the script beside its bundled folders. Requires macOS and Python 3.10+.
If macOS blocks the downloaded script, inspect it and use the normal macOS
Open/security approval flow. This package does not bypass Gatekeeper or install Python.

The installer verifies bundled file hashes, copies the runtime to
`~/Library/Application Support/BIFROST/HeadlessRuntime`, registers
`~/Library/LaunchAgents/eden.bifrost.headless.plist`, starts the service and checks
its exact source/runtime identity before opening http://127.0.0.1:8798.
It starts again on login. It does not require the native macOS BIFROST application.
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
