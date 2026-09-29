import test from "node:test";import assert from "node:assert/strict";
import {dividendAmount,visibleAt} from "../core/dividends.js";
import {effectiveCapabilities} from "../core/entitlements.js";

const events=[
 {securityId:"S1",exDate:"2026-01-01",amount:2,status:"paid",knownAt:"2025-12-01T00:00:00Z"},
 {securityId:"S1",exDate:"2026-02-01",amount:3,status:"declared",knownAt:"2026-01-15T00:00:00Z"},
 {securityId:"S1",exDate:"2026-03-01",amount:4,status:"estimated",knownAt:"2026-01-01T00:00:00Z"}
];

test("forecast never contaminates realized dividend",()=>assert.equal(dividendAmount(events,{securityId:"S1",from:"2026-01-01",to:"2026-12-31",basis:"realized"}),2));
test("declared basis excludes estimates",()=>assert.equal(dividendAmount(events,{securityId:"S1",from:"2026-01-01",to:"2026-12-31",basis:"declared"}),5));
test("point in time excludes later-known evidence",()=>assert.equal(visibleAt(events,"2026-01-10T00:00:00Z").length,2));
test("subscription expiry cannot remove permanent full",()=>{const c=effectiveCapabilities({free:["lookup"],full:["expert"],intelligence:["cloud"],ownsFull:true,intelligenceActive:false});assert.deepEqual(c,["expert","lookup"])});
