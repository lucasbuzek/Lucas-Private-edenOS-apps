import test from 'node:test';
import assert from 'node:assert/strict';
import {webcrypto} from 'node:crypto';
import {onRequest} from '../functions/mcp.js';
if(!globalThis.crypto)globalThis.crypto=webcrypto;
const {publicKey,privateKey}=await crypto.subtle.generateKey(
 {name:'RSASSA-PKCS1-v1_5',modulusLength:2048,publicExponent:new Uint8Array([1,0,1]),hash:'SHA-256'},true,['sign','verify']);
const jwk=await crypto.subtle.exportKey('jwk',publicKey);jwk.kid='appleraven-test-kid';
const b64=o=>Buffer.from(JSON.stringify(o)).toString('base64url');
async function jwt(over={}){
 const now=Math.floor(Date.now()/1000),head=b64({alg:'RS256',kid:jwk.kid});
 const payload=b64({iss:'https://raven-access.invalid',aud:['raven-aud'],sub:'owner-stable-sub',
  email:'owner@example.invalid',exp:now+120,...over});
 const signed=head+'.'+payload;
 const sig=await crypto.subtle.sign('RSASSA-PKCS1-v1_5',privateKey,new TextEncoder().encode(signed));
 return signed+'.'+Buffer.from(sig).toString('base64url');
}
const fetchBefore=globalThis.fetch;
globalThis.fetch=async()=>new Response(JSON.stringify({keys:[jwk]}),{headers:{'Content-Type':'application/json'}});
test.after(()=>{globalThis.fetch=fetchBefore});
const user={id:'usr_owner',subject:'owner-stable-sub',email:'owner@example.invalid',role:'owner',
  disabled_at:null};
const db={prepare(sql){
 const q=sql.toLowerCase();
 return {bind:()=>({
  first:async()=>q.includes('select * from users')?user:null,
  all:async()=>({results:[]}),
  run:async()=>({meta:{changes:0}})
 })};
}};
const env={DB:db,ACCESS_TEAM_DOMAIN:'raven-access.invalid',ACCESS_AUD:'raven-aud'};
function req(token,method='tools/list'){
 const headers={'Accept':'application/json, text/event-stream','Content-Type':'application/json',
  'MCP-Protocol-Version':'2026-07-28','Mcp-Method':method};
 if(token)headers['Cf-Access-Jwt-Assertion']=token;
 return new Request('https://raven.example.invalid/mcp',{method:'POST',headers,
  body:JSON.stringify({jsonrpc:'2.0',id:1,method,params:{_meta:{
   'io.modelcontextprotocol/protocolVersion':'2026-07-28',
   'io.modelcontextprotocol/clientCapabilities':{}
  }}})});
}
test('missing Access configuration fails closed',async()=>{
 assert.equal((await onRequest({request:req(''),env:{DB:db}})).status,503);
});
test('missing signed user assertion is rejected',async()=>{
 assert.equal((await onRequest({request:req(''),env})).status,401);
});
test('valid signed Access JWT and DB user can list read-only tools',async()=>{
 const r=await onRequest({request:req(await jwt()),env});
 assert.equal(r.status,200);
 assert.deepEqual((await r.json()).result.tools.map(x=>x.name),
  ['appleraven.nodes.status','appleraven.actions.status']);
});
test('wrong issuer rejected',async()=>{
 assert.equal((await onRequest({request:req(await jwt({iss:'https://attacker.invalid'})),env})).status,401);
});
test('wrong audience rejected',async()=>{
 assert.equal((await onRequest({request:req(await jwt({aud:['other-aud']})),env})).status,401);
});
test('signed but unprovisioned user denied',async()=>{
 const missing={...env,DB:{prepare:()=>({bind:()=>({first:async()=>null,all:async()=>({results:[]})})})}};
 assert.equal((await onRequest({request:req(await jwt()),env:missing})).status,401);
});
test('legacy operator keys are not accepted on /mcp',async()=>{
 const h=new Headers(req('').headers);
 h.set('Authorization','Bearer '+'a'.repeat(64));
 const original=req('');
 const request=new Request(original.url,{method:'POST',headers:h,body:await original.text()});
 assert.equal((await onRequest({request,env:{...env,OPERATOR_KEY_SHA256:'deadbeef'}})).status,401);
});
