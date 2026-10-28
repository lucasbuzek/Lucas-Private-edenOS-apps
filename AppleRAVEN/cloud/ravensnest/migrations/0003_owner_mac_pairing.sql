-- AppleRAVEN additive one-use owner-approved Mac enrollment.
-- Reuse existing users, devices, grants, node_state and actions; never seed fake data.
CREATE TABLE IF NOT EXISTS appleraven_pair_challenges (
 id TEXT PRIMARY KEY,
 code_hash TEXT UNIQUE NOT NULL,
 client_proof TEXT NOT NULL,
 device_name TEXT NOT NULL,
 created_at INTEGER NOT NULL,
 expires_at INTEGER NOT NULL,
 approved_by TEXT REFERENCES users(id),
 approved_at INTEGER,
 redeemed_at INTEGER,
 device_id TEXT UNIQUE
);
CREATE INDEX IF NOT EXISTS appleraven_pair_expiry ON appleraven_pair_challenges(expires_at,redeemed_at);
