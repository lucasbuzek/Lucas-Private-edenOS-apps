import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {webcrypto} from 'node:crypto';
globalThis.crypto ??= webcrypto;

const sessionSource=readFileSync(new URL('../functions/api/portal-session.js',import.meta.url)).toString();
const sessionModule='data:text/javascript;base64,'+Buffer.from(sessionSource).toString('base64');
let source=readFileSync(new URL('../functions/api/auth.js',import.meta.url)).toString();
source=source.replace("from './portal-session.js';","from '"+sessionModule+"';");
const {onRequest}=await import('data:text/javascript;base64,'+Buffer.from(source).toString('base64'));
const b64=data=>Buffer.from(typeof data==='string'?data:JSON.stringify(data)).toString('base64url');
const now=()=>Math.floor(Date.now()/1000);
const originalFetch=globalThis.fetch;
let env,identity,claimsExtra,claimsKey,fetches;
const keyPair=await crypto.subtle.generateKey({name:'RSASSA-PKCS1-v1_5',modulusLength:2048,publicExponent:new Uint8Array([1,0,1]),hash:'SHA-256'},true,['sign','verify']);
const publicJwk={...await crypto.subtle.exportKey('jwk',keyPair.publicKey),kid:'test-key',use:'sig',alg:'RS256'};
function database(){
 const attempts=new Map(),identities=new Map(),sessions=new Map();
 const user={id:'owner',subject:'pre-enrolled-subject',email:'owner@example.test',role:'owner',disabled_at:null};
 const db={
  attempts,identities,sessions,user,
  prepare(sql){
   let params=[];
   return {
    bind(...v){params=v;return this},
    async first(){
     if(sql.startsWith('SELECT code_verifier,nonce FROM raven_oauth_attempts')){
      const x=attempts.get(params[0]);
      return x?.provider===params[1]&&!x.consumed&&x.expires>=params[2]?{code_verifier:x.verifier,nonce:x.nonce}:null;
     }
     if(sql.includes('FROM raven_portal_identities i JOIN users')){
      const id=identities.get(params[0]+':'+params[1]);
      return id===user.id?{...user}:null;
     }
     if(sql.startsWith('SELECT id,email,role,disabled_at FROM users WHERE email')){
      return user.email===params[0]?{...user}:null;
     }
     if(sql.startsWith('SELECT user_id FROM raven_portal_identities')){
      const id=identities.get(params[0]+':'+params[1]);return id?{user_id:id}:null;
     }
     if(sql.includes('FROM raven_portal_sessions s JOIN users')){
      const s=sessions.get(params[0]);
      return s&&!s.revoked&&s.expires>params[1]?{...user}:null;
     }
     if(sql.includes("SELECT id FROM users WHERE role='owner'"))return {id:user.id};
     throw Error('Unexpected select: '+sql);
    },
    async run(){
     if(sql.startsWith('INSERT INTO raven_oauth_attempts')){
      attempts.set(params[0],{provider:params[1],verifier:params[2],nonce:params[3],expires:params[5],consumed:false});
      return {meta:{changes:1}};
     }
     if(sql.startsWith('UPDATE raven_oauth_attempts SET consumed_at')){
      const x=attempts.get(params[1]);if(!x||x.consumed||x.expires<params[2])return {meta:{changes:0}};
      x.consumed=true;return {meta:{changes:1}};
     }
     if(sql.startsWith('INSERT OR IGNORE INTO raven_portal_identities')){
      const key=params[0]+':'+params[1];if(!identities.has(key))identities.set(key,params[2]);
      return {meta:{changes:1}};
     }
     if(sql.startsWith('INSERT INTO raven_portal_sessions')){
      sessions.set(params[0],{id:params[1],expires:params[3],revoked:false});
      return {meta:{changes:1}};
     }
     if(sql.startsWith('UPDATE raven_portal_sessions SET revoked_at')){
      const s=sessions.get(params[1]);if(s)s.revoked=true;
      return {meta:{changes:s?1:0}};
     }
     throw Error('Unexpected write: '+sql);
    }
   };
  }
 };
 return db;
}
function setFixtures(){
 env={DB:database(),RAVEN_GOOGLE_CLIENT_ID:'test-google-client',RAVEN_GOOGLE_CLIENT_SECRET:'test-google-secret'};
 identity={sub:'google-user-123',email:'owner@example.test',email_verified:true,iss:'https://accounts.google.com',aud:'test-google-client'};
 claimsExtra={};
 claimsKey=keyPair.privateKey;
 fetches=[];
 globalThis.fetch=async(url,opts)=>{
  fetches.push({url:String(url),opts});
  if(String(url)==='https://www.googleapis.com/oauth2/v3/certs')return new Response(JSON.stringify({keys:[publicJwk]}));
  if(String(url)==='https://oauth2.googleapis.com/token'){
   const attempt=[...env.DB.attempts.values()][0];
   const head=b64({alg:'RS256',kid:'test-key'});
   const payload=b64({...identity,nonce:attempt.nonce,iat:now(),exp:now()+3600,...claimsExtra});
   const message=head+'.'+payload;
   const sig=new Uint8Array(await crypto.subtle.sign('RSASSA-PKCS1-v1_5',claimsKey,new TextEncoder().encode(message)));
   return new Response(JSON.stringify({id_token:message+'.'+b64(sig)}),{headers:{'content-type':'application/json'}});
  }
  throw Error('Unexpected remote fetch: '+url);
 };
}
function call(action,opts={}){
 const u=new URL('https://raven.example/api/auth?action='+action);
 for(const [k,v] of Object.entries(opts.query||{}))u.searchParams.set(k,v);
 return onRequest({request:new Request(u,{method:opts.method||'GET',headers:opts.headers||{},...(opts.body?{body:opts.body}:{})}),env});
}
async function start(){
 const response=await call('start',{query:{provider:'google'}});
 assert.equal(response.status,302);
 const dest=new URL(response.headers.get('location'));
 assert.equal(dest.hostname,'accounts.google.com');
 assert.equal(dest.searchParams.get('code_challenge_method'),'S256');
 assert.ok(dest.searchParams.get('code_challenge'));
 assert.ok(dest.searchParams.get('nonce'));
 const state=dest.searchParams.get('state');
 const cookie='__Host-raven_oauth_state='+state;
 assert.match(response.headers.get('set-cookie'),/HttpOnly/);
 return {state,cookie,dest};
}
async function callback(flow){
 return call('callback',{query:{provider:'google',state:flow.state,code:'authorization-code'},headers:{cookie:flow.cookie}});
}
test.beforeEach(()=>setFixtures());
test.afterEach(()=>{globalThis.fetch=originalFetch});

