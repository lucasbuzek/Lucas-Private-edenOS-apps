-- Lucas Raven edge state. Holds representation/queue state only;
-- BIFROST node and specialist Apps remain the authoritative owners.
CREATE TABLE IF NOT EXISTS node_state (
  node_id    TEXT PRIMARY KEY,
  meta       TEXT NOT NULL,
  state      TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS actions (
  id           TEXT PRIMARY KEY,
  node_id      TEXT NOT NULL,
  capability   TEXT NOT NULL,
  params       TEXT NOT NULL,
  status       TEXT NOT NULL,          -- queued | claimed | succeeded | failed | expired
  origin       TEXT,                   -- provenance: requesting client summary
  created_at   INTEGER NOT NULL,
  claimed_at   INTEGER,
  completed_at INTEGER,
  result       TEXT
);

CREATE INDEX IF NOT EXISTS actions_queue ON actions (node_id, status, created_at);
