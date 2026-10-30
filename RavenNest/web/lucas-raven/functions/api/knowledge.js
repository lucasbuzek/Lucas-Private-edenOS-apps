// Extend the original RavenNest Pages project; no independent knowledge service.
// Source-first HTTPS library with existing Cloudflare Access identity and D1 grants.
import {verifyAccessJwt} from './[[path]].js';
const MAX_BODY=12_000;
const json=(value,status=200)=>new Response(JSON.stringify(value),{status,headers:{'content-type':'application/json; charset=utf-8','cache-control':'private, no-store','x-content-type-options':'nosniff','referrer-policy':'no-referrer','x-robots-tag':'noindex, nofollow'}});
const err=(status,message)=>json({error:message},status);
const TEXT=x=>typeof x==='string'?x.trim():'';
const number=(x,fallback,max)=>{const n=Number(x);return Number.isInteger(n)&&n>=0&&n<=max?n:fallback};
function verifiedUrl(text){
 if(typeof text!=='string'||text.length>2048)return null;
 let u;try{u=new URL(text)}catch{return null}
 if(u.protocol!=='https:'||!u.hostname||u.username||u.password||u.port||u.hash)return null;
 if(u.hostname.length>240||u.hostname==='localhost'||u.hostname.endsWith('.localhost')||u.hostname.endsWith('.local')||u.hostname.endsWith('.internal'))return null;
 if(/^\d+\.\d+\.\d+\.\d+$/.test(u.hostname)||u.hostname.includes(':'))return null; // never enqueue private or numeric hosts
 if(!u.hostname.includes('.'))return null;
 return u.href;
}
async function identity(request,env){
 if(!env.DB)return null;
 let claims;try{claims=await verifyAccessJwt(request.headers.get('cf-access-jwt-assertion'),env)}catch{return null}
 if(!Number.isFinite(claims.exp)||claims.exp<=Date.now()/1000)return null;
 const u=await env.DB.prepare('SELECT id,subject,email,disabled_at FROM users WHERE subject=?1 AND email=?2').bind(claims.sub,claims.email).first();
 return u&&!u.disabled_at?u:null;
}
const eligible="(s.owner_user_id=?1 OR (s.visibility='granted' AND EXISTS(SELECT 1 FROM raven_library_grants g WHERE g.source_id=s.id AND g.user_id=?1 AND g.can_read=1 AND g.revoked_at IS NULL)))";
const fields='s.id,s.source_title AS title,s.source_description AS description,s.source_url AS url,s.source_site AS site,s.taxonomy_namespace AS taxonomy_namespace,s.taxonomy_key AS taxonomy_key,s.source_kind AS kind,s.source_language AS language,s.provenance,s.review_status AS review_status,s.added_at AS added_at';
function safeItem(x){return {id:x.id,title:x.title,description:x.description,url:x.url,site:x.site,taxonomy_namespace:x.taxonomy_namespace,taxonomy_key:x.taxonomy_key,kind:x.kind,language:x.language,provenance:x.provenance,review_status:x.review_status,added_at:x.added_at}}
async function list(db,user,params){
 const q=TEXT(params.get('q')).slice(0,120),limit=number(params.get('limit'),30,50)||30,offset=number(params.get('offset'),0,100_000);
 const pat='%'+q.replace(/[\\%_]/g,'\\$&')+'%';
 const sql=`SELECT ${fields} FROM raven_library_sources s WHERE ${eligible} AND (s.source_title LIKE ?2 ESCAPE '\\' OR s.source_description LIKE ?2 ESCAPE '\\' OR s.source_site LIKE ?2 ESCAPE '\\' OR s.taxonomy_key LIKE ?2 ESCAPE '\\') ORDER BY s.added_at DESC,s.id DESC LIMIT ?3 OFFSET ?4`;
 const data=(await db.prepare(sql).bind(user.id,pat,limit+1,offset).all()).results||[];
 return {items:data.slice(0,limit).map(safeItem),next_offset:data.length>limit?offset+limit:null};
}
async function get(db,user,id){
 if(!/^[a-f0-9-]{36}$/.test(id||''))return null;
 const row=await db.prepare(`SELECT ${fields} FROM raven_library_sources s WHERE s.id=?2 AND ${eligible}`).bind(user.id,id).first();
 return row?safeItem(row):null;
}
async function add(db,user,request){
 if(!request.headers.get('origin')||request.headers.get('origin')!==new URL(request.url).origin)return err(403,'same-origin submission required');
 if(!(request.headers.get('content-type')||'').toLowerCase().startsWith('application/json'))return err(415,'JSON required');
 const size=Number(request.headers.get('content-length')||0);if(size>MAX_BODY)return err(413,'too large');
 let text=await request.text();if(text.length>MAX_BODY)return err(413,'too large');
 let b;try{b=JSON.parse(text)}catch{return err(400,'invalid JSON')}
 if(!b||typeof b!=='object'||Array.isArray(b))return err(400,'invalid resource');
 if(Object.keys(b).some(x=>!['url','title','description','kind','language','taxonomy_namespace','taxonomy_key'].includes(x)))return err(400,'unsupported field');
 const url=verifiedUrl(b.url),title=TEXT(b.title),description=TEXT(b.description),kind=TEXT(b.kind)||'website';
 if(!url||!title||title.length>160||description.length>1500||!['website','repository','documentation','dataset','zim','file-reference','other'].includes(kind))return err(400,'invalid source');
 const ns=TEXT(b.taxonomy_namespace)||'unclassified',key=TEXT(b.taxonomy_key),lang=TEXT(b.language);
 if(ns.length>80||key.length>160||lang.length>20||!/^[-a-zA-Z0-9_.:]*$/.test(ns)||!/^[-a-zA-Z0-9_.:]*$/.test(key))return err(400,'invalid classification');
 const now=Date.now(),id=crypto.randomUUID();
 // Private on creation and visible immediately to the submitting principal.
 // Does not fetch, copy, publicize or automatically grant another tenant access.
 await db.prepare(`INSERT INTO raven_library_sources (id,owner_user_id,tenant_key,source_url,source_title,source_description,source_site,taxonomy_namespace,taxonomy_key,source_kind,source_language,provenance,review_status,visibility,added_at,updated_at) VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,?12,'link-only','private',?13,?13)`).bind(id,user.id,user.id,url,title,description,new URL(url).hostname,ns,key,kind,lang,'user-supplied',now).run();
 return json({ok:true,id,visibility:'private',availability:'immediate-link',reading:'original-website'},201);
}
export async function onRequest({request,env}){
 if(!['GET','POST'].includes(request.method))return err(405,'method not allowed');
 const u=new URL(request.url);if(u.search.length>1000)return err(400,'query too long');
 if(request.method==='GET'&&request.headers.get('origin')&&request.headers.get('origin')!==u.origin)return err(403,'cross-origin request denied');
 if(!env.DB)return err(503,'library storage not configured');
 const principal=await identity(request,env);if(!principal)return err(401,'sign-in required');
 try{
  if(request.method==='POST')return await add(env.DB,principal,request);
  const action=u.searchParams.get('action')||'list';
  if(action==='list')return json(await list(env.DB,principal,u.searchParams));
  if(action==='get'){const row=await get(env.DB,principal,u.searchParams.get('id'));return row?json({item:row}):err(404,'not found')}
  return err(404,'unknown action');
 }catch{return err(503,'library unavailable')}
}
