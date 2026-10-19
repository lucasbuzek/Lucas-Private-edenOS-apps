import {createSoftwareSharingBackend} from './backend.mjs';
import {createD1SharingRateLimit} from './rate-limit.mjs';
import {d1WaitlistStore} from '../closed-testing/d1.mjs';
import {createTurnstileVerifier} from '../closed-testing/turnstile.mjs';
import {validateSharingCatalog} from './catalog.mjs';

/**
 * Public REQUEST gateway only, never app access or software downloads.
 * Cloudflare Pages can forward /software and /api/software-sharing/request to
 * a dedicated Worker, with an independently scoped sharing-only D1 database.
 */
export function createCloudflareSoftwareSharingWorker({catalog, fetchImpl=fetch}={}) {
  if(!validateSharingCatalog(catalog).ok||typeof fetchImpl!=='function') {
    throw new TypeError('Reviewed request-only catalog and verification transport required');
  }
  return Object.freeze({
    async fetch(request,env) {
      if(typeof env?.SOFTWARE_REQUEST_HOST!=='string'||!env.SOFTWARE_REQUEST_HOST.trim()||
        typeof env?.SOFTWARE_TURNSTILE_SITE_KEY!=='string'||!env.SOFTWARE_TURNSTILE_SITE_KEY.trim()||
        typeof env?.SOFTWARE_TURNSTILE_SECRET!=='string'||!env.SOFTWARE_TURNSTILE_SECRET.trim()||
        typeof env?.SOFTWARE_QUEUE_DB?.prepare!=='function') {
        return new Response('Private invitation service unavailable', {status:503,
          headers:{'cache-control':'no-store'}});
      }
      try{
        const notifyOwner=typeof env.REQUEST_ALERTS?.send==='function'
          ? async request=>env.REQUEST_ALERTS.send({
              type:'software-invitation-pending',appId:request.appId,
              // Email stays in the private queue, not in external transport.
            })
          : undefined;
        const queue=createSoftwareSharingBackend({
          catalog,requestHost:env.SOFTWARE_REQUEST_HOST,
          turnstileSiteKey:env.SOFTWARE_TURNSTILE_SITE_KEY,
          verifyTurnstile:createTurnstileVerifier({
            secret:env.SOFTWARE_TURNSTILE_SECRET,
            expectedHostname:env.SOFTWARE_REQUEST_HOST,
            expectedAction:'software-share',
            fetchImpl,
          }),
          rateLimit:createD1SharingRateLimit({db:env.SOFTWARE_QUEUE_DB}),
          store:d1WaitlistStore(env.SOFTWARE_QUEUE_DB),
          notifyOwner,
        });
        return await queue.fetch(request);
      }catch{
        return new Response('Private invitation service unavailable',{
          status:503,headers:{'cache-control':'no-store'}});
      }
    },
  });
}
