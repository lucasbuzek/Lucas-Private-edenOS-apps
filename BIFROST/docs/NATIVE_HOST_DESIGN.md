# Task 2 Native Host execution design
Authority: user Task 2 handoff, Project Bibles/BIFROST.txt and
RECONCILIATION_STATE.md recovered via connected GitHub.
Baseline: 2c50f36b9be6f88b80c322355e60f52820295e52; tree
7b4c9d8ce8a6fc4f26870b90117e21224a6fc19a. No verified runtime LKG recovered.
Task 1 branch/session is outside this workstream. No changes to remote_provider.py.

Native Host is a separate deterministic provider. Reuse official MCP Python SDK
1.26.0 (verified tagged source, established v1 API) for negotiation, schemas,
stdio and errors. The current upstream release is v2.3.0; a v2 migration requires
its own regression gate. Do not implement MCP framing ourselves.
Python stdlib supplies SQLite, subprocess supervision, POSIX descriptor-relative
filesystem operations, bounded search, transfers and diagnostics. Apple Keychain
uses keyring's explicit macOS backend; no fallback secret files.

Owner-only enrollment and scope changes are outside advertised MCP tools. A
trusted native UI asks the user, chooses folders, and invokes the local control
API. Authenticated sessions recheck revocation for every operation. Folder
permissions do not imply command confinement: exact argv/cwd/environment command
grants are separate authority. Commands run under the owner's OS privileges and
must explicitly be approved as such. No remote listener. Optional peer route
uses system OpenSSH with strict host verification; SSH login authorization and
BIFROST scopes are both required. Never enable macOS Remote Login automatically.

Filesystem uses pinned root identity plus openat-style dir_fd operations and
O_NOFOLLOW; forbid traversal, symlinks, hardlinks and special files. Bounded binary
read chunks; staged upload plus final atomic publish; write replacement/delete
requires a current digest and explicit destructive scope. No root/home defaults.

State is private owner-only SQLite, with stable host UUID, named devices, scoped
grants, exact approved command records, and metadata-only bounded audit records.
Bearer secrets exist only in Keychain/in-memory sessions. A capability adapter
exports stable neutral names and requires evidence gating before switching away
from RDC. Registration is not parity.

Tests assert actual filesystem effects, authorization failures, revoked sessions,
process stdout/stderr/exit/control and persistence. CI must test the actual pinned
MCP SDK with an independent SDK client, then package and clean-install test.
Native UI, Keychain, Spotlight, SSH/LAN and device gates remain UNKNOWN until run.
