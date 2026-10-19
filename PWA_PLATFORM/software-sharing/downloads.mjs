import { normalizeEmail } from '../closed-testing/d1.mjs';

const ID=/^[a-z][a-z0-9-]{1,58}$/;
const DIGEST=/^[a-f0-9]{64}$/;
const SAFE_NAME=/^[A-Za-z0-9][A-Za-z0-9 _().-]{0,120}\.(zip|dmg|pkg|exe|msi|apk|pdf)$/;
const releaseKey=x=>x.appId+':'+x.releaseId;

export function validatePrivateReleases(releases) {
  const problems=[];
  if(!Array.isArray(releases)) return {ok:false,errors:['Explicit accepted release registry required']};
  const names=new Set(),objects=new Set();
  for(const r of releases) {
    if(!r||!ID.test(r.appId||'')||!ID.test(r.releaseId||'')) problems.push('Invalid app or release identity');
    const name=releaseKey(r||{});
    if(names.has(name)) problems.push('Duplicate release identity');
    names.add(name);
    if(r.approvedForSharing!==true||r.physicalAcceptance!==true) problems.push('Release must be physically accepted for private sharing');
    if(!DIGEST.test(r.sha256||'')) problems.push('Verified SHA256 required');
    if(!SAFE_NAME.test(r.filename||'')) problems.push('Safe download filename required');
    if(typeof r.objectKey!=='string'||!/^releases\/[a-z][a-z0-9-]{1,58}\/[A-Za-z0-9_.-]{2,180}$/.test(r.objectKey)) {
      problems.push('Private R2 object key outside release-only prefix');
    } else {
      if(objects.has(r.objectKey))problems.push('Reused R2 object key');
      objects.add(r.objectKey);
    }
    if(r.publicUrl!==undefined||r.localSourcePath!==undefined||r.credentials!==undefined) {
      problems.push('Public URL, source path and credentials forbidden');
    }
  }
  return {ok:problems.length===0,errors:problems};
}

const respond=(value,status)=>new Response(JSON.stringify(value),{status,headers:{
  'content-type':'application/json','cache-control':'no-store','x-content-type-options':'nosniff'
}});

/**
 * The caller must mount on an Access-protected, independently verified app host.
 * Approval of an email and authenticated app authorization are BOTH required.
 * The R2 bucket must have no public buckets/custom domains and accept read-only get.
 */
export function createPrivateDownloadHandler({
  releases,ownerEmail,privateHost,authenticate,authorizeApp,store,bucket,
}={}) {
  const checked=validatePrivateReleases(releases);
  const owner=normalizeEmail(ownerEmail);
  if(!checked.ok||!owner||typeof privateHost!=='string'||!privateHost.endsWith('.pages.dev')||
    typeof authenticate!=='function'||typeof authorizeApp!=='function'||
    typeof store?.isApproved!=='function'||typeof bucket?.get!=='function') {
    throw new TypeError('Private releases need accepted manifests, authenticated application authorization and bound private R2');
  }
  const byRelease=new Map(releases.map(x=>[releaseKey(x),x]));
  return Object.freeze({
    async fetch(request) {
      let url;
      try{url=new URL(request.url);}catch{return respond({error:'Invalid request URL'},400);}
      if(url.protocol!=='https:'||url.hostname!==privateHost||url.port||url.username||url.password)
        return respond({error:'Unknown protected application origin'},403);
      if(request.method!=='GET') return respond({error:'Method not allowed'},405);
      const origin=request.headers.get('origin');
      if(origin && origin!==url.origin)return respond({error:'Cross-origin download denied'},403);
      if(url.search||url.hash)return respond({error:'Unsigned query parameters forbidden'},400);
      const match=/^\/api\/private-releases\/([a-z][a-z0-9-]{1,58})\/([a-z][a-z0-9-]{1,58})$/.exec(url.pathname);
      if(!match)return respond({error:'Not found'},404);
      const [_,appId,id]=match, release=byRelease.get(appId+':'+id);
      if(!release)return respond({error:'No accepted private release'},404);
      let identity;
      try{identity=await authenticate(request);}catch{return respond({error:'Verified sign-in required'},401);}
      const email=normalizeEmail(identity?.email);
      if(!email||!identity?.id)return respond({error:'Verified sign-in required'},401);
      // Explicit app authorization prevents a shared global waitlist approval from
      // crossing app boundaries. The owner role must also be independently verified.
      let accepted=false;
      try{accepted=await authorizeApp(identity,appId)===true;}catch{}
      if(!accepted)return respond({error:'App authorization denied'},403);
      if(email!==owner) {
        let approved=false;
        try{approved=await store.isApproved(appId,email)===true;}catch{return respond({error:'Approval service unavailable'},503);}
        if(!approved)return respond({error:'Download requires owner approval'},403);
      }
      let object;
      try{object=await bucket.get(release.objectKey);}catch{return respond({error:'Private storage unavailable'},503);}
      if(!object?.body)return respond({error:'Verified artifact unavailable'},404);
      if(object.customMetadata?.sha256!==release.sha256)return respond({error:'Private artifact checksum not verified'},503);
      return new Response(object.body,{status:200,headers:{
        'content-type':'application/octet-stream',
        'content-disposition':'attachment; filename="'+release.filename+'"',
        'cache-control':'private, no-store, max-age=0',
        'content-security-policy':"default-src 'none'",
        'x-content-type-options':'nosniff',
        'referrer-policy':'no-referrer',
        'x-robots-tag':'noindex,nofollow,noarchive'
      }});
    }
  });
}
