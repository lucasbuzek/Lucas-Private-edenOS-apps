# BIFROSTcore — standalone ChatGPT MCP first-use candidate

**2026-10-26 · Draft PR #15 only · NOT INSTALLED · NOT PAIRED**

## Recovery and purpose

- Existing BIFROST Headless owns the service, browser UI and storage capability. This change **does not** introduce a second daemon, private profile database or storage engine.
- Added `headless/mcp_stdio.py` as an *on-demand process* that imports existing `core_runtime`, `storage_adapter`, `setup_manager`, and `first_use_accounts`.
- Existing BIFROST source and deployment/LKG are not replaced automatically by this branch. Owner/ForgeMASTER must compare current Mac tree and branch first.
- RDC is neither installed nor called by the new MCP subprocess. Previously recovered RDC labels in the optional `first_use_accounts` inspection are metadata only and not requirements for any bridge operation.

## Local stdio smoke — after owner-approved source reconciliation

```sh
python3 -B "$HOME/edenOS/Software Development/BIFROST/headless/mcp_stdio.py" <<'EOF'
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"BIFROST-test","version":"1"}}}
{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}
EOF
```

Production installer path, only **after** its actual installed runtime is verified:

```
~/Library/Application Support/BIFROST/HeadlessRuntime/headless/mcp_stdio.py
```

Use a supported MCP host with `python3 -B <absolute_path_to_mcp_stdio.py>` and private on-device process permissions; do not run as root. The existing BIFROST Headless Web UI is separate; no new HTTP port is opened by this stdio adapter.

## Tools (read-only)

`bifrost_status`, `bifrost_storage_providers`, `bifrost_storage_accounts`, `bifrost_storage_preview` (saved-profile local metadata only, no remote read), `bifrost_inspector`, `bifrost_installer` (catalog only), `bifrost_specialists` (PENELOPE/JANITOR unresolved handoff, never invoke), `bifrost_first_use_accounts` (existing labels only).

No copy, sync, delete, remote shell, account creation, port-forwarding, credential export, specialist invocation, install, restart or OS permission elevation through these tools. Cloud provider login remains separately authorized and verified.

## ChatGPT-to-Mac acceptance path

1. Owner reconciles this draft branch against the canonical Mac BIFROST source, dirty files and known-good build. Run the full existing BIFROST suite plus `python3 -B -m unittest discover -s tests -p test_mcp_stdio.py -v`; preserve the existing installed runtime.
2. On the Mac, launch the exact local MCP stdio process through a supported **Secure MCP Tunnel** (or an appropriately authenticated HTTPS MCP transport). Do not expose an unauthenticated local endpoint to the Internet or share tunnel credentials here.
3. Owner connects the corresponding custom MCP tool in ChatGPT and explicitly grants its read-only permissions.
4. In **this** ChatGPT conversation, invoke `bifrost_status`; record the actual tool result and source/runtime identity readback. A passing terminal smoke, source commit, ZIP, Web UI page or tunnel health indicator does *not* satisfy this gate.
5. Invoke `bifrost_storage_accounts`, then an explicitly authorized saved-profile preview; verify account isolation, denial, disconnect/reconnect, offline behavior and no side effects before expanding permissions or claiming RDC replacement.
6. Only then test optional HEIMDALL iOS/Shortcuts/Siri entry and separately approved PENELOPE/JANITOR actions. No remote execution is currently implemented by this adapter.

## Evidence & gating

- Local portable tests of equivalent source: **18 MCP tests PASS** in isolated Python, including stdio sequence, denial, existing adapter reuse and no shell/RDC calls. GitHub source & test file readback confirmed after commit. *Mac full-suite / live ChatGPT plugin/physical iOS acceptance remains UNKNOWN.*
- Project manager task: [Asana Priority 1 BIFROST](https://app.asana.com/1/1219873107425826/project/1219864291600755/task/1219884235752856).
- Candidate integration: [GitHub BIFROST draft PR #15](https://github.com/lucasbuzek/Lucas-Private-edenOS-apps/pull/15).
- Reused 2026-10-25 existing Headless storage, first-use account labels, no-clobber installer/source and Web UI. The separate 21 KB standalone prototype is *not* authoritative BIFROST.

EITRIMB: SOURCE_IMPLEMENTED + SANDBOX_TESTED (MCP adapter), DEVICE_LIVE UNKNOWN, PROVIDER_VERIFIED UNKNOWN, RELEASED NO.
