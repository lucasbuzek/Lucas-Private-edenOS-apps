-- BIFROST cloud-control routing metadata, staging only.
-- Authority: BIFROST/core/shortcalls.v1.json and approved project contract.
-- This database does not replace the local ledger or authorize execution.
-- No tokens, raw prompts, shell commands, file contents, or credentials stored.
-- Apply only to the verified empty bifrost_control_staging D1 database.

CREATE TABLE IF NOT EXISTS cloud_nodes (
  node_id TEXT PRIMARY KEY,
  owner_subject TEXT NOT NULL,
  display_name TEXT NOT NULL,
  platform TEXT NOT NULL,
  trust_state TEXT NOT NULL DEFAULT 'unpaired'
    CHECK (trust_state IN ('unpaired', 'paired', 'revoked')),
  connectivity TEXT NOT NULL DEFAULT 'offline'
    CHECK (connectivity IN ('offline', 'online', 'unknown')),
  paired_at INTEGER,
  last_seen_at INTEGER,
  created_at INTEGER NOT NULL DEFAULT (unixepoch())
);

CREATE TABLE IF NOT EXISTS cloud_capabilities (
  action_id TEXT NOT NULL,
  node_id TEXT NOT NULL,
  effect TEXT NOT NULL
    CHECK (effect IN ('read', 'write', 'install', 'permission', 'workflow', 'destructive')),
  implementation_state TEXT NOT NULL DEFAULT 'unverified'
    CHECK (implementation_state IN ('unverified', 'verified', 'disabled')),
  requires_approval INTEGER NOT NULL DEFAULT 1
    CHECK (requires_approval IN (0, 1)),
  last_verified_at INTEGER,
  PRIMARY KEY (action_id, node_id),
  FOREIGN KEY (node_id) REFERENCES cloud_nodes(node_id)
);

CREATE TABLE IF NOT EXISTS cloud_tasks (
  task_id TEXT PRIMARY KEY,
  owner_subject TEXT NOT NULL,
  action_id TEXT NOT NULL,
  target_node_id TEXT NOT NULL,
  idempotency_key TEXT NOT NULL,
  state TEXT NOT NULL DEFAULT 'queued'
    CHECK (state IN ('queued','leased','running','completed','failed','cancelled','expired','blocked')),
  effect TEXT NOT NULL
    CHECK (effect IN ('read','write','install','permission','workflow','destructive')),
  approval_ref TEXT,
  params_sha256 TEXT,
  provider_task_id TEXT,
  created_at INTEGER NOT NULL DEFAULT (unixepoch()),
  updated_at INTEGER NOT NULL DEFAULT (unixepoch()),
  expires_at INTEGER NOT NULL,
  lease_until INTEGER,
  attempts INTEGER NOT NULL DEFAULT 0 CHECK (attempts BETWEEN 0 AND 3),
  effects_verified INTEGER NOT NULL DEFAULT 0 CHECK (effects_verified IN (0, 1)),
  UNIQUE(owner_subject, idempotency_key),
  FOREIGN KEY (target_node_id) REFERENCES cloud_nodes(node_id),
  FOREIGN KEY (action_id, target_node_id) REFERENCES cloud_capabilities(action_id, node_id)
);

CREATE TABLE IF NOT EXISTS cloud_receipts (
  receipt_id TEXT PRIMARY KEY,
  task_id TEXT NOT NULL UNIQUE,
  executor_node_id TEXT NOT NULL,
  provider_task_id TEXT,
  observed_state TEXT NOT NULL CHECK (observed_state IN ('completed', 'failed', 'cancelled')),
  effects_verified INTEGER NOT NULL DEFAULT 0 CHECK (effects_verified IN (0,1)),
  evidence_sha256 TEXT,
  received_at INTEGER NOT NULL DEFAULT (unixepoch()),
  FOREIGN KEY (task_id) REFERENCES cloud_tasks(task_id),
  FOREIGN KEY (executor_node_id) REFERENCES cloud_nodes(node_id)
);

CREATE TABLE IF NOT EXISTS cloud_audit (
  event_id TEXT PRIMARY KEY,
  task_id TEXT,
  actor_class TEXT NOT NULL CHECK (actor_class IN ('owner','device','service')),
  event_type TEXT NOT NULL,
  recorded_at INTEGER NOT NULL DEFAULT (unixepoch()),
  FOREIGN KEY (task_id) REFERENCES cloud_tasks(task_id)
);

CREATE INDEX IF NOT EXISTS cloud_nodes_online ON cloud_nodes(trust_state, connectivity, last_seen_at);
CREATE INDEX IF NOT EXISTS cloud_tasks_dispatch ON cloud_tasks(state, target_node_id, expires_at);
CREATE INDEX IF NOT EXISTS cloud_tasks_owner_recent ON cloud_tasks(owner_subject, created_at DESC);
CREATE INDEX IF NOT EXISTS cloud_audit_task_time ON cloud_audit(task_id, recorded_at DESC);

-- Invariants for the eventual authenticated route handler:
-- 1. Fail closed until human/device identities are independently verified.
-- 2. Admit only canonical shortNameCall IDs with verified node capability.
-- 3. Require policy approval for effectful actions; no raw shell/MCP passthrough.
-- 4. Atomically lease a queued task; honor expiration/cancel/revoke.
-- 5. Executor attests a provider task ID and observed receipt. A route ACK
--    is never a verified device effect.
-- 6. Keep payloads outside this metadata database until encryption/grants
--    and retention policy are independently tested.
-- 7. No workers route is public without authentication; health may be
--    minimal and redacted. This file does not deploy a Worker.