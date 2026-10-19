import test from 'node:test';
import assert from 'node:assert/strict';
import {createReadOnlyActionBridge,readonlyActionNames} from '../intelligence/read-only-actions.mjs';

const principal={id:'signed-in-user',allowedApps:['hermes']};
function fixture({grant=true,available=true,readOnly=true}={}){
  const calls=[];
  const bridge=createReadOnlyActionBridge({
    appActions:{hermes:{
      'github.repository.metadata':'github.repository.read',
      'dropbox.folder.list':'dropbox.folder.read',
    }},
    authorize:async ({appId,actionId,connectionId,args})=>({
      allowed:grant,appId,actionId,connectionId,resource:args.repository||args.folder,mode:'read-only',
    }),
    resolveCapability:async ({capability,connectionId})=>({
      capability,connectionId,state:available?'AVAILABLE':'UNKNOWN',
      readOnly,connected:true,accepted:true,
    }),
    invokeResolved:async req=>{
      calls.push(req);
      if(req.actionId==='github.repository.metadata')
        return {private:true,default_branch:'main',authorization:'NEVER_EXPOSE'};
      return {entries:[{name:'source.txt',type:'file',path:'/private/source.txt',
        token:'NEVER_EXPOSE'}],secrets:'NEVER_EXPOSE'};
    },
  });
  return {bridge,calls};
}

test('only declared deterministic read-only Actions exist',()=>{
  assert.deepEqual(readonlyActionNames(),['github.repository.metadata','dropbox.folder.list']);
  assert.throws(()=>createReadOnlyActionBridge({
    appActions:{hermes:{'shell.exec':'unsafe.command'}},
    authorize:async()=>({allowed:true}),resolveCapability:async()=>({state:'AVAILABLE'}),invokeResolved:async()=>{},
  }),/Unknown or unsafe/);
});

test('GitHub read-only Action requires explicit trusted grant and BIFROST resolution',async()=>{
  const {bridge,calls}=fixture();
  const r=await bridge.run({principal,appId:'hermes',actionId:'github.repository.metadata',
    connectionId:'github-primary',args:{repository:'lucasbuzek/Lucas-Private-edenOS-apps'}});
  assert.equal(r.state,'COMPLETED');
  assert.deepEqual(r.data,{repository:'lucasbuzek/Lucas-Private-edenOS-apps',
    private:true,defaultBranch:'main'});
  assert.equal(calls.length,1);
  assert.equal(calls[0].capability,'github.repository.read');
  assert.doesNotMatch(JSON.stringify(r),/NEVER_EXPOSE/);
  assert.equal(r.providerAcceptance,'UNVERIFIED_LIVE');
});

test('Dropbox read-only Action provides minimal metadata without private tokens or file paths',async()=>{
  const {bridge,calls}=fixture();
  const r=await bridge.run({principal,appId:'hermes',actionId:'dropbox.folder.list',
    connectionId:'dropbox-primary',args:{folder:'/ChatGPT'}});
  assert.equal(r.state,'COMPLETED');
  assert.deepEqual(r.data,{folder:'/ChatGPT',count:1,entries:[{name:'source.txt',type:'file'}]});
  assert.equal(calls[0].capability,'dropbox.folder.read');
  assert.doesNotMatch(JSON.stringify(r),/NEVER_EXPOSE|\/private\/source/);
});

test('unsigned or cross-app principals cannot run Actions',async()=>{
  const {bridge,calls}=fixture();
  for(const who of [null,{id:'u',allowedApps:[]},{id:'u',allowedApps:['cresus']}]) {
    const r=await bridge.run({principal:who,appId:'hermes',actionId:'github.repository.metadata',
      connectionId:'github-primary',args:{repository:'owner/repo'}});
    assert.equal(r.reason,'APP_LOGIN_REQUIRED');
  }
  assert.equal(calls.length,0);
});

