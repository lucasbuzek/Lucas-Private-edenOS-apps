import {normalizeEmail} from '../closed-testing/d1.mjs';
import {publicSharingEntries,validatedRequestedApp} from './catalog.mjs';

const esc=x=>String(x??'').replace(/[&<>"']/g,c=>({
  '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;',
})[c]);
const toJSON=(value,status=200)=>new Response(JSON.stringify(value),{status,headers:{
  'content-type':'application/json; charset=utf-8',
  'cache-control':'no-store','x-content-type-options':'nosniff','referrer-policy':'no-referrer',
  'x-robots-tag':'noindex,nofollow',
}});
const HEADERS={
  'content-type':'text/html; charset=utf-8','cache-control':'no-store',
  'x-content-type-options':'nosniff','referrer-policy':'no-referrer',
  'x-robots-tag':'noindex,nofollow','x-frame-options':'DENY',
  'content-security-policy':"default-src 'none'; script-src https://challenges.cloudflare.com; frame-src https://challenges.cloudflare.com; connect-src https://challenges.cloudflare.com; style-src 'unsafe-inline'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'",
};
const toHTML=(body,status=200)=>new Response(body,{status,headers:HEADERS});
function htmlShell(title,inside) {
  return '<!doctype html><html lang="en"><head><meta charset="utf-8">'+
    '<meta name="viewport" content="width=device-width,initial-scale=1">'+
    '<meta name="robots" content="noindex,nofollow,noarchive">'+
    '<meta name="color-scheme" content="light dark"><title>'+esc(title)+'</title>'+
    '<style>:root{font:16px system-ui,-apple-system,sans-serif;color-scheme:light;background:#f7f8fb;color:#1c2735}*{box-sizing:border-box}body{margin:0;padding:32px 16px;min-height:100vh}main{max-width:740px;margin:0 auto;padding:clamp(24px,5vw,48px);border-radius:22px;background:#fff;border:1px solid #dce1e8}h1{font-size:clamp(30px,5vw,46px);letter-spacing:-.035em;margin:12px 0}h2{font-size:19px;margin:25px 0 8px}p{line-height:1.6;color:#4c5c70}.eyebrow{font-size:12px;font-weight:750;letter-spacing:.12em;color:#476e98;text-transform:uppercase}label{font-weight:600;display:block;margin:15px 0 6px}input,select,button{font:inherit;width:100%;padding:12px 14px;border:1px solid #9cacbe;border-radius:11px;background:#fff;color:#1c2735}button{cursor:pointer;background:#1f4d78;border-color:#1f4d78;color:#fff;font-weight:650;margin-top:18px}button:focus-visible,input:focus-visible,select:focus-visible{outline:3px solid #6da8ea;outline-offset:2px}.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:12px;margin-top:18px}.card{border:1px solid #dce1e8;border-radius:12px;padding:15px;background:#fafbfd}.card p{margin:8px 0 0;font-size:14px}.quiet{font-size:13px;color:#657588}.trap{position:absolute;left:-10000px;width:1px;height:1px;overflow:hidden}@media(prefers-color-scheme:dark){:root{background:#10141d;color:#f1f4f8}main{background:#192230;border-color:#38495c}h1,input,select{color:#f1f4f8}input,select{background:#1e2b3b;border-color:#68819e}.card{background:#202c3a;border-color:#38495c}p,.quiet{color:#c3d1df}}</style></head>'+
    '<body><main>'+inside+'</main></body></html>';
}
function catalogPage(catalog,siteKey) {
  const entries=publicSharingEntries(catalog);
  const cards=entries.map(item=>'<article class="card"><strong>'+esc(item.name)+'</strong>'+
    '<p>'+esc(item.description)+'</p><p class="quiet">Private testing · request required · no download offered</p></article>').join('');
  const options=entries.map(x=>'<option value="'+esc(x.id)+'">'+esc(x.name)+'</option>').join('');
  const body='<div class="eyebrow">EDENOS · private software testing</div>'+
    '<h1>Request access</h1><p>Browse the available testing invitations. Every request is reviewed by the owner. Approval and verified sign-in are required. No software or source files can be downloaded from this page.</p>'+
    '<div class="cards">'+cards+'</div><h2>Apply for an invitation</h2>'+
    '<form action="/api/software-sharing/request" method="POST">'+
    '<label for="application">Software</label><select id="application" name="appId" required>'+options+'</select>'+
    '<label for="email">Email address</label><input type="email" id="email" name="email" autocomplete="email" maxlength="254" required>'+
    '<div class="trap" aria-hidden="true"><label>Leave this empty<input name="website" tabindex="-1" autocomplete="off"></label></div>'+
    '<div class="cf-turnstile" data-sitekey="'+esc(siteKey)+'" data-action="software-share"></div>'+
    '<button type="submit">Request invitation</button></form>'+
    '<p class="quiet">Your email is used to review this request. Only the owner can approve or deny it. No automatic subscription, account, download or email delivery is created. You may contact the owner to request removal.</p>'+
    '<script async defer src="https://challenges.cloudflare.com/turnstile/v0/api.js"></script>';
  return htmlShell('Software sharing · edenOS',body);
}
function genericConfirmation(){
  return htmlShell('Request received · edenOS',
    '<div class="eyebrow">EDENOS · software testing</div><h1>Request received</h1>'+
    '<p>If your request is eligible, it will be reviewed by the owner. This response does not confirm whether an email was already registered or approved, and no access is granted automatically.</p>');
}
async function formData(req) {
  const contentType=req.headers.get('content-type') || '';
  if(!contentType.toLowerCase().startsWith('application/x-www-form-urlencoded'))return null;
  const length=Number(req.headers.get('content-length')||0);
  if(!Number.isSafeInteger(length)||length>4096)return null;
  const raw=await req.text();
  if(new TextEncoder().encode(raw).byteLength>4096)return null;
  const params=new URLSearchParams(raw);
  if([...params.keys()].some(key=>!['email','appId','website','cf-turnstile-response'].includes(key)))return null;
  for(const key of ['email','appId','website','cf-turnstile-response']){
    if(params.getAll(key).length>1)return null;
  }
  return Object.fromEntries(params);
}
function hostname(raw) {
  return typeof raw==='string'&&/^[a-z0-9]+(?:[.-][a-z0-9]+)*\.[a-z0-9-]+$/.test(raw)
    ? raw : null;
}
async function hash(value) {
  const bytes=new TextEncoder().encode(value);
  const sum=await crypto.subtle.digest('SHA-256',bytes);
  return Array.from(new Uint8Array(sum),x=>x.toString(16).padStart(2,'0')).join('');
}

