// THEMIS owner-private web access variant. The original Python store remains authoritative for its local database.
// Owner Access JWT is mandatory; fail closed in the absence of configured Access credentials.
import { DurableObject } from 'cloudflare:workers';

const KINDS = ['matter','party','agreement','clause','obligation','jurisdiction','evidence','correspondence','research','deadline','version','approval'];
const json = (data,status=200) => new Response(JSON.stringify(data),{status,headers:{'content-type':'application/json; charset=utf-8','cache-control':'no-store','x-content-type-options':'nosniff'}});
const err = (reason,status=400) => json({error:reason},status);
const decode64 = t => Uint8Array.from(atob(t.replace(/-/g,'+').replace(/_/g,'/')+'='.repeat((4-t.length%4)%4)),c=>c.charCodeAt(0));
const b64json = x => JSON.parse(new TextDecoder().decode(decode64(x)));
const hex = bytes => Array.from(bytes,b=>b.toString(16).padStart(2,'0')).join('');
const sha256 = async text => hex(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(text))));
function escapeHTML(v){return String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));}
async function verifyOwner(req,env) {
  if (!env.ACCESS_AUD || !env.TEAM_DOMAIN || !env.OWNER_EMAIL) return false;
  const jwt=req.headers.get('Cf-Access-Jwt-Assertion');
  if(!jwt) return false;
  const parts=jwt.split('.');if(parts.length!==3)return false;
  try{
    const header=b64json(parts[0]), claims=b64json(parts[1]);
    if(header.alg!=='RS256'||typeof header.kid!=='string')return false;
    if(claims.iss!==`https://${env.TEAM_DOMAIN}`||Date.now()/1000>=Number(claims.exp)||Date.now()/1000<Number(claims.nbf||0))return false;
    const aud=Array.isArray(claims.aud)?claims.aud:[claims.aud];
    if(!aud.includes(env.ACCESS_AUD)||String(claims.email||'').toLowerCase()!==env.OWNER_EMAIL.toLowerCase())return false;
    const res=await fetch(`https://${env.TEAM_DOMAIN}/cdn-cgi/access/certs`);
    if(!res.ok)return false;
    const keys=(await res.json()).keys||[]; const jwk=keys.find(x=>x.kid===header.kid&&x.kty==='RSA');
    if(!jwk)return false;
    const key=await crypto.subtle.importKey('jwk',jwk,{name:'RSASSA-PKCS1-v1_5',hash:'SHA-256'},false,['verify']);
    return await crypto.subtle.verify('RSASSA-PKCS1-v1_5',key,decode64(parts[2]),new TextEncoder().encode(parts[0]+'.'+parts[1]));
  }catch{return false;}
}
function secure(response) {
  const h=new Headers(response.headers);
  h.set('x-frame-options','DENY');h.set('referrer-policy','no-referrer');h.set('x-content-type-options','nosniff');
  h.set('cache-control','no-store');h.set('content-security-policy',"default-src 'none'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; connect-src 'self'; base-uri 'none'; form-action 'self'; frame-ancestors 'none'");
  return new Response(response.body,{status:response.status,headers:h});
}
export class ThemisState extends DurableObject {
  constructor(ctx,env){
    super(ctx,env);this.sql=ctx.storage.sql;
    this.sql.exec('CREATE TABLE IF NOT EXISTS records(id TEXT PRIMARY KEY,kind TEXT NOT NULL,title TEXT NOT NULL,fields TEXT NOT NULL,provenance TEXT NOT NULL,created_at TEXT NOT NULL,updated_at TEXT NOT NULL)');
    this.sql.exec('CREATE INDEX IF NOT EXISTS records_kind ON records(kind)');
    this.sql.exec('CREATE TABLE IF NOT EXISTS events(id TEXT PRIMARY KEY,at TEXT NOT NULL,action TEXT NOT NULL,record_id TEXT,payload TEXT NOT NULL)');
    this.sql.exec('CREATE TABLE IF NOT EXISTS snapshots(id TEXT PRIMARY KEY,at TEXT NOT NULL,label TEXT NOT NULL,payload TEXT NOT NULL,sha256 TEXT NOT NULL,is_lkg INTEGER NOT NULL DEFAULT 0)');
  }
  rows(query,...params){return Array.from(this.sql.exec(query,...params));}
  toRecord(r){return {...r,fields:JSON.parse(r.fields),provenance:JSON.parse(r.provenance)};}
  log(action,id,extra={}){this.sql.exec('INSERT INTO events(id,at,action,record_id,payload) VALUES (?,?,?,?,?)',crypto.randomUUID(),new Date().toISOString(),action,id||null,JSON.stringify(extra));}
  async fetch(request){
    const url=new URL(request.url),path=url.pathname,method=request.method;
    if(method==='GET'&&path==='/api/health')return json({service:'THEMIS',mode:'owner-private',status:'ok',record_types:KINDS,storage:'sqlite-durable-object'});
    if(method==='GET'&&path==='/api/records'){
      const kind=url.searchParams.get('kind'),q=(url.searchParams.get('q')||'').slice(0,120);
      if(kind&&!KINDS.includes(kind))return err('Unsupported record type');
      let list=this.rows('SELECT * FROM records ORDER BY updated_at DESC LIMIT 501').map(r=>this.toRecord(r));
      if(kind)list=list.filter(x=>x.kind===kind);
      if(q)list=list.filter(x=>x.title.toLowerCase().includes(q.toLowerCase()));
      return json({records:list.slice(0,500),truncated:list.length>500});
    }
    if(method==='GET'&&/^\/api\/records\/[a-zA-Z0-9-]+$/.test(path)){
      const id=path.slice('/api/records/'.length),r=this.rows('SELECT * FROM records WHERE id=?',id)[0];
      return r?json(this.toRecord(r)):err('Record not found',404);
    }
    if(method==='GET'&&path==='/api/events')return json({events:this.rows('SELECT * FROM events ORDER BY at DESC LIMIT 250').map(x=>({...x,payload:JSON.parse(x.payload)}))});
    if(method==='GET'&&path==='/api/snapshots')return json({snapshots:this.rows('SELECT id,at,label,sha256,is_lkg FROM snapshots ORDER BY at DESC LIMIT 50')});
    if(!['POST','PATCH'].includes(method))return err('Not found',404);
    let body;
    try{if(Number(request.headers.get('content-length')||0)>131072)return err('Payload too large',413);const raw=await request.text();if(raw.length>131072)return err('Payload too large',413);body=JSON.parse(raw);if(!body||typeof body!=='object'||Array.isArray(body))throw new Error();}
    catch{return err('Expected JSON object');}
    if(method==='POST'&&path==='/api/records'){
      if(!KINDS.includes(body.kind)||typeof body.title!=='string'||!body.title.trim()||body.title.length>240)return err('Invalid record kind/title');
      if(body.fields!==undefined&&(!body.fields||typeof body.fields!=='object'||Array.isArray(body.fields)))return err('Invalid fields');
      if(body.provenance!==undefined&&(!body.provenance||typeof body.provenance!=='object'||Array.isArray(body.provenance)))return err('Invalid provenance');
      const id=crypto.randomUUID(),at=new Date().toISOString(),fields=body.fields||{},provenance=body.provenance||{};
      this.sql.exec('INSERT INTO records VALUES (?,?,?,?,?,?,?)',id,body.kind,body.title.trim(),JSON.stringify(fields),JSON.stringify(provenance),at,at);
      this.log('add',id,{kind:body.kind});
      return json({id,kind:body.kind,title:body.title.trim(),fields,provenance,created_at:at,updated_at:at},201);
    }
    if(method==='PATCH'&&/^\/api\/records\/[a-zA-Z0-9-]+$/.test(path)){
      const id=path.slice('/api/records/'.length),prior=this.rows('SELECT * FROM records WHERE id=?',id)[0];
      if(!prior)return err('Record not found',404);
      if(body.title!==undefined&&(typeof body.title!=='string'||!body.title.trim()||body.title.length>240))return err('Invalid title');
      if(body.fields!==undefined&&(!body.fields||typeof body.fields!=='object'||Array.isArray(body.fields)))return err('Invalid fields');
      const title=body.title===undefined?prior.title:body.title.trim(),fields={...JSON.parse(prior.fields),...(body.fields||{})};
      this.sql.exec('UPDATE records SET title=?,fields=?,updated_at=? WHERE id=?',title,JSON.stringify(fields),new Date().toISOString(),id);
      this.log('update',id,{previous:{title:prior.title,fields:JSON.parse(prior.fields)}});
      return json(this.toRecord(this.rows('SELECT * FROM records WHERE id=?',id)[0]));
    }
    if(method==='POST'&&path==='/api/snapshots'){
      const label=typeof body.label==='string'?body.label.slice(0,90):'snapshot';
      const records=this.rows('SELECT * FROM records ORDER BY id'),events=this.rows('SELECT * FROM events ORDER BY at,id');
      const payload=JSON.stringify({schema:1,records,events});if(payload.length>4000000)return err('Snapshot too large',413);
      const hash=await sha256(payload),id=crypto.randomUUID(),at=new Date().toISOString();
      if(body.set_lkg===true)this.sql.exec('UPDATE snapshots SET is_lkg=0 WHERE is_lkg=1');
      this.sql.exec('INSERT INTO snapshots VALUES (?,?,?,?,?,?)',id,at,label,payload,hash,body.set_lkg===true?1:0);
      this.log('snapshot',null,{id,label,sha256:hash,is_lkg:body.set_lkg===true});
      return json({id,at,label,sha256:hash,is_lkg:body.set_lkg===true},201);
    }
    if(method==='POST'&&path==='/api/rollback'){
      if(body.confirm!=='ROLLBACK_LKG')return err('Explicit rollback confirmation required',403);
      const snap=this.rows('SELECT * FROM snapshots WHERE is_lkg=1 LIMIT 1')[0];if(!snap)return err('No LKG snapshot',409);
      if(await sha256(snap.payload)!==snap.sha256)return err('Snapshot hash mismatch',409);
      const parsed=JSON.parse(snap.payload);if(parsed.schema!==1||!Array.isArray(parsed.records)||!Array.isArray(parsed.events))return err('Invalid snapshot',409);
      // Atomic rollback: failures must preserve the entire pre-rollback database.
      this.ctx.storage.transactionSync(()=>{
        this.sql.exec('DELETE FROM records');this.sql.exec('DELETE FROM events');
        for(const r of parsed.records)this.sql.exec('INSERT INTO records VALUES (?,?,?,?,?,?,?)',r.id,r.kind,r.title,r.fields,r.provenance,r.created_at,r.updated_at);
        for(const e of parsed.events)this.sql.exec('INSERT INTO events VALUES (?,?,?,?,?)',e.id,e.at,e.action,e.record_id,e.payload);
        this.log('rollback_lkg',null,{id:snap.id,sha256:snap.sha256});
      });
      return json({restored:true,snapshot_id:snap.id,record_count:parsed.records.length});
    }
    return err('Not found',404);
  }
}

