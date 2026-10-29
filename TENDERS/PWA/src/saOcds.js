// TENDERS source adapter: South African National Treasury public OCDS releases.
// Public notices only; records are DISCOVERED, never independently VERIFIED.
export const SA_OCDS_ENDPOINT = "https://ocds-api.etenders.gov.za/api/OCDSReleases";
const DAY = 86400000;
function parseDay(day) {
  if (typeof day !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(day)) return NaN;
  const time = Date.parse(day + "T00:00:00Z");
  return Number.isFinite(time) && new Date(time).toISOString().slice(0,10) === day ? time : NaN;
}
export function validateSaWindow(from, to) {
  const start = parseDay(from), end = parseDay(to);
  if (!Number.isFinite(start) || !Number.isFinite(end) || start > end || end - start > 31*DAY) {
    throw new Error("Use valid ISO dates with dateFrom <= dateTo and a maximum 31-day range.");
  }
  return {from,to};
}
export function defaultSaWindow(now = () => new Date()) {
  const date = now(), end = new Date(date).toISOString().slice(0,10);
  const start = new Date(Date.parse(end + "T00:00:00Z") - 14*DAY).toISOString().slice(0,10);
  return {from:start,to:end};
}
export function saPageUrl({from,to,page=1,pageSize=50}) {
  validateSaWindow(from,to);
  if (!Number.isInteger(page) || page < 1 || page > 3 || !Number.isInteger(pageSize) || pageSize < 1 || pageSize > 100) {
    throw new Error("Invalid bounded OCDS pagination.");
  }
  const url = new URL(SA_OCDS_ENDPOINT);
  url.searchParams.set("PageNumber",String(page));
  url.searchParams.set("PageSize",String(pageSize));
  url.searchParams.set("dateFrom",from);
  url.searchParams.set("dateTo",to);
  return url.href;
}
function safeText(value, max=2000) { return typeof value === "string" ? value.trim().slice(0,max) : ""; }
export function mapSaRelease(release) {
  if (!release || typeof release !== "object") return null;
  const ocid=safeText(release.ocid,200), title=safeText(release.tender?.title,300);
  if (!ocid || !title) return null;
  const t=release.tender||{};
  return {
    id:safeText(release.id,200)||ocid,
    reference:safeText(t.id,200)||ocid,
    ocid,
    title,
    url:SA_OCDS_ENDPOINT+"/release/"+encodeURIComponent(ocid),
    buyer:{name:safeText(release.buyer?.name,300)},
    publishedAt:safeText(release.date,60)||null,
    deadline:safeText(t.tenderPeriod?.endDate,60)||null,
    summary:safeText(t.description,2000),
    sourceFormat:"ocds-json",
    discoveryStatus:"DISCOVERED",
    verified:false
  };
}
export async function fetchSaOcds({from,to,fetchImpl=fetch,now=()=>new Date(),pages=3,pageSize=50}={}) {
  const defaults=defaultSaWindow(now);
  const window=validateSaWindow(from||defaults.from,to||defaults.to);
  if (!Number.isInteger(pages)||pages<1||pages>3 || !Number.isInteger(pageSize)||pageSize<1||pageSize>100) throw new Error("Pagination limit exceeded.");
  const latest=new Map();
  let lastHasNext=false, fetchedPages=0;
  for(let page=1;page<=pages;page++){
    const source=saPageUrl({...window,page,pageSize});
    const response=await fetchImpl(source,{
      method:"GET",redirect:"error",cache:"no-store",
      headers:{Accept:"application/json"},
      signal:AbortSignal.timeout(12000)
    });
    if(!response?.ok) throw new Error("Official OCDS source returned HTTP "+(response?.status||"unknown"));
    if(Number(response.headers?.get?.("content-length")||0)>5000000) throw new Error("Official OCDS response too large.");
    const body=await response.text();
    if(body.length>5000000) throw new Error("Official OCDS response too large.");
    let data;try{data=JSON.parse(body)}catch{throw new Error("Official OCDS source returned invalid JSON.");}
    if(!data||!Array.isArray(data.releases))throw new Error("Official OCDS source returned unexpected release schema.");
    for(const raw of data.releases){
      const item=mapSaRelease(raw);
      if(!item)continue;
      const existing=latest.get(item.ocid);
      if(!existing || String(item.publishedAt||"")>=String(existing.publishedAt||""))latest.set(item.ocid,item);
    }
    fetchedPages++;
    lastHasNext=Boolean(data.links?.next) || data.releases.length===pageSize;
    if(!lastHasNext)break;
  }
  return {
    provider:"SA National Treasury OCDS",
    sourceUrl:SA_OCDS_ENDPOINT,
    fetchedAt:new Date(now()).toISOString(),
    dateFrom:window.from,dateTo:window.to,
    pagesFetched:fetchedPages,
    truncated:lastHasNext,
    coverage:"subset of public procurement data; never proof of all open tenders",
    verified:false,
    results:[...latest.values()]
  };
}
