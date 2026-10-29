import test from "node:test";
import assert from "node:assert/strict";
import {defaultSaWindow,fetchSaOcds,mapSaRelease,saPageUrl,validateSaWindow,SA_OCDS_ENDPOINT} from "../src/saOcds.js";
import handler from "../netlify/functions/sa-ocds.mjs";
const release=(id,ocid="ocds-9t57fa-11",date="2026-10-25")=>({id,ocid,date,buyer:{name:"Public Department"},tender:{id:"BID-51",title:"Public supplies",description:"Test notice",tenderPeriod:{endDate:"2026-11-10T11:00:00Z"}}});
const json=(data,status=200)=>new Response(JSON.stringify(data),{status,headers:{"content-type":"application/json"}});
test("pins OCDS requests to the published official endpoint and bounded parameters",()=>{
 const url=new URL(saPageUrl({from:"2026-10-01",to:"2026-10-10",page:1,pageSize:50}));
 assert.equal(url.origin,"https://ocds-api.etenders.gov.za");
 assert.equal(url.pathname,"/api/OCDSReleases");
 assert.equal(url.searchParams.get("dateFrom"),"2026-10-01");
 assert.equal(url.searchParams.get("PageSize"),"50");
 assert.throws(()=>saPageUrl({from:"2026-10-01",to:"2026-10-11",page:4}),/pagination/);
});
test("refuses invalid dates, wrong order, oversized ranges and impossible calendar dates",()=>{
 for(const [from,to] of [["2026-02-30","2026-03-01"],["2026-10-30","2026-10-01"],["2026-01-01","2026-04-01"],["2026-10-01","x"]]){
  assert.throws(()=>validateSaWindow(from,to),/ISO dates/);
 }
});
test("maps official records to DISCOVERED provenance only, with safe canonical notice URL",()=>{
 const item=mapSaRelease(release("release-1"));
 assert.equal(item.id,"release-1");
 assert.equal(item.reference,"BID-51");
 assert.equal(item.url,SA_OCDS_ENDPOINT+"/release/ocds-9t57fa-11");
 assert.equal(item.buyer.name,"Public Department");
 assert.equal(item.deadline,"2026-11-10T11:00:00Z");
 assert.equal(item.discoveryStatus,"DISCOVERED");
 assert.equal(item.verified,false);
 assert.equal(mapSaRelease({tender:{title:"No OCID"}}),null);
});
test("reads official schema, follows bounded pages without trusting arbitrary pagination links, dedupes latest",async()=>{
 const calls=[];
 const fetchImpl=async url=>{
   calls.push(url);
   const page=Number(new URL(url).searchParams.get("PageNumber"));
   return page===1?json({releases:[release("old")],links:{next:"https://attacker.example/steal"}}):json({releases:[release("updated","ocds-9t57fa-11","2026-10-26")],links:{}});
 };
 const data=await fetchSaOcds({from:"2026-10-01",to:"2026-10-10",pages:3,pageSize:50,fetchImpl,now:()=>new Date("2026-10-29T09:00:00Z")});
 assert.equal(calls.length,2);
 assert.ok(calls.every(x=>new URL(x).hostname==="ocds-api.etenders.gov.za"));
 assert.equal(data.results.length,1);
 assert.equal(data.results[0].id,"updated");
 assert.equal(data.truncated,false);
 assert.equal(data.verified,false);
});
test("upstream errors and malformed release payloads fail closed",async()=>{
 await assert.rejects(()=>fetchSaOcds({from:"2026-10-01",to:"2026-10-08",fetchImpl:async()=>json({error:"no"},503)}),/HTTP 503/);
 await assert.rejects(()=>fetchSaOcds({from:"2026-10-01",to:"2026-10-08",fetchImpl:async()=>json({items:[]})}),/schema/);
});
test("default window is deterministic 14 days and does not claim all live opportunities",async()=>{
 assert.deepEqual(defaultSaWindow(()=>new Date("2026-10-29T06:00:00Z")),{from:"2026-10-15",to:"2026-10-29"});
 const out=await fetchSaOcds({now:()=>new Date("2026-10-29T06:00:00Z"),fetchImpl:async()=>json({releases:[],links:{}})});
 assert.equal(out.results.length,0);
 assert.match(out.coverage,/subset/);
});
test("Netlify HTTP function never performs a mutating operation",async()=>{
 const result=await handler(new Request("https://tenders.example/api/official/sa-ocds",{method:"POST"}));
 assert.equal(result.status,405);
 assert.equal((await result.json()).error,"Method not allowed");
});
test("Netlify HTTP function rejects invalid date parameters before any upstream fetch",async()=>{
 const result=await handler(new Request("https://tenders.example/api/official/sa-ocds?dateFrom=2026-10-31&dateTo=2026-10-01"));
 assert.equal(result.status,400);
 assert.equal((await result.json()).verified,false);
});
