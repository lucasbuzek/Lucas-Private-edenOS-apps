import {normalizeEmail} from './d1.mjs';

const esc=s=>String(s??'').replace(/&/g,'&amp;').replace(/</g,'&lt;')
  .replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');
function reply(body,status=200,kind='application/json') {
  return new Response(kind==='text/html' ? body : JSON.stringify(body),{
    status,headers:{
      'content-type':kind+';charset=utf-8','cache-control':'no-store',
      'x-content-type-options':'nosniff','referrer-policy':'no-referrer',
      'content-security-policy':"default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'self'; frame-ancestors 'none'",
    },
  });
}
const DENIED=['admin','api','assets','sw.js'];
function validHost(host) {
  return host==='lucas.edenosprivate.pages.dev';
}
async function parse(request) {
  const size=Number(request.headers.get('content-length')||0);
  if(!Number.isFinite(size)||size>4096)return null;
  const contentType=request.headers.get('content-type')||'';
  if(!contentType.startsWith('application/x-www-form-urlencoded'))return null;
  const raw=await request.text();
  if(new TextEncoder().encode(raw).length>4096)return null;
  return Object.fromEntries(new URLSearchParams(raw));
}

/**
 * Owner-only control surface. Each app is a separate trusted admin service:
 * no shared app datastore or automatic cross-app membership is created.
 * The hosting adapter must authenticate with its OWN Cloudflare Access audience
 * and pass principal.allowedApps=['lucas-admin'] only for that verified audience.
 */
