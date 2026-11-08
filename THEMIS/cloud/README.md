# THEMIS Cloud access variant

This is an additive Cloudflare Worker access variant of the **existing THEMIS application**, not a new legal product. The original Python store and prior LKG remain unchanged.

Cloud backend: dedicated SQLite-backed Durable Object per owner; no shared D1 database. 12 canonical record kinds, revision-checked updates, audit trail, checksum snapshots and explicit guarded rollback. Owner-private web UI. The MCP Streamable HTTP endpoint at `/mcp` requires the owner bearer key; web uses a signed 12-hour HttpOnly session.

Cloudflare free-tier SQLite Durable Objects support is documented at https://developers.cloudflare.com/durable-objects/ . Do not place OWNER_HASH or owner secret in Git. Set the Worker secret `OWNER_HASH` to SHA-256 hexadecimal digest of a high-entropy owner password. Without it, all private routes fail closed (503).

Worker metadata: `main_module:worker.mjs`, second module `ui.js`, `bindings:[{type:'durable_object_namespace',name:'THEMIS_VAULT',class_name:'ThemisVault'}]`, `migrations:{new_tag:'v1',new_sqlite_classes:['ThemisVault']}` for first creation. Do not reapply the new class migration on subsequent updates.

MCP tools: themis_list_records, themis_get_record, themis_create_record, themis_update_record, themis_list_snapshots, themis_create_snapshot. Server returns JSON-RPC over POST /mcp. No general-purpose AI model or legal authority is falsely claimed. HTTPS + owner authentication is required. This version does not automatically synchronize with the local Python store; the shared record contract is compatible but migrations/sync are not yet acceptance-tested.

Document generation here exports Word-editable HTML `.doc`, not DOCX and not a recreation of the original 19-page 31-Oct document. Real DOCX/full original workflow remains a separate acceptance gate.
