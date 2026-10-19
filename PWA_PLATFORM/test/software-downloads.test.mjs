import test from 'node:test';
import assert from 'node:assert/strict';
import { validatePrivateReleases, createPrivateDownloadHandler } from '../software-sharing/downloads.mjs';

const DIGEST='a'.repeat(64);
const release={
  appId:'hermes',releaseId:'v01',sha256:DIGEST,filename:'HERMES-v0.1.zip',
  objectKey:'releases/hermes/HERMES-v0.1.zip',approvedForSharing:true,physicalAcceptance:true,
};
function fixture({approval=false,identity=true,entitled=true,validHash=true}={}) {
  const calls={get:0,authorized:0,approval:0};
  const handler=createPrivateDownloadHandler({
    releases:[release],ownerEmail:'owner@example.com',privateHost:'hermes.edenosprivate.pages.dev',
    authenticate:async()=>identity ? {id:'verified-user',email:'tester@example.com'} : null,
    authorizeApp:async(_,app)=>{calls.authorized++;return entitled && app==='hermes';},
    store:{isApproved:async(app,email)=>{calls.approval++;return approval && app==='hermes'&&email==='tester@example.com';}},
    bucket:{get:async(key)=>{
      calls.get++;
      if(key!==release.objectKey)throw Error('Wrong R2 object');
      return {body:new Response('test package body').body,
        customMetadata:{sha256:validHash?DIGEST:'b'.repeat(64)}};
    }},
  });
  return {handler,calls};
}
function req(path='/api/private-releases/hermes/v01',host='hermes.edenosprivate.pages.dev',headers={}) {
  return new Request('https://'+host+path,{headers});
}

test('private releases require explicit physically accepted manifest and SHA256',()=>{
  assert.deepEqual(validatePrivateReleases([release]),{ok:true,errors:[]});
  for(const patch of [
    {approvedForSharing:false},{physicalAcceptance:false},{sha256:'unknown'},
    {publicUrl:'https://public.example/file.zip'},{objectKey:'../secrets'},
    {filename:'../../private.zip'},{localSourcePath:'/Users/lucas/private'},
  ])assert.equal(validatePrivateReleases([{...release,...patch}]).ok,false);
  assert.equal(validatePrivateReleases([{...release}, {...release}]).ok,false);
  assert.equal(validatePrivateReleases([]).ok,true);
});

test('unauthenticated and unapproved testers receive no private bytes',async()=>{
  const anon=fixture({approval:true,identity:false});
  assert.equal((await anon.handler.fetch(req())).status,401);
  assert.equal(anon.calls.get,0);
  const pending=fixture({approval:false});
  assert.equal((await pending.handler.fetch(req())).status,403);
  assert.equal(pending.calls.get,0);
});

test('existing app membership and private download approval are independent gates',async()=>{
  const wrongApp=fixture({approval:true,entitled:false});
  assert.equal((await wrongApp.handler.fetch(req())).status,403);
  assert.equal(wrongApp.calls.approval,0);
  assert.equal(wrongApp.calls.get,0);
});

test('approved authenticated tester may stream only accepted release from private R2',async()=>{
  const f=fixture({approval:true});
  const response=await f.handler.fetch(req());
  assert.equal(response.status,200);
  assert.equal(await response.text(),'test package body');
  assert.equal(response.headers.get('cache-control'),'private, no-store, max-age=0');
  assert.match(response.headers.get('content-disposition'),/attachment/);
  assert.equal(f.calls.get,1);
});

test('R2 checksum drift refuses download instead of returning stale artifact',async()=>{
  const f=fixture({approval:true,validHash:false});
  assert.equal((await f.handler.fetch(req())).status,503);
});

test('cannot bypass private app origin or resolve arbitrary releases',async()=>{
  const f=fixture({approval:true});
  for(const candidate of [
    req('/api/private-releases/hermes/v01','attacker.pages.dev'),
    req('/api/private-releases/hermes/other'),
    req('/api/private-releases/cresus/v01'),
    req('/api/private-releases/hermes/v01?token=guess'),
    req('/api/private-releases/hermes/v01',undefined,{origin:'https://other.example'})
  ])assert.notEqual((await f.handler.fetch(candidate)).status,200);
  assert.equal(f.calls.get,0);
});
