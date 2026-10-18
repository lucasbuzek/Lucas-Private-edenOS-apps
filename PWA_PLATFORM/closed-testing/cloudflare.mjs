import { createCloudflareAccessAuthenticator } from '../authentication/jwt.mjs';
import { createTurnstileVerifier } from './turnstile.mjs';
import { d1WaitlistStore } from './d1.mjs';
import { cresusWaitlistStore } from './cresus-store.mjs';
import { createClosedTestingGateway } from './gateway.mjs';

/**
 * Instantiated as its own Worker for EACH pilot: no shared database or origin.
 * HERMES uses an internal ASSETS binding with run_worker_first = true.
 * CRESUS uses APP service binding to the existing private CRESUS Worker.
 */
export function createCloudflareClosedTestWorker({ appId, appName } = {}) {
  if (!/^[a-z][a-z0-9-]+$/.test(appId || '') || !appName) {
    throw new TypeError('Exact independent application identity is required');
  }
  return Object.freeze({
    async fetch(request, env) {
      // Never serve the application from an unconfigured or direct workers.dev origin.
      const required = ['PRIVATE_HOST','WAITLIST_HOST','OWNER_EMAIL','ACCESS_TEAM_DOMAIN',
        'ACCESS_AUD','TURNSTILE_SECRET','TURNSTILE_SITE_KEY'];
      if(required.some(key=>typeof env?.[key]!=='string' || !env[key].trim()) ||
         !env.GATE_DB || typeof env.GATE_DB.prepare!=='function') {
        return new Response('Closed testing is not configured', {status:503,
          headers:{'cache-control':'no-store'}});
      }
      const mode=env.PRIVATE_UPSTREAM_MODE;
      if(mode!=='assets' && mode!=='service')return new Response('Private origin unavailable',{status:503});
      if(mode==='assets' && typeof env.ASSETS?.fetch!=='function')return new Response('Private assets unavailable',{status:503});
      if(mode==='service' && typeof env.APP?.fetch!=='function')return new Response('Private app service unavailable',{status:503});

      try {
        const authenticate=createCloudflareAccessAuthenticator({
          appId,teamDomain:env.ACCESS_TEAM_DOMAIN,audience:env.ACCESS_AUD,
          // The gateway makes the final app/ledger authorization AFTER cryptographic JWT verification.
          authorize:async()=>({allowed:true}),
        });
        const gate=createClosedTestingGateway({
          appId,appName,
          ownerEmail:env.OWNER_EMAIL,
          privateHost:env.PRIVATE_HOST,
          waitlistHost:env.WAITLIST_HOST,
          turnstileSiteKey:env.TURNSTILE_SITE_KEY,
          verifyTurnstile:createTurnstileVerifier({
            secret:env.TURNSTILE_SECRET,
            expectedHostname:env.WAITLIST_HOST,
          }),
          authenticate,
          store:appId==='cresus' && env.WAITLIST_STORE==='cresus-users'
            ? cresusWaitlistStore(env.GATE_DB)
            : d1WaitlistStore(env.GATE_DB),
          appFetch:async incoming => mode==='service'
            ? env.APP.fetch(incoming)
            : env.ASSETS.fetch(incoming),
        });
        return await gate.fetch(request);
      } catch {
        return new Response('Closed testing security configuration invalid',{
          status:503,headers:{'cache-control':'no-store'},
        });
      }
    },
  });
}
