// EU Publications Office TED Search API v3 — public notices only.
// Never treats ACTIVE scope as verification that every result is an open tender.
export const TED_SEARCH_ENDPOINT="https://api.ted.europa.eu/v3/notices/search";
const allowedCountries=new Set(["SVK","CZE","AUT","POL","HUN","DEU"]);
export function normalizeTedCountry(value){
  const country=String(value||"SVK").toUpperCase();
  if(!allowedCountries.has(country))throw new Error("Unsupported country scope.");
  return country;
}
export function makeTedSearchBody({country="SVK",limit=30,page=1}={}){
  country=normalizeTedCountry(country);
  if(!Number.isInteger(limit)||limit<1||limit>50||!Number.isInteger(page)||page<1||page>3)throw new Error("TED query bounds exceeded.");
  return {
    query:"buyer-country="+country+" SORT BY publication-date DESC",
    fields:["publication-number","notice-title","buyer-name","buyer-country","publication-date","deadline","notice-type"],
    limit, page, scope:"ACTIVE",checkQuerySyntax:false,paginationMode:"PAGE_NUMBER"
  };
}
function plain(value,locale="slk"){
  if(typeof value==="string")return value.trim();
  if(Array.isArray(value))return value.map(v=>plain(v,locale)).find(Boolean)||"";
  if(!value||typeof value!=="object")return "";
  const candidates=[value[locale],value.eng,value.slk,value.slk_SK,...Object.values(value)];
  for(const x of candidates){const s=plain(x,locale);if(s)return s}
  return "";
}
export function mapTedNotice(notice,{locale="slk"}={}){
  if(!notice||typeof notice!=="object")return null;
  const reference=plain(notice["publication-number"]).slice(0,40);
  if(!/^[0-9]{1,8}-[0-9]{4}$/.test(reference))return null;
  const title=plain(notice["notice-title"],locale).slice(0,300);
  if(!title)return null;
  const url="https://ted.europa.eu/"+(locale==="slk"?"sk":"en")+"/notice/"+reference+"/html";
  return {
    id:reference,reference,title,url,
    buyer:plain(notice["buyer-name"],locale).slice(0,300),
    country:plain(notice["buyer-country"],locale).slice(0,10),
    publishedAt:plain(notice["publication-date"]).slice(0,35)||null,
    deadline:plain(notice.deadline).slice(0,35)||null,
    summary:"TED public notice; source verification, notice type and eligibility still required.",
    sourceFormat:"ted-json",discoveryStatus:"DISCOVERED",verified:false
  };
}
export async function fetchTedPublic({country="SVK",limit=30,page=1,fetchImpl=fetch,now=()=>new Date()}={}){
  const body=makeTedSearchBody({country,limit,page});
  const response=await fetchImpl(TED_SEARCH_ENDPOINT,{
    method:"POST",headers:{"content-type":"application/json",accept:"application/json"},
    body:JSON.stringify(body),cache:"no-store",redirect:"error",signal:AbortSignal.timeout(12000)
  });
  if(!response?.ok)throw Error("TED Search API returned HTTP "+(response?.status||"unknown"));
  if(Number(response.headers?.get?.("content-length")||0)>5000000)throw Error("TED response too large");
  const content=await response.text();
  if(content.length>5000000)throw Error("TED response too large");
  let data;try{data=JSON.parse(content)}catch{throw Error("Invalid TED JSON response")}
  if(!data||!Array.isArray(data.notices))throw Error("Unexpected TED notices schema");
  const byRef=new Map();
  for(const notice of data.notices){
    const item=mapTedNotice(notice,{locale:"slk"});
    if(item)byRef.set(item.id,item);
  }
  return {
    provider:"EU TED Search API",
    sourceUrl:TED_SEARCH_ENDPOINT,
    fetchedAt:new Date(now()).toISOString(),country:body.query.slice("buyer-country=".length, "buyer-country=".length+3),
    query:body.query,scope:body.scope,pagesFetched:1,
    truncated: data.notices.length>=limit || (typeof data.totalNoticeCount==="number" && data.totalNoticeCount>page*limit),
    count:byRef.size,
    verified:false,
    coverage:"TED ACTIVE may include planning, competition and result notices; verify each notice status and eligibility.",
    results:[...byRef.values()]
  };
}
