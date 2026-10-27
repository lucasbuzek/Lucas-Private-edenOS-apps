import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createPlan, advancePlan, evaluateMarket, probeLunoMarket, ONBOARDING_STEPS, PROVIDERS } from '../engine.mjs';

test('onboarding is capped at 5 USD and never silently enables trading', () => {
  let p = createPlan({ provider: 'luno', spendingLimitUSD: 5 });
  assert.equal(p.liveExecutionEnabled, false);
  assert.equal(p.automationEnabled, false);
  assert.throws(() => createPlan({ provider: 'luno', spendingLimitUSD: 5.01 }));
  assert.throws(() => createPlan({ provider: 'unknown' }));
  assert.throws(() => advancePlan(p, 'FUND_MANUALLY'));
  for (const step of ONBOARDING_STEPS) p = advancePlan(p, step);
  assert.equal(p.status, 'USER_REPORTED_FINISHED_NOT_API_VERIFIED');
  assert.equal(p.liveExecutionEnabled, false);
});
test('provider matrix separates equities and crypto and does not advertise verified virtual card', () => {
  assert.equal(PROVIDERS.easyequities.capabilities.liveOrderAPI, false);
  assert.match(PROVIDERS.luno.capabilities.cardFunding, /CONFLICTING/);
});
test('read-only quote is fresh and calculates actual displayed spread only', () => {
  const now = Date.now();
  const sample = { pair:'XBTZAR', bid:'99.00', ask:'100.00', timestamp:now, status:'ACTIVE' };
  const r = evaluateMarket(sample, 'XBTZAR', now);
  assert.equal(r.spreadPercent,1); assert.equal(r.tradeAuthorized,false);
  assert.equal(r.pipeline.at(-1),'NO_EXECUTION');
  assert.throws(() => evaluateMarket({...sample,timestamp:now-125000},'XBTZAR',now));
  assert.throws(() => evaluateMarket({...sample,ask:'95.00'},'XBTZAR',now));
  assert.throws(() => evaluateMarket({...sample,status:'HALTED'},'XBTZAR',now));
  assert.throws(() => evaluateMarket({...sample,pair:'ETHZAR'},'XBTZAR',now));
});
test('market probe uses official allowlisted URL and no wallet or order writes', async () => {
  let target;
  const res=await probeLunoMarket('ETHZAR',async (url,opts)=>{
    target=url;assert.equal(opts.headers.accept,'application/json');
    return {ok:true,json:async()=>({pair:'ETHZAR',bid:'199',ask:'200',
      timestamp:Date.now(),status:'ACTIVE'})};
  });
  assert.equal(target,'https://api.luno.com/api/1/ticker?pair=ETHZAR');
  assert.equal(res.status,'RESEARCH_ONLY');
  await assert.rejects(()=>probeLunoMarket('BAD/PAIR'));
});
