// Independent owner/invited-user OIDC login. Google/Apple authorization code + PKCE.
// Provider identities are user-specific; provider-file OAuth grants remain separate.
// Configuration requires explicit client IDs/secrets and the verified target origin.
import {randomToken,hashToken,cookieValue,portalUser,issueSession,expiredSessionCookie,revokeSession} from './portal-session.js';
const AUTH_COOKIE='__Host-raven_oauth_state',TEN_MIN=600,encoder=new TextEncoder();
const J=(x,s=200)=>new Response(JSON.stringify(x),{status:s,headers:{'content-type':'application/json','cache-control':'no-store','x-content-type-options':'nosniff','referrer-policy':'no-referrer'}});
const bad=(s='Authentication unavailable',status=401)=>J({error:s},status);
const eraseOAuth=()=>AUTH_COOKIE+'=; Secure; HttpOnly; SameSite=None; Path=/; Max-Age=0';
const b64url=a=>btoa(String.fromCharCode(...a)).replace(/\+/g,'-').replace(/\//g,'_').replace(/=+$/g,'');
const unb64url=s=>Uint8Array.from(atob(s.replace(/-/g,'+').replace(/_/g,'/')+'='.repeat((4-s.length%4)%4)),c=>c.charCodeAt(0));
const sha256=async s=>b64url(new Uint8Array(await crypto.subtle.digest('SHA-256',encoder.encode(s))));
function config(provider,env){
 if(provider==='google'&&env.RAVEN_GOOGLE_CLIENT_ID&&env.RAVEN_GOOGLE_CLIENT_SECRET)
  return {clientId:env.RAVEN_GOOGLE_CLIENT_ID,clientSecret:env.RAVEN_GOOGLE_CLIENT_SECRET,auth:'https://accounts.google.com/o/oauth2/v2/auth',token:'https://oauth2.googleapis.com/token',jwks:'https://www.googleapis.com/oauth2/v3/certs'};
 if(provider==='apple'&&env.RAVEN_APPLE_CLIENT_ID&&env.RAVEN_APPLE_TEAM_ID&&env.RAVEN_APPLE_KEY_ID&&env.RAVEN_APPLE_PRIVATE_KEY)
  return {clientId:env.RAVEN_APPLE_CLIENT_ID,auth:'https://appleid.apple.com/auth/authorize',token:'https://appleid.apple.com/auth/token',jwks:'https://appleid.apple.com/auth/keys'};
 return null;
}
const callbackUrl=(url,provider)=>url.origin+'/api/auth?action=callback&provider='+provider;
async function appleClientSecret(env,clientId){
 const pem=String(env.RAVEN_APPLE_PRIVATE_KEY||'').replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g,'');
 const bytes=Uint8Array.from(atob(pem),c=>c.charCodeAt(0));
 const key=await crypto.subtle.importKey('pkcs8',bytes,{name:'ECDSA',namedCurve:'P-256'},false,['sign']);
 const now=Math.floor(Date.now()/1000);
 const header=b64url(encoder.encode(JSON.stringify({alg:'ES256',kid:env.RAVEN_APPLE_KEY_ID,typ:'JWT'})));
 const body=b64url(encoder.encode(JSON.stringify({iss:env.RAVEN_APPLE_TEAM_ID,iat:now,exp:now+300,aud:'https://appleid.apple.com',sub:clientId})));
 const signature=await crypto.subtle.sign({name:'ECDSA',hash:'SHA-256'},key,encoder.encode(header+'.'+body));
 return header+'.'+body+'.'+b64url(new Uint8Array(signature));
}
async function verifyIdentity(idToken,provider,cfg,nonce){
 if(typeof idToken!=='string'||idToken.length>12000)throw Error('Invalid ID token');
 const parts=idToken.split('.');if(parts.length!==3)throw Error('Invalid ID token');
 const header=JSON.parse(new TextDecoder().decode(unb64url(parts[0])));
 const claims=JSON.parse(new TextDecoder().decode(unb64url(parts[1])));
 if(header.alg!=='RS256'||typeof header.kid!=='string')throw Error('Invalid ID token');
 const r=await fetch(cfg.jwks,{redirect:'error'});
 if(!r.ok)throw Error('Provider identity unavailable');
 const jwks=await r.json(),jwk=(jwks.keys||[]).find(x=>x.kid===header.kid&&x.kty==='RSA');
 if(!jwk)throw Error('Invalid signing key');
 const key=await crypto.subtle.importKey('jwk',jwk,{name:'RSASSA-PKCS1-v1_5',hash:'SHA-256'},false,['verify']);
 const valid=await crypto.subtle.verify('RSASSA-PKCS1-v1_5',key,unb64url(parts[2]),encoder.encode(parts[0]+'.'+parts[1]));
 const now=Math.floor(Date.now()/1000);
 const issuer=provider==='google'?['https://accounts.google.com','accounts.google.com']:['https://appleid.apple.com'];
 if(!valid||!issuer.includes(claims.iss)||claims.aud!==cfg.clientId||claims.nonce!==nonce||
  typeof claims.sub!=='string'||!claims.sub||claims.sub.length>255||
  !Number.isFinite(claims.exp)||claims.exp<=now||!Number.isFinite(claims.iat)||claims.iat>now+60)
  throw Error('Invalid ID token');
 return claims;
}
function extractEmail(claims){
 if(typeof claims.email!=='string'||claims.email.length>255||
  !(claims.email_verified===true||claims.email_verified==='true'))return null;
 const mail=claims.email.trim().toLowerCase();
 return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(mail)?mail:null;
}
async function linkedUser(env,provider,claims){
 const now=Math.floor(Date.now()/1000);
 const linked=await env.DB.prepare('SELECT u.id,u.email,u.role,u.disabled_at FROM raven_portal_identities i JOIN users u ON u.id=i.user_id WHERE i.provider=?1 AND i.provider_subject=?2').bind(provider,claims.sub).first();
 if(linked)return linked.disabled_at?null:linked;
 const email=extractEmail(claims);if(!email)return null;
 let user=await env.DB.prepare('SELECT id,email,role,disabled_at FROM users WHERE email=?1').bind(email).first();
 // Owner bootstrap is explicitly allowlisted; never create a member or owner for arbitrary email.
 if(!user&&env.RAVEN_BOOTSTRAP_OWNER_EMAIL?.trim().toLowerCase()===email){
  const existing=await env.DB.prepare("SELECT id FROM users WHERE role='owner' LIMIT 1").first();
  if(!existing){
   const id='usr_'+[...crypto.getRandomValues(new Uint8Array(12))].map(x=>x.toString(16).padStart(2,'0')).join('');
   await env.DB.prepare("INSERT OR IGNORE INTO users(id,subject,email,display_name,role,created_at) VALUES(?1,?2,?3,?4,'owner',?5)").bind(id,'oidc:'+provider+':'+claims.sub,email,claims.name||email,now*1000).run();
   user=await env.DB.prepare('SELECT id,email,role,disabled_at FROM users WHERE email=?1').bind(email).first();
  }
 }
 if(!user||user.disabled_at)return null;
 await env.DB.prepare('INSERT OR IGNORE INTO raven_portal_identities(provider,provider_subject,user_id,linked_at) VALUES(?1,?2,?3,?4)').bind(provider,claims.sub,user.id,now).run();
 const resolved=await env.DB.prepare('SELECT user_id FROM raven_portal_identities WHERE provider=?1 AND provider_subject=?2').bind(provider,claims.sub).first();
 return resolved?.user_id===user.id?user:null;
}
async function start(request,env,url){
 const provider=url.searchParams.get('provider'),cfg=config(provider,env);
 if(!cfg)return bad('Sign-in provider not configured',503);
 if(!env.DB)return bad('Identity storage unavailable',503);
 const state=randomToken(),nonce=randomToken(),verifier=randomToken(48),now=Math.floor(Date.now()/1000);
 await env.DB.prepare('INSERT INTO raven_oauth_attempts(state_hash,provider,code_verifier,nonce,created_at,expires_at) VALUES(?1,?2,?3,?4,?5,?6)').bind(await hashToken(state),provider,verifier,nonce,now,now+TEN_MIN).run();
 const target=new URL(cfg.auth);
 for(const [k,v] of Object.entries({client_id:cfg.clientId,redirect_uri:callbackUrl(url,provider),response_type:'code',scope:provider==='apple'?'name email':'openid email profile',state,nonce,code_challenge:await sha256(verifier),code_challenge_method:'S256'}))target.searchParams.set(k,v);
 if(provider==='apple')target.searchParams.set('response_mode','form_post');
 else target.searchParams.set('prompt','select_account');
 return new Response(null,{status:302,headers:{location:target.toString(),'set-cookie':AUTH_COOKIE+'='+state+'; Secure; HttpOnly; SameSite=None; Path=/; Max-Age='+TEN_MIN,'cache-control':'no-store','referrer-policy':'no-referrer'}});
}
async function callback(request,env,url){
 const provider=url.searchParams.get('provider'),cfg=config(provider,env);
 if(!cfg||!env.DB)return bad('Sign-in provider unavailable',503);
 if(request.method==='POST'&&(Number(request.headers.get('content-length')||0)>8192||!String(request.headers.get('content-type')||'').startsWith('application/x-www-form-urlencoded')))return bad('Invalid callback payload',400);
 const p=request.method==='POST'?await request.formData():url.searchParams;
 const state=p.get('state'),code=p.get('code');
 if(typeof state!=='string'||typeof code!=='string'||state.length>128||code.length>3000||
  !state||!code||cookieValue(request,AUTH_COOKIE)!==state)return bad('Sign-in state invalid');
 const now=Math.floor(Date.now()/1000),digest=await hashToken(state);
 const attempt=await env.DB.prepare('SELECT code_verifier,nonce FROM raven_oauth_attempts WHERE state_hash=?1 AND provider=?2 AND consumed_at IS NULL AND expires_at>=?3').bind(digest,provider,now).first();
 if(!attempt)return bad('Sign-in attempt expired');
 const done=await env.DB.prepare('UPDATE raven_oauth_attempts SET consumed_at=?1 WHERE state_hash=?2 AND consumed_at IS NULL AND expires_at>=?3').bind(now,digest,now).run();
 if(done.meta?.changes!==1)return bad('Sign-in attempt already used');
 const body=new URLSearchParams({grant_type:'authorization_code',code,redirect_uri:callbackUrl(url,provider),client_id:cfg.clientId,code_verifier:attempt.code_verifier});
 body.set('client_secret',provider==='apple'?await appleClientSecret(env,cfg.clientId):cfg.clientSecret);
 const tokenResp=await fetch(cfg.token,{method:'POST',headers:{'content-type':'application/x-www-form-urlencoded'},body,redirect:'error'});
 if(!tokenResp.ok)return bad('Provider sign-in refused');
 const tokens=await tokenResp.json(),claims=await verifyIdentity(tokens.id_token,provider,cfg,attempt.nonce);
 const user=await linkedUser(env,provider,claims);
 if(!user)return bad('Account is not enrolled for this portal',403);
 const session=await issueSession(env,user.id);
 const response=new Response(null,{status:303,headers:{location:'/files.html','cache-control':'no-store','referrer-policy':'no-referrer'}});
 response.headers.append('set-cookie',eraseOAuth());
 response.headers.append('set-cookie',session.cookie);
 return response;
}
export async function onRequest({request,env}){
 const url=new URL(request.url),action=url.searchParams.get('action')||'status';
 if(action!=='callback'&&(request.headers.get('origin')&&request.headers.get('origin')!==url.origin||request.headers.get('sec-fetch-site')==='cross-site'))return bad('Cross-origin request denied',403);
 try{
  if(action==='status'&&request.method==='GET'){
   const user=await portalUser(request,env);
   const providers=['google','apple'].filter(p=>!!config(p,env));
   return J(user?{authenticated:true,user:{email:user.email,role:user.role},providers}:{authenticated:false,providers});
  }
  if(action==='start'&&request.method==='GET')return start(request,env,url);
  if(action==='callback'&&(request.method==='GET'||request.method==='POST'))return callback(request,env,url);
  if(action==='logout'&&request.method==='POST'){
   await revokeSession(request,env);
   const response=new Response(null,{status:204,headers:{'cache-control':'no-store'}});
   response.headers.append('set-cookie',expiredSessionCookie());
   return response;
  }
  return bad('Method or route not available',405);
 }catch{return bad('Sign-in failed',401)}
}
