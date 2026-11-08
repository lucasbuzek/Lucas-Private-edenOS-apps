
import { DurableObject } from "cloudflare:workers";
import UI from "./ui.js";
const KINDS = ["matter","party","agreement","clause","obligation","jurisdiction","evidence","correspondence","research","deadline","version","approval"];
const DEPARTMENTS = ["Contracts & Commercial","Corporate","Regulatory & Compliance","Employment","Intellectual Property & Technology","Disputes","Legal Research","Documents & Evidence"];
function send(v, status=200, headers={}) {
  return new Response(JSON.stringify(v), {status, headers:{"Content-Type":"application/json;charset=utf-8","Cache-Control":"no-store","X-Content-Type-Options":"nosniff",...headers}});
}
function error(m,status=400){return send({error:m},status);}
function record(row){
  if(!row)return null;
  return {id:row.id,kind:row.kind,title:row.title,fields:JSON.parse(row.fields),provenance:JSON.parse(row.provenance),revision:row.revision,created_at:row.created_at,updated_at:row.updated_at};
}
function validate(input,create=true){
  if(!input || typeof input!=="object" || Array.isArray(input))throw Error("Invalid input");
  if(create && !KINDS.includes(input.kind))throw Error("Invalid record kind");
  if((create || "title" in input) && (typeof input.title!=="string" || !input.title.trim() || input.title.length>240))throw Error("Title required (max 240 characters)");
  for(const field of ["fields","provenance"])if(field in input && (!input[field] || typeof input[field]!=="object" || Array.isArray(input[field])))throw Error("Invalid "+field);
  if(JSON.stringify(input).length>65536)throw Error("Record exceeds 64 KiB");
}
async function hash(text){const b=new TextEncoder().encode(text);const h=await crypto.subtle.digest("SHA-256",b);return Array.from(new Uint8Array(h)).map(x=>x.toString(16).padStart(2,"0")).join("");}
function equal(a,b){if(typeof a!=="string"||typeof b!=="string"||a.length!==b.length)return false;let d=0;for(let i=0;i<a.length;i++)d|=a.charCodeAt(i)^b.charCodeAt(i);return d===0;}
async function sig(data,secret){const key=await crypto.subtle.importKey("raw",new TextEncoder().encode(secret),{name:"HMAC",hash:"SHA-256"},false,["sign"]);const bits=await crypto.subtle.sign("HMAC",key,new TextEncoder().encode(data));return Array.from(new Uint8Array(bits)).map(x=>x.toString(16).padStart(2,"0")).join("");}
let accessKeys=null,accessKeyTime=0;
async function accessOwner(req,env){
 if(!env.ACCESS_AUD||!env.TEAM_DOMAIN||!env.OWNER_EMAIL)return false;
 const jwt=req.headers.get("Cf-Access-Jwt-Assertion");
 if(!jwt)return false;
 try{
   const parts=jwt.split(".");
   if(parts.length!==3)return false;
   const dec=s=>Uint8Array.from(atob(s.replace(/-/g,"+").replace(/_/g,"/")+"=".repeat((4-s.length%4)%4)),c=>c.charCodeAt(0));
   const header=JSON.parse(new TextDecoder().decode(dec(parts[0])));
   const claims=JSON.parse(new TextDecoder().decode(dec(parts[1])));
   if(header.alg!=="RS256"||!header.kid)return false;
   const aud=Array.isArray(claims.aud)?claims.aud:[claims.aud];
   const now=Date.now()/1000;
   if(!aud.includes(env.ACCESS_AUD)||claims.iss!=="https://"+env.TEAM_DOMAIN||Number(claims.exp)<=now||Number(claims.nbf||0)>now)return false;
   if(String(claims.email||"").toLowerCase()!==env.OWNER_EMAIL.toLowerCase())return false;
   if(!accessKeys||Date.now()-accessKeyTime>300000){
     const res=await fetch("https://"+env.TEAM_DOMAIN+"/cdn-cgi/access/certs",{redirect:"error"});
     if(!res.ok)return false;
     accessKeys=(await res.json()).keys||[];accessKeyTime=Date.now();
   }
   const jwk=accessKeys.find(k=>k.kid===header.kid&&k.kty==="RSA");
   if(!jwk)return false;
   const key=await crypto.subtle.importKey("jwk",jwk,{name:"RSASSA-PKCS1-v1_5",hash:"SHA-256"},false,["verify"]);
   return await crypto.subtle.verify("RSASSA-PKCS1-v1_5",key,dec(parts[2]),new TextEncoder().encode(parts[0]+"."+parts[1]));
 }catch{return false}
}
async function logged(req,env) {
 if(await accessOwner(req,env))return true;
 if(!env.OWNER_HASH)return false;
 const bearer=req.headers.get("Authorization")?.match(/^Bearer (.+)$/i)?.[1];
 if(bearer && equal(await hash(bearer),env.OWNER_HASH))return true;
 const cookie=(req.headers.get("Cookie")||"").split(";").map(x=>x.trim()).find(x=>x.startsWith("themis_session="))?.slice(15);
 if(!cookie)return false;
 const m=/^(\d+)\.([a-f0-9]{64})$/.exec(cookie);
 if(!m||Number(m[1])<Date.now()||Number(m[1])>Date.now()+43210000)return false;
 return equal(await sig(m[1],env.OWNER_HASH),m[2]);
}
function headersForHtml(nonce){return {"Content-Type":"text/html;charset=utf-8","Cache-Control":"no-store","Referrer-Policy":"no-referrer","X-Frame-Options":"DENY","X-Content-Type-Options":"nosniff","Content-Security-Policy":"default-src 'none'; script-src 'nonce-"+nonce+"'; style-src 'unsafe-inline'; connect-src 'self'; img-src 'self' data:; form-action 'self'; base-uri 'none'; frame-ancestors 'none'"};}
export class ThemisVault extends DurableObject {
 constructor(ctx,env){
  super(ctx,env);
  this.sql=ctx.storage.sql;
  this.sql.exec("CREATE TABLE IF NOT EXISTS records (id TEXT PRIMARY KEY, kind TEXT NOT NULL, title TEXT NOT NULL, fields TEXT NOT NULL, provenance TEXT NOT NULL, revision INTEGER NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)");
  this.sql.exec("CREATE INDEX IF NOT EXISTS idx_themis_kind ON records(kind)");
  this.sql.exec("CREATE TABLE IF NOT EXISTS events (seq INTEGER PRIMARY KEY AUTOINCREMENT,at TEXT NOT NULL,action TEXT NOT NULL,record_id TEXT,payload TEXT NOT NULL)");
  this.sql.exec("CREATE TABLE IF NOT EXISTS snapshots (id TEXT PRIMARY KEY,created_at TEXT NOT NULL,label TEXT NOT NULL,sha256 TEXT NOT NULL,payload TEXT NOT NULL,is_lkg INTEGER NOT NULL)");
 }
 audit(action,id,payload){this.sql.exec("INSERT INTO events(at,action,record_id,payload) VALUES(?,?,?,?)",new Date().toISOString(),action,id||null,JSON.stringify(payload||{}));}
 async execute(operation,input={}){
  const sql=this.sql;
  if(operation==="list"){const kind=input.kind;
    if(kind && !KINDS.includes(kind))throw Error("Invalid kind");
    const rows=kind?sql.exec("SELECT * FROM records WHERE kind=? ORDER BY updated_at DESC LIMIT 500",kind).toArray():sql.exec("SELECT * FROM records ORDER BY updated_at DESC LIMIT 500").toArray();
    return {records:rows.map(record)};
  }
  if(operation==="get"){return {record:record(sql.exec("SELECT * FROM records WHERE id=?",input.id||"").toArray()[0])};}
  if(operation==="create"){
    validate(input,true);const id=crypto.randomUUID(),at=new Date().toISOString();
    const fields=JSON.stringify(input.fields||{}), provenance=JSON.stringify(input.provenance||{});
    this.ctx.storage.transactionSync(()=>{sql.exec("INSERT INTO records VALUES(?,?,?,?,?,?,?,?)",id,input.kind,input.title.trim(),fields,provenance,1,at,at);this.audit("create",id,{kind:input.kind});});
    return {record:record(sql.exec("SELECT * FROM records WHERE id=?",id).toArray()[0])};
  }
  if(operation==="update"){
    validate(input,false);const old=sql.exec("SELECT * FROM records WHERE id=?",input.id||"").toArray()[0];
    if(!old)throw Error("Record not found");
    if(input.expected_revision!==old.revision)throw Error("Revision conflict; reload before updating");
    const title=typeof input.title==="string"?input.title.trim():old.title;
    const fields=input.fields?{...JSON.parse(old.fields),...input.fields}:JSON.parse(old.fields);
    this.ctx.storage.transactionSync(()=>{sql.exec("UPDATE records SET title=?,fields=?,revision=revision+1,updated_at=? WHERE id=?",title,JSON.stringify(fields),new Date().toISOString(),old.id);this.audit("update",old.id,{from_revision:old.revision,to_revision:old.revision+1});});
    return {record:record(sql.exec("SELECT * FROM records WHERE id=?",old.id).toArray()[0])};
  }
  if(operation==="events")return {events:sql.exec("SELECT * FROM events ORDER BY seq DESC LIMIT 200").toArray().map(x=>({...x,payload:JSON.parse(x.payload)}))};
  if(operation==="snapshots")return {snapshots:sql.exec("SELECT id,label,sha256,is_lkg,created_at FROM snapshots ORDER BY created_at DESC LIMIT 100").toArray()};
  if(operation==="snapshot"){
    const rows=sql.exec("SELECT * FROM records ORDER BY id").toArray();
    const payload=JSON.stringify(rows);
    if(payload.length>3000000)throw Error("Snapshot exceeds 3 MB; use export");
    const sha256=await hash(payload),id=crypto.randomUUID(),label=String(input.label||"checkpoint").slice(0,100),at=new Date().toISOString();
    this.ctx.storage.transactionSync(()=>{if(input.set_lkg)sql.exec("UPDATE snapshots SET is_lkg=0 WHERE is_lkg=1");sql.exec("INSERT INTO snapshots VALUES(?,?,?,?,?,?)",id,at,label,sha256,payload,input.set_lkg?1:0);this.audit("snapshot",null,{id,sha256,lkg:!!input.set_lkg,count:rows.length});});
    return {snapshot:{id,sha256,label,created_at:at,count:rows.length,is_lkg:!!input.set_lkg}};
  }
  if(operation==="rollback"){
    if(input.confirm!=="RESTORE")throw Error("Explicit RESTORE confirmation required");
    const row=sql.exec("SELECT * FROM snapshots WHERE id=?",input.id||"").toArray()[0];
    if(!row)throw Error("Snapshot not found");
    if(!equal(await hash(row.payload),row.sha256))throw Error("Snapshot integrity mismatch");
    const records=JSON.parse(row.payload);
    this.ctx.storage.transactionSync(()=>{
      sql.exec("DELETE FROM records");
      for(const r of records)sql.exec("INSERT INTO records VALUES(?,?,?,?,?,?,?,?)",r.id,r.kind,r.title,r.fields,r.provenance,r.revision,r.created_at,r.updated_at);
      this.audit("rollback",null,{snapshot_id:row.id,count:records.length,sha256:row.sha256});
    });
    return {restored:true,count:records.length,snapshot_id:row.id};
  }
  if(operation==="export"){return {schema:"THEMIS-Cloud-1",exported_at:new Date().toISOString(),records:sql.exec("SELECT * FROM records ORDER BY id").toArray().map(record),events:sql.exec("SELECT * FROM events ORDER BY seq").toArray()}};
  throw Error("Unknown operation");
 }
}
function doc(recordData){
 const esc=x=>String(x??"").replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
 const rec=recordData;
 const fields=Object.entries(rec.fields).map(([k,v])=>"<tr><th>"+esc(k)+"</th><td>"+esc(typeof v==="object"?JSON.stringify(v):v)+"</td></tr>").join("");
 return '<!DOCTYPE html><html><head><meta charset="utf-8"><style>body{font-family:Calibri,Arial;margin:55px;line-height:1.5}h1{color:#132f4d}table{border-collapse:collapse;width:100%}th,td{border:1px solid #bbb;padding:8px;text-align:left}</style></head><body><h1>THEMIS | '+esc(rec.title)+'</h1><p><strong>Type:</strong> '+esc(rec.kind)+' &nbsp; <strong>Revision:</strong> '+esc(rec.revision)+'</p><p>Controlled working draft. Verify all facts, law, effective dates and approvals before reliance.</p><h2>Record details</h2><table>'+fields+'</table><h2>Provenance</h2><pre>'+esc(JSON.stringify(rec.provenance,null,2))+'</pre><p>Record ID: '+esc(rec.id)+'</p></body></html>';
}
const TOOLS=[
{name:"themis_list_records",description:"List authorised THEMIS legal records, optionally filtered by one of the 12 kinds.",inputSchema:{type:"object",properties:{kind:{type:"string",enum:KINDS}}}},
{name:"themis_get_record",description:"Get a legal record by ID including provenance and revision.",inputSchema:{type:"object",properties:{id:{type:"string"}},required:["id"]}},
{name:"themis_create_record",description:"Create a source-grounded legal record in the owner's THEMIS vault.",inputSchema:{type:"object",properties:{kind:{type:"string",enum:KINDS},title:{type:"string"},fields:{type:"object"},provenance:{type:"object"}},required:["kind","title"]}},
{name:"themis_update_record",description:"Revision-checked record update. Requires expected_revision to prevent overwrites.",inputSchema:{type:"object",properties:{id:{type:"string"},expected_revision:{type:"integer"},title:{type:"string"},fields:{type:"object"}},required:["id","expected_revision"]}},
{name:"themis_list_snapshots",description:"List recorded backups and known-good markers.",inputSchema:{type:"object",properties:{}}},
{name:"themis_create_snapshot",description:"Create a checksum-protected snapshot. Set set_lkg to mark as last-known-good.",inputSchema:{type:"object",properties:{label:{type:"string"},set_lkg:{type:"boolean"}}}}
];
async function mcp(body,env){
 if(body.method==="initialize")return {protocolVersion:"2025-06-18",capabilities:{tools:{listChanged:false}},serverInfo:{name:"THEMIS",version:"0.2.0"}};
 if(body.method==="ping")return {};
 if(body.method==="tools/list")return {tools:TOOLS};
 if(body.method==="tools/call"){
  const name=body.params?.name,a=body.params?.arguments||{};
  const ops={themis_list_records:"list",themis_get_record:"get",themis_create_record:"create",themis_update_record:"update",themis_list_snapshots:"snapshots",themis_create_snapshot:"snapshot"};
  if(!ops[name])throw Error("Unknown tool");
  const result=await env.THEMIS_VAULT.getByName("owner").execute(ops[name],a);
  return {content:[{type:"text",text:JSON.stringify(result)}],structuredContent:result};
 }
 throw Error("Unsupported method");
}
export default {
 async fetch(req,env){
  const url=new URL(req.url),p=url.pathname,method=req.method;
  if(method==="GET" && p==="/api/health")return send({service:"THEMIS",identity:"one-product",ready:!!env.OWNER_HASH||!!(env.ACCESS_AUD&&env.TEAM_DOMAIN&&env.OWNER_EMAIL),storage:"SQLite Durable Object",version:"0.2.0"});
  if(method==="GET" && p==="/"){
   const nonce=crypto.randomUUID().replace(/-/g,"");
   return new Response(UI.replace("THEMIS_NONCE",nonce),{headers:headersForHtml(nonce)});
  }
  if(!env.OWNER_HASH && !(env.ACCESS_AUD && env.TEAM_DOMAIN && env.OWNER_EMAIL))return error("Owner authentication not configured",503);
  if(method==="POST" && p==="/auth/login"){
   if(req.headers.get("Origin")!==url.origin)return error("Origin mismatch",403);
   if(!req.headers.get("Content-Type")?.startsWith("application/json"))return error("JSON required",415);
   let body;try{body=await req.json()}catch{return error("Invalid login",400)}
   if(typeof body?.password!=="string"||body.password.length>512||!equal(await hash(body.password),env.OWNER_HASH))return error("Invalid credentials",401);
   const expiry=String(Date.now()+12*60*60*1000),signature=await sig(expiry,env.OWNER_HASH);
   return send({authenticated:true,role:"owner"},200,{"Set-Cookie":"themis_session="+expiry+"."+signature+"; Max-Age=43200; HttpOnly; Secure; SameSite=Strict; Path=/"});
  }
  if(method==="POST" && p==="/auth/logout")return send({authenticated:false},200,{"Set-Cookie":"themis_session=; Max-Age=0; HttpOnly; Secure; SameSite=Strict; Path=/"});
  if(!(await logged(req,env)))return send({error:"Authentication required"},401,{"WWW-Authenticate":'Bearer realm="THEMIS"'});
  if(method==="GET" && p==="/auth/me")return send({authenticated:true,role:"owner"});
  if(p==="/mcp"){
   if(method==="GET")return error("Streamable HTTP POST is supported; SSE GET is not",405);
   if(method!=="POST")return error("Method not allowed",405);
   let body;try{body=await req.json()}catch{return error("Invalid JSON-RPC",400)}
   if(!body.id && body.method?.startsWith("notifications/"))return new Response(null,{status:202});
   if(body.jsonrpc!=="2.0"||body.id===undefined)return error("JSON-RPC 2.0 required");
   try{return send({jsonrpc:"2.0",id:body.id,result:await mcp(body,env)},200,{"MCP-Protocol-Version":"2025-06-18"})}
   catch(e){return send({jsonrpc:"2.0",id:body.id,error:{code:-32603,message:e.message}},200)}
  }
  if(!p.startsWith("/api/"))return error("Not found",404);
  if(["POST","PUT","PATCH","DELETE"].includes(method)){
    if(req.headers.get("Origin")!==url.origin && !req.headers.has("Authorization"))return error("Origin mismatch",403);
    if(!req.headers.get("Content-Type")?.startsWith("application/json"))return error("JSON required",415);
  }
  const segments=p.split("/").filter(Boolean);
  const op=async(operation,args)=>{try{return send(await env.THEMIS_VAULT.getByName("owner").execute(operation,args))}catch(e){return error(e.message,e.message.includes("not found")?404:e.message.includes("conflict")?409:400)}};
  if(p==="/api/records" && method==="GET")return op("list",{kind:url.searchParams.get("kind")||undefined});
  if(p==="/api/records" && method==="POST"){let b;try{b=await req.json()}catch{return error("Invalid JSON")};try{const r=await env.THEMIS_VAULT.getByName("owner").execute("create",b);return send(r,201)}catch(e){return error(e.message)}}
  if(segments[1]==="records"&&segments.length===3&&method==="GET")return op("get",{id:segments[2]});
  if(segments[1]==="records"&&segments.length===3&&(method==="PUT"||method==="PATCH")){let b;try{b=await req.json()}catch{return error("Invalid JSON")};return op("update",{...b,id:segments[2]})}
  if(segments[1]==="records"&&segments.length===4&&segments[3]==="document"&&method==="GET"){
   const result=await env.THEMIS_VAULT.getByName("owner").execute("get",{id:segments[2]});
   if(!result.record)return error("Record not found",404);
   return new Response(doc(result.record),{headers:{"Content-Type":"application/msword;charset=utf-8","Content-Disposition":'attachment; filename="THEMIS-record.doc"',"Cache-Control":"no-store","X-Content-Type-Options":"nosniff"}});
  }
  if(p==="/api/events"&&method==="GET")return op("events",{});
  if(p==="/api/snapshots"&&method==="GET")return op("snapshots",{});
  if(p==="/api/snapshots"&&method==="POST"){let b;try{b=await req.json()}catch{return error("Invalid JSON")};return op("snapshot",b)}
  if(p==="/api/rollback"&&method==="POST"){let b;try{b=await req.json()}catch{return error("Invalid JSON")};return op("rollback",b)}
  if(p==="/api/export"&&method==="GET")return op("export",{});
  return error("Not found",404);
 }
};