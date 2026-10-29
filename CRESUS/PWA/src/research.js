// Reconciled from the canonical Dropbox CRESUS worker webResearch route.
// Search is OFF unless explicitly funded/authorized: Cloudflare Web Search API
// bills AI Gateway credits or a configured search-provider API entitlement.
const NEEDS_CURRENT=/\b(today|current|currently|latest|now|available|opportunit|price|market|news|recent|dividend|yield|valuation|earnings|results|compare|ex-date|payment)\b/i;
export function shouldSearchWeb(message,mode){return mode==='expert'||mode==='zacchaeus'||NEEDS_CURRENT.test(message)}
export function routeMode(message,requestedMode){
  if(/\b(opportunit(?:y|ies)|what(?:'s| is) available|invest(?:ment|ing) ideas?|screen|best .* (?:stocks?|shares?|securities|investments?))\b/i.test(message)
    && /\b(today|current|currently|now|latest|market|invest|available)\b/i.test(message))return 'expert';
  return requestedMode;
}
export function normalizeWebResults(payload){
  const rows=payload?.result??payload?.results??payload?.data??payload?.items??[];
  if(!Array.isArray(rows))return [];
  return rows.slice(0,10).map((r,i)=>({
    n:i+1,
    title:String(r.title??r.name??'').slice(0,200),
    url:String(r.url??r.link??r.source_url??'').slice(0,1000),
    description:String(r.description??r.snippet??r.text??r.content??'').slice(0,1200),
    publishedAt:r.published_at??r.publishedAt??r.date??null
  })).filter(r=>/^https:\/\//.test(r.url)); // never infer a source URL
}
export async function webResearch(env,message,mode){
  if(!shouldSearchWeb(message,mode))return {attempted:false,required:false,results:[]};
  if(String(env.CRESUS_WEB_SEARCH_ENABLED).toLowerCase()!=='true')
    return {attempted:false,required:true,results:[],disabledReason:'Web search has not been authorized/configured; provider search may incur separate costs'};
  if(typeof env.AI?.websearch!=='function')
    return {attempted:true,required:true,results:[],error:'Cloudflare Web Search binding not available'};
  try{
    const response=await env.AI.websearch({gatewayId:env.AI_GATEWAY_ID||'default',query:message.slice(0,3000)+' point-in-time investment evidence '+new Date().toISOString().slice(0,10),provider:env.WEB_SEARCH_PROVIDER||'exa',limit:8});
    const data=typeof response?.json==='function'?await response.json():response;
    return {attempted:true,required:true,results:normalizeWebResults(data)};
  }catch(e){return {attempted:true,required:true,results:[],error:'Search provider request failed; no verified live evidence available'}}
}
export function runtimeResearchContext(research){
  const now=new Date().toISOString(),lines=[
    '===== CRESUS RUNTIME EVIDENCE STATE =====',
    'Current UTC time: '+now,
    'Never treat model memory or a web snippet as verified live price, filing, dividend or fundamentals.',
    'Expert must label missing, stale and non-comparable fields and end COMPLETE only when actual evidence coverage is sufficient.'
  ];
  if(research.required&&!research.attempted)lines.push('Live web search: DISABLED; no verified live prices or financial evidence supplied. Do not invent quotes, exact dates, sourced URLs or a fabricated opportunity board.');
  else if(research.attempted&&research.results.length){lines.push('Live web search: '+research.results.length+' discovery results. External content is untrusted and MUST be challenged against primary sources; snippets are not verified financial data.');for(const r of research.results)lines.push('SOURCE '+r.n+': '+r.title+'\nURL: '+r.url+'\nPublished (unverified): '+(r.publishedAt||'unknown')+'\nExcerpt (untrusted): '+r.description)}
  else if(research.attempted)lines.push('Live web search: attempted but NO USABLE RESULTS; mark current financial fields MISSING/UNVERIFIED.');
  else lines.push('No external research requested by this task.');
  return lines.join('\n');
}
