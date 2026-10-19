import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createPrivateOwnerHub} from '../closed-testing/owner-hub.mjs';
import {createSoftwareSharingBackend,createSoftwareSharingOwnerAdapter} from '../software-sharing/backend.mjs';

const host='lucas.edenosprivate.pages.dev';
const url=p=>'https://'+host+p;
const owner='owner@example.com';
const catalog=JSON.parse(readFileSync(new URL('../software-sharing/catalog.json',import.meta.url),'utf8'));
function system() {
  const rows=new Map([['hermes|tester@example.com','pending']]);
  const software=createSoftwareSharingBackend({
    catalog,requestHost:'requests.edenosprivate.pages.dev',turnstileSiteKey:'TEST_KEY',
    verifyTurnstile:async()=>true,rateLimit:async()=>true,
    store:{
      request:async()=>true,
      list:async app=>[...rows.entries()].filter(([key])=>key.startsWith(app+'|')).map(([key,status])=>({email:key.split('|')[1],status})),
      decide:async(app,email,decision)=>{const key=app+'|'+email;if(!rows.has(key))return false;rows.set(key,decision==='approve'?'approved':'denied');return true;},
      isApproved:async(app,email)=>rows.get(app+'|'+email)==='approved',
    },
  });
  const unchanged={list:async()=>[],decide:async()=>false};
  const admin=createPrivateOwnerHub({
    ownerEmail:owner,
    authenticate:async request=>{
      const header=request.headers.get('x-test-identity');
      if(header==='owner')return {id:'u1',email:owner,allowedApps:['lucas-admin']};
      if(header==='family')return {id:'u2',email:'family@example.com',allowedApps:['hermes']};
      return null;
    },
    services:{hermes:unchanged,cresus:unchanged,softwareSharing:createSoftwareSharingOwnerAdapter(software)},
  });
  return {admin,rows,software};
}
const get=(identity='owner')=>new Request(url('/api/admin/waitlists'),{headers:{'x-test-identity':identity}});
const decision=(appId,decision,identity='owner',target='hermes')=>new Request(url('/admin/decision'),{
  method:'POST',headers:{'x-test-identity':identity,origin:url('/').slice(0,-1),
    'content-type':'application/x-www-form-urlencoded'},
  body:new URLSearchParams({appId,email:'tester@example.com',decision,targetAppId:target}),
});

test('software sharing requests appear independently in Lucas owner dashboard',async()=>{
  const {admin}=system();
  const response=await admin.fetch(get());
  assert.equal(response.status,200);
  const body=await response.json();
  assert.deepEqual(Object.keys(body.apps).sort(),['cresus','hermes','softwareSharing']);
  assert.equal(body.apps.softwareSharing[0].targetAppId,'hermes');
  assert.equal(body.apps.softwareSharing[0].status,'pending');
  assert.equal(body.softwareDownloads,'NO_RELEASES_ACTIVATED');
});

test('only verified Lucas-admin principal may approve individual app requests',async()=>{
  const {admin,software,rows}=system();
  assert.equal((await admin.fetch(decision('softwareSharing','approve','family'))).status,403);
  assert.equal(rows.get('hermes|tester@example.com'),'pending');
  assert.equal((await admin.fetch(decision('softwareSharing','approve'))).status,200);
  assert.equal(rows.get('hermes|tester@example.com'),'approved');
  assert.equal(await software.canRequestPrivateSoftware('hermes','tester@example.com'),true);
  assert.equal(await software.canRequestPrivateSoftware('cresus','tester@example.com'),false);
  assert.equal((await admin.fetch(decision('softwareSharing','deny'))).status,200);
  assert.equal(await software.canRequestPrivateSoftware('hermes','tester@example.com'),false);
});

test('software request owner decision refuses missing/unauthorized app and cross-origin',async()=>{
  const {admin,rows}=system();
  assert.equal((await admin.fetch(decision('softwareSharing','approve','owner','unknown-app'))).status,404);
  assert.equal((await admin.fetch(decision('softwareSharing','approve','owner','../../test'))).status,400);
  const cross=new Request(url('/admin/decision'),{
    method:'POST',headers:{'x-test-identity':'owner',origin:'https://attacker.example',
      'content-type':'application/x-www-form-urlencoded'},
    body:new URLSearchParams({appId:'softwareSharing',email:'tester@example.com',decision:'approve',targetAppId:'hermes'}),
  });
  assert.equal((await admin.fetch(cross)).status,403);
  assert.equal(rows.get('hermes|tester@example.com'),'pending');
});
