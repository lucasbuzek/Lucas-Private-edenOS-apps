CREATE TABLE IF NOT EXISTS users (
  email       TEXT PRIMARY KEY,
  role        TEXT NOT NULL DEFAULT 'member',   -- 'admin' | 'member'
  status      TEXT NOT NULL DEFAULT 'active',   -- 'active' | 'disabled'
  added_by    TEXT,
  created_at  TEXT NOT NULL DEFAULT (datetime('now')),
  last_seen   TEXT
);

CREATE TABLE IF NOT EXISTS settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
INSERT OR IGNORE INTO settings (key, value) VALUES ('max_users', '2');
INSERT OR IGNORE INTO settings (key, value) VALUES ('daily_message_limit', '40');

CREATE TABLE IF NOT EXISTS conversations (
  id          TEXT PRIMARY KEY,
  email       TEXT NOT NULL,
  title       TEXT NOT NULL DEFAULT 'New chat',
  created_at  TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at  TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_conv_email ON conversations(email, updated_at DESC);

CREATE TABLE IF NOT EXISTS messages (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  conversation_id TEXT NOT NULL,
  role            TEXT NOT NULL,               -- 'user' | 'assistant'
  content         TEXT NOT NULL,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  client_id       TEXT,                        -- idempotency key for retried sends
  mode            TEXT                         -- simple | expert | zacchaeus | strategy | council
);
CREATE INDEX IF NOT EXISTS idx_msg_conv ON messages(conversation_id, id);
CREATE INDEX IF NOT EXISTS idx_msg_client ON messages(conversation_id, client_id);

CREATE TABLE IF NOT EXISTS usage (
  email TEXT NOT NULL,
  day   TEXT NOT NULL,
  count INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (email, day)
);
