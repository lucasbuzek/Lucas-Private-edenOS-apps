import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createSoftwareSharingBackend} from '../software-sharing/backend.mjs';
import {createCloudflareSoftwareSharingWorker} from '../software-sharing/cloudflare.mjs';
import {validateSharingCatalog,discoverSoftwareFolders} from '../software-sharing/catalog.mjs';

const catalog=JSON.parse(readFileSync(new URL('../software-sharing/catalog.json',import.meta.url),'utf8'));
const host='requests.edenosprivate.pages.dev';
const form=(id,email,token='valid-turnstile')=>new URLSearchParams({
  appId:id,email,'cf-turnstile-response':token,
}).toString();
const submit=(body,extra={})=>new Request('https://'+host+'/api/software-sharing/request',{
  method:'POST',headers:{'content-type':'application/x-www-form-urlencoded',
    origin:'https://'+host,'cf-connecting-ip':'192.0.2.1',...extra},
  body,
});
function fixture() {
  const rows=new Map();let notifications=0,turnstile=0;
  const backend=createSoftwareSharingBackend({
    catalog,requestHost:host,turnstileSiteKey:'TEST_PUBLIC_KEY',
    verifyTurnstile:async token=>{turnstile++;return token==='valid-turnstile';},
    rateLimit:async()=>true,
    store:{
      async request(id,email){const key=id+'|'+email;if(rows.has(key))return false;rows.set(key,'pending');return true;},
      async list(id){return [...rows.entries()].filter(([k])=>k.startsWith(id+'|'))
        .map(([k,status])=>({email:k.split('|')[1],status}));},
      async decide(id,email,decision){const key=id+'|'+email;if(!rows.has(key))return false;
        rows.set(key,decision==='approve'?'approved':'denied');return true;},
      async isApproved(id,email){return rows.get(id+'|'+email)==='approved';},
    },
    notifyOwner:async()=>{notifications++},
  });
  return {backend,rows,get notifications(){return notifications},get turnstile(){return turnstile}};
}

test('sharing catalog is curated and cannot infer software publication from local folders',()=>{
  assert.equal(validateSharingCatalog(catalog).ok,true);
  for(const patch of [{downloadable:true},{authorizedRelease:true},{state:'RELEASED'},
    {sourcePath:'/Users/lucas/edenOS/Software Development/HERMES'},
    {artifactUrl:'https://anywhere.example/private.zip'}]) {
    const edited=structuredClone(catalog);Object.assign(edited.entries[0],patch);
    assert.equal(validateSharingCatalog(edited).ok,false);
  }
  assert.throws(()=>discoverSoftwareFolders('/tmp'),/canonical Software Development/);
});

test('public software form lists only requestable candidates and never offers files',async()=>{
  const f=fixture();
  const r=await f.backend.fetch(new Request('https://'+host+'/software'));
  assert.equal(r.status,200);
  const html=await r.text();
  assert.match(html,/Request access/);
  assert.match(html,/cf-turnstile/);
  assert.doesNotMatch(html,/href=".*\.(zip|dmg|pkg)"/i);
  const list=await f.backend.fetch(new Request('https://'+host+'/api/software-sharing/catalog'));
  assert.equal((await list.json()).downloadsAvailable,false);
  assert.equal((await f.backend.fetch(new Request('https://'+host+'/private-files.zip'))).status,404);
});

test('public request is pending-only and can be approved/denied only through owner-only adapter',async()=>{
  const f=fixture();
  assert.equal((await f.backend.fetch(submit(form('hermes','Person@Example.com')))).status,202);
  assert.equal(f.rows.get('hermes|person@example.com'),'pending');
  assert.equal(f.notifications,1);
  assert.equal(await f.backend.canRequestPrivateSoftware('hermes','person@example.com'),false);
  assert.equal((await f.backend.fetch(submit(form('hermes','Person@Example.com')))).status,202);
  assert.equal(f.notifications,1);
  assert.equal(await f.backend.decideOwnerRequest({
    appId:'hermes',email:'person@example.com',decision:'approve',reviewer:'owner@example.com'
  }),true);
  assert.equal(await f.backend.canRequestPrivateSoftware('hermes','person@example.com'),true);
  assert.equal(await f.backend.canRequestPrivateSoftware('cresus','person@example.com'),false);
  await f.backend.decideOwnerRequest({
    appId:'hermes',email:'person@example.com',decision:'deny',reviewer:'owner@example.com'
  });
  assert.equal(await f.backend.canRequestPrivateSoftware('hermes','person@example.com'),false);
});

test('spam, cross-origin, unauthorized app and no CF source fail closed',async()=>{
  const f=fixture();
  const spam=new URLSearchParams({appId:'hermes',email:'bot@example.com',website:'spam.example',
    'cf-turnstile-response':'valid-turnstile'}).toString();
  assert.equal((await f.backend.fetch(submit(spam))).status,202);
  assert.equal(f.rows.size,0);
  assert.equal((await f.backend.fetch(submit(form('unlisted-app','u@example.com')))).status,400);
  assert.equal((await f.backend.fetch(submit(form('hermes','u@example.com'),{origin:'https://attacker.example'}))).status,403);
  assert.equal((await f.backend.fetch(submit(form('hermes','u@example.com'),{'cf-connecting-ip':''}))).status,403);
  assert.equal((await f.backend.fetch(submit(form('hermes','u@example.com','wrong-token')))).status,403);
  assert.equal(f.rows.size,0);
});

test('Cloudflare public adapter refuses missing config or API download attempts',async()=>{
  const worker=createCloudflareSoftwareSharingWorker({catalog,fetchImpl:async()=>new Response('{}')});
  const noConfig=await worker.fetch(new Request('https://'+host+'/software'),{});
  assert.equal(noConfig.status,503);
  const env={SOFTWARE_REQUEST_HOST:host,SOFTWARE_TURNSTILE_SITE_KEY:'TEST_PUBLIC_KEY',
    SOFTWARE_TURNSTILE_SECRET:'TEST_SERVER_SECRET',
    SOFTWARE_QUEUE_DB:{prepare:()=>({bind:()=>({run:async()=>({meta:{changes:1}})})})}};
  const formResult=await worker.fetch(new Request('https://'+host+'/software'),env);
  assert.equal(formResult.status,200);
  const downloadAttempt=await worker.fetch(new Request('https://'+host+'/api/private-releases/hermes/v01'),env);
  assert.equal(downloadAttempt.status,404);
});
