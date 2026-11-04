import upstream from "./owner-mcp-tunnel.mjs";
import {PAIR_TOOLS} from "./owner-pair-addon.mjs";
const name="AppleRAVEN",protocols=["2025-03-26","2025-06-18","2025-11-25","2026-07-28"];
const json=(value,status=200,additional={})=>new Response(JSON.stringify(value),{status,headers:{"content-type":"application/json","cache-control":"no-store","x-content-type-options":"nosniff",...additional}});
const err=(id,code,message,status=200)=>json({jsonrpc:"2.0",id,error:{code,message}},status);
export default {
 async fetch(request,env,ctx){
  const path=new URL(request.url).pathname;
  if(path!=="/mcp")return upstream.fetch(request,env,ctx);
  const origin=request.headers.get("origin");
  if(origin&&origin!==new URL(request.url).origin)return json({error:"origin_forbidden"},403);
  if(request.method!=="POST")return json({error:"method_not_allowed"},405,{"allow":"POST"});
  const bearer=(request.headers.get("authorization")||"").match(/^Bearer ([A-Za-z0-9_-]{40,128})$/);
  if(!bearer||typeof env.TUNNEL_ORIGIN_TOKEN!=="string")return json({error:"tunnel_bearer_required"},401,{"www-authenticate":'Bearer realm="AppleRAVEN-tunnel-origin"'});
  const enc=new TextEncoder();
  const a=new Uint8Array(await crypto.subtle.digest("SHA-256",enc.encode(bearer[1])));
  const b=new Uint8Array(await crypto.subtle.digest("SHA-256",enc.encode(env.TUNNEL_ORIGIN_TOKEN)));
  let diff=0;for(let i=0;i<a.length;i++)diff|=a[i]^b[i];
  if(diff!==0)return json({error:"invalid_tunnel_bearer"},401,{"www-authenticate":'Bearer realm="AppleRAVEN-tunnel-origin"'});
  if(!(request.headers.get("content-type")||"").toLowerCase().startsWith("application/json"))return json({error:"content_type_required"},415);
  let payload;
  try{const raw=await request.text();if(raw.length>32768)return json({error:"request_too_large"},413);payload=JSON.parse(raw)}catch{return json({error:"invalid_json"},400)}
  if(!payload||payload.jsonrpc!=="2.0"||typeof payload.method!=="string")return json({error:"invalid_jsonrpc"},400);
  const id=payload.id;
  if(id===undefined){
    if(payload.method==="notifications/initialized"||payload.method.startsWith("notifications/"))return new Response(null,{status:202,headers:{"cache-control":"no-store"}});
    return new Response(null,{status:202,headers:{"cache-control":"no-store"}});
  }
  if(typeof id!=="string"&&typeof id!=="number")return json({error:"invalid_request_id"},400);
  if(payload.method==="initialize"){
    const proposed=payload.params?.protocolVersion;
    const selected=protocols.includes(proposed)?proposed:"2025-06-18";
    return json({jsonrpc:"2.0",id,result:{protocolVersion:selected,capabilities:{tools:{listChanged:false}},serverInfo:{name,version:"0.2.0"},instructions:"Owner-private AppleRAVEN cloud tools and paired Mac providers. A paired online device is required for native execution. iCloud tools require configured private cloud source bindings."}});
  }
  if(payload.method==="ping")return json({jsonrpc:"2.0",id,result:{}});
  if(!["tools/list","tools/call","server/discover"].includes(payload.method))return err(id,-32601,"Method not found");
  const param=payload.params&&typeof payload.params==="object"&&!Array.isArray(payload.params)?{...payload.params}:{};
  param._meta={...param._meta,"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientCapabilities":{},"io.modelcontextprotocol/clientInfo":{name:"openai-secure-tunnel",version:"1.0"}};
  const forward={jsonrpc:"2.0",id,method:payload.method,params:param};
  const headers=new Headers(request.headers);
  headers.set("MCP-Protocol-Version","2026-07-28");
  headers.set("Mcp-Method",payload.method);
  if(payload.method==="tools/call"){
   if(typeof param.name!=="string")return err(id,-32602,"Tool name required");
   headers.set("Mcp-Name",param.name);
  }
  headers.set("content-type","application/json");
  const url=new URL(request.url);url.pathname="/api/mcp";
  const response=await upstream.fetch(new Request(url.toString(),{method:"POST",headers,body:JSON.stringify(forward)}),env,ctx);
  let result;
  try{result=await response.json()}catch{return err(id,-32603,"Upstream AppleRAVEN response invalid",502)}
  if(result?.error)return json({jsonrpc:"2.0",id,error:result.error},response.ok?200:response.status);
  if(!result?.result)return err(id,-32603,"Upstream AppleRAVEN result missing",502);
  const {resultType,_meta,...standard}=result.result;
  return json({jsonrpc:"2.0",id,result:standard});
 }
};