-- AppleRAVEN source MCP federation.
-- Additive migration. No existing tables, users, grants or commands are dropped.
-- Run against the AppleRAVEN D1 database before deploying unified Workers.
CREATE TABLE IF NOT EXISTS appleraven_provider_tools (
 node_id TEXT NOT NULL REFERENCES devices(id),
 tool_name TEXT NOT NULL,
 description TEXT NOT NULL,
 schema_json TEXT NOT NULL CHECK(json_valid(schema_json)),
 updated_at INTEGER NOT NULL,
 PRIMARY KEY (node_id,tool_name)
);
CREATE TABLE IF NOT EXISTS appleraven_proxy_commands (
 id TEXT PRIMARY KEY,
 node_id TEXT NOT NULL REFERENCES devices(id),
 owner_id TEXT NOT NULL REFERENCES users(id),
 tool_name TEXT NOT NULL,
 args_json TEXT NOT NULL CHECK(json_valid(args_json)),
 status TEXT NOT NULL DEFAULT 'queued' CHECK(status IN ('queued','claimed','done','expired','failed')),
 result_json TEXT CHECK(result_json IS NULL OR json_valid(result_json)),
 is_error INTEGER NOT NULL DEFAULT 0,
 created_at INTEGER NOT NULL,
 claimed_at INTEGER,
 completed_at INTEGER,
 expires_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_appleraven_proxy_work ON appleraven_proxy_commands(node_id,status,created_at);
CREATE INDEX IF NOT EXISTS idx_appleraven_proxy_owner ON appleraven_proxy_commands(owner_id,created_at);
