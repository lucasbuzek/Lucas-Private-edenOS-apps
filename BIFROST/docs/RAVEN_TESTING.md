# BIFROST ZERO / Lucas Raven — testing guide

Status: DRAFT test route, written 2026-10-08. Evidence ladder applies: only Level 1 has been run (on a copy, 9/9 OK). Levels 2 and 3 are UNVERIFIED until you run them.

What is being tested: a Cloudflare Pages + D1 edge (`web/lucas-raven`) and an outbound-only Mac bridge (`bifrost/raven_bridge.py`) that runs only allowlisted actions: `power.keepawake.start` (1-480 min), `power.keepawake.stop`, `bifrost.state.refresh`. There is no shell action.

Run everything from `BIFROST/` unless stated. No secret ever goes in a file, a commit or a chat.

## Level 1 - offline automated (safe, no network)
```
python3 -B -m unittest discover -s tests -v
```
Expected: all Python tests pass (the original 9 plus catalog, collectors, singleton,
enrollment, and WORKinCODEX guardrail/transport tests). A `ResourceWarning` about a
short-lived test subprocess is known and harmless.

The device catalog is `catalog/capabilities.v1.json`. If it is absent or invalid,
the bridge logs the failure and advertises only the original three actions. List
collectors run on a daemon thread, have a five-minute Codex back-off, cap metadata
at 50 items, and never read Claude/ChatGPT message content.

## Device enrollment and singleton bridge

Read an edge-issued one-time token from stdin (never put it in shell history):
```
./bifrostctl raven-enroll
```
The CLI posts it to `/api/node/enroll`; it asks before replacing an existing
`eden.bifrost.raven.node` Keychain item and never prints the returned credential.
Legacy Keychain credentials continue to be read by the bridge.

The launchd job owns the singleton lock. A second `./bifrostctl raven-bridge`
exits politely. `--force` is an explicit diagnostic flag, but intentionally does
not break a live process lock or kill its owner.

Install/reload launchd on the Mac (not run by this change):
```
mkdir -p ~/Library/LaunchAgents ~/Library/Logs/BIFROST
cp launchd/eden.bifrost.raven-bridge.plist ~/Library/LaunchAgents/
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/eden.bifrost.raven-bridge.plist 2>/dev/null || true
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/eden.bifrost.raven-bridge.plist
launchctl kickstart -k gui/$(id -u)/eden.bifrost.raven-bridge
```

## WORKinCODEX unattended device action

`codex.cloud.submit` is fail-closed. It validates the real handoff path, exact
hash, 100,000-character limit, environment/branch allowlists, verbatim scope
guard, secret scan, sensitive-operation scan, identity isolation, persisted
three-per-hour limit, prior 429, and two consecutive failures before opening a
new visible Terminal window. False positives require attended review. It saves
and restores clipboard text and uses static AppleScript plus an argv value; it
never uses System Events keystrokes. STARTED is returned only after a new
`task_e_...` appears in `codex cloud list`. Applying, pushing, merging and
deleting remain attended-only.

After Lucas has reviewed a 429/two-failure stop, clear only the local submission
history with:
```
./bifrostctl raven-submit-clear
```

Manual Mac checks (none are exercised by offline tests):
```
./bifrostctl state
./bifrostctl raven-bridge --once
codex cloud list --limit 20
tail -n 20 ~/Library/Logs/BIFROST/codex-submissions.jsonl
```
Then queue a harmless, scoped handoff through Raven and confirm a **new** Terminal
window appears, the prior clipboard text is restored, and the reported task id
is visible in `codex cloud list`. Enable the optional ChatGPT adapter only after
granting Terminal/Python access at **System Settings -> Privacy & Security ->
Accessibility**, then set `RAVEN_CHATGPT_APP=1`; it is best-effort and fragile.

