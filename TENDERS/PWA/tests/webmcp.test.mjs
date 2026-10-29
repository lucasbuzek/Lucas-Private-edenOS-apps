import test from "node:test";
import assert from "node:assert/strict";
import {registerPublicTenderWebMcp} from "../src/webmcp.js";
const now=()=>new Date("2026-10-29T09:00:00Z");
test("WebMCP gracefully degrades in Safari and unsupported browsers",()=>{
 const x=registerPublicTenderWebMcp({modelContext:null,now});
 assert.equal(x.supported,false);
 x.dispose();
});
test("registers only read-only public source tools with abort lifecycle",async()=>{
 let captured,config;
 const ctx={registerTool(tool,options){captured=tool;config=options}};
 const reg=registerPublicTenderWebMcp({modelContext:ctx,now,fetchImpl:async()=>{throw Error("not used")}});
 assert.equal(await reg.ready,true);
 assert.equal(captured.name,"tenders_search_sa_public_notices");
 assert.equal(captured.annotations.readOnlyHint,true);
 assert.equal(captured.annotations.untrustedContentHint,true);
 assert.match(captured.description,/No private TENDERS workspace access/);
 assert.equal(config.signal.aborted,false);
 reg.dispose();
 assert.equal(config.signal.aborted,true);
});
test("public tool reads only bounded official source and does not expose client secrets or local workspace",async()=>{
 let tool,call;
 const ctx={registerTool(x){tool=x}};
 const reg=registerPublicTenderWebMcp({modelContext:ctx,origin:"https://tenders.example",now,
   fetchImpl:async(url,opts)=>{
     call={url,opts};
     return {ok:true,json:async()=>({provider:"SA National Treasury OCDS",sourceUrl:"https://ocds-api.etenders.gov.za/api/OCDSReleases",fetchedAt:"2026-10-29T09:00:00Z",truncated:false,results:[{ocid:"ocds-abc",title:"Public equipment",reference:"B-1",url:"https://ocds-api.etenders.gov.za/api/OCDSReleases/release/ocds-abc",buyer:{name:"Buyer"},deadline:null,token:"PRIVATE-NEVER-RETURN"}]})};
   }});
 const result=await tool.execute({dateFrom:"2026-10-10",dateTo:"2026-10-11"});
 assert.equal(new URL(call.url).pathname,"/api/official/sa-ocds");
 assert.equal(new URL(call.url).searchParams.get("dateFrom"),"2026-10-10");
 assert.equal(call.opts.credentials,"same-origin");
 assert.equal(result.status,"DISCOVERED");
 assert.equal(result.opportunities[0].title,"Public equipment");
 assert.ok(!JSON.stringify(result).includes("PRIVATE-NEVER-RETURN"));
 reg.dispose();
});
test("WebMCP rejects out-of-range dates without contacting provider",async()=>{
 let tool,count=0;
 const reg=registerPublicTenderWebMcp({modelContext:{registerTool(x){tool=x}},fetchImpl:async()=>{count++;},now});
 await assert.rejects(()=>tool.execute({dateFrom:"2025-01-01",dateTo:"2026-10-29"}),/31-day range/);
 assert.equal(count,0);reg.dispose();
});
test("WebMCP reports unreachable or malformed backend; never returns pretend tender results",async()=>{
 let tool;
 const reg=registerPublicTenderWebMcp({modelContext:{registerTool(x){tool=x}},fetchImpl:async()=>({ok:false,status:502}),now});
 await assert.rejects(()=>tool.execute({}),/HTTP 502/);
 reg.dispose();
});
