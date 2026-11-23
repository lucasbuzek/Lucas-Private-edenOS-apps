// Cloudflare Pages Function: owner-authorized reverse proxy to the real Postiz runtime.
// Never serve an unprotected immutable deployment URL, or a fake backend fallback.
const textResponse=(message,status,headers={})=>new Response(message,{status,headers:{'Cache-Control':'no-store','X-Robots-Tag':'noindex',...headers}});
const b64urlBytes=(value)=>{
  if(!/^[A-Za-z0-9_-]+$/.test(value))throw new Error('Malformed JWT');
  const base64=value.replace(/-/g,'+').replace(/_/g,'/')+'='.repeat((4-value.length%4)%4);
  return Uint8Array.from(atob(base64),c=>c.charCodeAt(0));
};
const b64urlJson=(value)=>JSON.parse(new TextDecoder().decode(b64urlBytes(value)));

export async function verifyOwnerJwt(request,env,fetchImpl=fetch){
  const jwt=request.headers.get('Cf-Access-Jwt-Assertion');
  if(!jwt)return {ok:false,status:401};
  const team=env.ACCESS_TEAM_DOMAIN;
  const audience=env.ACCESS_AUD;
  const owner=env.BRAGI_OWNER_EMAIL;
  if(!team||!audience||!owner||!/^[a-z0-9-]+\.cloudflareaccess\.com$/.test(team))return {ok:false,status:503};
  try{
    const parts=jwt.split('.'); if(parts.length!==3)return {ok:false,status:403};
    const header=b64urlJson(parts[0]);const claims=b64urlJson(parts[1]);
    const now=Math.floor(Date.now()/1000);
    if(header.alg!=='RS256'||!header.kid||claims.iss!==`https://${team}` ||
      !Array.isArray(claims.aud)||!claims.aud.includes(audience)||
      claims.email?.toLowerCase()!==owner.toLowerCase()||
      typeof claims.exp!=='number'||claims.exp<=now||
      (typeof claims.nbf==='number'&&claims.nbf>now))return {ok:false,status:403};
    const certs=await fetchImpl(`https://${team}/cdn-cgi/access/certs`,{cf:{cacheTtl:300,cacheEverything:true}});
    if(!certs.ok)return {ok:false,status:503};
    const jwks=await certs.json();
    const jwk=jwks.keys?.find(x=>x.kid===header.kid&&x.kty==='RSA');
    if(!jwk)return {ok:false,status:403};
    const publicKey=await crypto.subtle.importKey('jwk',jwk,{name:'RSASSA-PKCS1-v1_5',hash:'SHA-256'},false,['verify']);
    const bytes=new TextEncoder().encode(`${parts[0]}.${parts[1]}`);
    const verified=await crypto.subtle.verify('RSASSA-PKCS1-v1_5',publicKey,b64urlBytes(parts[2]),bytes);
    return {ok:verified,status:verified?200:403};
  }catch{return {ok:false,status:403};}
}

export async function onRequest({request,env}){
  const owner=await verifyOwnerJwt(request,env);
  if(!owner.ok)return textResponse(owner.status===401?'Authentication required':owner.status===503?'Authentication configuration unavailable':'Forbidden',owner.status);
  if(!env.POSTIZ_ORIGIN)return textResponse('BRAGI Postiz engine is not configured',503);
  let origin;
  try{
    origin=new URL(env.POSTIZ_ORIGIN);
    if(origin.protocol!=='https:'||origin.username||origin.password||origin.pathname!=='/'||origin.search||origin.hash)throw new Error('Unsafe upstream');
  }catch{return textResponse('Upstream configuration invalid',503);}
  if(Boolean(env.POSTIZ_SERVICE_CLIENT_ID)!==Boolean(env.POSTIZ_SERVICE_CLIENT_SECRET))return textResponse('Upstream authentication incomplete',503);
  const browser=new URL(request.url);
  const destination=new URL(browser.pathname+browser.search,origin);
  const headers=new Headers(request.headers);
  for(const key of [...headers.keys()]){
    if(key.toLowerCase().startsWith('cf-access-')||['host','x-forwarded-host','x-forwarded-proto','x-real-ip','proxy-authorization'].includes(key.toLowerCase()))headers.delete(key);
  }
  if(env.POSTIZ_SERVICE_CLIENT_ID){
    headers.set('CF-Access-Client-Id',env.POSTIZ_SERVICE_CLIENT_ID);
    headers.set('CF-Access-Client-Secret',env.POSTIZ_SERVICE_CLIENT_SECRET);
  }
  let response;
  try{
    response=await fetch(new Request(destination,{method:request.method,headers,body:['GET','HEAD'].includes(request.method)?undefined:request.body,redirect:'manual'}));
  }catch{return textResponse('Postiz engine unavailable',502);}
  const result=new Response(response.body,{status:response.status,statusText:response.statusText,headers:response.headers});
  result.headers.set('Cache-Control','private, no-store');
  result.headers.set('X-Robots-Tag','noindex');
  result.headers.set('X-Content-Type-Options','nosniff');
  const location=result.headers.get('Location');
  if(location){
    try{const target=new URL(location,origin);if(target.origin===origin.origin){target.protocol=browser.protocol;target.host=browser.host;result.headers.set('Location',target.toString());}}catch{}
  }
  const cookies=response.headers.getSetCookie?.()||[];
  if(cookies.length){
    result.headers.delete('Set-Cookie');
    for(const cookie of cookies)result.headers.append('Set-Cookie',cookie.replace(/;\s*Domain=[^;]+/ig,''));
  }
  return result;
}
