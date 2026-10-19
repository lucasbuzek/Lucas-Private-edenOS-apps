// Server-only, exact-release GitHub asset retrieval. NEVER expose private repo
// bearer credentials, CDN signed URLs, or unverified bytes to portal clients.
const REPOSITORY=/^[A-Za-z0-9][A-Za-z0-9_.-]{0,99}\/[A-Za-z0-9][A-Za-z0-9_.-]{0,99}$/;
const SHA256=/^[a-f0-9]{64}$/;
const MAX_BYTES=64*1024*1024;
const ASSET_HOSTS=new Set([
  'release-assets.githubusercontent.com',
  'objects.githubusercontent.com',
  'github-releases.githubusercontent.com',
]);

const digest=async bytes=>{
  const hash=await crypto.subtle.digest('SHA-256',bytes);
  return Array.from(new Uint8Array(hash),b=>b.toString(16).padStart(2,'0')).join('');
};

export function validateGitHubAsset(source) {
  const parts=typeof source?.repository==='string'?source.repository.split('/'):[];
  return Boolean(source?.kind==='github-release' &&
    REPOSITORY.test(source?.repository||'') &&
    parts.length===2 && parts.every(s=>s!=='.'&&s!=='..'&&!s.endsWith('.')) &&
    Number.isSafeInteger(source.assetId) && source.assetId>0 &&
    typeof source.tokenRef!=='string' && !('authorization' in source));
}

/**
 * A release must already have passed native package verification and LKG gates.
 * Private repo token must be read-only Contents on this exact repository.
 * Assets over 64 MiB require a verified R2 mirror or other streaming adapter.
 */
export function createGitHubReleaseReader({token,allowedRepositories,fetchImpl=fetch,maxBytes=MAX_BYTES}={}) {
  if(typeof token!=='string'||!token.trim()||
    !Array.isArray(allowedRepositories)||!allowedRepositories.length||
    allowedRepositories.some(r=>!REPOSITORY.test(r))||
    typeof fetchImpl!=='function'||
    !Number.isSafeInteger(maxBytes)||maxBytes<1||maxBytes>MAX_BYTES)
    throw new TypeError('Private GitHub repository read token and bounded fetch required');
  const metadataHeaders={
    accept:'application/vnd.github+json',
    authorization:'Bearer '+token,
    'x-github-api-version':'2022-11-28',
    'user-agent':'edenos-private-release-gateway',
  };
  return Object.freeze({
    async read(release) {
      if(!validateGitHubAsset(release?.source)||
        !allowedRepositories.includes(release.source.repository)||
        !SHA256.test(release.sha256||'')||
        typeof release.filename!=='string' ||
        !Number.isSafeInteger(release.sizeBytes)||release.sizeBytes<1||
        release.sizeBytes>maxBytes)
        throw new Error('Unverified or oversized private GitHub release');
      const [owner,repo]=release.source.repository.split('/');
      const endpoint='https://api.github.com/repos/'+encodeURIComponent(owner)+'/'+
        encodeURIComponent(repo)+'/releases/assets/'+release.source.assetId;
      const opts={method:'GET',headers:metadataHeaders,redirect:'manual',
        signal:AbortSignal.timeout(18000)};
      const metaResponse=await fetchImpl(endpoint,opts);
      if(metaResponse.status!==200)throw new Error('GitHub asset metadata is unavailable');
      const meta=await metaResponse.json();
      if(meta?.id!==release.source.assetId || meta.name!==release.filename ||
        meta.size!==release.sizeBytes || meta.state!=='uploaded' ||
        (meta.digest && meta.digest!=='sha256:'+release.sha256))
        throw new Error('GitHub release asset provenance did not match the accepted manifest');
      const request=await fetchImpl(endpoint,{
        ...opts,headers:{...metadataHeaders,accept:'application/octet-stream'}
      });
      let binary=request;
      if(request.status===302){
        const location=request.headers.get('location');
        let target;
        try{target=new URL(location);}catch{throw new Error('Invalid signed release redirect');}
        if(target.protocol!=='https:'||!ASSET_HOSTS.has(target.hostname)||
           target.username||target.password||target.port)
          throw new Error('Unexpected asset redirect destination');
        // Do NOT forward the GitHub private repository bearer credential to CDN.
        binary=await fetchImpl(target.href,{
          method:'GET',redirect:'error',
          headers:{'user-agent':'edenos-private-release-gateway'},
          signal:AbortSignal.timeout(25000),
        });
      }
      if(binary.status!==200)throw new Error('Private release bytes unavailable');
      const type=binary.headers.get('content-type')||'';
      if(/application\/json|text\/html/i.test(type))
        throw new Error('Unexpected GitHub API or HTML response in binary release');
      const length=binary.headers.get('content-length');
      if(length && (Number(length)>maxBytes||Number(length)!==release.sizeBytes))
        throw new Error('Asset size differs from accepted manifest');
      if(!binary.body)throw new Error('Private release has no body');
      const stream=binary.body.getReader();
      const chunks=[];
      let count=0;
      try{
        while(true){
          const {done,value}=await stream.read();
          if(done)break;
          if(!(value instanceof Uint8Array))throw new Error('Malformed GitHub release stream');
          count+=value.byteLength;
          if(count>maxBytes||count>release.sizeBytes)throw new Error('Private release exceeded verified size');
          chunks.push(value);
        }
      }catch(error){
        try{await stream.cancel();}catch{}
        throw error;
      }finally{stream.releaseLock();}
      const bytes=new Uint8Array(count);
      let position=0;
      for(const chunk of chunks){bytes.set(chunk,position);position+=chunk.byteLength;}
      if(bytes.byteLength!==release.sizeBytes ||
         bytes.byteLength>maxBytes ||
         await digest(bytes)!==release.sha256)
        throw new Error('Release checksum verification failed');
      return bytes;
    }
  });
}
