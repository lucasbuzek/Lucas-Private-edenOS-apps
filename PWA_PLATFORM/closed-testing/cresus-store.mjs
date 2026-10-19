/**
 * CRESUS-specific adapter that REUSES its existing app-owned users table
 * and admin approval statuses instead of introducing a duplicate identity ledger.
 * Applies only to the independently deployed CRESUS Worker pilot.
 */
export function cresusWaitlistStore(db) {
  if (!db || typeof db.prepare!=='function') throw new TypeError('CRESUS existing D1 binding required');
  return Object.freeze({
    async request(appId,email) {
      if(appId!=='cresus')throw new Error('CRESUS membership cannot be used for another app');
      await db.prepare(
        "INSERT OR IGNORE INTO users (email,role,status,added_by) VALUES (?, 'member', 'pending','waitlist')"
      ).bind(email).run();
    },
    async isApproved(appId,email) {
      if(appId!=='cresus')return false;
      const row=await db.prepare("SELECT status FROM users WHERE email=?").bind(email).first();
      return row?.status==='active';
    },
    async list(appId) {
      if(appId!=='cresus')return [];
      const result=await db.prepare(
        "SELECT email, status, created_at AS requested_at, NULL AS reviewed_at, added_by AS reviewed_by FROM users WHERE role!='admin' ORDER BY created_at DESC LIMIT 200"
      ).all();
      return Array.isArray(result?.results)?result.results:[];
    },
    async decide(appId,email,decision,reviewer) {
      if(appId!=='cresus')throw new Error('CRESUS membership cannot be updated by another app');
      const status=decision==='approve'?'active':decision==='deny'?'disabled':null;
      if(!status)throw new Error('Decision must approve or deny');
      const result=await db.prepare(
        "UPDATE users SET status=?, added_by=? WHERE email=? AND role='member'"
      ).bind(status,reviewer,email).run();
      return (result?.meta?.changes || 0)>0;
    },
  });
}
