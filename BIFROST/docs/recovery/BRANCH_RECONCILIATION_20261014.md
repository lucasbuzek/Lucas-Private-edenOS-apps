# BIFROST GitHub branch reconciliation — 2026-10-14

Repository: `lucasbuzek/Lucas-Private-edenOS-apps` (private, accessible through connected GitHub integration).
Method: queried each branch's commit and full recursive tree; generated BIFROST-only path/SHA/size manifests; compared remote Git blob SHA against `/usr/bin/git hash-object` on the canonical local file. This does not require a local .git directory. All four remote trees were complete (`truncated=false`).

## Manifest evidence
Manifests are stored alongside this report:
- `GITHUB_BRANCH_MANIFESTS_20261014/native-consolidated.tsv`
- `GITHUB_BRANCH_MANIFESTS_20261014/task1-chatgpt-apple.tsv`
- `GITHUB_BRANCH_MANIFESTS_20261014/task2-native-host.tsv`
- `GITHUB_BRANCH_MANIFESTS_20261014/zero-cloud-task-gateway.tsv`

| Candidate | Commit | Remote BIFROST files | Local exact matches | Differences | Remote files absent locally |
|---|---|---:|---:|---:|---:|
| `bifrost/native-consolidated-20261010` | `d9c0e0539694d7d1885f6d45cbe10df2fd484cef` | 42 | 38 | 4 | 0 |
| `bifrost/task1-chatgpt-apple-20261005` | `48f611dbe627a6f96f8874a875d52233874ea316` | 53 | 6 | 9 | 38 |
| `bifrost/task2-native-host-20261005` | `cb8bca61a9d28498f226ab2073059cb9f67c1872` | 27 | 0 | 1 | 26 |
| `bifrost/zero-cloud-task-gateway` | `367341148d4cafd59777156fe5565845e120ee83` | 10 | 0 | 1 | 9 |

## Interpretation
### Native consolidated
The current local native source lineage is strongly established: all 19 Swift source files, portable kernel, all current Headless/PWA assets, project.yml, and most tests exactly match the native-consolidated branch by Git blob SHA. The four differences are README.md plus three test fixtures:
- `tests/test_headless.py`
- `tests/test_platform_contract.py`
- `tests/test_pwa_adapter.py`

The three test differences align with the recorded local-only reverse-DNS fixture repair and updated architecture paths. The README has accumulated local project documentation. This is evidence of code lineage, not by itself a release/LKG promotion or proof that the remote branch is the newest complete authority.

### Task 1 — ChatGPT integration candidate
This branch is a distinct integration candidate. It adds a separate Apple Swift package, ChatGPT pane, local provider helper, OAuth/identity validation, Keychain-backed credentials, MCP adapter, and dedicated tests. The recovered intent routes through an injected authorized closure; the current branch does not prove it is wired to a live authenticated BIFROST task API. The provider uses official hosted inference/Responses interfaces with explicit account eligibility/scope and can transmit user-approved files to the provider. This is not the same as Lucas's preferred silentChatGPT Shortcuts extension route. Do not copy or enable it automatically; first review eligibility, provider terms/cost/privacy, source lineage, exact dependency/package evidence, and compare against the established Apple Shortcuts canon.

### Task 2 — Native Host candidate
This branch adds a distinct owner-controlled native MCP/filesystem/process host with SQLite state, Keychain secrets, explicit folder grants and optional strict SSH stdio transport. It is a local/device executor, not a cloud router or general cloud coding agent. It must be reviewed for platform, SDK pinning, package cleanliness, permission scopes, actual filesystem/process tests, and owner UI integration before any adoption. Its files are absent from the current local workspace, so it must remain isolated until a testable candidate is prepared.

### ZERO cloud task gateway
This branch is a small Cloudflare-to-GitHub Issues handoff gateway. Its own README states that a GitHub issue is `QUEUED_FOR_EXECUTOR`, not a Codex execution; it does not start or monitor Codex. It needs a secure server-side authenticated session and scoped GitHub token. It is useful for queueing/audit only if that gap is desired; it cannot satisfy remote execution acceptance by itself.

## Decision
- Preserve the current native-consolidated-derived source and existing rollback snapshot.
- Do not merge branches or create a fifth architecture.
- Reuse only selected, reviewed capabilities: Task 1 provider only if it aligns with chosen ChatGPT interface and authorized account eligibility; Task 2 native host only for a defined local-node capability; ZERO gateway only as an explicitly queue-only adapter.
- Next integration milestone should be a stable typed task/receipt contract and durable ledger, then one real executor adapter whose actual provider submission/status/result can be independently verified. Cloudflare remains the control plane.
- No remote branches were changed; no code was merged/copied by this comparison.