test('browser consent does not replace a verified server-side capability grant',async()=>{
  const {bridge,calls}=fixture({grant:false});
  const r=await bridge.run({principal,appId:'hermes',actionId:'github.repository.metadata',
    connectionId:'github-primary',args:{repository:'owner/repo'},consent:true});
  assert.equal(r.reason,'EXPLICIT_APP_SCOPED_GRANT_REQUIRED');
  assert.equal(calls.length,0);
});

test('unavailable or write-enabled BIFROST capabilities cannot be invoked',async()=>{
  for(const f of [fixture({available:false}),fixture({readOnly:false})]){
    const r=await f.bridge.run({principal,appId:'hermes',actionId:'github.repository.metadata',
      connectionId:'github-primary',args:{repository:'owner/repo'}});
    assert.equal(r.reason,'BIFROST_CAPABILITY_UNVERIFIED');
    assert.equal(f.calls.length,0);
  }
});

test('invalid resource paths and undeclared Actions never invoke providers',async()=>{
  const f=fixture();
  for(const item of [
    {actionId:'github.repository.metadata',args:{repository:'../secrets'}},
    {actionId:'github.repository.metadata',args:{repository:'owner/..'}},
    {actionId:'dropbox.folder.list',args:{folder:'/ChatGPT/../Private'}},
    {actionId:'dropbox.folder.list',args:{folder:'/ChatGPT?q=all'}},
    {actionId:'dropbox.folder.write',args:{folder:'/ChatGPT'}},
  ]){
    const r=await f.bridge.run({principal,appId:'hermes',connectionId:'primary',...item});
    assert.equal(r.state,'DENIED');
  }
  assert.equal(f.calls.length,0);
});

test('oversized result is rejected rather than passed through',async()=>{
  const bridge=createReadOnlyActionBridge({
    appActions:{hermes:{'dropbox.folder.list':'dropbox.folder.read'}},
    authorize:async ({appId,actionId,connectionId,args})=>({
      allowed:true,appId,actionId,connectionId,resource:args.folder,mode:'read-only',
    }),
    resolveCapability:async ({capability,connectionId})=>({
      state:'AVAILABLE',capability,connectionId,readOnly:true,connected:true,accepted:true,
    }),
    invokeResolved:async()=>({entries:Array.from({length:51},(_,i)=>({name:'f'+i,type:'file'}))}),
  });
  const r=await bridge.run({principal,appId:'hermes',actionId:'dropbox.folder.list',
    connectionId:'dropbox-main',args:{folder:'/ChatGPT'}});
  assert.equal(r.reason,'READ_ONLY_RESULT_UNVERIFIED');
});

test('server-side consent must bind the exact resource',async()=>{
  const bridge=createReadOnlyActionBridge({
    appActions:{hermes:{'github.repository.metadata':'github.repository.read'}},
    authorize:async ({appId,actionId,connectionId})=>({
      allowed:true,appId,actionId,connectionId,resource:'owner/other-repo',mode:'read-only',
    }),
    resolveCapability:async()=>{throw Error('Must not resolve');},
    invokeResolved:async()=>{throw Error('Must not invoke');},
  });
  assert.equal((await bridge.run({principal,appId:'hermes',actionId:'github.repository.metadata',
    connectionId:'github-primary',args:{repository:'owner/repo'}})).reason,
    'EXPLICIT_APP_SCOPED_GRANT_REQUIRED');
});

test('post-construction mutations cannot add unreviewed Action bindings',async()=>{
  const config={hermes:{'github.repository.metadata':'github.repository.read'}};
  const bridge=createReadOnlyActionBridge({appActions:config,
    authorize:async()=>({allowed:false}),resolveCapability:async()=>({}),
    invokeResolved:async()=>{},
  });
  config.hermes['dropbox.folder.list']='dropbox.folder.read';
  assert.equal((await bridge.run({principal,appId:'hermes',actionId:'dropbox.folder.list',
    connectionId:'dropbox-primary',args:{folder:'/ChatGPT'}})).reason,'READ_ONLY_ACTION_NOT_DECLARED');
});
