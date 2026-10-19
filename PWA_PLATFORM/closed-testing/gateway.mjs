import { normalizeEmail } from './d1.mjs';

const enc = x => String(x ?? '').replace(/&/g,'&amp;').replace(/</g,'&lt;')
  .replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');
const json = (data,status=200) => new Response(JSON.stringify(data), {
  status, headers:{'content-type':'application/json;charset=utf-8','cache-control':'no-store',
    'x-content-type-options':'nosniff','referrer-policy':'no-referrer'},
});
const page = (html,status=200) => new Response(html,{
  status, headers:{'content-type':'text/html;charset=utf-8','cache-control':'no-store',
    'x-content-type-options':'nosniff','referrer-policy':'no-referrer',
    'content-security-policy':"default-src 'none'; style-src 'unsafe-inline'; script-src https://challenges.cloudflare.com; frame-src https://challenges.cloudflare.com; connect-src https://challenges.cloudflare.com; form-action 'self'; base-uri 'none'; frame-ancestors 'none'"},
});
const htmlShell = (title,inside) => '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>'+
  enc(title)+'</title><style>body{font:16px system-ui,sans-serif;max-width:720px;margin:6vh auto;padding:1.5rem;color:#21242a;line-height:1.5}main{padding:1.6rem;border:1px solid #d5d9e0;border-radius:16px}label{display:block;margin:.6rem 0}input,button{font:inherit;padding:.6rem;margin:.4rem .2rem .4rem 0}button{cursor:pointer}table{border-collapse:collapse;width:100%}td,th{padding:.5rem;border-bottom:1px solid #ddd;text-align:left}small{color:#555}</style><main>'+inside+'</main></html>';

function waitlistPage(appName,siteKey) {
  const body = '<h1>'+enc(appName)+' — closed testing</h1><p>Request an invitation using your email address. The administrator individually approves or denies each application. Submitting does not grant access.</p>'+
    '<form method="POST" action="/api/waitlist/request"><label>Email address <input name="email" type="email" autocomplete="email" maxlength="254" required></label>'+
    '<div class="cf-turnstile" data-sitekey="'+enc(siteKey)+'" data-action="waitlist"></div>'+
    '<button type="submit">Request access</button></form><small>Your address is used only to review your testing request. No account is created until approval and identity verification.</small>'+
    '<script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>';
  return htmlShell(appName+' waitlist',body);
}
function thanksPage(appName) {
  return htmlShell(appName+' waitlist','<h1>Request received</h1><p>If your submission is eligible, it will be reviewed by the administrator. Access is never automatic.</p>');
}
function adminPage(appName,rows) {
  let list = '<h1>'+enc(appName)+' — testing access</h1><p>Only the verified owner can approve or deny requests. Approval in this ledger is not proof of Cloudflare Access policy synchronization.</p><table><thead><tr><th>Email</th><th>Status</th><th>Decision</th></tr></thead><tbody>';
  for(const row of rows) {
    const email=enc(row.email);
    list+='<tr><td>'+email+'</td><td>'+enc(row.status)+'</td><td>'+
      '<form method="POST" action="/admin/decision"><input type="hidden" name="email" value="'+email+'">'+
      '<button type="submit" name="decision" value="approve">Approve</button>'+
      '<button type="submit" name="decision" value="deny">Deny</button></form></td></tr>';
  }
  return htmlShell(appName+' admin',list+'</tbody></table>');
}

function validHost(host) {
  return typeof host==='string' && /^[a-z0-9](?:[a-z0-9.-]{0,251}[a-z0-9])?$/.test(host) &&
    host.includes('.') && !host.includes('..');
}

async function parseSubmission(request,maxSize=4096) {
  const size=Number(request.headers.get('content-length')||'0');
  if(size>maxSize || !Number.isFinite(size)) return null;
  const contentType=request.headers.get('content-type')||'';
  if(!contentType.startsWith('application/x-www-form-urlencoded') &&
     !contentType.startsWith('application/json')) return null;
  const raw=await request.text();
  if(new TextEncoder().encode(raw).byteLength>maxSize) return null;
  try {
    if(contentType.startsWith('application/json')) {
      const value=JSON.parse(raw);
      return value && typeof value==='object' && !Array.isArray(value) ? value : null;
    }
    const params=new URLSearchParams(raw);
    return Object.fromEntries(params);
  } catch {return null;}
}

