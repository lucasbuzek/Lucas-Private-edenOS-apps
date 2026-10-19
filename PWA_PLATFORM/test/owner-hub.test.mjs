import test from 'node:test';
import assert from 'node:assert/strict';
import {createPrivateOwnerHub} from '../closed-testing/owner-hub.mjs';

const ownerEmail='owner@example.com';
function fixture(){
  const operations=[];
  const rows={
    hermes:[{email:'person@example.com',status:'pending'}],
    cresus:[{email:'person@example.com',status:'pending'},{email:'friend@example.com',status:'active'}],
  };
  const services=Object.fromEntries(['hermes','cresus'].map(appId=>[appId,{
    async list(scope){
      if(scope!==appId)throw new Error('cross-app list forbidden');
      return rows[appId];
    },
    async decide(scope,email,decision,reviewer){
      if(scope!==appId)throw new Error('cross-app decision forbidden');
      const row=rows[appId].find(x=>x.email===email);
      if(!row)return false;
      row.status=decision==='approve'?'approved':'denied';
      operations.push({appId,email,decision,reviewer});
      return true;
    },
  }]));
  const authenticate=async request=>{
    const user=request.headers.get('x-test-email');
    if(!user)return null;
    return {id:'test-principal',email:user,
      allowedApps:request.headers.get('x-test-audience')==='owner' ? ['lucas-admin']:['hermes']};
  };
  return {hub:createPrivateOwnerHub({ownerEmail,services,authenticate}),operations,rows};
}
const req=(path,method='GET',fields=null,{email=null,audience='owner',origin=undefined,host='lucas.edenosprivate.pages.dev'}={})=>{
  const url='https://'+host+path;
  const headers={};
  if(email)headers['x-test-email']=email;
  if(audience)headers['x-test-audience']=audience;
  if(fields!==null)headers['content-type']='application/x-www-form-urlencoded';
  if(method==='POST'&&origin!==null)headers.origin=origin||'https://'+host;
  return new Request(url,{method,headers,body:fields===null?undefined:new URLSearchParams(fields)});
};

test('Lucas owner console requires correct private host and an owner-scoped verified Access audience',async()=>{
  const {hub}=fixture();
  assert.equal((await hub.fetch(req('/'))).status,401);
  assert.equal((await hub.fetch(req('/', 'GET',null,{email:'friend@example.com'}))).status,403);
  assert.equal((await hub.fetch(req('/', 'GET',null,{email:ownerEmail,audience:'hermes'}))).status,403);
  assert.equal((await hub.fetch(req('/', 'GET',null,{email:ownerEmail,host:'hermes.edenosprivate.pages.dev'}))).status,403);
  assert.equal((await hub.fetch(req('/', 'GET',null,{email:ownerEmail}))).status,200);
});

test('owner dashboard retrieves HERMES/CRESUS separately without combining memberships',async()=>{
  const {hub,rows}=fixture();
  const r=await hub.fetch(req('/api/admin/waitlists','GET',null,{email:ownerEmail}));
  assert.equal(r.status,200);
  const data=await r.json();
  assert.equal(data.owner,true);
  assert.equal(data.apps.hermes.length,1);
  assert.equal(data.apps.cresus.length,2);
  assert.equal(data.accessPolicies,'UNVERIFIED');
  assert.equal(rows.hermes[0].status,'pending');
  const html=await (await hub.fetch(req('/admin','GET',null,{email:ownerEmail}))).text();
  assert.match(html,/Lucas — private EDENOS administration/);
  assert.match(html,/HERMES/);
  assert.match(html,/CRESUS/);
});

test('owner approval/denial is app scoped and never synchronizes Access permissions silently',async()=>{
  const {hub,operations,rows}=fixture();
  const approval=await hub.fetch(req('/admin/decision','POST',
    {appId:'hermes',email:'person@example.com',decision:'approve'},{email:ownerEmail}));
  assert.equal(approval.status,200);
  assert.deepEqual(await approval.json(),{
    ok:true,appId:'hermes',decision:'approve',accessPolicies:'REQUIRES_VERIFICATION',
  });
  assert.equal(rows.hermes[0].status,'approved');
  assert.equal(rows.cresus[0].status,'pending');
  const denial=await hub.fetch(req('/admin/decision','POST',
    {appId:'cresus',email:'person@example.com',decision:'deny'},{email:ownerEmail}));
  assert.equal(denial.status,200);
  assert.equal(rows.cresus[0].status,'denied');
  assert.deepEqual(operations.map(x=>x.appId),['hermes','cresus']);
});

test('non-owner, cross-origin or unsupported app cannot make approval decisions',async()=>{
  const {hub,operations}=fixture();
  const fields={appId:'hermes',email:'person@example.com',decision:'approve'};
  assert.equal((await hub.fetch(req('/admin/decision','POST',fields,{email:'friend@example.com'}))).status,403);
  assert.equal((await hub.fetch(req('/admin/decision','POST',fields,{email:ownerEmail,audience:'hermes'}))).status,403);
  assert.equal((await hub.fetch(req('/admin/decision','POST',fields,{email:ownerEmail,origin:null}))).status,403);
  assert.equal((await hub.fetch(req('/admin/decision','POST',fields,{email:ownerEmail,origin:'https://evil.example'}))).status,403);
  assert.equal((await hub.fetch(req('/admin/decision','POST',{...fields,appId:'another-app'},{email:ownerEmail}))).status,400);
  assert.equal((await hub.fetch(req('/admin/decision','POST',{...fields,email:ownerEmail},{email:ownerEmail}))).status,400);
  assert.equal(operations.length,0);
});

test('owner hub is fail-closed when per-app admin sources are missing',()=>{
  assert.throws(()=>createPrivateOwnerHub({ownerEmail,authenticate:async()=>null,services:{hermes:{}}}),/independently scoped/);
});
