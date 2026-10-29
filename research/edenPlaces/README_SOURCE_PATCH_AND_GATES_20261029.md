# edenPlaces / Dropbox Lite — source-scoped local account labels (candidate, 2026-10-29)

**Status: PATCH CREATED, CONTEXT-APPLY VERIFIED, ISOLATED SWIFT TESTS PASS; NOT APPLIED TO MAC / NOT A RELEASE.**

## Existing authority / scope
This is an incremental optional patch for the pre-existing Dropbox Lite Swift Package at `~/edenOS/Software Development/Dropbox Lite`, **not** a new app, daemon, storage engine, installer, server, online portal, or Git LKG. The research-original was obtained via the owner-provided Dropbox shared archive `#AI toolkit/Dropbox Lite/Sources/DropboxLiteApp/DropboxLiteApp.swift`, 679 lines at inspection. Its current Mac checkout, dirty state, binary and LKG were not verified; do not apply this patch to an uninspected Mac checkout. The existing v0.4.2 Bible, source, release and backup remain untouched.

## Research-to-code files
- `DropboxLiteApp-local-nickname-20261029.patch`: 5 exact source-backed unified hunks adding local nickname state and editing controls to original SwiftUI Accounts panel. GNU-patch-style hunks reconciled against original Dropbox text, including proper coordinates; source-context match verified for all hunks.
- `AccountNicknamePolicy.swift`: copy to the existing package's `Sources/DropboxLiteCore/` **only after** current Mac state/backups and patch context are checked.
- `AccountNicknamePolicyTests.swift`: copy to the original `Tests/DropboxLiteCoreTests/` at that same authorized staged update.

The GitHub research folder is intentionally not a second runnable Dropbox Lite package. Review/apply to true owner source only after backup verification and a diff from active Mac source. No system/global Rclone config rewrites, accounts renamed, OAuth requested, folders scanned or data transferred.

## Functionality being added
- User-provided *local nickname* keyed by `RemoteSource.rawValue + "|" + remote.name`, separately for managed vs system remotes.
- Nicknames are display-only and explicitly show “local label” and “owner unverified”. They do **not** claim provider account identity or deduplicate five opaque remotes into two users.
- Nickname validation: max 48 Unicode characters, trim surrounding whitespace; reject control and bidi override/isolate characters. Reject invalid remote names or source qualifiers. Empty nickname removes a local label.
- Local persistence in `UserDefaults.standard` under `DropboxLite.accountNicknames.v1`; non-secret user-facing labels only, not credentials, grants or account tokens.
- Existing exact remote IDs, account-switch permission revocation, OFF-by-default auto-sync, non-Dropbox transfer failure, and all Rclone operations unchanged.
- The button for non-Dropbox provider sign-in remains informational and is **not** represented as working. Provider-specific permissioned account verification and real Google Drive are separately unimplemented gates.

## Evidence
- Origin: direct Dropbox `fetch` of `PROJECT_BIBLE.md`, `Models.swift`, `RcloneEngine.swift`, `DropboxAuthorization.swift`, `DropboxLiteApp.swift`, existing tests.
- Rclone official `config userinfo` exists but source inspection of `backend/dropbox/dropbox.go` and `backend/drive/drive.go` did **not** reveal the `UserInfo` capability needed to rely on it for those two providers; no incorrect “verified email” feature was added.
- Swift 6.2.1 x86_64 Linux, isolated package containing new policy source and four XCTest functions: **4 passed / 0 failures** (2026-10-29 19:55 UTC); tests cover stable source-qualified keys, malformed remote/source rejection, normalization, maximum length, control/bidi spoof rejection. **Not** full existing macOS Swift package build/Xcode/iPhone tests.
- Exact patch application simulation against original 679-line archived SwiftUI source: all **5 hunks match** source, yielding 718 lines, 39-line net addition, and no alteration to original Rclone execution/transfer methods. This is not real compilation of AppKit/SwiftUI, Mac physical UX, account authentication or network acceptance.
- Existing Cloudflare `workaicloud-preview` Worker source has RS256 Cloudflare Access JWT signature verification, audience+issuer+email+expiration checks, and limited task/reference `/mcp`; **not** remotely proven to authorize independent ChatGPT/iOS MCP client integrations. Public anonymous requests via web open could not be checked. Vercel connected project listing showed only `raven-archive-knowledge-preview` (not edenPlaces) — do not deploy to unrelated project.

## Accepted next gates
1. Reconcile the live original Mac project/Bible, dirty state, actual two Dropbox accounts, five Rclone remote aliases, and verified LKG/snapshot.
2. Stage the code in that original checkout and run `swift test` (full suite) and a native macOS build; confirm real label editing/persistence in menu bar and account-switch no-grant inheritance.
3. Implement actual account user verification via supported provider API/permissions only, keeping credentials in Keychain/Rclone-owned storage; test revoked/expired/session-change behavior.
4. Implement non-Dropbox browser connectors with owner-granted OAuth and negative cross-tenant ACL, mobile file browse/read/download, remote MCP OAuth compatibility; verify source/data recovery and rollback before release.

**No live Cloudflare/Vercel deployment, public sharing change, Mac native source overwrite, original Dropbox Lite account configuration change, or actual user file transfer occurred.**
