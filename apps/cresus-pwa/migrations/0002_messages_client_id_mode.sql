-- Migrate, do not reset: adds retry-safety and mode columns to an existing database.
ALTER TABLE messages ADD COLUMN client_id TEXT;
ALTER TABLE messages ADD COLUMN mode TEXT;
CREATE INDEX IF NOT EXISTS idx_msg_client ON messages(conversation_id, client_id);