test('signed Google ID token logs in pre-enrolled owner; session is revocable',async()=>{
 const flow=await start();
 const result=await callback(flow);
 assert.equal(result.status,303);
 assert.equal(result.headers.get('location'),'/files.html');
 const cookies=result.headers.getSetCookie();
 const sessionCookie=cookies.find(x=>x.startsWith('__Host-raven_session='));
 assert.ok(sessionCookie);
 assert.match(sessionCookie,/Secure; HttpOnly; SameSite=Lax/);
 assert.equal(env.DB.sessions.size,1);
 const token=sessionCookie.split(';')[0];
 const identityStatus=await call('status',{headers:{cookie:token}});
 assert.deepEqual((await identityStatus.json()).user,{email:'owner@example.test',role:'owner'});
 assert.equal((await identityStatus.json().catch(()=>null)),null);
 const loggedOut=await call('logout',{method:'POST',headers:{cookie:token}});
 assert.equal(loggedOut.status,204);
 assert.equal((await (await call('status',{headers:{cookie:token}})).json()).authenticated,false);
 assert.equal((await callback(flow)).status,401,'authorization code state must be single-use');
});
test('anonymous status is unauthenticated and lists only configured login providers',async()=>{
 const r=await call('status');
 assert.deepEqual(await r.json(),{authenticated:false,providers:['google']});
});
test('callback rejects CSRF mismatch before calling provider',async()=>{
 const flow=await start();
 const r=await call('callback',{query:{provider:'google',state:flow.state,code:'authorization-code'},headers:{cookie:'__Host-raven_oauth_state=wrong'}});
 assert.equal(r.status,401);
 assert.equal(fetches.length,0);
});
test('invalid nonce in otherwise signed ID token fails closed',async()=>{
 const flow=await start();claimsExtra.nonce='different-nonce';
 const r=await callback(flow);
 assert.equal(r.status,401);assert.equal(env.DB.sessions.size,0);
});
test('unverified emails cannot self-enroll',async()=>{
 const flow=await start();identity.email_verified=false;
 const r=await callback(flow);
 assert.equal(r.status,403);assert.equal(env.DB.sessions.size,0);
});
test('unknown users are denied without creating accounts',async()=>{
 const flow=await start();identity.email='attacker@example.test';
 const r=await callback(flow);
 assert.equal(r.status,403);assert.equal(env.DB.sessions.size,0);
});
test('invalid audience, issuer and expired signed tokens are rejected',async()=>{
 for(const payload of [{aud:'wrong-audience'},{iss:'https://evil.example'},{exp:1}]){
  setFixtures();const flow=await start();Object.assign(claimsExtra,payload);
  const r=await callback(flow);assert.equal(r.status,401);assert.equal(env.DB.sessions.size,0);
 }
});
test('cross-origin logout, oversized OAuth callback and unconfigured Apple fail closed',async()=>{
 assert.equal((await call('logout',{method:'POST',headers:{origin:'https://evil.example'}})).status,403);
 assert.equal((await call('callback',{query:{provider:'google'},method:'POST',headers:{'content-type':'application/json'},body:'{}'})).status,400);
 assert.equal((await call('start',{query:{provider:'apple'}})).status,503);
});
