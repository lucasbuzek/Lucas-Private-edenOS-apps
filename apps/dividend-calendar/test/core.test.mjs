import assert from "node:assert/strict";
import test from "node:test";
import {normalizeDividendEvent,eventsInWindow,trailingYield,dividendGrowthSeries,detectDividendCuts} from "../src/core.js";
import {dividendCaptureScenario,assertNoLookahead} from "../src/strategy.js";

const events=[
 normalizeDividendEvent({symbol:"abc",exDate:"2025-03-01",amount:1,status:"paid",source:"fixture"}),
 normalizeDividendEvent({symbol:"ABC",exDate:"2025-06-01",amount:1,status:"paid",source:"fixture"}),
 normalizeDividendEvent({symbol:"ABC",exDate:"2025-09-01",amount:1,status:"paid",source:"fixture"}),
 normalizeDividendEvent({symbol:"ABC",exDate:"2025-12-01",amount:1,status:"declared",source:"fixture"})
];

test("normalizes and queries calendar",()=>{
 assert.equal(events[0].symbol,"ABC");
 assert.equal(eventsInWindow(events,"exDate","2025-05-01","2025-10-01").length,2);
});

test("trailing yield uses sourced price input",()=>{
 assert.equal(trailingYield({events,symbol:"ABC",asOf:"2025-12-31",price:100}),0.04);
});

test("detects annual dividend cut",()=>{
 const s=dividendGrowthSeries([
  normalizeDividendEvent({symbol:"X",exDate:"2024-01-01",amount:4,status:"paid"}),
  normalizeDividendEvent({symbol:"X",exDate:"2025-01-01",amount:2,status:"paid"})
 ],"X");
 assert.equal(detectDividendCuts(s).length,1);
});

test("capture strategy includes price drop and frictions",()=>{
 const r=dividendCaptureScenario({buyPrice:100,sellPrice:99,dividend:1,quantity:1,commissionBuy:.1,commissionSell:.1,spreadCost:.1,slippage:.1,dividendTaxRate:.2});
 assert.ok(r.totalReturn<0);
 assert.equal(Number(r.netPnL.toFixed(2)),-0.6);
});

test("lookahead guard rejects future knowledge",()=>{
 assert.throws(()=>assertNoLookahead({decisionAt:"2026-01-01T10:00:00Z",eventKnownAt:"2026-01-02T10:00:00Z"}),/look-ahead/);
});
