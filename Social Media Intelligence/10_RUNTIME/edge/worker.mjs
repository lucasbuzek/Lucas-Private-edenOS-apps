/* FAMA owner preview Cloudflare adapter.
 * Deliberately distinct transport from the original Python/macOS runtime.
 * Same original data/approval contract. No paid providers or social posting.
 * Bundle this module with the original web assets via edge/bundle.mjs.
 */
const HTML = "__FAMA_HTML__";
const JAVASCRIPT = "__FAMA_JS__";
const CSS = "__FAMA_CSS__";
const MAX_BODY = 8192;
const QUEUE_OPS = new Set(["list", "show", "create", "edit", "ready", "approve", "schedule-proposal", "verify"]);
const STATES = new Set(["DRAFT", "NEEDS_RESEARCH", "READY_FOR_REVIEW", "APPROVED", "SCHEDULE_PREPARED", "REJECTED", "EXPIRED", "WITHDRAWN"]);
const HEADERS = {
  "Cache-Control":"no-store", "Referrer-Policy":"no-referrer",
  "X-Content-Type-Options":"nosniff", "X-Frame-Options":"DENY",
  "Content-Security-Policy":"default-src 'none'; script-src 'self'; style-src 'self'; connect-src 'self'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'"
};
function respond(value, status=200, additional={}) {
  return new Response(JSON.stringify(value), {status,headers:{"Content-Type":"application/json; charset=utf-8",...HEADERS,...additional}});
}
function replyError(status, text){return respond({error:text},status);}
function check(condition, message){if(!condition)throw new Error(message);}
function textValue(v, name, max, required=true){
  check(typeof v==="string"&&v.length<=max&&(!required||Boolean(v.trim())),name+" must be text of at most "+max+" characters");
  return v.trim();
}
function exactKeys(o, keys){
  check(o&&typeof o==="object"&&!Array.isArray(o),"Expected object");
  for(const k of Object.keys(o))check(keys.includes(k),"Unsupported field: "+k);
}
function validPublicUrl(url){
  try{
    const u=new URL(url);
    if(!["http:","https:"].includes(u.protocol)||u.username||u.password||url.length>500)return false;
    const h=u.hostname.toLowerCase();
    if(!h.includes(".")||h==="localhost"||h.endsWith(".local")||/^(127\.|10\.|192\.168\.|0\.|169\.254\.)/.test(h))return false;
    if(/^\d+\.\d+\.\d+\.\d+$/.test(h))return false;
    if(h.startsWith("[")||h.includes(":"))return false; // fail closed for literal IPv6
    return true;
  }catch{return false;}
}
function sourceURLs(arr){
  check(Array.isArray(arr)&&arr.length>=1&&arr.length<=8,"1..8 public URLs required");
  return arr.map(v=>{check(typeof v==="string"&&validPublicUrl(v),"Invalid public source URL");return v;});
}
function future(value,label){
  const input=textValue(value,label,40);
  check(/(Z|[+-]\d\d:\d\d)$/.test(input),label+" requires explicit timezone");
  const t=Date.parse(input);
  check(Number.isFinite(t)&&t>Date.now(),label+" must be a future timestamp");
  return new Date(t).toISOString();
}
function idValue(v){
  const id=textValue(v,"post_id",80);
  check(/^[a-zA-Z0-9_-]+$/.test(id),"Invalid post_id");
  return id;
}
function canonical(value){
  if(Array.isArray(value))return "["+value.map(canonical).join(",")+"]";
  if(value&&typeof value==="object")return "{"+Object.keys(value).sort().map(k=>JSON.stringify(k)+":"+canonical(value[k])).join(",")+"}";
  return JSON.stringify(value);
}
async function sha256(obj){
  const bin=await crypto.subtle.digest("SHA-256",new TextEncoder().encode(canonical(obj)));
  return Array.from(new Uint8Array(bin),b=>b.toString(16).padStart(2,"0")).join("");
}
function contentPayload(p){
  const out={};for(const [k,v] of Object.entries(p)){
    if(!["content_hash","approval","state","created_at","updated_at","history"].includes(k))out[k]=v;
  }return out;
}
async function validOwner(request,env){
  const expected=env.FAMA_OWNER_TOKEN;
  const value=request.headers.get("Authorization")||"";
  if(typeof expected!=="string"||expected.length<40||!value.startsWith("Bearer ")||value.length!==expected.length+7)return false;
  const a=await crypto.subtle.digest("SHA-256",new TextEncoder().encode(value.slice(7)));
  const b=await crypto.subtle.digest("SHA-256",new TextEncoder().encode(expected));
  const aa=new Uint8Array(a), bb=new Uint8Array(b);
  let diff=0;for(let i=0;i<aa.length;i++)diff|=aa[i]^bb[i];
  return diff===0;
}
function checkOrigin(request){
  const origin=request.headers.get("Origin");
  return !origin||origin===new URL(request.url).origin;
}
async function parseInput(request){
  const size=request.headers.get("Content-Length");
  if(size&&(!/^\d+$/.test(size)||Number(size)>MAX_BODY))throw Error("Body size exceeds limit");
  const b=await request.arrayBuffer();
  check(b.byteLength>0&&b.byteLength<=MAX_BODY,"Body size exceeds limit");
  let value;try{value=JSON.parse(new TextDecoder("utf-8",{fatal:true}).decode(b));}catch{throw Error("Invalid JSON");}
  check(value&&typeof value==="object"&&!Array.isArray(value),"Expected JSON object");
  return value;
}
function validateResearch(data) {
  exactKeys(data,["query","hours","limit"]);
  const q=textValue(data.query,"query",120);
  check(q.length>=2,"Query must contain at least 2 characters");
  const hours=data.hours===undefined?72:data.hours,limit=data.limit===undefined?5:data.limit;
  check(Number.isInteger(hours)&&hours>=1&&hours<=168,"hours outside 1..168");
  check(Number.isInteger(limit)&&limit>=1&&limit<=5,"limit outside 1..5");
  return {q,hours,limit};
}
async function research(data){
  const {q,hours,limit}=validateResearch(data);
  const fmt=t=>new Date(t).toISOString().replace(/[-:TZ.]/g,"").slice(0,14);
  const url=new URL("https://api.gdeltproject.org/api/v2/doc/doc");
  url.search=new URLSearchParams({query:q,mode:"ArtList",format:"json",maxrecords:String(limit),
    sort:"DateDesc",startdatetime:fmt(Date.now()-hours*3600000),enddatetime:fmt(Date.now())}).toString();
  const ctl=new AbortController();const abort=setTimeout(()=>ctl.abort(),8000);
  try{
    const response=await fetch(url,{signal:ctl.signal,headers:{"Accept":"application/json"}});
    if(!response.ok)throw Error("GDELT HTTP "+response.status);
    const raw=await response.text();
    if(raw.length>500000)throw Error("GDELT response too large");
    const parsed=JSON.parse(raw);
    const leads=[];const seen=new Set();
    for(const item of parsed.articles||[]){
      if(!validPublicUrl(item.url)||seen.has(item.url))continue;
      seen.add(item.url);
      leads.push({title:String(item.title||"Untitled lead").slice(0,250),url:item.url,
        published_at:item.seendate||null,discovery_source:"GDELT_DOC",
        snippet:"",capture_status:"LEAD_ONLY",claim_verification_status:"NOT_VERIFIED",
        source_metadata:{domain:String(item.domain||"").slice(0,150),
          language:String(item.language||"").slice(0,60)}});
      if(leads.length>=limit)break;
    }
    return {run_status:leads.length?"RESULTS_FOUND":"NO_RESULTS",candidates:leads,
      sources_attempted:["GDELT_DOC"],external_social_action:"NOT_PERFORMED"};
  }catch(err){
    return {run_status:"PROVIDER_UNAVAILABLE",candidates:[],sources_attempted:["GDELT_DOC"],
      provider_error:String(err.message||"upstream unavailable").slice(0,140),
      external_social_action:"NOT_PERFORMED"};
  }finally{clearTimeout(abort);}
}
export class FamaStore{
  constructor(state){
    this.state=state;this.sql=state.storage.sql;
    this.state.blockConcurrencyWhile(async()=>{
      this.sql.exec("CREATE TABLE IF NOT EXISTS posts (id TEXT PRIMARY KEY, payload TEXT NOT NULL, updated TEXT NOT NULL)");
      this.sql.exec("CREATE TABLE IF NOT EXISTS audit (at TEXT NOT NULL, operation TEXT NOT NULL, id TEXT NOT NULL, digest TEXT NOT NULL)");
      this.sql.exec("CREATE TABLE IF NOT EXISTS rates (window TEXT PRIMARY KEY, count INTEGER NOT NULL)");
    });
  }
  read(id){
    const row=this.sql.exec("SELECT payload FROM posts WHERE id=?",id).toArray()[0];
    if(!row)throw Error("Unknown post_id");
    return {post:JSON.parse(row.payload),raw:row.payload};
  }
  write(p,old=null){
    const raw=JSON.stringify(p),updated=new Date().toISOString();
    if(old===null){
      this.sql.exec("INSERT INTO posts (id,payload,updated) VALUES (?,?,?)",p.post_id,raw,updated);
    }else{
      this.sql.exec("UPDATE posts SET payload=?,updated=? WHERE id=? AND payload=?",raw,updated,p.post_id,old);
      const n=this.sql.exec("SELECT changes() AS count").one().count;
      check(n===1,"Concurrent draft change: reload current version");
    }
    return p;
  }
  audit(op,p){
    this.sql.exec("INSERT INTO audit (at,operation,id,digest) VALUES (?,?,?,?)",
      new Date().toISOString(),op,p.post_id,p.content_hash||"");
  }
  async queue(data){
    const op=data.operation;check(QUEUE_OPS.has(op),"Unsupported queue operation");
    if(op==="list"){
      exactKeys(data,["operation","state"]);
      if(data.state!==undefined)check(STATES.has(data.state),"Unknown state");
      const rows=this.sql.exec("SELECT payload FROM posts ORDER BY updated DESC LIMIT 200").toArray();
      const posts=rows.map(row=>JSON.parse(row.payload))
        .filter(p=>!data.state||p.state===data.state)
        .map(p=>({post_id:p.post_id,persona_id:p.persona_id,platform:p.platform,
          account_id:p.account_id,state:p.state,proposed_publish_at:p.proposed_publish_at,
          content_hash:p.content_hash}));
      return posts;
    }
    const id=idValue(data.post_id);
    if(op==="create"){
      exactKeys(data,["operation","post_id","persona_id","platform","account_id","audience","text","source_urls","proposed_publish_at"]);
      const now=new Date().toISOString();
      const p={post_id:id,persona_id:textValue(data.persona_id,"persona_id",80),
        platform:textValue(data.platform,"platform",40),account_id:textValue(data.account_id,"account_id",100),
        audience:textValue(data.audience,"audience",200),text:textValue(data.text,"text",1800),
        source_urls:sourceURLs(data.source_urls),proposed_publish_at:future(data.proposed_publish_at,"proposed_publish_at"),
        state:"DRAFT",approval:null,created_at:now,updated_at:now,history:[{at:now,event:"CREATED"}]};
      p.content_hash=await sha256(contentPayload(p));this.write(p);this.audit("POST_CREATED",p);
      return {post_id:id,state:p.state,content_hash:p.content_hash};
    }
    const {post:p,raw}=this.read(id);
    if(op==="show"){exactKeys(data,["operation","post_id"]);return p;}
    if(op==="verify"){exactKeys(data,["operation","post_id"]);
      const hash=await sha256(contentPayload(p));
      return {post_id:id,hash_matches:p.content_hash===hash,
        approval_hash_matches:!!p.approval&&p.approval.content_hash===hash,
        state:p.state,publishing_enabled:false};
    }
    if(op==="edit"){
      exactKeys(data,["operation","post_id","text","source_urls","proposed_publish_at"]);
      check(!["REJECTED","EXPIRED","WITHDRAWN"].includes(p.state),"Cannot edit terminal post");
      check(["text","source_urls","proposed_publish_at"].some(k=>k in data),"No changes supplied");
      if("text" in data)p.text=textValue(data.text,"text",1800);
      if("source_urls" in data)p.source_urls=sourceURLs(data.source_urls);
      if("proposed_publish_at" in data)p.proposed_publish_at=future(data.proposed_publish_at,"proposed_publish_at");
      const hash=await sha256(contentPayload(p));
      if(hash!==p.content_hash){p.approval=null;
        if(["APPROVED","SCHEDULE_PREPARED"].includes(p.state))p.state="READY_FOR_REVIEW";
        p.history.push({at:new Date().toISOString(),event:"CONTENT_CHANGED_APPROVAL_INVALIDATED"});}
      p.content_hash=hash;p.updated_at=new Date().toISOString();
      p.history.push({at:p.updated_at,event:"EDITED"});this.write(p,raw);this.audit("POST_EDITED",p);
      return {post_id:id,state:p.state,content_hash:p.content_hash,approval:p.approval};
    }
    if(op==="ready"){
      exactKeys(data,["operation","post_id"]);
      check(["DRAFT","NEEDS_RESEARCH","READY_FOR_REVIEW"].includes(p.state),"Cannot replace an approved decision");
      check(p.source_urls.length>0&&Boolean(p.text.trim()),"Text and source URLs required");
      check(p.content_hash===await sha256(contentPayload(p)),"Post integrity mismatch");
      p.state="READY_FOR_REVIEW";p.updated_at=new Date().toISOString();
      p.history.push({at:p.updated_at,event:"MARKED_READY_FOR_REVIEW"});
      this.write(p,raw);this.audit("READY_FOR_REVIEW",p);
      return {post_id:id,state:p.state,content_hash:p.content_hash};
    }
    if(op==="approve"){
      exactKeys(data,["operation","post_id","reviewer","action","expires_at","content_hash","platform","account_id","note"]);
      check(p.state==="READY_FOR_REVIEW","Requires READY_FOR_REVIEW");
      const hash=await sha256(contentPayload(p));
      check(p.content_hash===hash&&data.content_hash===hash&&
        data.platform===p.platform&&data.account_id===p.account_id,
        "Post changed: reload exact draft before approval");
      check(["PREPARE_SCHEDULE","HUMAN_SUBMIT"].includes(data.action),"Exact action required");
      const now=new Date().toISOString();
      p.approval={reviewer:textValue(data.reviewer,"reviewer",100),decision:"APPROVE",
        content_hash:hash,platform:p.platform,account_id:p.account_id,action:data.action,
        approved_at:now,expires_at:future(data.expires_at,"expires_at"),
        note:data.note===undefined?"":textValue(data.note,"note",400,false)};
      p.state="APPROVED";p.updated_at=now;
      p.history.push({at:now,event:"HUMAN_APPROVED",content_hash:hash});
      this.write(p,raw);this.audit("HUMAN_APPROVED",p);
      return {post_id:id,state:p.state,approval:p.approval};
    }
    exactKeys(data,["operation","post_id"]);
    check(p.state==="APPROVED"&&!!p.approval,"Current approval required");
    check(["PREPARE_SCHEDULE","HUMAN_SUBMIT"].includes(p.approval.action),"Schedule preparation not authorized");
    check(Date.parse(p.approval.expires_at)>Date.now(),"Approval expired");
    check(p.approval.content_hash===p.content_hash&&p.content_hash===await sha256(contentPayload(p)),
      "Post changed since approval");
    p.state="SCHEDULE_PREPARED";p.updated_at=new Date().toISOString();
    p.history.push({at:p.updated_at,event:"LOCAL_SCHEDULE_PROPOSAL_PREPARED"});
    this.write(p,raw);this.audit("LOCAL_SCHEDULE_PROPOSAL_PREPARED",p);
    return {post_id:id,state:p.state,proposed_publish_at:p.proposed_publish_at,external_action:"NOT_PERFORMED"};
  }
  async fetch(request){
    try{
      const path=new URL(request.url).pathname;
      const data=await request.json();
      if(path==="/rate"){
        const window=Math.floor(Date.now()/60000).toString();
        this.sql.exec("INSERT INTO rates(window,count) VALUES (?,1) ON CONFLICT(window) DO UPDATE SET count=count+1",window);
        const count=this.sql.exec("SELECT count FROM rates WHERE window=?",window).one().count;
        if(count>3)return replyError(429,"Research request limit reached");
        return respond({status:"PASS"});
      }
      check(path==="/queue","Unknown private operation");
      const result=await this.queue(data);
      return respond({status:"PASS",operation:data.operation,result,
        external_social_action:"NOT_PERFORMED",data_scope:"FAMA_OWNER_PREVIEW"});
    }catch(error){
      const message=String(error.message||"Request rejected").slice(0,250);
      return replyError(/UNIQUE constraint/i.test(message)?409:400,message);
    }
  }
}
export default {
  async fetch(request,env){
    const path=new URL(request.url).pathname;
    if(request.method==="GET"){
      if(path==="/health")return respond({status:"RUNNING",scope:"OWNER_PREVIEW",publishing:"DISABLED"});
      const file=path==="/"
        ?[HTML,"text/html; charset=utf-8"]
        :path==="/app.js"?[JAVASCRIPT,"text/javascript; charset=utf-8"]
        :path==="/style.css"?[CSS,"text/css; charset=utf-8"]:null;
      if(!file)return replyError(404,"Not found");
      return new Response(file[0],{headers:{"Content-Type":file[1],...HEADERS}});
    }
    if(request.method!=="POST"||!["/api/queue","/api/research","/api/capabilities"].includes(path))
      return replyError(404,"Operation not exposed");
    if(!checkOrigin(request))return replyError(403,"Cross-origin request denied");
    if(!await validOwner(request,env))return replyError(401,"Owner authentication required");
    let data;try{data=await parseInput(request);}catch(err){return replyError(400,String(err.message));}
    if(path==="/api/capabilities")return respond({status:"PASS",mode:"CLOUD_OWNER_PREVIEW",
      operations:["research","queue","capabilities"],publishing:"DISABLED",
      remote_scheduling:"DISABLED",account_connections:"NOT_CONFIGURED",
      model_provider:"NOT_CONFIGURED",chatgpt_connector:"NOT_CONFIGURED",
      data_scope:"FAMA_OWNER_PREVIEW",original_python_runtime:"SEPARATE_LOCAL_SOURCE"});
    const stub=env.FAMA_STORE.get(env.FAMA_STORE.idFromName("fama-owner"));
    if(path==="/api/queue")
      return stub.fetch(new Request("https://fama.internal/queue",{method:"POST",
        headers:{"Content-Type":"application/json"},body:JSON.stringify(data)}));
    try{
      validateResearch(data);
      const rate=await stub.fetch(new Request("https://fama.internal/rate",{method:"POST",body:"{}"}));
      if(!rate.ok)return rate;
      return respond(await research(data));
    }catch(err){return replyError(400,String(err.message||"Research request rejected").slice(0,180));}
  }
};
