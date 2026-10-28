AppleRAVEN — MacBook Air M1 Setup Candidate
28 October 2026 | Owner-private, no sudo or public ports

WHAT THIS PACKAGE DOES
- Installs one small AppleRAVEN Mac agent into your own ~/Library folder.
- Keeps existing installations, RDC, BIFROST, Tailscale, macOS settings and Apple credentials intact.
- Asks whether you want to pair the Mac; you decide.
- Uses the already-deployed AppleRAVEN device Worker and the protected /pair webpage.
- Saves an approved device credential in your local macOS login Keychain.
- Once paired, attempts to start the local agent at login using launchctl.
- The only allowed native action is listing your Shortcuts (read-only).

QUICK START ON THE MAC (NOT ON YOUR IPHONE)
1. Download and unzip AppleRAVEN-Mac-M1-Setup-20261028.zip onto your MacBook Air M1.
2. Double-click AppleRAVEN-Mac-Setup.command. If macOS prevents opening it,
   use Finder Control-click > Open for this file only after verifying the package.
3. In Terminal, read the checks and enter 'y' when asked to begin pairing.
4. Open https://appleraven-private.lucasravensnest.workers.dev/pair in your browser.
   Sign in as the existing AppleRAVEN owner using Cloudflare Access one-time email verification.
5. Enter the pairing code shown by Terminal; approve only your MacBook Air.
6. Return to Terminal. On success, the setup loads the background agent.
   It is not accepted as a connected Mac until the private MCP reports an
   online device and an actual Shortcuts-list result is returned.

IF THE MAC HAS AN EXISTING APPLE RAVEN AGENT
This installer refuses to overwrite an unrecognized agent or LaunchAgent. It
will reuse an identical installed candidate without deleting your Keychain.

ENVIRONMENT
- Apple Silicon (arm64), normal signed-in macOS user session.
- Python >=3.9 must already be available via `python3`.
- Working outbound HTTPS, Cloudflare Access owner email OTP login in browser.
- No local admin / sudo / Xcode / Homebrew / Node required for this candidate.
- No arbitrary shell, VNC, Mail, Messages or Photos permissions included.

STATUS / RECOVERY
- AppleRAVEN-Mac-Setup.command --dry-run (syntax/delivery smoke test)
- Source agent file after installation:
  ~/Library/Application Support/AppleRAVEN/agent.py
- macOS service label: com.lucasbuzek.appleraven.agent
- Logs: ~/Library/Logs/AppleRAVEN.log and AppleRAVEN.error.log
- To verify paired status (in macOS Terminal):
  python3 "$HOME/Library/Application Support/AppleRAVEN/agent.py" --status
- To check the service:
  launchctl print "gui/$(id -u)/com.lucasbuzek.appleraven.agent"
- If setup reports failure, retain files and send the *non-secret* error message.
  Do not share pairing codes, owner OTPs, device tokens or raw logs containing secrets.

LIMITATIONS
- This is an install-and-pair candidate, not a signed/notarized .app or .dmg.
- Cloudflare owner sign-in and physical M1 pairing require actions on the actual Mac.
- Source tests are mocked; no actual Mac native-action acceptance has occurred.
- This file is not ChatGPT iOS remote custom MCP installation.
- The external original create-dmg project packages an existing macOS .app;
  it cannot package this .command into a notarized app by itself.

28 October repair: result payload is bounded to the deployed 2048-byte request limit; oversized listings explicitly report truncation. HTTP redirects are refused. Seven targeted regression tests pass in Linux; physical macOS acceptance remains unverified.
