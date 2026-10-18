import test from 'node:test';
import assert from 'node:assert/strict';
import { createClosedTestingGateway } from '../closed-testing/gateway.mjs';
import { createTurnstileVerifier } from '../closed-testing/turnstile.mjs';
import { normalizeEmail } from '../closed-testing/d1.mjs';

const APP = 'cresus';
const privateHost = 'private.cresus.example';
const waitlistHost = 'join.cresus.example';
const OWNER = 'owner@example.com';
const origin = 'https://' + privateHost;

function fixture() {
  const rows=new Map();
  let forward=0,checks=0;
  const store={
    async request(app,email) {
      const key=app+'|'+email;
      if(!rows.has(key))rows.set(key,{email,status:'pending',requested_at:'2026-10-18',reviewed_at:null,reviewed_by:null});
    },
    async isApproved(app,email) {
      return rows.get(app+'|'+email)?.status==='approved';
    },
    async list(app) {
      return [...rows.entries()].filter(([key])=>key.startsWith(app+'|')).map(([,row])=>({...row}));
    },
    async decide(app,email,decision,reviewer) {
      const row=rows.get(app+'|'+email);
      if(!row)return false;
      row.status=decision==='approve'?'approved':'denied';
      row.reviewed_by=reviewer;
      return true;
    },
  };
  const appFetch=async request => {forward++;return new Response('PRIVATE_APP_OK:'+new URL(request.url).pathname);};
  const authenticate=async request => {
    const v=request.headers.get('x-test-principal'); // a fake verifier used only in tests
    if(!v)return null;
    return {id:v,email:v};
  };
  const verifyTurnstile=async token => {checks++;return token==='valid-turnstile-token';};
  const gateway=createClosedTestingGateway({appId:APP,appName:'CRESUS',ownerEmail:OWNER,privateHost,waitlistHost,
    turnstileSiteKey:'publicTestKey123',store,appFetch,authenticate,verifyTurnstile});
  return {gateway,store,rows,get forward(){return forward},get checks(){return checks}};
}

function req(host,path,method='GET',body=null,{principal=null,originHeader=undefined}={}) {
  const url='https://'+host+path;
  const headers={};
  if(principal)headers['x-test-principal']=principal;
  if(method!=='GET' && originHeader!==null)headers.origin=originHeader||'https://'+host;
  if(body!==null)headers['content-type']='application/x-www-form-urlencoded';
  return new Request(url,{method,headers,body});
}
const submit=(email,token='valid-turnstile-token') =>
  new URLSearchParams({email,'cf-turnstile-response':token}).toString();

test('public waitlist host serves only form; never application or private admin',async()=>{
  const f=fixture();
  const publicForm=await f.gateway.fetch(req(waitlistHost,'/'));
  assert.equal(publicForm.status,200);
  const text=await publicForm.text();
  assert.match(text,/closed testing/);
  assert.match(text,/cf-turnstile/);
  assert.equal((await f.gateway.fetch(req(waitlistHost,'/api/chat'))).status,404);
  assert.equal((await f.gateway.fetch(req(waitlistHost,'/admin'))).status,404);
  assert.equal(f.forward,0);
});

test('public request requires a real Turnstile decision and same-origin submission',async()=>{
  const f=fixture();
  assert.equal((await f.gateway.fetch(req(waitlistHost,'/api/waitlist/request','POST',submit('a@example.com','invalid')))).status,403);
  assert.equal((await f.gateway.fetch(req(waitlistHost,'/api/waitlist/request','POST',submit('a@example.com'),{originHeader:null}))).status,403);
  assert.equal((await f.gateway.fetch(req(waitlistHost,'/api/waitlist/request','POST',submit('a@example.com'),{originHeader:'https://attacker.example'}))).status,403);
  assert.equal((await f.gateway.fetch(req(waitlistHost,'/api/waitlist/request','POST',submit('invalid-address')))).status,400);
  assert.equal(f.rows.size,0);
  assert.equal((await f.gateway.fetch(req(waitlistHost,'/api/waitlist/request','POST',submit('  Person@Example.com  ')))).status,202);
  assert.equal(f.rows.get(APP+'|person@example.com').status,'pending');
  assert.equal(f.forward,0);
});

test('no verified identity or pending/denied membership can access any private assets, API or service worker',async()=>{
  const f=fixture();
  await f.store.request(APP,'tester@example.com');
  for(const path of ['/','/app.js','/sw.js','/api/chat','/api/closed-test/me']){
    assert.equal((await f.gateway.fetch(req(privateHost,path))).status,401);
    assert.equal((await f.gateway.fetch(req(privateHost,path,'GET',null,{principal:'tester@example.com'}))).status,403);
  }
  await f.store.decide(APP,'tester@example.com','deny',OWNER);
  assert.equal((await f.gateway.fetch(req(privateHost,'/','GET',null,{principal:'tester@example.com'}))).status,403);
  assert.equal(f.forward,0);
});

