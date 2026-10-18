import test from 'node:test';
import assert from 'node:assert/strict';
import { qualificationCases, qualifyIntelligenceProvider } from '../intelligence/qualification.mjs';

test('unconfigured / paid / unavailable models cannot pass as capable intelligence',async()=>{
  for(const provider of [null, {available:false,generate:async()=>''}, {available:true,costClass:'paid',generate:async()=>''}]){
    const r=await qualifyIntelligenceProvider({appId:'cresus',provider});
    assert.equal(r.status,'BLOCKED_NO_AUTHORIZED_PROVIDER');
    assert.equal(r.productionAccepted,false);
  }
});

test('mock good responses are provisional, NOT real model acceptance',async()=>{
  const provider={
    id:'test-mock',available:true,costClass:'free-tier',
    generate:async({messages})=>{
      if(messages[0].content.includes('Portfolio'))return '7 * 10 + 3 * 20 = 130, first holding = 53.85%';
      return 'The fictional ticker has no live market feed. The exact price is UNVERIFIED.';
    },
  };
  const r=await qualifyIntelligenceProvider({appId:'cresus',provider});
  assert.equal(r.automatedPass,true);
  assert.equal(r.productionAccepted,false);
  assert.equal(r.status,'PROVISIONAL_MANUAL_AND_LIVE_EVIDENCE_REQUIRED');
  assert.equal(r.checks.length,2);
});

test('fabricated live prices and misidentified eligibility fail the quality gate',async()=>{
  const provider={id:'unsafe-mock',available:true,costClass:'free-tier',
    generate:async()=> 'Everything is eligible and I verified today price is $42.00.'};
  for(const appId of ['cresus','hermes']){
    const r=await qualifyIntelligenceProvider({appId,provider});
    assert.equal(r.automatedPass,false);
    assert.equal(r.productionAccepted,false);
    assert.equal(r.status,'FAILED_AUTOMATED_CAPABILITY_GATE');
  }
});

test('provider errors fail the affected case without implicit fallback',async()=>{
  let calls=0;
  const provider={available:true,costClass:'user-connected',
    generate:async()=>{calls++;throw new Error('quota');}};
  const r=await qualifyIntelligenceProvider({appId:'hermes',provider});
  assert.equal(r.automatedPass,false);
  assert.equal(calls,qualificationCases('hermes').length);
  assert.ok(r.checks.every(c=>c.reason==='PROVIDER_EXECUTION_FAILED'));
});

test('no unknown app identity inherits arbitrary model capability certification',async()=>{
  assert.deepEqual(qualificationCases('unknown-app'),[]);
  const r=await qualifyIntelligenceProvider({appId:'unknown-app',provider:{}});
  assert.equal(r.status,'UNKNOWN_APP_PROFILE');
});
