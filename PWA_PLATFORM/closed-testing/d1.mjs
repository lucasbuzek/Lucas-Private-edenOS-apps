const EMAIL = /^[A-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?(?:\.[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?)+$/i;
export function normalizeEmail(value) {
  if (typeof value !== 'string' || value.length > 254) return null;
  const email = value.trim().toLowerCase();
  return email.length <= 254 && EMAIL.test(email) ? email : null;
}

/** D1 database dedicated to a single app, with app_id constrained on every read/write. */
export function d1WaitlistStore(db) {
  if (!db || typeof db.prepare !== 'function') throw new TypeError('Dedicated waitlist D1 binding is required');
  return Object.freeze({
    async request(appId, email) {
      await db.prepare(
        "INSERT OR IGNORE INTO pwa_waitlist (app_id,email,status) VALUES (?,?,'pending')"
      ).bind(appId,email).run();
    },
    async isApproved(appId, email) {
      const row = await db.prepare(
        "SELECT status FROM pwa_waitlist WHERE app_id=? AND email=?"
      ).bind(appId,email).first();
      return row?.status === 'approved';
    },
    async list(appId) {
      const r = await db.prepare(
        "SELECT email,status,requested_at,reviewed_at,reviewed_by FROM pwa_waitlist WHERE app_id=? ORDER BY requested_at DESC LIMIT 200"
      ).bind(appId).all();
      return Array.isArray(r?.results) ? r.results : [];
    },
    async decide(appId,email,decision,reviewer) {
      const status=decision==='approve'?'approved':decision==='deny'?'denied':null;
      if (!status) throw new Error('Decision must approve or deny');
      const result=await db.prepare(
        "UPDATE pwa_waitlist SET status=?,reviewed_at=datetime('now'),reviewed_by=? WHERE app_id=? AND email=?"
      ).bind(status,reviewer,appId,email).run();
      return (result?.meta?.changes || 0)>0;
    },
  });
}
