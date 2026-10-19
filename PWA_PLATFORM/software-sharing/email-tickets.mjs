const HEX = /^[a-f0-9]{64}$/;
const ID = /^[a-z][a-z0-9-]{1,58}$/;

export function createD1EmailTicketStore(db) {
  if (typeof db?.prepare !== 'function' || typeof db?.batch !== 'function')
    throw new TypeError('Dedicated, transactional D1 email ticket database is required');
  return Object.freeze({
    async issue({tokenHash,appId,releaseId,email,issuedAt,expiresAt}) {
      if(!HEX.test(tokenHash||'') || !ID.test(appId||'') || !ID.test(releaseId||'') ||
        typeof email!=='string' || !Number.isSafeInteger(issuedAt) ||
        !Number.isSafeInteger(expiresAt) || expiresAt<=issuedAt)
        throw new TypeError('Validated hash, approved release and expiry are required');
      // D1 batch operations are transactional; a new ticket invalidates earlier links
      // for this exact application and address without touching another app.
      await db.batch([
        db.prepare("UPDATE software_email_tickets SET revoked_at=? WHERE app_id=? AND email=? AND consumed_at IS NULL AND revoked_at IS NULL")
          .bind(issuedAt,appId,email),
        db.prepare("INSERT INTO software_email_tickets (token_hash,app_id,release_id,email,issued_at,expires_at) VALUES (?,?,?,?,?,?)")
          .bind(tokenHash,appId,releaseId,email,issuedAt,expiresAt),
      ]);
    },
    async consume(tokenHash,now) {
      if(!HEX.test(tokenHash||'')||!Number.isSafeInteger(now))return null;
      const result=await db.prepare(
        "UPDATE software_email_tickets SET consumed_at=? WHERE token_hash=? AND consumed_at IS NULL AND revoked_at IS NULL AND expires_at>? RETURNING app_id,release_id,email"
      ).bind(now,tokenHash,now).first();
      return result ? {appId:result.app_id,releaseId:result.release_id,email:result.email} : null;
    },
    async revoke(tokenHash,now) {
      if(!HEX.test(tokenHash||'')||!Number.isSafeInteger(now))return false;
      const result=await db.prepare(
        "UPDATE software_email_tickets SET revoked_at=? WHERE token_hash=? AND consumed_at IS NULL AND revoked_at IS NULL"
      ).bind(now,tokenHash).run();
      return Number(result?.meta?.changes||0)===1;
    },
    async revokeRecipient({appId,email,now}) {
      if(!ID.test(appId||'')||typeof email!=='string'||!Number.isSafeInteger(now))return false;
      const result=await db.prepare(
        "UPDATE software_email_tickets SET revoked_at=? WHERE app_id=? AND email=? AND consumed_at IS NULL AND revoked_at IS NULL"
      ).bind(now,appId,email).run();
      return Number(result?.meta?.changes||0)>=1;
    },
  });
}
