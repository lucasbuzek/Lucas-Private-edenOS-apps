-- Additive Raven chat counters and metadata-only audit. Safe to run repeatedly.
CREATE TABLE IF NOT EXISTS chat_daily (day INTEGER PRIMARY KEY, count INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS chat_user_minute (subject TEXT NOT NULL, minute INTEGER NOT NULL, count INTEGER NOT NULL, PRIMARY KEY(subject, minute));
CREATE TABLE IF NOT EXISTS chat_audit (
  id INTEGER PRIMARY KEY AUTOINCREMENT, ts INTEGER NOT NULL, subject TEXT NOT NULL,
  intent TEXT, topic TEXT, capability TEXT, outcome TEXT NOT NULL,
  provider TEXT NOT NULL, latency_ms INTEGER NOT NULL, handoff_excerpt TEXT
);
CREATE INDEX IF NOT EXISTS chat_audit_ts ON chat_audit(ts DESC);
