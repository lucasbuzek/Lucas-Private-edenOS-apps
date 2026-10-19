import {normalizeEmail} from '../closed-testing/d1.mjs';
import {validateGitHubAsset} from './github-release.mjs';

const ID=/^[a-z][a-z0-9-]{1,58}$/;
const SHA=/^[a-f0-9]{64}$/;
const TICKET=/^[A-Za-z0-9_-]{43}$/;
const NAME=/^[A-Za-z0-9][A-Za-z0-9 _().-]{0,120}\.(?:zip|dmg|pkg|exe|msi|apk|pdf)$/;
const MAX_BYTES=64*1024*1024;
const sha256=async data=>Array.from(new Uint8Array(
  await crypto.subtle.digest('SHA-256',data)
),b=>b.toString(16).padStart(2,'0')).join('');

const deny=(status,message)=>new Response(message,{status,headers:{
  'content-type':'text/plain; charset=utf-8','cache-control':'no-store',
  'x-robots-tag':'noindex,nofollow,noarchive','referrer-policy':'no-referrer',
  'x-content-type-options':'nosniff',
}});
const SECURITY={
  'cache-control':'no-store','referrer-policy':'no-referrer',
  'x-content-type-options':'nosniff','x-robots-tag':'noindex,nofollow,noarchive',
  'x-frame-options':'DENY',
  'content-security-policy':"default-src 'none'; script-src 'self'; connect-src 'none'; style-src 'unsafe-inline'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'",
};
const FORM_SCRIPT=[
  '(()=>{',
  "const ticket=new URLSearchParams(location.hash.slice(1)).get('ticket');",
  "history.replaceState(null,'',location.pathname);",
  "const button=document.getElementById('download');",
  "const hidden=document.getElementById('ticket');",
  "const message=document.getElementById('message');",
  "if(!ticket||!/^[A-Za-z0-9_-]{43}$/.test(ticket)){",
  "message.textContent='This email link is invalid. Request a new invitation.';return;}",
  "hidden.value=ticket;button.disabled=false;",
  "message.textContent='Your email link is ready. Choose Download to use it once.';",
  '})();'
].join('\n');
const PAGE=[
  '<!doctype html><html lang="en"><head><meta charset="utf-8">',
  '<meta name="viewport" content="width=device-width,initial-scale=1">',
  '<meta name="robots" content="noindex,nofollow,noarchive">',
  '<title>Private EDEN software download</title><style>',
  ':root{font:16px system-ui,-apple-system,sans-serif;color-scheme:light dark}',
  'body{min-height:100vh;margin:0;display:grid;place-items:center;padding:24px;background:#111925;color:#edf4fd}',
  'main{width:min(100%,560px);padding:clamp(24px,6vw,48px);border:1px solid #334962;border-radius:20px;background:#1c2a3b}',
  'h1{font-size:clamp(30px,5vw,45px);letter-spacing:-.035em}p{line-height:1.6;color:#ccd8e7}',
  'button{font:inherit;padding:13px 26px;border:0;border-radius:10px;background:#a5cff5;color:#102033;font-weight:700;cursor:pointer}',
  'button:disabled{opacity:.4;cursor:not-allowed}button:focus-visible{outline:3px solid white;outline-offset:4px}',
  'small{display:block;margin-top:22px;color:#abbacd}</style></head><body><main>',
  '<small>EDENOS · PRIVATE SOFTWARE</small><h1>Download by email invitation</h1>',
  '<p id="message">Checking your email link…</p>',
  '<form method="POST" action="/api/software-sharing/redeem">',
  '<input id="ticket" type="hidden" name="ticket" value="">',
  '<button id="download" disabled type="submit">Download verified release</button>',
  '</form><small>One use only · Expires automatically · No public release URLs</small>',
  '<script src="/download/redeem.js"></script></main></body></html>'
].join('');