const APP=`<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="robots" content="noindex,nofollow"><title>THEMIS · Legal Workbench</title><style>
:root{color-scheme:dark;font-family:-apple-system,BlinkMacSystemFont,Inter,Segoe UI,sans-serif;color:#f0f2f6;background:#101116}*{box-sizing:border-box}body{margin:0}header{position:sticky;top:0;background:#171922ee;backdrop-filter:blur(16px);border-bottom:1px solid #333642;padding:18px clamp(20px,5vw,80px);display:flex;justify-content:space-between;align-items:center}h1{font-size:21px;margin:0;letter-spacing:.1em}small{color:#8e97ac}main{max-width:1160px;margin:34px auto;padding:0 20px}nav{display:flex;gap:10px;flex-wrap:wrap;margin-bottom:22px}button,input,select,textarea{font:inherit;border-radius:9px;border:1px solid #454959;background:#242735;color:#f5f5f7;padding:10px 13px}button{cursor:pointer}button:hover{background:#313648}button.primary{background:#e1e5ef;color:#16171e;font-weight:650}button.danger{border-color:#9b6868}article{background:#1b1d27;border:1px solid #30333f;border-radius:16px;padding:24px;margin-bottom:18px}h2{font-size:17px;margin:0 0 16px}label{font-size:13px;color:#bdc3d1;display:block;margin-bottom:8px}input,select,textarea{width:100%;margin-top:6px}textarea{min-height:92px;resize:vertical}#list{display:grid;gap:8px}#list button{text-align:left;background:#222633}#list button.selected{border-color:#c7cbd8}#status{min-height:22px;color:#a9c5e9;margin:8px 0}.grid{display:grid;grid-template-columns:minmax(245px,1fr) minmax(320px,2fr);gap:18px}@media(max-width:800px){.grid{grid-template-columns:1fr}}.actions{display:flex;gap:8px;flex-wrap:wrap}code{color:#cbd4ea}footer{font-size:12px;color:#8c92a2;padding:15px 0 40px}</style>
<header><div><h1>THEMIS</h1><small>Legal workbench · Owner private</small></div><small>Records · Evidence · Documents</small></header><main>
<nav><button id="refresh">Refresh</button><button id="export">Export records (.json)</button><button id="snapshot">Set LKG snapshot</button><button id="events">Audit events</button><button id="rollback" class="danger">Rollback to LKG</button></nav>
<p id="status" role="status"></p><div class="grid"><article><h2>Legal records</h2><label>Filter<input id="search" placeholder="Search titles"></label><label>Record type<select id="filter"><option value="">All types</option></select></label><section id="list" aria-label="Records"></section></article>
<article><h2 id="formtitle">New record</h2><form id="editor"><label>Type<select id="kind"></select></label><label>Title<input id="title" maxlength="240" required placeholder="Matter, agreement, or evidence title"></label><label>Details (JSON object)<textarea id="fields" spellcheck="false">{}</textarea></label><label>Source and provenance (JSON object)<textarea id="provenance" spellcheck="false">{}</textarea></label><div class="actions"><button type="submit" class="primary">Save record</button><button type="button" id="new">New</button><button type="button" id="doc">Export editable document (.doc)</button></div></form></article></div><footer>THEMIS is a legal support application, not a substitute for professional legal review. Protected by account owner authentication. All substantive legal conclusions require traceable sources and verification.</footer></main>
<script>
const KINDS=${JSON.stringify(KINDS)};let selected=null,cache=[];
const el=id=>document.getElementById(id);const status=(s,bad=false)=>{el('status').textContent=s;el('status').style.color=bad?'#efaaa7':'#a9c5e9'};
function escapeText(s){return String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))}
for(const k of KINDS){for(const id of ['kind','filter']){const opt=document.createElement('option');opt.value=k;opt.textContent=k;el(id).append(opt)}}
async function api(path,options={}){const res=await fetch(path,{...options,headers:{'content-type':'application/json',...(options.headers||{})}});let v=await res.json().catch(()=>({error:'Unexpected server response'}));if(!res.ok)throw Error(v.error||'Request failed');return v}
async function load(){try{let v=await api('/api/records');cache=v.records;render();status('Loaded '+cache.length+' records')}catch(e){status(e.message,true)}}
function render(){const q=el('search').value.toLowerCase(),kind=el('filter').value;const area=el('list');area.replaceChildren();for(const r of cache.filter(r=>(!kind||r.kind===kind)&&r.title.toLowerCase().includes(q))){const b=document.createElement('button');b.type='button';b.className=r.id===selected?'selected':'';b.textContent=r.kind.toUpperCase()+' · '+r.title;b.onclick=()=>choose(r);area.append(b)}}
function choose(r){selected=r.id;el('formtitle').textContent='Edit '+r.kind;el('kind').value=r.kind;el('kind').disabled=true;el('title').value=r.title;el('fields').value=JSON.stringify(r.fields,null,2);el('provenance').value=JSON.stringify(r.provenance,null,2);render();status('Selected '+r.id)}
function newRecord(){selected=null;el('formtitle').textContent='New record';el('kind').disabled=false;el('kind').value='matter';el('title').value='';el('fields').value='{}';el('provenance').value='{}';render()}
el('editor').onsubmit=async e=>{e.preventDefault();try{const fields=JSON.parse(el('fields').value),provenance=JSON.parse(el('provenance').value),title=el('title').value.trim();if(!fields||Array.isArray(fields)||typeof fields!=='object'||!provenance||Array.isArray(provenance)||typeof provenance!=='object')throw Error('JSON fields must be objects');if(selected){await api('/api/records/'+selected,{method:'PATCH',body:JSON.stringify({title,fields})})}else{await api('/api/records',{method:'POST',body:JSON.stringify({kind:el('kind').value,title,fields,provenance})})}newRecord();await load()}catch(e){status(e.message,true)}};
el('refresh').onclick=load;el('new').onclick=newRecord;el('search').oninput=render;el('filter').onchange=render;
function download(name,body,type){const a=document.createElement('a'),url=URL.createObjectURL(new Blob([body],{type}));a.href=url;a.download=name;a.click();setTimeout(()=>URL.revokeObjectURL(url),500)}
el('export').onclick=()=>download('THEMIS_records.json',JSON.stringify({records:cache,exported_at:new Date().toISOString()},null,2),'application/json');
el('doc').onclick=()=>{const fields=el('fields').value;let body;try{body=JSON.stringify(JSON.parse(fields),null,2)}catch(e){status('Invalid JSON',true);return}const text='<html><head><meta charset="UTF-8"></head><body><h1>'+escapeText(el('title').value)+'</h1><p>THEMIS | Controlled draft | Not legal advice</p><h2>Record details</h2><pre>'+escapeText(body)+'</pre><h2>Source and provenance</h2><pre>'+escapeText(el('provenance').value)+'</pre></body></html>';download('THEMIS_document.doc',text,'application/msword');status('Editable draft exported. Review before use.')};
el('snapshot').onclick=async()=>{if(!confirm('Create and mark a new last-known-good snapshot of current records?'))return;try{const s=await api('/api/snapshots',{method:'POST',body:JSON.stringify({label:'owner-approved',set_lkg:true})});status('LKG snapshot '+s.id+' created')}catch(e){status(e.message,true)}};
el('events').onclick=async()=>{try{const r=await api('/api/events');download('THEMIS_events.json',JSON.stringify(r,null,2),'application/json');status('Audit events exported')}catch(e){status(e.message,true)}};
el('rollback').onclick=async()=>{if(prompt('This restores the last approved LKG and discards later changes. Type ROLLBACK_LKG to proceed:')!=='ROLLBACK_LKG')return;try{const r=await api('/api/rollback',{method:'POST',body:JSON.stringify({confirm:'ROLLBACK_LKG'})});newRecord();await load();status('Restored '+r.record_count+' records from '+r.snapshot_id)}catch(e){status(e.message,true)}};
load();
</script></html>`;

export default {
  async fetch(request,env){
    const url=new URL(request.url);
    if(!await verifyOwner(request,env))return secure(err('Owner authentication required',401));
    if(request.method==='GET'&&(url.pathname==='/'||url.pathname==='/app'))return secure(new Response(APP,{headers:{'content-type':'text/html; charset=utf-8'}}));
    if(!env.THEMIS_STATE)return secure(err('Backend binding unavailable',503));
    const obj=env.THEMIS_STATE.get(env.THEMIS_STATE.idFromName('themis-owner'));
    return secure(await obj.fetch(request));
  }
};
