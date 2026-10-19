export function createTurnstileVerifier({ secret, expectedHostname, expectedAction = 'waitlist', fetchImpl = fetch } = {}) {
  if (typeof secret !== 'string' || !secret.trim() ||
      typeof expectedHostname !== 'string' || !expectedHostname.trim() ||
      typeof expectedAction !== 'string' || !/^[a-z][a-z0-9-]{0,31}$/.test(expectedAction)) {
    throw new TypeError('A private Turnstile secret and exact public waitlist hostname are required');
  }
  return async (token, request) => {
    if (typeof token !== 'string' || token.length < 10 || token.length > 2048) return false;
    try {
      const payload = new URLSearchParams({secret, response:token});
      const ip = request?.headers?.get?.('CF-Connecting-IP');
      if (ip) payload.set('remoteip',ip);
      const r=await fetchImpl('https://challenges.cloudflare.com/turnstile/v0/siteverify',{
        method:'POST',headers:{'content-type':'application/x-www-form-urlencoded'},
        body:payload.toString(),redirect:'error',signal:AbortSignal.timeout(10000),
      });
      if (!r.ok) return false;
      const data=await r.json();
      return data?.success===true && data.hostname===expectedHostname &&
        data.action===expectedAction;
    } catch { return false; }
  };
}