## Level 2 - edge API on your Mac only (no Cloudflare account state touched)
Uses a local D1 and throwaway keys. `npx` will fetch wrangler into its cache (no node_modules in the repo).
```
cd web/lucas-raven
OP=$(openssl rand -hex 24); ND=$(openssl rand -hex 24)
h() { printf %s "$1" | shasum -a 256 | cut -d' ' -f1; }
npx wrangler d1 execute lucas-raven --local --file=schema.sql
npx wrangler pages dev public --d1 DB=lucas-raven \
  --binding OPERATOR_KEY_SHA256="$(h $OP)" --binding NODE_KEY_SHA256="$(h $ND)"
```
In a second Terminal (same `OP`/`ND` values; URL is whatever wrangler prints, usually http://127.0.0.1:8788):
```
U=http://127.0.0.1:8788
curl -s $U/api/health                                   # ok:true
curl -s -o /dev/null -w '%{http_code}\n' $U/api/state    # 401 (no key)
curl -s -X POST $U/api/node/state -H "authorization: Bearer $ND" -H 'content-type: application/json' \
  -d '{"node_id":"lucas-macbook","bridge_version":"t","hostname":"t","actions":["power.keepawake.start","power.keepawake.stop","bifrost.state.refresh"],"state":{}}'
curl -s -X POST $U/api/actions -H "authorization: Bearer $OP" -H 'content-type: application/json' \
  -d '{"capability":"bifrost.state.refresh"}'            # 202 + act_... id
curl -s -X POST $U/api/node/claim -H "authorization: Bearer $ND" -H 'content-type: application/json' -d '{"node_id":"lucas-macbook"}'
curl -s -X POST $U/api/node/result -H "authorization: Bearer $ND" -H 'content-type: application/json' -d '{"node_id":"lucas-macbook","id":"<act id>","ok":true,"result":{}}'
curl -s $U/api/actions/<act id> -H "authorization: Bearer $OP"   # status succeeded
```
Must be rejected: capability `shell.run` (400 unknown capability); `{"capability":"power.keepawake.start","params":{"minutes":9999}}` (400); operator key on `/api/node/*` (401); node key on `/api/state` (401).

## Level 3 - live end to end (needs Cloudflare login; real Keep Awake for 30 min, then released)
One-time setup:
1. `./bifrostctl raven-provision` (creates node/operator keys in the login Keychain).
2. Put the two key hashes in Cloudflare Pages secrets: `./bifrostctl raven-hash node` and `raven-hash operator`, then `npx wrangler pages secret put NODE_KEY_SHA256` / `OPERATOR_KEY_SHA256` (project `lucas-raven`).
3. `npx wrangler d1 execute lucas-raven --remote --file=web/lucas-raven/schema.sql`, then `npx wrangler pages deploy web/lucas-raven/public --project-name lucas-raven`. (Check that Pages also picks up `functions/`; deploy from `web/lucas-raven` if the API 404s.)
4. Bridge, one cycle: `RAVEN_URL=https://lucas-raven.pages.dev ./bifrostctl raven-bridge --once`.

Manual check: `./bifrostctl raven-pair` copies the pairing link; open it on your iPhone; the badge should show the node online; press Keep awake, confirm `pmset -g assertions` lists a `caffeinate`, press Release, confirm it is gone.

Automated check (Chrome required; starts then releases a real Keep Awake):
```
RAVEN_OPERATOR_KEY="$(security find-generic-password -s eden.bifrost.raven.operator -w)" \
  node web/lucas-raven/tests/browser_e2e.mjs
```
PASS means: pairing fragment stripped, node badge online, capability cards render, start SUCCEEDED, a pmset assertion exists for the managed pid, stop SUCCEEDED, assertion gone.

Optional, only after Level 3 passes: `launchd/eden.bifrost.raven-bridge.plist` keeps the bridge running at login (copy to `~/Library/LaunchAgents/`, `launchctl load`). Not yet tested.

## Not covered yet
Expired/stuck action sweeps (queue 120 s, claim 600 s), the 5-pending-action limit, bridge restart while Keep Awake is running, and any non-Mac node.

Real Terminal `do script`, macOS Accessibility, Keychain writes, enrollment
against a live edge, and real Codex cloud submission/status/list calls remain
UNKNOWN until Lucas performs the Mac checks above. Offline mocks are TESTED only.

## Live state seen on the Mac, 2026-10-08 (read-only check)
- Edge deployed: `https://lucas-raven.pages.dev/api/health` answered `{"ok":true,"service":"lucas-raven","zero":"0.1.0"}`.
- Keychain items `eden.bifrost.raven.node` and `eden.bifrost.raven.operator` exist.
- launchd job `eden.bifrost.raven-bridge` is loaded and the bridge process is running.
- Bridge log shows `edge unreachable` warnings (DNS failure at 05:36, then connection reset, TLS handshake timeout and read timeouts from 06:15). At that time the Mac had a load average near 200 and a 98%-full disk, so slow or dropped connections are expected. Treat a failing live test as inconclusive until the Mac is idle.
- Whether the Chrome end-to-end (`browser_e2e.mjs`) passed has NOT been confirmed; a leftover Chrome profile from 2026-10-07 14:19 only shows it was started.

## Shortest live test (once the Mac is idle)
1. `launchctl list | grep raven` shows the job; `tail -n 5 ~/Library/Logs/BIFROST/raven-bridge.log` shows no new `edge unreachable`.
2. `./bifrostctl raven-pair`, open the copied link on your iPhone: the node badge should show online.
3. Press Keep awake (30 min), check `pmset -g assertions` for a `caffeinate` child of the bridge, press Release, check it is gone.
4. Optional: the Chrome script in Level 3.

## Troubleshooting
- `edge unreachable` repeating while other sites work: check `curl -s https://lucas-raven.pages.dev/api/health`; if that answers, restart the bridge (`launchctl kickstart -k gui/$(id -u)/eden.bifrost.raven-bridge`).
- 401 from every call: edge secrets `OPERATOR_KEY_SHA256` / `NODE_KEY_SHA256` do not match the Keychain keys (`./bifrostctl raven-hash node|operator`).
- Action stays `queued`: node offline (no state for 90 s) or bridge not claiming; queued actions expire after 120 s, claimed ones fail after 600 s.

## Multi-user edge and cloud node (2026-10-08)
Evidence ceiling is TESTED offline. Run from the repository root:
```sh
BIFROST/web/lucas-raven/tests/run_all.sh
python3 -B -m unittest discover -s BIFROST/tests -v
```
The node suite covers catalog parity/validation, JWT signature and claim failures, legacy-node isolation, and cloud handler isolation/error states. Browser, Cloudflare Access policy, remote D1, Pages, cron, GitHub and physical Mac/iPhone behavior remain UNKNOWN until Lucas follows `RAVEN_ACCESS_SETUP.md`.

Migration idempotence check (offline SQLite):
```sh
rm -f /tmp/raven-migration-test.sqlite
sqlite3 /tmp/raven-migration-test.sqlite < BIFROST/web/lucas-raven/schema.sql
sqlite3 /tmp/raven-migration-test.sqlite < BIFROST/web/lucas-raven/migrations/0002_multiuser.sql
sqlite3 /tmp/raven-migration-test.sqlite < BIFROST/web/lucas-raven/migrations/0002_multiuser.sql
```
