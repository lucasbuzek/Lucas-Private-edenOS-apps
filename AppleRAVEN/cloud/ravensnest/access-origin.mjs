import upstream,{verifyAccess} from "./owner-mcp-v2.candidate.mjs";
const APP="AppleRAVEN",ISSUER="https://lucasravensnest.cloudflareaccess.com";
const RESOURCE="https://appleraven-private.lucasravensnest.workers.dev/mcp";
const SUPPORTED=["2025-03-26","2025-06-18","2025-11-25","2026-07-28"];
const json=(body,status=200,extra={})=>new Response(JSON.stringify(body),{status,headers:{"content-type":"application/json","cache-control":"no-store","x-content-type-options":"nosniff",...extra}});
const fail=(id,code,message,status=200)=>json({jsonrpc:"2.0",id,error:{code,message}},status);
const unauthorized=()=>json({error:"owner_auth_required"},401,{"www-authenticate":'Bearer resource_metadata="https://appleraven-private.lucasravensnest.workers.dev/.well-known/oauth-protected-resource"'});
export default {
 async fetch(req,env,ctx){
  const u=new URL(req.url),path=u.pathname;
  if(path==="/.well-known/oauth-protected-resource"||path==="/.well-known/oauth-protected-resource/mcp"){
   if(req.method!=="GET")return json({error:"method_not_allowed"},405);
   return json({resource:RESOURCE,authorization_servers:[ISSUER],bearer_methods_supported:["header"],scopes_supported:["appleraven:read"]});
  }
  if(path!=="/mcp")return upstream.fetch(req,env,ctx);
  const origin=req.headers.get("origin");
  if(origin&&origin!==u.origin)return json({error:"origin_forbidden"},403);
  if(req.method!=="POST")return json({error:"method_not_allowed"},405,{"allow":"POST"});
  const identity=await verifyAccess(req);
  if(!identity)return unauthorized();
  if(!(req.headers.get("content-type")||"").toLowerCase().startsWith("application/json"))return json({error:"content_type_required"},415);
  let payload;
  try{const raw=await req.text();if(raw.length>32768)return json({error:"request_too_large"},413);payload=JSON.parse(raw)}catch{return json({error:"invalid_json"},400)}
  if(!payload||payload.jsonrpc!=="2.0"||typeof payload.method!=="string")return json({error:"invalid_jsonrpc"},400);
  const id=payload.id;
  if(id===undefined)return new Response(null,{status:202,headers:{"cache-control":"no-store"}});
  if(typeof id!=="number"&&typeof id!=="string")return json({error:"invalid_request_id"},400);
  if(payload.method==="initialize"){
   return json({jsonrpc:"2.0",id,result:{protocolVersion:SUPPORTED.includes(payload.params?.protocolVersion)?payload.params.protocolVersion:"2025-06-18",capabilities:{tools:{listChanged:false}},serverInfo:{name:APP,version:"0.2.1"},instructions:"Authenticated AppleRAVEN owner service. Tools are performed by existing paired providers or provisioned cloud sources; catalog entries alone do not mean a device is online."}});
  }
  if(payload.method==="ping")return json({jsonrpc:"2.0",id,result:{}});
  if(!["server/discover","tools/list","tools/call"].includes(payload.method))return fail(id,-32601,"Method not found");
  const params=payload.params&&typeof payload.params==="object"&&!Array.isArray(payload.params)?{...payload.params}:{};
  params._meta={...params._meta,"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientCapabilities":{},"io.modelcontextprotocol/clientInfo":{name:"chatgpt-remote-mcp",version:"1.0"}};
  const fwd={jsonrpc:"2.0",id,method:payload.method,params};
  const headers=new Headers(req.headers);
  headers.set("Mcp-Method",payload.method);
  headers.set("MCP-Protocol-Version","2026-07-28");
  headers.set("content-type","application/json");
  if(payload.method==="tools/call"){
   if(typeof params.name!=="string")return fail(id,-32602,"Tool name required");
   headers.set("Mcp-Name",params.name);
  }
  u.pathname="/api/mcp";
  const response=await upstream.fetch(new Request(u.toString(),{method:"POST",headers,body:JSON.stringify(fwd)}),env,ctx);
  let old;
  try{old=await response.json()}catch{return fail(id,-32603,"Upstream response invalid",502)}
  if(old?.error)return json({jsonrpc:"2.0",id,error:old.error},response.ok?200:response.status);
  if(!old?.result)return fail(id,-32603,"Upstream MCP result missing",502);
  const {resultType,_meta,...standard}=old.result;
  return json({jsonrpc:"2.0",id,result:standard});
 }
};