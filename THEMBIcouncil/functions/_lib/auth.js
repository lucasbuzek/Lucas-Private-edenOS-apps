const NOT_AUTH=Object.freeze({error:"authentication_required"});
const issued = (j)=>Response.json(j,{headers:{"Cache-Control":"no-store","X-Content-Type-Options":"nosniff","Referrer-Policy":"no-referrer"}});
function decodeBase64Url(data){const raw=atob(data.replace(/-/g,"+").replace(/_/g,"/").padEnd(Math.ceil(data.length/4)*4,"="));return Uint8Array.from(raw,c=>c.charCodeAt(0))}
function decodeJSON(data){return JSON.parse(new TextDecoder().decode(decodeBase64Url(data)))}
let keysCache=null;let keysUntil=0;
async function publicKeys(issuer){if(keysCache&&Date.now()<keysUntil)return keysCache;const r=await fetch(issuer+"/cdn-cgi/access/certs",{headers:{accept:"application/json"}});if(!r.ok)throw new Error("identity_keys_unavailable");const data=await r.json();if(!Array.isArray(data.keys)||!data.keys.length)throw new Error("identity_keys_unavailable");keysCache=data.keys;keysUntil=Date.now()+120000;return keysCache}
export async function authenticated(context){
  const env=context.env,issuer=String(env.COUNCIL_ACCESS_ISSUER||"").replace(/\/$/,"");
  const aud=String(env.COUNCIL_ACCESS_AUD||"");
  if(!env.COUNCIL_DB||!issuer||!aud||!env.COUNCIL_OWNER_EMAIL||!env.COUNCIL_ADMIN_EMAIL)throw new Error("identity_not_configured");
  const jwt=context.request.headers.get("Cf-Access-Jwt-Assertion");
  if(!jwt||jwt.length>8192)return null;
  const parts=jwt.split(".");if(parts.length!==3)return null;
  try{
    const head=decodeJSON(parts[0]),payload=decodeJSON(parts[1]);
    if(head.alg!=="RS256"||typeof head.kid!=="string"||payload.iss!==issuer||!Array.isArray(payload.aud)||!payload.aud.includes(aud))return null;
    const sec=Math.floor(Date.now()/1000);
    if(typeof payload.exp!=="number"||payload.exp<=sec||typeof payload.iat!=="number"||payload.iat>sec+60||payload.nbf&&payload.nbf>sec+60)return null;
    const keys=await publicKeys(issuer),jwk=keys.find(k=>k.kid===head.kid&&k.kty==="RSA");
    if(!jwk)return null;
    const key=await crypto.subtle.importKey("jwk",jwk,{name:"RSASSA-PKCS1-v1_5",hash:"SHA-256"},false,["verify"]);
    const input=new TextEncoder().encode(parts[0]+"."+parts[1]),sig=decodeBase64Url(parts[2]);
    if(!await crypto.subtle.verify("RSASSA-PKCS1-v1_5",key,sig,input))return null;
    const email=String(payload.email||"").toLowerCase().trim(),owner=String(env.COUNCIL_OWNER_EMAIL).toLowerCase().trim(),admin=String(env.COUNCIL_ADMIN_EMAIL).toLowerCase().trim();
    if(email!==owner&&email!==admin)return null;
    return {email,role:email===owner?"owner_admin":"founder_admin",name:email===owner?"Thembi":"Lucas"};
  }catch{return null}
}
export async function authorize(context){
 const request=context.request;
 if(!["GET","HEAD"].includes(request.method)){const origin=request.headers.get("Origin");if(!origin||origin!==new URL(request.url).origin)return {error:issued({error:"invalid_request_origin"},403)}}
 try{const user=await authenticated(context);if(!user)return {error:new Response(JSON.stringify(NOT_AUTH),{status:401,headers:{"Content-Type":"application/json","Cache-Control":"no-store"}})};return {user}}catch{return {error:new Response(JSON.stringify({error:"service_unavailable"}),{status:503,headers:{"Content-Type":"application/json","Cache-Control":"no-store"}})}}
}
export function json(data,status=200){return new Response(JSON.stringify(data),{status,headers:{"Content-Type":"application/json; charset=utf-8","Cache-Control":"no-store","X-Content-Type-Options":"nosniff"}})}
