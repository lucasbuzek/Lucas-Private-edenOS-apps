# AppleRAVEN — Standalone private Apple MCP (candidate v0.1.0)

AppleRAVEN is a separately operable, private local-first Apple capability service for the LucasRAVEN / Murder of Crows environment. **Not a BIFROST dependency, not official edenOS, not a second project governor, not HEIMDALL's replacement.** Existing EDEN specialists retain their duties. Created as a candidate on a protected branch; do not overwrite any original Mac source or LKG before reconciliation.

## Actual local MCP features

Works with Python 3.10+ and no external packages using stdio MCP protocol 2025-06-18, bounded JSON-RPC and strict tool schemas.

1. `appleraven.status`: profile and local capability discovery.
2. `appleraven.shortcuts.list`: Apple's macOS Shortcuts CLI.
3. `appleraven.shortcuts.run`: only configured named Shortcuts, optional text input; effectful/opaque.
4. `appleraven.icloud.list`: files under an approved local File Provider/iCloud Drive folder.
5. `appleraven.icloud.read_text`: approved small text files under that scope.
6. `appleraven.devices.list`: read-only Xcode developer-device inventory.

No general shell, no unattended login/account switching, no default TCC/Full Disk Access, no Keychain access, no remote listener, no vendor relay, no secrets in source, and no autonomous modifications to Mail, Messages or system preferences. macOS Shortcuts may themselves be effectful, so only owner-approved names belong on the allowlist.

## macOS first-use

From the `AppleRAVEN` folder:

```sh
python3 -m appleraven.server --init-config
python3 -m unittest discover -s tests -v
python3 -m appleraven.server --profile lucascouncil
```

`--init-config` creates `~/.config/appleraven/config.json` (owner-only 0600, refuses overwrite). Configure only approved capabilities, e.g.:

```json
{"schema":1,"profiles":{
  "lucascouncil":{"allow_shortcuts":["HEIMDALL Status"],
    "allow_roots":{"icloud":"~/Library/Mobile Documents/com~apple~CloudDocs"},
    "allow_file_read":false},
  "lucaspro":{"allow_shortcuts":[],"allow_roots":{},"allow_file_read":false}
}}
```

The example is a **proposed configuration**, not evidence of a currently installed Shortcut or authorized iCloud scope. Each client starts its own process with the exact `--profile`. No MCP tool can switch profiles; authorization is never inherited between LucasCouncil/LucasPRO/CROWnest and separate EDEN identities.

For Codex, review the exact path, then register:

```sh
codex mcp add appleraven -- /bin/bash "/absolute/path/to/AppleRAVEN/Run-AppleRAVEN.command" --profile lucascouncil
```

For Claude Desktop, add one `mcpServers.appleraven` entry with command `/bin/bash` and args `["/absolute/path/to/AppleRAVEN/Run-AppleRAVEN.command","--profile","lucascouncil"]`; merge without replacing existing settings. The plain local stdio endpoint is **not** an internet-accessible ChatGPT mobile connector.

## Acceptance scope still open

The independent stdio transport and fixed-profile test candidate are implemented; macOS/iPhone installation, Apple TCC consent, real Shortcuts, Apple Intelligence, App Intents, iCloud account aliases, Mac screen sharing, device pairing, multi-Mac auth, secure optional remote transport, and the current 2026 MCP protocol interop still require real source/code/physical verification. A device listing is not remote device control. Apple Intelligence and Siri should be integrated with native App Intents through HEIMDALL, reusing a single capability interface.

Canonical AppleRAVEN main source should be reconciled with live `#common` and any original Mac Project Bible before promotion. The isolated 9-test sandbox candidate passed, while this separately committed GitHub revision has not yet been executed on the Mac or in CI. Test with the repo-provided suite, do not label a unit test as physical acceptance.

Official references: [Apple App Intents](https://developer.apple.com/documentation/appintents), [Apple Xcode MCP](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode), [MCP Python SDK v2](https://github.com/modelcontextprotocol/python-sdk).