test('only the verified owner can approve and deny, and denial revokes forwarded app access immediately',async()=>{
  const f=fixture();
  await f.store.request(APP,'tester@example.com');
  assert.equal((await f.gateway.fetch(req(privateHost,'/api/admin/waitlist','GET',null,{principal:'tester@example.com'}))).status,403);
  const listing=await f.gateway.fetch(req(privateHost,'/api/admin/waitlist','GET',null,{principal:OWNER}));
  assert.equal(listing.status,200);
  assert.equal((await listing.json()).requests[0].status,'pending');
  const approval=req(privateHost,'/api/admin/waitlist/decision','POST',new URLSearchParams({
    email:'tester@example.com',decision:'approve'
  }),{principal:OWNER});
  const result=await f.gateway.fetch(approval);
  assert.equal(result.status,200);
  assert.equal((await result.json()).accessPolicySync,'REQUIRES_VERIFICATION');
  assert.equal((await f.gateway.fetch(req(privateHost,'/api/chat','GET',null,{principal:'tester@example.com'}))).status,200);
  assert.equal(f.forward,1);
  const denial=req(privateHost,'/api/admin/waitlist/decision','POST',new URLSearchParams({
    email:'tester@example.com',decision:'deny'
  }),{principal:OWNER});
  assert.equal((await f.gateway.fetch(denial)).status,200);
  assert.equal((await f.gateway.fetch(req(privateHost,'/api/chat','GET',null,{principal:'tester@example.com'}))).status,403);
  assert.equal(f.forward,1);
});

test('unapproved users cannot self-approve, and cross-app membership is not inherited',async()=>{
  const f=fixture();
  await f.store.request('hermes','tester@example.com');
  await f.store.decide('hermes','tester@example.com','approve',OWNER);
  assert.equal((await f.gateway.fetch(req(privateHost,'/api/chat','GET',null,{principal:'tester@example.com'}))).status,403);
  const spoof=req(privateHost,'/api/admin/waitlist/decision','POST',new URLSearchParams({
    email:'tester@example.com',decision:'approve'
  }),{principal:'tester@example.com'});
  assert.equal((await f.gateway.fetch(spoof)).status,403);
});

test('owner dashboard sanitizes applicant email and disallows invalid review',async()=>{
  const f=fixture();
  await f.store.request(APP,'member@example.com');
  const dash=await f.gateway.fetch(req(privateHost,'/admin','GET',null,{principal:OWNER}));
  assert.equal(dash.status,200);
  assert.match(await dash.text(),/member@example.com/);
  const bad=req(privateHost,'/admin/decision','POST',new URLSearchParams({
    email:OWNER,decision:'approve'
  }),{principal:OWNER});
  assert.equal((await f.gateway.fetch(bad)).status,400);
});

test('unrecognized hosts and non-HTTPS origins are rejected before serving any app content',async()=>{
  const f=fixture();
  assert.equal((await f.gateway.fetch(new Request('http://'+privateHost+'/'))).status,403);
  assert.equal((await f.gateway.fetch(req('wrong.example','/'))).status,421);
  assert.equal(f.forward,0);
});

test('Turnstile server verification enforces exact origin/action and rejects tokens after provider failure',async()=>{
  let calls=0;
  const create=(payload,status=200)=>createTurnstileVerifier({
    secret:'PRIVATE-TEST-SECRET',expectedHostname:waitlistHost,
    fetchImpl:async(url,options)=>{
      calls++;
      assert.equal(url,'https://challenges.cloudflare.com/turnstile/v0/siteverify');
      assert.equal(options.method,'POST');
      assert.equal(new URLSearchParams(options.body).get('secret'),'PRIVATE-TEST-SECRET');
      return new Response(JSON.stringify(payload),{status});
    },
  });
  assert.equal(await create({success:true,hostname:waitlistHost,action:'waitlist'})('valid-token-123456'),true);
  assert.equal(await create({success:true,hostname:'attacker.example',action:'waitlist'})('valid-token-123456'),false);
  assert.equal(await create({success:true,hostname:waitlistHost,action:'other'})('valid-token-123456'),false);
  assert.equal(await create({success:false,hostname:waitlistHost,action:'waitlist'})('valid-token-123456'),false);
  assert.equal(await create({success:true,hostname:waitlistHost,action:'waitlist'},500)('valid-token-123456'),false);
  assert.equal(await create({success:true,hostname:waitlistHost,action:'waitlist'})('bad'),false);
  assert.equal(calls,5);
});

test('email normalization rejects malformed addresses',()=>{
  assert.equal(normalizeEmail(' Person@Example.com '),'person@example.com');
  assert.equal(normalizeEmail('no-at'),null);
  assert.equal(normalizeEmail('a@b'),null);
});
