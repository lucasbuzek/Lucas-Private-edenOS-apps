CREATE TABLE IF NOT EXISTS intelligence_preferences (
  email TEXT PRIMARY KEY,
  provider TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);