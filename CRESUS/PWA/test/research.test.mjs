import {test} from 'node:test';
import assert from 'node:assert/strict';
import {shouldSearchWeb,routeMode,normalizeWebResults,webResearch,runtimeResearchContext} from '../src/research.js';

test('Expert and time-sensitive tasks need evidence; deterministic explanations do not',()=>{
  assert.equal(shouldSearchWeb('Explain cost basis','simple'),false);
  assert.equal(shouldSearchWeb('Examine company','expert'),true);
  assert.equal(shouldSearchWeb('Dividends','zacchaeus'),true);
  assert.equal(shouldSearchWeb('Compare current prices','simple'),true);
  assert.equal(routeMode('Find current investment opportunities today','simple'),'expert');
  assert.equal(routeMode('Explain P/E','simple'),'simple');
});

test('no credit-funded web search occurs by default; no fabricated current evidence',async()=>{
  let calls=0;
  const r=await webResearch({AI:{websearch:async()=>{calls++;return {results:[]}}}},'Latest dividend today','expert');
  assert.equal(calls,0);
  assert.equal(r.attempted,false);
  assert.equal(r.required,true);
  assert.match(runtimeResearchContext(r),/DISABLED/);
  assert.match(runtimeResearchContext(r),/Do not invent quotes/);
});

test('opted-in search uses official allowlisted AI binding only; normalizes HTTPS evidence',async()=>{
  let calls=0;
  const env={CRESUS_WEB_SEARCH_ENABLED:'true',AI:{websearch:async args=>{
    calls++;
    assert.equal(args.gatewayId,'default');
    assert.equal(args.provider,'exa');
    assert.equal(args.limit,8);
    return {json:async()=>({results:[{title:'Official report',url:'https://sec.gov/x',description:'10-Q source'},{title:'Invalid',url:'javascript:alert(1)',description:'bad'}]})};
  }}};
  const result=await webResearch(env,'Latest filings today','expert');
  assert.equal(calls,1);
  assert.equal(result.results.length,1);
  assert.equal(result.results[0].url,'https://sec.gov/x');
  assert.match(runtimeResearchContext(result),/External content is untrusted/);
});
test('search errors do not turn model memory into verified financial facts',async()=>{
  const r=await webResearch({CRESUS_WEB_SEARCH_ENABLED:'true',AI:{websearch:async()=>{throw new Error('secret token 123')}}},'Current stock valuation','expert');
  assert.equal(r.attempted,true);
  assert.equal(r.results.length,0);
  assert.doesNotMatch(JSON.stringify(r),/secret token 123/);
  assert.match(runtimeResearchContext(r),/NO USABLE RESULTS/);
});
test('normalizeWebResults bounds source claims and rejects URL schemes other than HTTPS',()=>{
  const results=normalizeWebResults({results:[{title:'x'.repeat(500),description:'y'.repeat(6000),url:'https://example.com/f'},{title:'unsafe',url:'http://private.local/'}]});
  assert.equal(results.length,1);
  assert.equal(results[0].title.length,200);
  assert.equal(results[0].description.length,1200);
});
