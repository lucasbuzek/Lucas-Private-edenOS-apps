import test from "node:test";
import assert from "node:assert/strict";
import {dedupeDiscovery,discoverTenderFeed,parseTenderFeed} from "../src/discovery.js";
test("parses RSS records and preserves source provenance without asserting verification",()=>{const feed='<?xml version="1.0"?><rss><channel><title>Public tenders</title><item><title>Supply of equipment</title><link>https://example.gov/tenders/1</link><guid>R-1</guid><pubDate>Tue, 13 Oct 2026 10:00:00 GMT</pubDate><description>Supply equipment</description><deadline>2026-11-01</deadline></item></channel></rss>';const items=parseTenderFeed(feed,{url:"https://example.gov/feed.xml",contentType:"application/rss+xml"});assert.equal(items.length,1);assert.equal(items[0].title,"Supply of equipment");assert.equal(items[0].id,"R-1");assert.equal(items[0].deadline,"2026-11-01");assert.equal(items[0].sourceFeedUrl,"https://example.gov/feed.xml")});
test("parses JSON opportunity feeds and deduplicates identical URLs",()=>{const feed=JSON.stringify({results:[{id:"A",title:"Tender A",url:"https://example.gov/a"},{id:"A2",title:"Tender A duplicate",url:"https://example.gov/a"},{title:"Bad item",url:"javascript:alert(1)"}]});const items=parseTenderFeed(feed,{url:"https://example.gov/feed.json",contentType:"application/json"});assert.equal(items.length,1);assert.equal(items[0].id,"A")});
test("rejects insecure feed URLs and unsupported formats",()=>{assert.throws(()=>parseTenderFeed("[]",{url:"file:///tmp/a"}),/HTTP or HTTPS/);assert.throws(()=>parseTenderFeed("not a feed",{url:"https://example.gov/feed"}),/Unsupported feed/)});
test("live fetch adapter verifies HTTP response and parses payload",async()=>{const result=await discoverTenderFeed("https://example.gov/feed.json",{fetchImpl:async(url,opts)=>({ok:true,status:200,headers:{get:()=>"application/json"},text:async()=>JSON.stringify([{id:"1",title:"Tender",url:"https://example.gov/t/1"}])}),now:()=>"2026-10-15T00:00:00.000Z"});assert.equal(result.httpStatus,200);assert.equal(result.count,1);assert.equal(result.items[0].title,"Tender");assert.equal(result.fetchedAt,"2026-10-15T00:00:00.000Z");if(result.contentSha256)assert.match(result.contentSha256,/^[a-f0-9]{64}$/)});
test("live fetch errors and HTTP failures are visible",async()=>{await assert.rejects(()=>discoverTenderFeed("https://example.gov/feed",{fetchImpl:async()=>{throw Error("CORS blocked")}}),/CORS/);await assert.rejects(()=>discoverTenderFeed("https://example.gov/feed",{fetchImpl:async()=>({ok:false,status:403})}),/HTTP 403/)});
test("deduplication compares existing source URL and reference",()=>{const items=[{id:"A",url:"https://example.gov/a"},{id:"B",url:"https://example.gov/b"}];assert.deepEqual(dedupeDiscovery(items,[{sourceUrl:"https://example.gov/a",reference:"old"}]).map(x=>x.id),["B"]) });

test("deduplication scopes feed item IDs to their originating feed",()=>{
 const records=[{reference:"SAME-ID",sourceUrl:"https://one.example/t/1",discovery:{sourceFeedUrl:"https://one.example/feed",sourceItemId:"SAME-ID"}}];
 const items=[
  {id:"SAME-ID",url:"https://one.example/t/1",sourceFeedUrl:"https://one.example/feed"},
  {id:"SAME-ID",url:"https://two.example/t/9",sourceFeedUrl:"https://two.example/feed"},
  {id:"OTHER",url:"https://one.example/t/2",sourceFeedUrl:"https://one.example/feed"}
 ];
 assert.deepEqual(dedupeDiscovery(items,records).map(x=>x.url),["https://two.example/t/9","https://one.example/t/2"]);
});

test("parses OCDS JSON tender releases with buyer, reference and closing date",()=>{
 const feed=JSON.stringify({uri:"https://example.gov/ocds",releases:[{id:"release-1",ocid:"ocds-123",date:"2026-10-14",buyer:{name:"Public Works"},tender:{id:"BID-44",title:"Road maintenance services",description:"Regional road maintenance",tenderPeriod:{endDate:"2026-11-30T12:00:00Z"},documents:[{url:"https://example.gov/bids/44"}]}}]});
 const items=parseTenderFeed(feed,{url:"https://example.gov/api/ocds",contentType:"application/json"});
 assert.equal(items.length,1);assert.equal(items[0].sourceFormat,"ocds-json");assert.equal(items[0].title,"Road maintenance services");assert.equal(items[0].buyer,"Public Works");assert.equal(items[0].reference,"BID-44");assert.equal(items[0].deadline,"2026-11-30T12:00:00Z");assert.equal(items[0].url,"https://example.gov/bids/44");
});
test("parses OCDS record packages using compiledRelease",()=>{
 const feed=JSON.stringify({records:[{compiledRelease:{id:"release-2",ocid:"ocds-456",buyer:{name:"Buyer"},tender:{id:"B-2",title:"IT equipment",documents:[{url:"https://example.gov/b/2"}]}}}]});
 const items=parseTenderFeed(feed,{url:"https://example.gov/api",contentType:"application/json"});
 assert.equal(items.length,1);assert.equal(items[0].title,"IT equipment");assert.equal(items[0].sourceFormat,"ocds-json");
});

