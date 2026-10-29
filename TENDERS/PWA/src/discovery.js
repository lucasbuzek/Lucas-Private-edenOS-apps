const text=v=>String(v??"").replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g,"$1").replace(/<[^>]+>/g," ").replace(/&amp;/g,"&").replace(/&lt;/g,"<").replace(/&gt;/g,">").replace(/&quot;/g,'"').replace(/&#39;|&apos;/g,"'").replace(/\s+/g," ").trim();
function tag(block,names){for(const name of names){const re=new RegExp("<(?:[\\w.-]+:)?"+name+"(?:\\s[^>]*)?>([\\s\\S]*?)<\\/(?:[\\w.-]+:)?"+name+"\\s*>","i");const m=block.match(re);if(m)return text(m[1])}return ""}
function xmlLink(block){const links=[...block.matchAll(/<(?:[\w.-]+:)?link\b([^>]*?)(?:\/?>)([^<]*)/gi)];for(const m of links){const href=m[1].match(/\bhref\s*=\s*["']([^"']+)["']/i)?.[1];const rel=m[1].match(/\brel\s*=\s*["']([^"']+)["']/i)?.[1];if(href&&(!rel||rel==="alternate"))return href;const body=text(m[2]);if(body)return body}return ""}
function normalizeUrl(value,base){try{const u=new URL(value,base);return ["https:","http:"].includes(u.protocol)?u.href:""}catch{return ""}}
function fromXml(body,feedUrl){const blocks=[...body.matchAll(/<(?:[\w.-]+:)?(item|entry)\b[^>]*>([\s\S]*?)<\/(?:[\w.-]+:)?\1\s*>/gi)];return blocks.map((m,i)=>{const b=m[2],title=tag(b,["title","name"]),url=normalizeUrl(xmlLink(b)||tag(b,["url","link"]),feedUrl),id=tag(b,["guid","id"]),published=tag(b,["pubDate","published","updated","date"]),deadline=tag(b,["deadline","closingDate","closing_date","submissionDeadline"]);return {id:id||url||String(i),title,url,publishedAt:published||null,deadline:deadline||null,summary:tag(b,["description","summary","content"]),sourceFormat:/entry/i.test(m[1])?"atom":"rss"}}).filter(x=>x.title&&x.url)}
function fromJson(body,feedUrl){
 let parsed;try{parsed=JSON.parse(body)}catch{return null}
 const ocds=Array.isArray(parsed?.releases)?parsed.releases:Array.isArray(parsed?.records)?parsed.records.map(r=>r?.compiledRelease||r):null;
 const items=ocds||(Array.isArray(parsed)?parsed:(parsed.items||parsed.results||parsed.data||parsed.opportunities||[]));
 if(!Array.isArray(items))return null;
 return items.map((x,i)=>{
  const tender=x?.tender||{},buyer=x?.buyer||{},documents=Array.isArray(tender.documents)?tender.documents:Array.isArray(x?.documents)?x.documents:[];
  const title=x?.title||x?.name||x?.subject||x?.tenderTitle||tender.title||"";
  const candidateUrl=x?.url||x?.link||x?.href||x?.sourceUrl||x?.source_url||documents.find(d=>d?.url)?.url;
  const url=normalizeUrl(candidateUrl,feedUrl);
  const id=String(x?.id||x?.guid||x?.reference||x?.tenderReference||tender.id||x?.ocid||url||i);
  return {id,reference:String(tender.id||x?.reference||x?.tenderReference||x?.ocid||x?.id||id),title:String(title).trim(),url,buyer:String(buyer.name||x?.buyerName||x?.buyer_name||""),publishedAt:x?.date||x?.publishedAt||x?.published_at||x?.published||x?.updated||null,deadline:tender.tenderPeriod?.endDate||tender.tenderPeriod?.endDateTime||x?.deadline||x?.closingDate||x?.closing_date||x?.submissionDeadline||null,summary:String(tender.description||x?.summary||x?.description||x?.excerpt||""),sourceFormat:ocds?"ocds-json":"json"};
 }).filter(x=>x.title&&x.url);
}
export function parseTenderFeed(body,{url,contentType=""}={}){if(typeof body!=="string"||!url)throw new Error("A response body and source URL are required.");const base=normalizeUrl(url);if(!base)throw new Error("Feed URL must use HTTP or HTTPS.");const json=/json/i.test(contentType)||/^\s*[\[{]/.test(body);const results=json?fromJson(body,base):fromXml(body,base);if(!results||(!json&&results.length===0&&!/<(?:[\w.-]+:)?(?:rss|feed)\b/i.test(body)))throw new Error("Unsupported feed. Use RSS, Atom or a JSON array/feed with title and link fields.");const seen=new Set();return results.filter(item=>{if(!item.url||seen.has(item.url))return false;seen.add(item.url);return true}).map(item=>({...item,sourceFeedUrl:base}));}
async function sha256Hex(value){
 if(!globalThis.crypto?.subtle||typeof TextEncoder==="undefined")return null;
 const digest=await globalThis.crypto.subtle.digest("SHA-256",new TextEncoder().encode(value));
 return [...new Uint8Array(digest)].map(b=>b.toString(16).padStart(2,"0")).join("");
}
export async function discoverTenderFeed(url,{fetchImpl=fetch,now=()=>new Date().toISOString()}={}){
 const feedUrl=normalizeUrl(url);if(!feedUrl)throw new Error("Feed URL must use HTTP or HTTPS.");
 let response;try{response=await fetchImpl(feedUrl,{headers:{Accept:"application/atom+xml, application/rss+xml, application/feed+json, application/json, application/xml, text/xml;q=0.9, text/plain;q=0.5"},cache:"no-store"})}catch(error){throw new Error("Live source could not be reached. The host may be offline or block browser cross-origin access (CORS). "+error.message)}
 if(!response.ok)throw new Error("Source returned HTTP "+response.status+"; no opportunities imported.");
 const contentType=response.headers?.get?.("content-type")||"",body=await response.text(),fetchedAt=now(),contentSha256=await sha256Hex(body);
 const items=parseTenderFeed(body,{url:feedUrl,contentType});
 return {sourceUrl:feedUrl,fetchedAt,httpStatus:response.status,contentType,contentSha256,count:items.length,items};
}
export function dedupeDiscovery(items,records){
 const knownUrls=new Set((records||[]).map(r=>r.sourceUrl).filter(Boolean).map(String));
 const knownFeedItems=new Set((records||[]).filter(r=>r.discovery?.sourceFeedUrl&&r.discovery?.sourceItemId).map(r=>String(r.discovery.sourceFeedUrl)+"\u0000"+String(r.discovery.sourceItemId)));
 return (items||[]).filter(item=>{
  if(item.url&&knownUrls.has(String(item.url)))return false;
  if(item.sourceFeedUrl&&item.id&&knownFeedItems.has(String(item.sourceFeedUrl)+"\u0000"+String(item.id)))return false;
  return true;
 });
}

