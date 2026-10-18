import test from 'node:test';
import assert from 'node:assert/strict';
import { createCloudflareClosedTestWorker } from '../closed-testing/cloudflare.mjs';

function configured(mode='assets') {
  let forwards=0;
  const env={
    PRIVATE_HOST:'private.hermes.example',WAITLIST_HOST:'join.hermes.example',
    OWNER_EMAIL:'owner@example.com',ACCESS_TEAM_DOMAIN:'team.cloudflareaccess.com',
    ACCESS_AUD:'hermes-test-aud',TURNSTILE_SECRET:'test-private-secret',
    TURNSTILE_SITE_KEY:'publicTestKey123',PRIVATE_UPSTREAM_MODE:mode,
    GATE_DB:{prepare:()=>({bind:()=>({first:async()=>null,run:async()=>({meta:{changes:1}}),all:async()=>({results:[]})})})},
    ASSETS:{fetch:async()=>{forwards++;return new Response('private assets');}},
    APP:{fetch:async()=>{forwards++;return new Response('private service');}},
  };
  return {env, get forwards(){return forwards;}};
}
const req=(host,path='/')=>new Request('https://'+host+path);

test('Cloudflare adapter requires complete app-specific security configuration',async()=>{
  const w=createCloudflareClosedTestWorker({appId:'hermes',appName:'HERMES'});
  assert.equal((await w.fetch(req('private.hermes.example'),{})).status,503);
  const f=configured();
  delete f.env.GATE_DB;
  assert.equal((await w.fetch(req('private.hermes.example'),f.env)).status,503);
  assert.equal(f.forwards,0);
});

test('Cloudflare adapter exposes only waitlist form publicly and refuses private app without JWT',async()=>{
  const w=createCloudflareClosedTestWorker({appId:'hermes',appName:'HERMES'});
  const f=configured();
  assert.equal((await w.fetch(req('join.hermes.example'),f.env)).status,200);
  assert.equal((await w.fetch(req('private.hermes.example','/sw.js'),f.env)).status,401);
  assert.equal((await w.fetch(req('private.hermes.example','/api/chat'),f.env)).status,401);
  assert.equal((await w.fetch(req('unknown.workers.dev'),f.env)).status,421);
  assert.equal(f.forwards,0);
});

test('Cloudflare worker must have the declared private upstream binding',async()=>{
  const w=createCloudflareClosedTestWorker({appId:'cresus',appName:'CRESUS'});
  const f=configured('service');
  delete f.env.APP;
  assert.equal((await w.fetch(req('private.hermes.example'),f.env)).status,503);
});

test('Cloudflare adapter cannot be created for an unknown application identity',()=>{
  assert.throws(()=>createCloudflareClosedTestWorker({appId:'../other',appName:'Test'}),/identity/);
});
