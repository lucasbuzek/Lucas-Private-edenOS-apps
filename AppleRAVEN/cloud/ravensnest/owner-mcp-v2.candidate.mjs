import {handleOwnerPair,PAIR_TOOLS,queueShortcuts,readAction} from "./owner-pair-addon.mjs";
/**
 * AppleRAVEN initial OWNER-ONLY MCP.
 * Cloudflare Access Managed OAuth authenticates the client, and this Worker
 * independently verifies its signed Access assertion before any D1 access.
 * No other identities, devices, external providers or privileged tools.
 * The original locked worker remains in worker.mjs as rollback.
 */
const ISSUER="https://lucasravensnest.cloudflareaccess.com";
const AUDIENCE="90f75e8cdcaa800f4dc2e2c08664ccdd16c1cff1116d0c18400b82be783b1be2";
const OWNER_EMAIL="lucasbuzek@gmail.com";
const VERSION="2026-07-28";
const APP="AppleRAVEN";
const MAX_BODY=32768;
const PROFILE_TOOL="appleraven.owner.status";
const DEVICE_TOOL="appleraven.devices.list";
const tools=Object.freeze([
 ...PAIR_TOOLS,
 {name:PROFILE_TOOL,title:"AppleRAVEN owner profile",description:"Report the authenticated owner profile and pairing state for this AppleRAVEN connection.",inputSchema:{type:"object",properties:{},additionalProperties:false},annotations:{readOnlyHint:true,destructiveHint:false,openWorldHint:false},_meta:{"openai/profile":true}},
 {name:DEVICE_TOOL,title:"My paired Apple devices",description:"List only live enrollment records explicitly granted to the authenticated owner. Returns empty until M1 is paired.",inputSchema:{type:"object",properties:{},additionalProperties:false},annotations:{readOnlyHint:true,destructiveHint:false,openWorldHint:false}}
]);
const headers={"content-type":"application/json","cache-control":"no-store","x-content-type-options":"nosniff"};
const json=(body,status=200,extra={})=>new Response(JSON.stringify(body),{status,headers:{...headers,...extra}});
const error=(id,code,message,status=400)=>json({jsonrpc:"2.0",id,error:{code,message}},status);
const reply=(id,value)=>json({jsonrpc:"2.0",id,result:{resultType:"complete",...value}});
function decode64(v){
 if(typeof v!=="string"||!v||!/^[A-Za-z0-9_-]+$/.test(v))throw new Error("invalid base64url");
 const b=atob(v.replace(/-/g,"+").replace(/_/g,"/").padEnd(Math.ceil(v.length/4)*4,"="));
 return Uint8Array.from(b,c=>c.charCodeAt(0));
}
const decodeJson=v=>JSON.parse(new TextDecoder().decode(decode64(v)));
async function verifyAccess(req){
 const token=req.headers.get("Cf-Access-Jwt-Assertion");
 if(!token||token.length>8192)return null;
 const pieces=token.split(".");
 if(pieces.length!==3)return null;
 let head,claims;
 try{head=decodeJson(pieces[0]);claims=decodeJson(pieces[1])}catch{return null}
 if(head.alg!=="RS256"||typeof head.kid!=="string"||typeof claims.sub!=="string"||!claims.sub)return null;
 const now=Math.floor(Date.now()/1000);
 if(claims.iss!==ISSUER||!(Array.isArray(claims.aud)?claims.aud:[claims.aud]).includes(AUDIENCE)
   ||typeof claims.exp!=="number"||claims.exp<=now
   ||typeof claims.iat!=="number"||claims.iat>now+60
   ||(typeof claims.nbf==="number"&&claims.nbf>now+60)
   ||typeof claims.email!=="string"||claims.email.toLowerCase()!==OWNER_EMAIL)return null;
 let keys;
 try{
   const r=await fetch(ISSUER+"/cdn-cgi/access/certs");
   if(!r.ok)return null;
   keys=(await r.json()).keys;
 }catch{return null}
 if(!Array.isArray(keys))return null;
 const jwk=keys.find(k=>k.kid===head.kid&&k.kty==="RSA"&&(!k.alg||k.alg==="RS256")&&(!k.use||k.use==="sig"));
 if(!jwk)return null;
 try{
  const key=await crypto.subtle.importKey("jwk",{kty:"RSA",n:jwk.n,e:jwk.e,alg:"RS256",ext:true}, {name:"RSASSA-PKCS1-v1_5",hash:"SHA-256"},false,["verify"]);
  const body=new TextEncoder().encode(pieces[0]+"."+pieces[1]);
  const verified=await crypto.subtle.verify({name:"RSASSA-PKCS1-v1_5"},key,decode64(pieces[2]),body);
  return verified?{issuer:claims.iss,subject:claims.sub,email:claims.email.toLowerCase()}:null;
 }catch{return null}
}
async function getOwner(env,identity){
 const bytes=new TextEncoder().encode(identity.issuer+"|"+identity.subject);
 const hash=Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256",bytes))).map(x=>x.toString(16).padStart(2,"0")).join("");
 const id="usr_"+hash.slice(0,32);
 const current=await env.DB.prepare("SELECT id,subject,email,role,disabled_at FROM users WHERE id=?1").bind(id).first();
 if(current){
   if(current.subject!==identity.subject||current.email.toLowerCase()!==OWNER_EMAIL||current.role!=="owner"||current.disabled_at)return null;
   return {id,email:current.email};
 }
 await env.DB.prepare("INSERT OR IGNORE INTO users(id,subject,email,role,created_at) VALUES(?1,?2,?3,'owner',?4)").bind(id,identity.subject,identity.email,Date.now()).run();
 const row=await env.DB.prepare("SELECT id,subject,email,role,disabled_at FROM users WHERE id=?1").bind(id).first();
 return row&&row.subject===identity.subject&&row.email.toLowerCase()===OWNER_EMAIL&&row.role==="owner"&&!row.disabled_at?{id,email:row.email}:null;
}
async function getDevices(env,id){
 const x=await env.DB.prepare(
 "SELECT d.id,d.name,d.kind,n.updated_at FROM devices d "+
 "INNER JOIN grants g ON g.device_id=d.id "+
 "LEFT JOIN node_state n ON n.node_id=d.id "+
 "WHERE g.user_id=?1 AND g.revoked_at IS NULL AND d.revoked_at IS NULL "+
 "GROUP BY d.id,d.name,d.kind,n.updated_at ORDER BY d.name LIMIT 10"
 ).bind(id).all();
 return (x.results||[]).map(d=>({id:d.id,name:d.name,kind:d.kind,online:typeof d.updated_at==="number"&&Date.now()-d.updated_at<90000}));
}
const resourceInfo={resource:"https://appleraven-private.lucasravensnest.workers.dev",authorization_servers:[ISSUER],scopes_supported:["appleraven:read"]};
const challenge=()=>json({error:"owner_login_required"},401,{"www-authenticate":'Bearer resource_metadata="https://appleraven-private.lucasravensnest.workers.dev/.well-known/oauth-protected-resource"'});
export default {
 async fetch(request,env){
  const path=new URL(request.url).pathname;
  if(path==="/pair"||path==="/pair/approve"){
   const identity=await verifyAccess(request);
   if(!identity)return challenge();
   let owner;try{owner=await getOwner(env,identity)}catch{return json({error:"owner_store_unavailable"},503)}
   if(!owner)return json({error:"owner_not_authorized"},403);
   return handleOwnerPair(request,env,owner);
  }
  if(path==="/health"&&request.method==="GET"){
   try{const d=await env.DB.prepare("SELECT 1 AS ok").first();return json({service:APP,hosting:"ravensnest",database:!!d?.ok,mode:"owner_read_only",m1:"unpaired"},d?.ok?200:503)}
   catch{return json({service:APP,status:"database_unavailable"},503)}
  }
  if(path==="/mcp"||path==="/api/mcp"){
   // Access should enforce OAuth before hitting the Worker. Token validation here
   // prevents trust in a forged header or an accidentally uncovered route.
   const identity=await verifyAccess(request);
   if(!identity)return challenge();
   if(request.method!=="POST")return json({error:"method_not_allowed"},405);
   const proto=request.headers.get("MCP-Protocol-Version");
   if(proto!==VERSION)return json({error:"unsupported_protocol"},400);
   const contentType=request.headers.get("content-type")||"";
   if(!contentType.startsWith("application/json"))return json({error:"unsupported_content_type"},415);
   let body;
   try{const raw=await request.text();if(raw.length>MAX_BODY)return json({error:"body_too_large"},413);body=JSON.parse(raw)}
   catch{return json({error:"invalid_json"},400)}
   if(!body||typeof body!=="object"||Array.isArray(body)||body.jsonrpc!=="2.0"||typeof body.method!=="string")return json({error:"invalid_mcp_request"},400);
   const id=body.id;
   if(body.method==="notifications/initialized"&&id===undefined)return new Response(null,{status:202});
   if(typeof id!=="number"&&typeof id!=="string")return json({error:"missing_request_id"},400);
   if(request.headers.get("Mcp-Method")!==body.method)return error(id,-32602,"method header mismatch");
   const meta=body.params?._meta;
   if(!meta||meta["io.modelcontextprotocol/protocolVersion"]!==VERSION||typeof meta["io.modelcontextprotocol/clientInfo"]?.name!=="string"||typeof meta["io.modelcontextprotocol/clientCapabilities"]!=="object")return error(id,-32602,"client metadata required");
   if(body.method==="server/discover")return reply(id,{supportedVersions:[VERSION],capabilities:{tools:{}},instructions:"Owner-private AppleRAVEN. M1 pairing required before native Apple tools are available."});
   if(body.method==="tools/list")return reply(id,{tools});
   if(body.method!=="tools/call")return error(id,-32601,"method not found",404);
   if(request.headers.get("Mcp-Name")!==body.params?.name)return error(id,-32602,"tool name mismatch");
   if(!tools.some(t=>t.name===body.params.name))return error(id,-32601,"unknown tool",404);
   const args=body.params.arguments||{};
   if(typeof args!=="object"||Array.isArray(args))return error(id,-32602,"invalid arguments");
   if(![PAIR_TOOLS[0].name,PAIR_TOOLS[1].name].includes(body.params.name)&&Object.keys(args).length)return error(id,-32602,"unexpected arguments");
   let owner;
   try{owner=await getOwner(env,identity)}catch{return error(id,-32603,"owner store unavailable",503)}
   if(!owner)return error(id,-32001,"account not authorized",403);
   let result;
   if(body.params.name===PROFILE_TOOL)result={id:owner.id,email:owner.email,role:"owner",paired_device_count:(await getDevices(env,owner.id)).length};
   else if(body.params.name===DEVICE_TOOL)result={devices:await getDevices(env,owner.id)};
   else if(body.params.name===PAIR_TOOLS[0].name){
    if(Object.keys(args).length!==1||typeof args.device_id!=="string")return error(id,-32602,"invalid device id");
    result=await queueShortcuts(env,owner,args.device_id);
    if(result.error)return error(id,-32001,result.error,result.status);
   }else if(body.params.name===PAIR_TOOLS[1].name){
    if(Object.keys(args).length!==1||typeof args.id!=="string")return error(id,-32602,"invalid action id");
    result=await readAction(env,owner,args.id);
    if(result.error)return error(id,-32002,result.error,result.status);
   }else return error(id,-32601,"unknown tool",404);
   return reply(id,{content:[{type:"text",text:JSON.stringify(result)}],structuredContent:result,isError:false});
  }
  return json({error:"not_found"},404);
 }
};
