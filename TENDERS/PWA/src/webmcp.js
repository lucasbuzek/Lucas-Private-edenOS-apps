// Optional Chrome WebMCP progressive enhancement for PUBLIC Treasury results only.
// No access to TENDERS local workspace, private files, credentials or bid actions.
import {defaultSaWindow,validateSaWindow} from "./saOcds.js";
export function registerPublicTenderWebMcp({
  modelContext=typeof document!=="undefined"?document.modelContext:null,
  fetchImpl=fetch,
  origin=typeof location!=="undefined"?location.origin:"https://localhost.invalid",
  now=()=>new Date()
}={}){
  const unavailable={supported:false,ready:Promise.resolve(false),dispose(){}};
  if(!modelContext || typeof modelContext.registerTool!=="function")return unavailable;
  const controller=new AbortController();
  const tool={
    name:"tenders_search_sa_public_notices",
    description:"Read up to 20 public procurement records published by South African National Treasury within an explicitly bounded date range. Results may be historical, incomplete and are never verified open tenders. No private TENDERS workspace access.",
    inputSchema:{
      type:"object",
      properties:{
        dateFrom:{type:"string",description:"Optional YYYY-MM-DD start date; maximum 31-day range"},
        dateTo:{type:"string",description:"Optional YYYY-MM-DD end date"}
      },
      additionalProperties:false
    },
    annotations:{readOnlyHint:true,consequentialHint:false,untrustedContentHint:true},
    execute:async ({dateFrom,dateTo}={},execution={})=>{
      const defaults=defaultSaWindow(now);
      const window=validateSaWindow(dateFrom||defaults.from,dateTo||defaults.to);
      const url=new URL("/api/official/sa-ocds",origin);
      url.searchParams.set("dateFrom",window.from);
      url.searchParams.set("dateTo",window.to);
      const response=await fetchImpl(url.href,{credentials:"same-origin",cache:"no-store",redirect:"error",signal:execution.signal||controller.signal});
      if(!response?.ok)throw Error("Authorised public source adapter unavailable (HTTP "+(response?.status||"unknown")+").");
      const data=await response.json();
      if(!data||!Array.isArray(data.results)||data.provider!=="SA National Treasury OCDS")throw Error("Unexpected official source adapter response.");
      return {
        source:data.sourceUrl,
        fetchedAt:data.fetchedAt,
        coverage:"Subset; do not assume tenders are open or eligible.",
        status:"DISCOVERED",
        truncated:Boolean(data.truncated)||data.results.length>20,
        opportunities:data.results.slice(0,20).map(item=>({
          ocid:String(item.ocid||"").slice(0,200),
          title:String(item.title||"").slice(0,300),
          reference:String(item.reference||"").slice(0,200),
          url:String(item.url||"").slice(0,1000),
          buyer:String(item.buyer?.name||"").slice(0,300),
          deadline:item.deadline||null,
          verified:false
        }))
      };
    }
  };
  let ready;
  try{ready=Promise.resolve(modelContext.registerTool(tool,{signal:controller.signal})).then(()=>true).catch(()=>false)}
  catch{controller.abort();return unavailable}
  return {supported:true,ready,dispose(){controller.abort()}};
}
