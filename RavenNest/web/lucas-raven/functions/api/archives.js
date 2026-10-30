// Reuse the already deployed R2 public archive Worker without copying its KV data.
// The private RAVENsNEST portal retains original Access JWT + its own D1 users.
import {verifyAccessJwt} from './[[path]].js';
const R2='https://ravensnest-knowledge.lucasravensnest.workers.dev';
const CATALOG=R2+'/public_catalog.json';
const json=(v,status=200)=>new Response(JSON.stringify(v),{status,headers:{'content-type':'application/json; charset=utf-8','cache-control':'private, no-store','x-content-type-options':'nosniff','referrer-policy':'no-referrer','x-robots-tag':'noindex, nofollow'}});
const error=(s,e)=>json({error:e},s);
async function principal(request,env){
 if(!env.DB)return null;
 let c;try{c=await verifyAccessJwt(request.headers.get('cf-access-jwt-assertion'),env)}catch{return null}
 if(!Number.isFinite(c.exp)||c.exp<=Date.now()/1000)return null;
 const u=await env.DB.prepare('SELECT id,disabled_at FROM users WHERE subject=?1 AND email=?2').bind(c.sub,c.email).first();
 return u&&!u.disabled_at?u:null;
}
function view(r){
 if(!r||typeof r!=='object'||!/^[-a-f0-9]{14,64}$/.test(String(r.id||'')))return null;
 const title=typeof r.title==='string'?r.title.slice(0,240):'Untitled source';
 const category=typeof r.category_label==='string'?r.category_label.slice(0,120):'Unclassified';
 const excerpt=typeof r.excerpt==='string'?r.excerpt.slice(0,600):'';
 const original=typeof r.url==='string'&&r.url.startsWith('https://')?r.url:null;
 const valid=r.status==='converted'&&/^content\/[a-z0-9-]+\/[a-f0-9]{14,64}\.html$/.test(String(r.html_path||''));
 return {id:r.id,title,category,excerpt,original_url:original,archive_url:valid?R2+'/'+r.html_path:null,status:valid?'converted':'source-only',source:'R2 public archive',provenance:'public_catalog.json'};
}
export async function onRequest({request,env}){
 if(request.method!=='GET')return error(405,'method not allowed');
 const u=new URL(request.url);
 if(u.search.length>1200)return error(400,'query too long');
 if(request.headers.get('origin')&&request.headers.get('origin')!==u.origin)return error(403,'cross-origin denied');
 if(!await principal(request,env))return error(401,'sign-in required');
 const q=(u.searchParams.get('q')||'').trim().slice(0,120).toLowerCase();
 const n=Number(u.searchParams.get('offset')||0),sz=Number(u.searchParams.get('limit')||30);
 if(!Number.isSafeInteger(n)||n<0||n>100_000||!Number.isSafeInteger(sz)||sz<1||sz>50)return error(400,'invalid pagination');
 try{
  // Fixed hostname only; never an untrusted URL/crawler or client-supplied storage key.
  const r=await fetch(CATALOG,{headers:{'accept':'application/json'},redirect:'error',signal:AbortSignal.timeout(8000)});
  if(!r.ok||!(r.headers.get('content-type')||'').includes('application/json'))return error(502,'public archive unavailable');
  const text=await r.text();if(text.length>4_000_000)return error(502,'public archive too large');
  const rows=JSON.parse(text);if(!Array.isArray(rows)||rows.length>10_000)return error(502,'invalid catalog');
  const views=rows.map(view).filter(Boolean);
  const matches=q?views.filter(v=>(v.title+' '+v.category+' '+v.excerpt).toLowerCase().includes(q)):views;
  return json({items:matches.slice(n,n+sz),next_offset:n+sz<matches.length?n+sz:null,total:matches.length,source:'R2 public archive',archive_home:R2+'/'});
 }catch{return error(502,'public archive unavailable')}
}
