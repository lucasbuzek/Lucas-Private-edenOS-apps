/** Atomic D1 rate counter. Uses only SHA-256 hashed keys, never raw IP/email. */
export function createD1SharingRateLimit({db,clock=()=>Date.now(),ipHourlyLimit=12,emailDailyLimit=4}={}) {
  if(!db || typeof db.prepare!=='function' || typeof clock!=='function' ||
      !Number.isSafeInteger(ipHourlyLimit)||ipHourlyLimit<1||
      !Number.isSafeInteger(emailDailyLimit)||emailDailyLimit<1) {
    throw new TypeError('Valid sharing-only D1 and explicit positive quotas required');
  }
  return async key=>{
    if(typeof key!=='string'||!/^share:(source|email):[a-f0-9]{64}$/.test(key))return false;
    const source=key.startsWith('share:source:');
    const now=clock();
    if(!Number.isFinite(now)||now<0)return false;
    const bucket=Math.floor(now/(source?3600000:86400000));
    const maximum=source?ipHourlyLimit:emailDailyLimit;
    const response=await db.prepare(
      'INSERT INTO share_rate_limits(key_hash,bucket,request_count) VALUES (?,?,1) '+
      'ON CONFLICT(key_hash,bucket) DO UPDATE SET request_count=request_count+1 '+
      'WHERE request_count < ?'
    ).bind(key,bucket,maximum).run();
    return Number(response?.meta?.changes||0)===1;
  };
}