export function createPrivateOwnerHub({ownerEmail,authenticate,services}) {
  const owner=normalizeEmail(ownerEmail);
  if(!owner||typeof authenticate!=='function'||!services||
     typeof services!=='object'||Array.isArray(services)||
     !['hermes','cresus'].every(app=>typeof services[app]?.list==='function'&&
       typeof services[app]?.decide==='function') ||
     (services.softwareSharing!==undefined&&
       (typeof services.softwareSharing?.list!=='function' ||
        typeof services.softwareSharing?.decide!=='function')) ||
     (services.downloadLinks!==undefined&&
       (typeof services.downloadLinks?.list!=='function' ||
        typeof services.downloadLinks?.issue!=='function' ||
        typeof services.downloadLinks?.setEnabled!=='function'))) {
    throw new TypeError('Owner Access verifier and independently scoped HERMES/CRESUS admin service adapters required');
  }
  return Object.freeze({
    async fetch(request) {
      let url;
      try{url=new URL(request.url);}catch{return reply({error:'Invalid URL'},400);}
      if(url.protocol!=='https:'||!validHost(url.hostname))return reply({error:'Owner hostname denied'},403);
      const origin=request.headers.get('origin');
      if(origin&&origin!==url.origin)return reply({error:'Cross-origin request denied'},403);
      let principal;
      try{principal=await authenticate(request);}catch{principal=null;}
      const email=normalizeEmail(principal?.email);
      if(!principal?.id||!email)return reply({error:'Owner sign-in required'},401);
      if(email!==owner||!Array.isArray(principal.allowedApps)||
         !principal.allowedApps.includes('lucas-admin'))return reply({error:'Owner only'},403);

      const path=url.pathname;
      if(request.method==='GET'&&(path==='/'||path==='/admin'||path==='/api/admin/waitlists')) {
        try {
          const listings={};
          // Each service independently applies its app_id and data permissions.
          for(const appId of ['hermes','cresus']) {
            const items=await services[appId].list(appId);
            if(!Array.isArray(items))throw new Error('Invalid admin service response');
            listings[appId]=items.slice(0,200).map(x=>({
              email:normalizeEmail(x.email),status:String(x.status||'unknown'),
            })).filter(x=>x.email);
          }
          if(services.softwareSharing) {
            const requests=await services.softwareSharing.list();
            if(!Array.isArray(requests))throw new Error('Invalid software request listing');
            listings.softwareSharing=requests.slice(0,200).map(x=>({
              email:normalizeEmail(x.email),status:String(x.status||'pending'),
              targetAppId:typeof x.targetAppId==='string'?x.targetAppId:null,
            })).filter(x=>x.email && /^[a-z][a-z0-9-]{1,58}$/.test(x.targetAppId||''));
          }
          const available=services.downloadLinks
            ? await services.downloadLinks.list() : [];
          if(!Array.isArray(available) || available.some(x=>
            !/^[a-z][a-z0-9-]{1,58}$/.test(x.appId||'') ||
            !/^[a-z][a-z0-9-]{1,58}$/.test(x.releaseId||'') ||
            typeof x.enabled!=='boolean')) {
            throw new Error('Invalid physically accepted release list');
          }
          if(path==='/api/admin/waitlists')return reply({
            owner:true,apps:listings,accessPolicies:'UNVERIFIED',
            softwareDownloads:available.length?'OWNER_RELEASE_SELECTION_REQUIRED':'NO_RELEASES_ACTIVATED',
            acceptedReleaseIds:available.map(x=>({appId:x.appId,releaseId:x.releaseId,
              enabled:x.enabled})),
          });
          let rows='';
          for(const [appId,items] of Object.entries(listings)) {
            rows+='<h2>'+esc(appId.toUpperCase())+'</h2><table><tr><th>Email</th><th>Status</th><th>Owner decision</th></tr>';
            for(const record of items) {
              rows+='<tr><td>'+esc(record.email)+'</td><td>'+esc(record.status)+'</td><td>'+
                '<form method="POST" action="/admin/decision">'+
                '<input type="hidden" name="appId" value="'+esc(appId)+'">'+
                '<input type="hidden" name="email" value="'+esc(record.email)+'">'+
                (appId==='softwareSharing'
                  ? '<input type="hidden" name="targetAppId" value="'+esc(record.targetAppId)+'">'+
                    '<small>'+esc(record.targetAppId)+'</small>' : '')+
                '<button name="decision" value="approve">Approve</button>'+
                '<button name="decision" value="deny">Deny</button></form>'+
                (appId==='softwareSharing' && record.status==='approved'
                  ? available.filter(x=>x.enabled===true&&x.appId===record.targetAppId).map(x=>
                    '<form method="POST" action="/api/admin/send-release">'+
                    '<input type="hidden" name="appId" value="'+esc(x.appId)+'">'+
                    '<input type="hidden" name="releaseId" value="'+esc(x.releaseId)+'">'+
                    '<input type="hidden" name="email" value="'+esc(record.email)+'">'+
                    '<button type="submit">Send one-use email download</button></form>'
                  ).join('') : '')+'</td></tr>';
            }
            rows+='</table>';
          }
          if(available.length && services.downloadLinks){
            rows+='<h2>Accepted release hosting controls</h2>'+
              '<p>Enabling a reviewed release does not bypass request approval or email verification.</p>';
            for(const item of available){
              rows+='<form method="POST" action="/api/admin/release-state">'+
                '<input type="hidden" name="appId" value="'+esc(item.appId)+'">'+
                '<input type="hidden" name="releaseId" value="'+esc(item.releaseId)+'">'+
                '<button name="enabled" value="'+(item.enabled?'false':'true')+'">'+
                (item.enabled?'Disable':'Enable')+' '+esc(item.appId)+' / '+esc(item.releaseId)+
                '</button></form>';
            }
          }
          return reply('<!doctype html><html lang="en"><meta charset="utf-8">'+
            '<meta name="viewport" content="width=device-width,initial-scale=1">'+
            '<title>Lucas — private EDENOS administration</title>'+
            '<style>body{font:16px system-ui,sans-serif;max-width:900px;margin:6vh auto;padding:2rem;color:#222}table{width:100%;border-collapse:collapse}td,th{padding:.5rem;text-align:left;border-bottom:1px solid #ddd}button{font:inherit;margin:.3rem;padding:.4rem}</style>'+
            '<h1>Lucas — private EDENOS administration</h1>'+
            '<p>Approval is app-specific. Cloudflare Access policy synchronization remains separately verified.</p>'+rows+'</html>',200,'text/html');
        }catch{return reply({error:'App administration services unavailable'},503);}
      }
      if(request.method==='POST'&&path==='/api/admin/release-state'){
        if(origin!==url.origin)return reply({error:'Same-origin owner action required'},403);
        if(!services.downloadLinks)return reply({error:'Release settings unavailable'},503);
        const data=await parse(request);
        if(!/^[a-z][a-z0-9-]{1,58}$/.test(data?.appId||'')||
          !/^[a-z][a-z0-9-]{1,58}$/.test(data?.releaseId||'')||
          !['true','false'].includes(data?.enabled))
          return reply({error:'Invalid accepted-release setting'},400);
        try{
          const result=await services.downloadLinks.setEnabled({
            principal,appId:data.appId,releaseId:data.releaseId,
            enabled:data.enabled==='true',
          });
          return result?.state==='UPDATED'
            ? reply({ok:true,appId:data.appId,releaseId:data.releaseId,
              enabled:result.enabled})
            : reply({error:'Release not accepted or settings unavailable'},403);
        }catch{return reply({error:'Release control service unavailable'},503);}
      }
      if(request.method==='POST'&&path==='/api/admin/send-release') {
        if(origin!==url.origin)return reply({error:'Exact same-origin owner action required'},403);
        if(!services.downloadLinks)return reply({error:'No accepted releases configured'},503);
        const data=await parse(request);
        const recipient=normalizeEmail(data?.email);
        if(!recipient||recipient===owner||
          !/^[a-z][a-z0-9-]{1,58}$/.test(data?.appId||'')||
          !/^[a-z][a-z0-9-]{1,58}$/.test(data?.releaseId||''))
          return reply({error:'Invalid approved download request'},400);
        try{
          const result=await services.downloadLinks.issue({
            principal,email:recipient,appId:data.appId,releaseId:data.releaseId,
          });
          return result?.state==='SUBMITTED'
            ? reply({ok:true,link:'SUBMITTED_TO_VERIFIED_EMAIL_PROVIDER',delivered:'UNKNOWN'})
            : reply({error:'Email download link unavailable',reason:result?.reason||'UNKNOWN'},403);
        }catch{return reply({error:'Email release service unavailable'},503);}
      }
      if(request.method==='POST'&&path==='/admin/decision') {
        if(origin!==url.origin)return reply({error:'Exact same-origin owner action required'},403);
        const data=await parse(request);
        const appId=data?.appId;
        const applicant=normalizeEmail(data?.email);
        const decision=data?.decision;
        const sharing = appId==='softwareSharing';
        const selected=sharing?services.softwareSharing:services[appId];
        const targetAppId=data?.targetAppId;
        if((!['hermes','cresus'].includes(appId)&&!sharing)||!selected||
           (sharing && (typeof targetAppId!=='string' ||
            !/^[a-z][a-z0-9-]{1,58}$/.test(targetAppId))) ||
           !applicant||applicant===owner||
           !['approve','deny'].includes(decision))return reply({error:'Invalid app-specific decision'},400);
        try {
          const applied=await selected.decide(appId,applicant,decision,owner,targetAppId);
          if(!applied)return reply({error:'Application request not found'},404);
          return reply({ok:true,appId,decision,accessPolicies:'REQUIRES_VERIFICATION'});
        }catch{return reply({error:'App-specific decision unavailable'},503);}
      }
      return reply({error:'Not found'},404);
    },
  });
}
