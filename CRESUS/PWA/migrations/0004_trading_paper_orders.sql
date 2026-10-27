-- Apply only to a backed-up staging D1 instance after provenance/LKG gate.
-- Additive only: never alters existing portfolios, conversations or provider preferences.
CREATE TABLE IF NOT EXISTS trading_paper_orders (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  payload_json TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_trading_paper_orders_email ON trading_paper_orders(email, created_at DESC);
