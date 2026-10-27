import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validatePaperDraft, assessPaperTrigger } from '../src/trading-core.js';
import { handleTradingApi } from '../src/trading-api.js';
const valid = () => ({
 mic:'XJSE', ticker:'NPN', currency:'ZAR',side:'BUY',
 quantity:2,limitPrice:100,availableCapital:5000,
 sourceUrl:'https://example.org/research',observedAt:new Date().toISOString()
});
test('guided paper preview is deterministic and never live', () => {
 const d=validatePaperDraft(valid());
 assert.equal(d.notional,200);assert.equal(d.allocationPercent,4);
 assert.equal(d.executionVenue,'PAPER');assert.equal(d.executableLive,false);
 assert.equal(d.evidence.state,'MANUAL_UNVERIFIED');
});
test('identity, leverage and risk gate are fail-closed', () => {
 for (const bad of [
 {mic:''},{currency:'USDZ'},{ticker:'DROP TABLE'},{side:'SELL'},
 {leverage:2},{executionVenue:'LIVE'},{live:true},
 {quantity:0},{limitPrice:NaN},{availableCapital:100},
 {maxAllocationPercent:1},{sourceUrl:'http://untrusted'}
 ]) assert.throws(()=>validatePaperDraft({...valid(),...bad}));
});
test('stale and unverified signals never trigger automated paper candidates', () => {
 const rule={condition:'AT_OR_BELOW',threshold:101};
 const quote={price:100,verified:true,sourceUrl:'https://example.org/quote',observedAt:new Date().toISOString()};
 assert.equal(assessPaperTrigger(rule,quote).eligible,true);
 assert.equal(assessPaperTrigger(rule,{...quote,verified:false}).reason,'UNVERIFIED_QUOTE');
 assert.equal(assessPaperTrigger(rule,{...quote,observedAt:'2000-01-01T00:00:00Z'}).reason,'STALE_OR_MISSING_QUOTE');
 assert.throws(()=>assessPaperTrigger({...rule,condition:'INVALID'},quote));
});
test('paper-only API requires authenticated caller and explicit confirmation', async () => {
 let r=await handleTradingApi(new Request('https://test/api/trading/status'),{},null,'/api/trading/status');
 assert.equal(r.status,401);
 r=await handleTradingApi(new Request('https://test/api/trading/status'),{}, {email:'owner@example.com'},'/api/trading/status');
 assert.equal((await r.json()).live,'DISABLED');
 r=await handleTradingApi(new Request('https://test/api/trading/paper',{method:'POST',body:JSON.stringify({order:valid()})}),{}, {email:'owner@example.com'},'/api/trading/paper');
 assert.equal(r.status,422);
});
