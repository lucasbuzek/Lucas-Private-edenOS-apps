// Independent web user sessions. Cloudflare Access remains an optional ADMIN boundary.
// No OAuth/provider token is stored in a browser or in this session table.
const COOKIE='__Host-raven_session', AGE=12*60*60;
const enc=new TextEncoder();
const b64url=a=>btoa(String.fromCharCode(...a)).replace(/\+/g,'-').replace(/\//g,'_').replace(/=+$/g,'');
export const randomToken=(n=32)=>b64url(crypto.getRandomValues(new Uint8Array(n)));
export async function hashToken(s){
 const digest=await crypto.subtle.digest('SHA-256',enc.encode(s));
 return [...new Uint8Array(digest)].map(x=>x.toString(16).padStart(2,'0')).join('');
}
export function cookieValue(request,name){
 const h=request.headers.get('cookie')||'';
 for(const part of h.split(';')){const x=part.trim();if(x.startsWith(name+'='))return x.slice(name.length+1)}
 return null;
}
export async function portalUser(request,env){
 if(!env.DB)return null;
 const token=cookieValue(request,COOKIE);
 if(typeof token!=='string'||!(/^[A-Za-z0-9_-]{43,64}$/.test(token)))return null;
 const digest=await hashToken(token);
 const u=await env.DB.prepare('SELECT u.id,u.subject,u.email,u.role,u.disabled_at FROM raven_portal_sessions s JOIN users u ON u.id=s.user_id WHERE s.token_hash=?1 AND s.revoked_at IS NULL AND s.expires_at>?2 AND u.disabled_at IS NULL').bind(digest,Math.floor(Date.now()/1000)).first();
 return u&&!u.disabled_at?u:null;
}
export async function issueSession(env,userId){
 const token=randomToken(),created=Math.floor(Date.now()/1000);
 await env.DB.prepare('INSERT INTO raven_portal_sessions(token_hash,user_id,created_at,expires_at) VALUES(?1,?2,?3,?4)').bind(await hashToken(token),userId,created,created+AGE).run();
 return {token,cookie:COOKIE+'='+token+'; Secure; HttpOnly; SameSite=Lax; Path=/; Max-Age='+AGE};
}
export const expiredSessionCookie=()=>COOKIE+'=; Secure; HttpOnly; SameSite=Lax; Path=/; Max-Age=0';
export async function revokeSession(request,env){
 const token=cookieValue(request,COOKIE);
 if(token&&/^[A-Za-z0-9_-]{43,64}$/.test(token))
  await env.DB.prepare('UPDATE raven_portal_sessions SET revoked_at=?1 WHERE token_hash=?2 AND revoked_at IS NULL').bind(Math.floor(Date.now()/1000),await hashToken(token)).run();
}
