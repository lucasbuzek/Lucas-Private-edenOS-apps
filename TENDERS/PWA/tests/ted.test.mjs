import test from "node:test";
import assert from "node:assert/strict";
import {TED_SEARCH_ENDPOINT,makeTedSearchBody,mapTedNotice,fetchTedPublic} from "../src/ted.js";
import handler from "../netlify/functions/eu-ted.mjs";
const sample={"publication-number":"123456-2026","notice-title":{"slk":["Dodanie elektrických zariadení"],"eng":["Supply of devices"]},"buyer-name":{"slk":["Verejný obstarávateľ"]},"buyer-country":"SVK","publication-date":"2026-10-28","deadline":"2026-11-15","notice-type":"cn-standard"};
const response=(body,status=200)=>new Response(JSON.stringify(body),{status,headers:{"content-type":"application/json"}});
test("TED query is pinned to official v3 contract, Slovakia default and public ACTIVE scope",()=>{
  assert.equal(TED_SEARCH_ENDPOINT,"https://api.ted.europa.eu/v3/notices/search");
  const b=makeTedSearchBody();
  assert.match(b.query,/buyer-country=SVK/);
  assert.equal(b.paginationMode,"PAGE_NUMBER");
  assert.equal(b.scope,"ACTIVE");
  assert.equal(b.limit,30);
});
test("TED query rejects unapproved country and oversized pages/limits",()=>{
 for(const options of [{country:"USA"},{country:"SVK OR buyer-country=AUT"},{limit:251},{page:99}]){
  assert.throws(()=>makeTedSearchBody(options),/Unsupported country|bounds exceeded/);
 }
});
test("maps multilingual Slovak public title to stable official Slovak notice URL",()=>{
 const mapped=mapTedNotice(sample);
 assert.equal(mapped.reference,"123456-2026");
 assert.equal(mapped.title,"Dodanie elektrických zariadení");
 assert.equal(mapped.url,"https://ted.europa.eu/sk/notice/123456-2026/html");
 assert.equal(mapped.buyer,"Verejný obstarávateľ");
 assert.equal(mapped.discoveryStatus,"DISCOVERED");
 assert.equal(mapped.verified,false);
});
test("rejects untrusted TED notice IDs to prevent URL injection or fictitious identity",()=>{
 assert.equal(mapTedNotice({...sample,"publication-number":"../api/secret"}),null);
 assert.equal(mapTedNotice({...sample,"notice-title":{}}),null);
});
test("public TED fetch uses fixed endpoint, POST body, no credentials and preserves source provenance",async()=>{
 const calls=[];
 const out=await fetchTedPublic({country:"SVK",now:()=>new Date("2026-10-29T09:00:00Z"),fetchImpl:async(url,init)=>{calls.push({url,init});return response({notices:[sample],totalNoticeCount:1})}});
 assert.equal(calls.length,1);
 assert.equal(calls[0].url,TED_SEARCH_ENDPOINT);
 assert.equal(calls[0].init.method,"POST");
 assert.equal(JSON.parse(calls[0].init.body).query,"buyer-country=SVK SORT BY publication-date DESC");
 assert.equal(calls[0].init.headers.authorization,undefined);
 assert.equal(out.results.length,1);
 assert.equal(out.verified,false);
 assert.match(out.coverage,/planning/);
});
test("TED failures and malformed response never create fake opportunities",async()=>{
 await assert.rejects(()=>fetchTedPublic({fetchImpl:async()=>response({error:"rate limit"},429)}),/HTTP 429/);
 await assert.rejects(()=>fetchTedPublic({fetchImpl:async()=>response({items:[]})}),/schema/);
});
test("Netlify proxy denies client POST and invalid country with no upstream access",async()=>{
 let resp=await handler(new Request("https://tenders.example/api/official/eu-ted",{method:"POST"}));
 assert.equal(resp.status,405);
 resp=await handler(new Request("https://tenders.example/api/official/eu-ted?country=USA"));
 assert.equal(resp.status,400);
});