/**
 * Per-app gateway. The public waitlist hostname cannot read app contents.
 * Private host requires verified Access JWT AND approved membership.
 * Deploy HERMES and CRESUS as independent Worker/service/D1/Access instances.
 */
export function createClosedTestingGateway({
  appId,appName,ownerEmail,privateHost,waitlistHost,turnstileSiteKey,
  verifyTurnstile,authenticate,store,appFetch,
}) {
  if(!/^[a-z][a-z0-9-]+$/.test(appId||'') || !appName || !validHost(privateHost) ||
     !validHost(waitlistHost) || privateHost===waitlistHost ||
     !normalizeEmail(ownerEmail) || typeof verifyTurnstile!=='function' ||
     typeof authenticate!=='function' || !store || typeof appFetch!=='function' ||
     typeof turnstileSiteKey!=='string' || !/^[a-zA-Z0-9_-]{3,128}$/.test(turnstileSiteKey)) {
    throw new TypeError('Closed-testing gateway requires distinct verified app/waitlist hosts, an owner, Turnstile, JWT authentication and a dedicated store/app service binding');
  }
  const owner=normalizeEmail(ownerEmail);
  return Object.freeze({
    async fetch(request) {
      let url;
      try{url=new URL(request.url);}catch{return json({error:'Invalid URL'},400);}
      if(url.protocol!=='https:')return json({error:'HTTPS required'},403);
      if(url.hostname!==privateHost && url.hostname!==waitlistHost)return json({error:'Unrecognized app host'},421);
      const path=url.pathname;
      const origin=request.headers.get('origin');
      if(origin && origin!==url.origin)return json({error:'Cross-origin request refused'},403);
      const method=request.method;
      if(url.hostname===waitlistHost){
        if(method==='GET' && (path==='/' || path==='/waitlist'))return page(waitlistPage(appName,turnstileSiteKey));
        if(method==='POST' && path==='/api/waitlist/request'){
          if(origin!==url.origin)return json({error:'Same-origin submission required'},403);
          const body=await parseSubmission(request);
          const email=normalizeEmail(body?.email);
          const token=body?.['cf-turnstile-response'] || body?.turnstileToken;
          if(!email)return json({error:'A valid email is required'},400);
          if(!(await verifyTurnstile(token,request)))return json({error:'Verification required'},403);
          // Do not expose status or change denied/approved users through resubmission.
          await store.request(appId,email);
          return page(thanksPage(appName),202);
        }
        return json({error:'Not found'},404);
      }
      // Every private host path, including HTML, icons, service worker and API, is gated.
      let principal;
      try { principal=await authenticate(request); } catch { principal=null; }
      const email=normalizeEmail(principal?.email);
      if(!email || !principal?.id)return json({error:'Verified login required'},401);
      const isOwner=email===owner;
      if(path==='/admin' || path.startsWith('/admin/') || path.startsWith('/api/admin/')){
        if(!isOwner)return json({error:'Owner only'},403);
        if(method==='GET' && (path==='/admin' || path==='/api/admin/waitlist')){
          const rows=await store.list(appId);
          return path==='/admin'?page(adminPage(appName,rows)):json({appId,requests:rows,accessPolicySync:'UNVERIFIED'});
        }
        if(method==='POST' && (path==='/admin/decision' || path==='/api/admin/waitlist/decision')){
          if(origin!==url.origin)return json({error:'Same-origin admin decision required'},403);
          const body=await parseSubmission(request);
          const emailToReview=normalizeEmail(body?.email);
          const decision=body?.decision;
          if(!emailToReview || emailToReview===owner || !['approve','deny'].includes(decision))return json({error:'Invalid review decision'},400);
          const changed=await store.decide(appId,emailToReview,decision,email);
          if(!changed)return json({error:'Waitlist request not found'},404);
          return json({ok:true,decision,appId,accessPolicySync:'REQUIRES_VERIFICATION'});
        }
        return json({error:'Not found'},404);
      }
      if(!isOwner && !(await store.isApproved(appId,email))) {
        return json({error:'Testing access not approved'},403);
      }
      if(method==='GET' && path==='/api/closed-test/me'){
        return json({appId,email,role:isOwner?'owner':'approved-tester'});
      }
      // No fallback to a public app origin. APP is a bound internal service.
      try{return await appFetch(request,principal);}
      catch{return json({error:'Private application service unavailable'},503);}
    },
  });
}
