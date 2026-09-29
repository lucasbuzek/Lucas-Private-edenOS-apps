import test from "node:test";import assert from "node:assert/strict";
import fs from "node:fs";
import {dividendAmount,visibleAt} from "../core/dividends.js";
import {effectiveCapabilities,allDeclaredCapabilities} from "../core/entitlements.js";
const contract=JSON.parse(fs.readFileSync(new URL("../contracts/capabilities.json",import.meta.url)));

const events=[
 {securityId:"S1",exDate:"2026-01-01",amount:2,status:"paid",knownAt:"2025-12-01T00:00:00Z"},
 {securityId:"S1",exDate:"2026-02-01",amount:3,status:"declared",knownAt:"2026-01-15T00:00:00Z"},
 {securityId:"S1",exDate:"2026-03-01",amount:4,status:"estimated",knownAt:"2026-01-01T00:00:00Z"}
];

test("forecast never contaminates realized dividend",()=>assert.equal(dividendAmount(events,{securityId:"S1",from:"2026-01-01",to:"2026-12-31",basis:"realized"}),2));
test("declared basis excludes estimates",()=>assert.equal(dividendAmount(events,{securityId:"S1",from:"2026-01-01",to:"2026-12-31",basis:"declared"}),5));
test("point in time excludes later-known evidence",()=>assert.equal(visibleAt(events,"2026-01-10T00:00:00Z").length,2));
test("alpha exposes every declared capability without purchase state",()=>{
 const got=effectiveCapabilities({contract,buildProfile:"development_alpha",ownsFull:false,intelligenceActive:false});
 assert.deepEqual(got,allDeclaredCapabilities(contract));
});
test("commercial subscription expiry cannot remove permanent full",()=>{
 const got=effectiveCapabilities({contract,buildProfile:"commercial",ownsFull:true,intelligenceActive:false});
 assert.ok(got.includes("expert"));assert.ok(!got.includes("cloud.reasoning"));
});
