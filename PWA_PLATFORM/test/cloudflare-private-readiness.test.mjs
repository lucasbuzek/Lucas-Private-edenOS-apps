import test from 'node:test';
import assert from 'node:assert/strict';
import {collectPrivateCloudflareInventory,assessPrivateCloudflareInventory}
  from '../deployment/cloudflare-private-readiness.mjs';

const ok=result=>({status:200,body:{success:true,result}});
const notFound={status:404,body:null};
const empty={
  pages:{
    edenosprivate:ok({name:'edenosprivate',latest_deployment:null,production_branch:'main'}),
    edenosportal:notFound,
  },
  accessApps:ok([]),zones:ok([]),routingRules:ok([]),
};

test('2026-10-19 verified private account: no Access and no sending zone block every deployment',()=>{
  const r=assessPrivateCloudflareInventory(empty);
  assert.equal(r.status,'BLOCKED_NOT_DEPLOYABLE');
  assert.deepEqual(r.privatePages,{exists:true,empty:true,verified:true});
  assert.deepEqual(r.portalPages,{exists:false,verified:false,absent:true});
  assert.equal(r.accessApps.count,0);
  assert.equal(r.dns.activeZoneCount,0);
  assert.equal(r.emailRouting.count,0);
  assert.equal(r.deployAllowed,false);
  for(const key of [
    'NO_ACCESS_APPLICATIONS','NO_ACTIVE_OWNED_DNS_ZONE_FOR_EMAIL',
    'PORTAL_PAGES_PROJECT_NOT_CREATED',
    'OWNER_ACCESS_POLICY_NOT_PHYSICALLY_ACCEPTED',
    'SENDER_DOMAIN_AND_RECIPIENT_DELIVERY_NOT_PHYSICALLY_ACCEPTED',
  ])assert.ok(r.blockers.includes(key),key);
});

test('Access API failure never looks like zero applications or a passing security gate',()=>{
  const fixture=structuredClone(empty);
  fixture.accessApps={status:403,body:null};
  fixture.zones={status:'NETWORK_UNAVAILABLE',body:null};
  const result=assessPrivateCloudflareInventory(fixture);
  assert.equal(result.accessApps.count,null);
  assert.equal(result.dns.activeZoneCount,null);
  assert.ok(result.blockers.includes('ACCESS_APPLICATIONS_API_UNVERIFIED'));
  assert.ok(result.blockers.includes('OWNED_DNS_ZONES_UNVERIFIED'));
  assert.equal(result.deployAllowed,false);
});

test('matching root and wildcard Access application names are insufficient proof of owner-only policy',()=>{
  const fixture=structuredClone(empty);
  fixture.pages.edenosportal=ok({name:'edenosportal',latest_deployment:null});
  fixture.accessApps=ok([
    {domain:'edenosprivate.pages.dev',type:'self_hosted',policies:[]},
    {domain:'*.edenosprivate.pages.dev',type:'self_hosted',policies:[]},
  ]);
  fixture.zones=ok([{id:'private-zone-id',name:'owned.example'}]);
  const r=assessPrivateCloudflareInventory(fixture);
  assert.ok(r.accessApps.protectedHosts.every(x=>x.matchedApplication));
  assert.ok(r.blockers.includes('OWNER_ACCESS_POLICY_NOT_PHYSICALLY_ACCEPTED'));
  assert.ok(r.blockers.includes('PREVIEW_HASH_AND_DIRECT_ORIGIN_NOT_PHYSICALLY_ACCEPTED'));
  assert.equal(r.deployAllowed,false);
});

test('only authenticated read-only GET requests to exact Cloudflare endpoints are emitted',async()=>{
  const called=[];
  const fake=async(uri,options)=>{
    called.push({uri,method:options.method,redirect:options.redirect,auth:options.headers.authorization});
    const path=new URL(uri).pathname;
    if(path.endsWith('/pages/projects/edenosportal'))
      return {status:404,json:async()=>({success:false})};
    if(path.endsWith('/pages/projects/edenosprivate'))
      return {status:200,json:async()=>({success:true,result:{name:'edenosprivate'}})};
    return {status:200,json:async()=>({success:true,result:[]})};
  };
  const inventory=await collectPrivateCloudflareInventory({
    accountId:'a'.repeat(32),apiToken:'example-read-only-token',fetchImpl:fake,
  });
  assert.equal(inventory.pages.edenosprivate.status,200);
  assert.equal(inventory.pages.edenosportal.status,404);
  assert.equal(called.length,5);
  assert.ok(called.every(x=>x.method==='GET'&&x.redirect==='error'));
  assert.ok(called.every(x=>x.uri.startsWith('https://api.cloudflare.com/client/v4/')));
  assert.ok(called.every(x=>x.auth==='Bearer example-read-only-token'));
  const report=JSON.stringify(assessPrivateCloudflareInventory(inventory));
  assert.doesNotMatch(report,/example-read-only-token|aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/);
});

test('unknown/invalid projects and malformed inventory cannot result in a deployable state',()=>{
  const bad=structuredClone(empty);
  bad.pages.edenosprivate=ok({name:'attacker'});
  assert.ok(assessPrivateCloudflareInventory(bad).blockers.includes('PRIVATE_PAGES_PROJECT_UNVERIFIED'));
  assert.throws(()=>assessPrivateCloudflareInventory(null),/required/);
});
