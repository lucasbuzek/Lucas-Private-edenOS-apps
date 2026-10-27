import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createBackend} from '../server.mjs';
const SECRET='local-test-token-longer-than-24-characters';
test('agent HTTP API persists guided account progress but refuses live orders',async()=>{
  const app=createBackend({token:SECRET});
  await new Promise(done=>app.server.listen(0,'127.0.0.1',done));
  const url='http://127.0.0.1:'+app.server.address().port;
  const call=async(path,method='GET',body,auth=true)=>{
    const r=await fetch(url+path,{method,headers:{
      ...(auth?{authorization:'Bearer '+SECRET}:{}),
      ...(body?{'content-type':'application/json'}:{})},body:body?JSON.stringify(body):undefined});
    return {status:r.status,data:await r.json()};
  };
  try{
    assert.equal((await call('/healthz','GET',null,false)).status,200);
    assert.equal((await call('/v1/providers','GET',null,false)).status,401);
    assert.equal((await call('/v1/onboarding','POST',{provider:'luno',spendingLimitUSD:6})).status,422);
    assert.equal((await call('/v1/onboarding','POST',{provider:'luno',card:'fake'})).status,422);
    const r=await call('/v1/onboarding','POST',{provider:'luno',spendingLimitUSD:5});
    assert.equal(r.status,201);const id=r.data.id;
    const session=await call('/v1/onboarding/'+id);
    assert.equal(session.data.plan.cardNumberStored,false);
    assert.equal(session.data.verified,false);
    assert.equal((await call('/v1/onboarding/'+id+'/attest','POST',{step:'FUND_MANUALLY'})).status,422);
    const next=await call('/v1/onboarding/'+id+'/attest','POST',{step:'CHOOSE_PROVIDER'});
    assert.equal(next.status,200);assert.equal(next.data.liveTradeAllowed,false);
    const audit=await call('/v1/onboarding/'+id+'/audit');assert.equal(audit.data.events.length,2);
    assert.equal((await call('/v1/orders/live','POST',{pair:'XBTZAR'})).status,403);
  }finally{await new Promise(done=>app.server.close(done));app.close();}
});
test('research returns evidence-backed quote, never market order',async()=>{
  const app=createBackend({token:SECRET,fetchFn:async()=>({
    ok:true,json:async()=>({pair:'XBTZAR',bid:'99',ask:'100',timestamp:Date.now(),status:'ACTIVE'})
  })});
  await new Promise(done=>app.server.listen(0,'127.0.0.1',done));
  try{
    const r=await fetch('http://127.0.0.1:'+app.server.address().port+'/v1/research/quote',{
      method:'POST',headers:{authorization:'Bearer '+SECRET,'content-type':'application/json'},
      body:JSON.stringify({pair:'XBTZAR'})});
    assert.equal(r.status,200);const data=await r.json();
    assert.equal(data.report.tradeAuthorized,false);
    assert.equal(data.report.spreadPercent,1);
  }finally{await new Promise(done=>app.server.close(done));app.close();}
});
