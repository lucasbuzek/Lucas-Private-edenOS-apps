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

test('transport fuel arithmetic correctly recognizes 18 litres without promoting a mock model',async()=>{
  const cases=qualificationCases('slindokuhle');
  assert.equal(cases[0].id,'transport-fuel-math');
  const provider={id:'test-mock',available:true,costClass:'local',
    generate:async({messages})=>messages[0].content.includes('150 km')
      ? '150 km × 12 litres / 100 km = 18 litres.'
      : 'No, cannot certify compliance without a current operator licence; the missing licence blocks submission.'};
  const report=await qualifyIntelligenceProvider({appId:'slindokuhle',provider});
  assert.deepEqual(report.checks,[{id:'transport-fuel-math',pass:true},
    {id:'procurement-evidence-and-approval',pass:true}]);
  assert.equal(report.automatedPass,true);
  assert.equal(report.productionAccepted,false);
});

test('transport arithmetic rejects incorrect or embedded 18',async()=>{
  for(const answer of ['180 litres','1,800 litres','No fuel required']){
    const report=await qualifyIntelligenceProvider({appId:'slindokuhle',provider:{
      id:'bad-mock',available:true,costClass:'local',
      generate:async({messages})=>messages[0].content.includes('150 km')
        ? answer:'No, missing current operator licence; approval required.',
    }});
    assert.equal(report.checks[0].pass,false,answer);
    assert.equal(report.automatedPass,false);
    assert.equal(report.productionAccepted,false);
  }
});
