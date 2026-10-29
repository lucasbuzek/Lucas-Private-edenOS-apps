// One bounded, read-only live upstream compatibility check (candidate QA only).
// Never submits notices, binds credentials or stores fetched tender content.
import {fetchSaOcds} from "../src/saOcds.js";
import {fetchTedPublic} from "../src/ted.js";
const now=new Date(),end=now.toISOString().slice(0,10),start=new Date(now.getTime()-3*86400000).toISOString().slice(0,10);
const probes=[
 ["South African Treasury OCDS",async()=>fetchSaOcds({from:start,to:end,pages:1,pageSize:1})],
 ["European TED Search",async()=>fetchTedPublic({country:"SVK",limit:1,page:1})],
];
let failed=0;
for(const [name,run] of probes){
 try{
  const d=await run();
  const records=d.results||[];
  if(!Array.isArray(records)||d.verified!==false)throw Error("Malformed or misleading result status");
  console.log(JSON.stringify({provider:name,outcome:"REACHABLE_SCHEMA_ACCEPTED",count:records.length,coverage:d.coverage,source:d.sourceUrl}));
 }catch(e){
  failed++;
  console.log(JSON.stringify({provider:name,outcome:"NOT_VERIFIED",reason:String(e.message).slice(0,250)}));
 }
}
if(failed)process.exitCode=1;