export function validateEmailLinkReleases(releases) {
  const errors=[];
  if(!Array.isArray(releases))return {ok:false,errors:['Explicit release registry required']};
  const keys=new Set();
  for(const item of releases) {
    const key=(item?.appId||'')+':'+(item?.releaseId||'');
    if(keys.has(key))errors.push('Duplicate release');
    keys.add(key);
    if(!ID.test(item?.appId||'')||!ID.test(item?.releaseId||'')||
       !SHA.test(item?.sha256||'')||!NAME.test(item?.filename||'')||
       !Number.isSafeInteger(item?.sizeBytes)||item.sizeBytes<1||item.sizeBytes>MAX_BYTES)
      errors.push('Unsafe artifact identity, digest, filename or size');
    if(item?.approvedForSharing!==true||item?.physicalAcceptance!==true)
      errors.push('Release approval and physical acceptance required');
    if(!validateGitHubAsset(item?.source))
      errors.push('Server-owned, exact private GitHub Release asset reference required');
    if(item?.publicUrl!==undefined||item?.token!==undefined||item?.credentials!==undefined||
       item?.localSourcePath!==undefined)
      errors.push('Browser release URL, token, credentials and local path are forbidden');
  }
  return {ok:errors.length===0,errors};
}

const tokenValue=()=>{
  const buf=new Uint8Array(32);
  crypto.getRandomValues(buf);
  return btoa(String.fromCharCode(...buf)).replace(/\+/g,'-').replace(/\//g,'_').replace(/=/g,'');
};
export function createCloudflareEmailMailer({binding,from}={}) {
  if(typeof binding?.send!=='function'||!normalizeEmail(from))
    throw new TypeError('Verified Cloudflare Email Service binding and sender required');
  return async({to,link,appId,filename})=>{
    const recipient=normalizeEmail(to);
    if(!recipient||!URL.canParse(link))throw new TypeError('Verified email destination and link required');
    const result=await binding.send({
      to:recipient,from,subject:'Your approved EDEN software download',
      text:'Your private '+appId+' release ('+filename+') is ready.\n\n'+
        'Use this link once to download the package:\n'+link+'\n\n'+
        'The link expires in 15 minutes. Do not forward it. If this was unexpected, ignore the email.',
    });
    if(!result||typeof result.messageId!=='string'||!result.messageId)
      throw new Error('Mail provider did not accept the delivery request');
    return {submitted:true};
  };
}

/**
 * One-use invitation, NOT app login. The email link's token stays in the URL
 * fragment, never request path/query. Scanners cannot consume via GET.
 * The user explicitly presses Download, performing a same-origin POST.
 */
export function createEmailDownloadService({
  releases,origin,ownerEmail,tickets,approved,releaseEnabled,sendEmail,readArtifact,
  now=()=>Date.now(),ttlMs=15*60*1000,
}={}) {
  const validity=validateEmailLinkReleases(releases);
  const owner=normalizeEmail(ownerEmail);
  let url;
  try{url=new URL(origin);}catch{}
  if(!validity.ok||!owner||!url||url.protocol!=='https:'||
     url.hostname!=='edenosportal.pages.dev'||url.pathname!=='/'||url.search||url.hash||
     typeof tickets?.issue!=='function'||typeof tickets?.consume!=='function'||
     typeof tickets?.revoke!=='function'||typeof approved!=='function'||
     typeof releaseEnabled!=='function'||
     typeof sendEmail!=='function'||typeof readArtifact!=='function'||
     !Number.isSafeInteger(ttlMs)||ttlMs<60_000||ttlMs>30*60_000)
    throw new TypeError('Accepted private releases, portal identity, owner, D1, recipient approval, mail and artifact services required');
  const entries=new Map(releases.map(x=>[x.appId+':'+x.releaseId,x]));
  return Object.freeze({
    async issue({principal,email,appId,releaseId}) {
      const recipient=normalizeEmail(email);
      if(!principal?.id||normalizeEmail(principal.email)!==owner||
         !principal.allowedApps?.includes('lucas-admin'))
        return {state:'DENIED',reason:'OWNER_LOGIN_REQUIRED'};
      if(!recipient||!ID.test(appId||'')||!ID.test(releaseId||'')||recipient===owner)
        return {state:'DENIED',reason:'INVALID_REQUEST'};
      const release=entries.get(appId+':'+releaseId);
      if(!release)return {state:'UNAVAILABLE',reason:'NO_ACCEPTED_RELEASE'};
      let enabled=false;
      try{enabled=(await releaseEnabled(appId,releaseId))===true;}catch{}
      if(!enabled)return {state:'UNAVAILABLE',reason:'RELEASE_DISABLED_BY_OWNER'};
      let allowed=false;
      try{allowed=(await approved(appId,recipient))===true;}catch{}
      if(!allowed)return {state:'DENIED',reason:'OWNER_APPROVAL_REQUIRED'};
      const token=tokenValue();
      const hash=await sha256(new TextEncoder().encode(token));
      const issuedAt=now(),expiresAt=issuedAt+ttlMs;
      if(!Number.isSafeInteger(issuedAt))return {state:'UNAVAILABLE',reason:'INVALID_CLOCK'};
      try{await tickets.issue({tokenHash:hash,appId,releaseId,email:recipient,issuedAt,expiresAt});}
      catch{return {state:'UNAVAILABLE',reason:'TICKET_STORAGE_UNAVAILABLE'};}
      const link=origin+'download/redeem#ticket='+encodeURIComponent(token);
      try{
        const submission=await sendEmail({to:recipient,link,appId,filename:release.filename});
        if(submission?.submitted!==true)throw new Error('Mail provider did not confirm submission');
      }catch{
        try{await tickets.revoke(hash,now());}catch{}
        return {state:'UNAVAILABLE',reason:'EMAIL_DELIVERY_UNAVAILABLE'};
      }
      return {state:'SUBMITTED',emailSubmitted:true,expiresAt,
        note:'Mail service accepted the request; recipient delivery not physically verified'};
    },
    async fetch(request) {
      let path;
      try{
        const target=new URL(request.url);
        if(target.origin!==url.origin||target.username||target.password||target.search||target.hash)
          return deny(403,'Unknown software download origin');
        path=target.pathname;
      }catch{return deny(400,'Invalid download URL');}
      if(request.method==='GET' && path==='/download/redeem')
        return new Response(PAGE,{status:200,headers:{...SECURITY,'content-type':'text/html; charset=utf-8'}});
      if(request.method==='GET' && path==='/download/redeem.js')
        return new Response(FORM_SCRIPT,{status:200,headers:{
          ...SECURITY,'content-type':'application/javascript; charset=utf-8',
        }});
      if(request.method!=='POST'||path!=='/api/software-sharing/redeem')
        return deny(404,'Not found');
      if(request.headers.get('origin')!==url.origin)
        return deny(403,'Same-origin submission required');
      const type=request.headers.get('content-type')||'';
      if(!type.startsWith('application/x-www-form-urlencoded'))
        return deny(415,'Unsupported content type');
      const length=Number(request.headers.get('content-length')||0);
      if(!Number.isSafeInteger(length)||length>1000)return deny(400,'Invalid form size');
      let params;
      try {
        const body=await request.text();
        if(body.length>1000)return deny(400,'Invalid form size');
        params=new URLSearchParams(body);
      }catch{return deny(400,'Invalid form');}
      if(params.getAll('ticket').length!==1||[...params.keys()].some(k=>k!=='ticket'))
        return deny(400,'Invalid invitation');
      const token=params.get('ticket');
      if(!TICKET.test(token||''))return deny(400,'Invalid invitation');
      const hash=await sha256(new TextEncoder().encode(token));
      let claim;
      try{claim=await tickets.consume(hash,now());}
      catch{return deny(503,'Secure invitation verification unavailable');}
      if(!claim)return deny(403,'Invitation expired, denied or already used');
      const release=entries.get(claim.appId+':'+claim.releaseId);
      if(!release)return deny(403,'Release withdrawn');
      let enabled=false;
      try{enabled=(await releaseEnabled(claim.appId,claim.releaseId))===true;}catch{}
      if(!enabled)return deny(403,'Release disabled by owner');
      let permission=false;
      try{permission=(await approved(claim.appId,claim.email))===true;}catch{}
      if(!permission)return deny(403,'Approval revoked or unavailable');
      try {
        const bytes=await readArtifact(release);
        if(!(bytes instanceof Uint8Array)||bytes.byteLength!==release.sizeBytes||
           await sha256(bytes)!==release.sha256)
          return deny(503,'Artifact verification failed');
        return new Response(bytes,{status:200,headers:{
          ...SECURITY,'content-type':'application/octet-stream',
          'content-disposition':'attachment; filename="'+release.filename+'"',
        }});
      }catch{return deny(503,'Verified release temporarily unavailable');}
    }
  });
}