/**
 * Public, untrusted application form. The *existing* D1 app-id membership table
 * is stored on a separate sharing-only D1 binding, never the CRESUS/HERMES DB.
 * Authoritative app access still requires independent provider-side approval.
 */
export function createSoftwareSharingBackend({
  catalog,requestHost,turnstileSiteKey,verifyTurnstile,rateLimit,store,notifyOwner,
}={}) {
  const entries=publicSharingEntries(catalog);
  if(!entries.length||!hostname(requestHost)||
    typeof turnstileSiteKey!=='string'||!/^[a-zA-Z0-9_-]{3,128}$/.test(turnstileSiteKey)||
    typeof verifyTurnstile!=='function'||typeof rateLimit!=='function'||
    !store||typeof store.request!=='function'||typeof store.list!=='function'||
    typeof store.decide!=='function'||typeof store.isApproved!=='function'||
    (notifyOwner!==undefined&&typeof notifyOwner!=='function')) {
    throw new TypeError('Explicit catalog, request host, Turnstile, durable rate limit and scoped sharing D1 store required');
  }
  return Object.freeze({
    async fetch(request) {
      let url;
      try{url=new URL(request.url);}catch{return toJSON({error:'Invalid URL'},400);}
      if(url.protocol!=='https:'||url.hostname!==requestHost||url.port)return toJSON({error:'Unrecognized secure request host'},421);
      if(url.username||url.password)return toJSON({error:'Invalid URL credentials'},400);
      const origin=request.headers.get('origin');
      if(origin&&origin!==url.origin)return toJSON({error:'Cross-origin denied'},403);
      if(request.method==='GET'&&(url.pathname==='/'||url.pathname==='/software')){
        return toHTML(catalogPage(catalog,turnstileSiteKey));
      }
      if(request.method==='GET'&&url.pathname==='/api/software-sharing/catalog'){
        return toJSON({apps:entries,downloadsAvailable:false,releaseAccepted:false});
      }
      if(request.method!=='POST'||url.pathname!=='/api/software-sharing/request'){
        return toJSON({error:'Not found'},404);
      }
      if(origin!==url.origin)return toJSON({error:'Same-origin submission required'},403);
      let body;
      try{body=await formData(request);}catch{return toJSON({error:'Invalid submission'},400);}
      if(!body)return toJSON({error:'Invalid form'},400);
      if(body.website){
        // Generic reply for honeypot spam; no DB write or notification.
        return toHTML(genericConfirmation(),202);
      }
      const email=normalizeEmail(body.email);
      const app=validatedRequestedApp(catalog,body.appId);
      if(!email||!app)return toJSON({error:'Valid email and listed app required'},400);
      if(typeof body['cf-turnstile-response']!=='string')return toJSON({error:'Verification required'},403);
      // Privacy: no raw IP or email is supplied as a rate-limit key.
      // Cloudflare Worker receives CF-Connecting-IP from the trusted edge.
      const ip=request.headers.get('cf-connecting-ip');
      if(!ip||ip.length>80)return toJSON({error:'Request source not verified'},403);
      try{
        const keyA='share:source:'+await hash(ip);
        const keyB='share:email:'+await hash(email);
        if(!(await rateLimit(keyA))||!(await rateLimit(keyB))){
          return toJSON({error:'Too many requests. Please try again later.'},429);
        }
      }catch{return toJSON({error:'Request rate protection unavailable'},503);}
      let verified=false;
      try{verified=await verifyTurnstile(body['cf-turnstile-response'],request);}catch{verified=false;}
      if(!verified)return toJSON({error:'Human verification failed'},403);
      let created=false;
      try{created=await store.request(app.id,email);}catch{
        return toJSON({error:'Request queue unavailable'},503);
      }
      // Notifications are a convenience, not an identity or access grant.
      if(created&&notifyOwner){
        try{await notifyOwner({appId:app.id,email});}catch{ /* durable queue remains canonical */ }
      }
      return toHTML(genericConfirmation(),202);
    },
    async listOwnerRequests() {
      const result=[];
      for(const app of entries){
        const rows=await store.list(app.id);
        if(!Array.isArray(rows))throw new Error('Invalid app-specific request listing');
        for(const row of rows) {
          const email=normalizeEmail(row.email);
          if(email)result.push({appId:app.id,email,status:row.status||'pending'});
        }
      }
      return result.slice(0,500);
    },
    async decideOwnerRequest({appId,email,decision,reviewer}) {
      const app=validatedRequestedApp(catalog,appId);
      const addr=normalizeEmail(email);
      const actor=normalizeEmail(reviewer);
      if(!app||!addr||!actor||!['approve','deny'].includes(decision))return false;
      return await store.decide(app.id,addr,decision,actor);
    },
    // Explicitly NOT a release/download or Access-policy provisioning endpoint.
    async canRequestPrivateSoftware(appId,email) {
      const app=validatedRequestedApp(catalog,appId);
      return Boolean(app&&normalizeEmail(email)&&await store.isApproved(appId,normalizeEmail(email)));
    },
  });
}

export function createSoftwareSharingOwnerAdapter(backend) {
  if(!backend||typeof backend.listOwnerRequests!=='function'||typeof backend.decideOwnerRequest!=='function')
    throw new TypeError('Validated sharing backend required');
  return Object.freeze({
    async list(){
      const rows=await backend.listOwnerRequests();
      return rows.map(row=>({email:row.email,status:row.status,targetAppId:row.appId}));
    },
    async decide(_scope,email,decision,reviewer,targetAppId){
      return backend.decideOwnerRequest({appId:targetAppId,email,decision,reviewer});
    },
  });
}
