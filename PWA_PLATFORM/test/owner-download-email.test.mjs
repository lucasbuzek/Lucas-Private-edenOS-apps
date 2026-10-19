import test from 'node:test';
import assert from 'node:assert/strict';
import {createPrivateOwnerHub} from '../closed-testing/owner-hub.mjs';

const origin='https://lucas.edenosprivate.pages.dev';
const owner='owner@example.com';
const tester='tester@example.com';
function fixture() {
 let calls=0;
 const service={
   list:async()=>[{appId:'hermes',releaseId:'v01',enabled:true}],
   setEnabled:async()=>({state:'UPDATED',enabled:false}),
   issue:async({principal,email,appId,releaseId})=>{
     calls++;
     assert.equal(principal.email,owner);
     assert.equal(email,tester);
     assert.equal(appId,'hermes');
     assert.equal(releaseId,'v01');
     return {state:'SUBMITTED'};
   },
 };
 const apps={hermes:{list:async()=>[],decide:async()=>false},
             cresus:{list:async()=>[],decide:async()=>false}};
 const software={list:async()=>[{email:tester,status:'approved',targetAppId:'hermes'}],
   decide:async()=>true};
 const hub=createPrivateOwnerHub({
   ownerEmail:owner,services:{...apps,softwareSharing:software,downloadLinks:service},
   authenticate:async req=>req.headers.get('x-test-user')==='owner'
     ? {id:'owner-1',email:owner,allowedApps:['lucas-admin']}
     : {id:'guest',email:tester,allowedApps:[]},
 });
 return {hub,get calls(){return calls}};
}
const get=(path,user='owner')=>new Request(origin+path,{
 headers:{'x-test-user':user},
});
const post=(user='owner',headers={})=>new Request(origin+'/api/admin/send-release',{
 method:'POST',headers:{'x-test-user':user,origin,'content-type':'application/x-www-form-urlencoded',...headers},
 body:new URLSearchParams({appId:'hermes',releaseId:'v01',email:tester}),
});

test('Lucas owner panel exposes Send one-use email only for already approved request/release',async()=>{
 const f=fixture();
 const panel=await f.hub.fetch(get('/admin'));
 assert.equal(panel.status,200);
 const html=await panel.text();
 assert.match(html,/Send one-use email download/);
 assert.match(html,/HERMES/i);
 const api=await f.hub.fetch(get('/api/admin/waitlists'));
 assert.equal((await api.json()).softwareDownloads,'OWNER_RELEASE_SELECTION_REQUIRED');
});

test('only verified owner may send link and link is never in API response',async()=>{
 const f=fixture();
 assert.equal((await f.hub.fetch(post('guest'))).status,403);
 assert.equal((await f.hub.fetch(post('owner',{origin:'https://attacker.example'}))).status,403);
 assert.equal(f.calls,0);
 const accepted=await f.hub.fetch(post());
 assert.equal(accepted.status,200);
 const result=await accepted.json();
 assert.equal(result.link,'SUBMITTED_TO_VERIFIED_EMAIL_PROVIDER');
 assert.equal(result.delivered,'UNKNOWN');
 assert.equal(f.calls,1);
});

test('without trusted email/link service, no download is sent or silently enabled',async()=>{
 const adapter={list:async()=>[],decide:async()=>false};
 const hub=createPrivateOwnerHub({
  ownerEmail:owner,authenticate:async()=>({id:'u',email:owner,allowedApps:['lucas-admin']}),
  services:{hermes:adapter,cresus:adapter}
 });
 assert.equal((await hub.fetch(post())).status,503);
});


test('Lucas dashboard may toggle only a reviewed release under verified owner authority',async()=>{
  const f=fixture();
  const form=(user='owner',enabled='false')=>new Request(origin+'/api/admin/release-state',{
    method:'POST',
    headers:{origin,'x-test-user':user,'content-type':'application/x-www-form-urlencoded'},
    body:new URLSearchParams({appId:'hermes',releaseId:'v01',enabled}),
  });
  assert.equal((await f.hub.fetch(form('guest'))).status,403);
  assert.equal((await f.hub.fetch(form('owner','invalid'))).status,400);
  const result=await f.hub.fetch(form());
  assert.equal(result.status,200);
  assert.equal((await result.json()).enabled,false);
  const html=await (await f.hub.fetch(get('/admin'))).text();
  assert.match(html,/Disable hermes \/ v01/);
});
