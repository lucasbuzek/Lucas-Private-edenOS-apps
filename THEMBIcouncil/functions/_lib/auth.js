const cookieName="__Secure-tc_session";
function readCookie(req){const c=req.headers.get("Cookie")||"";return c.split(/;\s*/).find(x=>x.startsWith(cookieName+"="))?.slice(cookieName.length+1)||""}
async function digest(str){return [...new Uint8Array(await crypto.subtle.digest("SHA-256",new TextEncoder().encode(str)))].map(x=>x.toString(16).padStart(2,"0")).join("")}
function role(email,env){const o=String(env.COUNCIL_OWNER_EMAIL||"").toLowerCase().trim(),a=String(env.COUNCIL_ADMIN_EMAIL||"").toLowerCase().trim();if(!o||!a||o===a)return null;return email===o?"owner_admin":email===a?"founder_admin":null}
export function json(data,status=200,headers={}){return new Response(JSON.stringify(data),{status,headers:{"Content-Type":"application/json; charset=utf-8","Cache-Control":"no-store","X-Content-Type-Options":"nosniff","Referrer-Policy":"no-referrer",...headers}})}
export function exactOrigin(request){const origin=request.headers.get("Origin"),site=request.headers.get("Sec-Fetch-Site");return origin?origin===new URL(request.url).origin:site==="same-origin"}
export async function authenticated(context){
 const e=context.env;
 if(!e.COUNCIL_DB||!e.COUNCIL_OWNER_EMAIL||!e.COUNCIL_ADMIN_EMAIL||e.COUNCIL_PRODUCT_AUTH!=="enabled")return null;
 const token=readCookie(context.request);if(!/^[A-Za-z0-9_-]{43}$/.test(token))return null;
 const row=await e.COUNCIL_DB.prepare("SELECT email,subject,provider,expires_at FROM council_sessions WHERE token_hash=?1 AND expires_at>?2 AND revoked_at IS NULL LIMIT 1").bind(await digest(token),Date.now()).first();
 if(!row)return null;const email=String(row.email).toLowerCase().trim(),r=role(email,e);if(!r)return null;
 return {email,role:r,name:r==="owner_admin"?"Thembi":"Lucas",subject:row.subject,provider:row.provider}
}
export async function authorize(context){
 if(!["GET","HEAD"].includes(context.request.method)&&!exactOrigin(context.request))return {error:json({error:"invalid_request_origin"},403)};
 try{
  if(context.env.COUNCIL_PRODUCT_AUTH!=="enabled")return {error:json({error:"product_auth_not_ready"},503)};
  const user=await authenticated(context);return user?{user}:{error:json({error:"authentication_required"},401)}
 }catch{return {error:json({error:"auth_service_unavailable"},503)}}
}
export function issueSession(token){return cookieName+"="+token+"; Max-Age=604800; Path=/app; Secure; HttpOnly; SameSite=Lax"}
export function clearSession(){return cookieName+"=; Max-Age=0; Path=/app; Secure; HttpOnly; SameSite=Lax"}
export async function digestToken(token){return digest(token)}
export function roleFor(email,env){return role(String(email).toLowerCase().trim(),env)}
export function sessionToken(){const b=crypto.getRandomValues(new Uint8Array(32));let s="";for(const v of b)s+=String.fromCharCode(v);return btoa(s).replace(/\+/g,"-").replace(/\//g,"_").replace(/=/g,"")}
export function rawToken(req){return readCookie(req)}
