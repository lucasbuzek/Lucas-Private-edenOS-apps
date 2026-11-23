import {test} from 'node:test';
import assert from 'node:assert/strict';
import {generateKeyPairSync,sign as nodeSign} from 'node:crypto';
import {onRequest,verifyOwnerJwt} from '../edge/functions/[[path]].js';
const {privateKey,publicKey}=generateKeyPairSync('rsa',{modulusLength:2048});
const jwk={...publicKey.export({format:'jwk'}),kid:'test-key',alg:'RS256'};
const env={ACCESS_TEAM_DOMAIN:'floral-sky-7240.cloudflareaccess.com',ACCESS_AUD:'test-audience',BRAGI_OWNER_EMAIL:'lucasbuzek@gmail.com',POSTIZ_ORIGIN:'https://postiz-origin.example'};
const enc=data=>Buffer.from(typeof data==='string'?data:JSON.stringify(data)).toString('base64url');
function token(overrides={}){const header=enc({alg:'RS256',kid:'test-key'});const payload=enc({iss:`https://${env.ACCESS_TEAM_DOMAIN}`,aud:['test-audience'],email:'lucasbuzek@gmail.com',exp:Math.floor(Date.now()/1000)+600,...overrides});const sig=nodeSign('RSA-SHA256',Buffer.from(`${header}.${payload}`),privateKey).toString('base64url');return `${header}.${payload}.${sig}`;}
const req=(jwt,path='/studio')=>new Request('https://bragiapp.ravensnest.pages.dev'+path,{headers:jwt?{'Cf-Access-Jwt-Assertion':jwt}:{} });
const originalFetch=globalThis.fetch;
const fetched=[];
globalThis.fetch=async(input,init)=>{
  const u=typeof input==='string'?input:input.url;fetched.push({url:u,headers:input?.headers});
  if(u.includes('/cdn-cgi/access/certs'))return Response.json({keys:[jwk]});
  return new Response('UPSTREAM_REAL_RESPONSE',{status:200,headers:{'Location':'https://postiz-origin.example/dashboard'}});
};
test('anonymous never receives a backend fetch',async()=>{fetched.length=0;const res=await onRequest({request:req(),env});assert.equal(res.status,401);assert.equal(fetched.length,0)});
test('forged owner email is denied despite valid signature',async()=>{fetched.length=0;const res=await onRequest({request:req(token({email:'someone@example.com'})),env});assert.equal(res.status,403);assert.equal(fetched.length,0)});
test('wrong Access audience denied',async()=>assert.equal((await onRequest({request:req(token({aud:['other']})),env})).status,403));
test('expired token denied',async()=>assert.equal((await onRequest({request:req(token({exp:1})),env})).status,403));
test('signature tampering denied',async()=>{const jwt=token();const [h,p,s]=jwt.split('.');const tampered=s[0]==='A'?'B'+s.slice(1):'A'+s.slice(1);assert.equal((await onRequest({request:req(`${h}.${p}.${tampered}`),env})).status,403)});
test('owner is proxied, Access JWT never forwarded, redirect rewritten',async()=>{fetched.length=0;const res=await onRequest({request:req(token(),'/api/posts?page=1'),env});assert.equal(res.status,200);assert.equal(await res.text(),'UPSTREAM_REAL_RESPONSE');const last=fetched.at(-1);assert.equal(last.url,'https://postiz-origin.example/api/posts?page=1');assert.equal(last.headers.get('Cf-Access-Jwt-Assertion'),null);assert.equal(res.headers.get('Location'),'https://bragiapp.ravensnest.pages.dev/dashboard')});
test('unconfigured Postiz origin fails closed',async()=>assert.equal((await onRequest({request:req(token()),env:{...env,POSTIZ_ORIGIN:''}})).status,503));
test('HTTP Postiz upstream rejected',async()=>assert.equal((await onRequest({request:req(token()),env:{...env,POSTIZ_ORIGIN:'http://postiz-origin.example'}})).status,503));
test('incomplete service auth rejected',async()=>assert.equal((await onRequest({request:req(token()),env:{...env,POSTIZ_SERVICE_CLIENT_ID:'abc'}})).status,503));
test('token certificate absent rejected',async()=>{const f=globalThis.fetch;globalThis.fetch=async()=>Response.json({keys:[]});try{assert.equal((await onRequest({request:req(token()),env})).status,403)}finally{globalThis.fetch=f}});
