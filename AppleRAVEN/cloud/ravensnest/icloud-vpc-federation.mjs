/**
 * Cloud-native iCloud Drive + Photos MCP federation over Cloudflare Workers VPC.
 * No Apple password/cookie crosses the Worker. Both upstream MCP servers live
 * on a private cloud node reachable through an outbound-only Cloudflare Tunnel.
 * No public origin IP, custom domain, Oracle account or Mac synchronization.
 */
export const ICLOUD_TOOLS=Object.freeze([
 {name:"appleraven.icloud.catalog",title:"iCloud cloud-source tools",description:"Discover tools operating directly on the signed-in owner's iCloud Drive and iCloud Photos web cloud, independent of local Mac sync.",inputSchema:{type:"object",properties:{query:{type:"string"},limit:{type:"integer",minimum:1,maximum:100},offset:{type:"integer",minimum:0}},additionalProperties:false},annotations:{readOnlyHint:true,destructiveHint:false,openWorldHint:false}},
 {name:"appleraven.icloud.invoke",title:"Call iCloud cloud-source tool",description:"Invoke one exact namespaced iCloud Drive/Photos MCP tool. Mutations require private server-side gates and user authorization; never send Apple credentials as tool arguments.",inputSchema:{type:"object",properties:{tool_name:{type:"string"},arguments:{type:"object"}},required:["tool_name"],additionalProperties:false},annotations:{readOnlyHint:false,destructiveHint:true,openWorldHint:false}}
]);
const PROVIDERS=Object.freeze([
 {id:"icloud.drive",binding:"ICLOUD_DRIVE_VPC",url:"http://127.0.0.1:8302/mcp"},
 {id:"icloud.photos",binding:"ICLOUD_PHOTOS_VPC",url:"http://127.0.0.1:8301/mcp"}
]);
const READONLY_DRIVE=new Set(["icloud_status","icloud_list","icloud_info","icloud_search","icloud_read_file","icloud_download","icloud_list_trash"]);
function getSource(env,id){
 const p=PROVIDERS.find(x=>x.id===id);
 if(!p||!env[p.binding]||typeof env[p.binding].fetch!=="function")return null;
 return {...p,client:env[p.binding]};
}
async function decode(response,id){
 if(!response.ok)throw Error("private_icloud_http_"+response.status);
 const payload=await response.text();
 if(payload.length>4_000_000)throw Error("private_icloud_response_too_large");
 const ct=response.headers.get("content-type")||"";
 if(ct.includes("text/event-stream")){
  for(const line of payload.split(/\r?\n/)){
   if(!line.startsWith("data:"))continue;
   const chunk=line.slice(5).trim();
   if(chunk==="[DONE]")continue;
   try{const result=JSON.parse(chunk);if(result.id===id)return result}catch{}
  }
  throw Error("private_icloud_sse_no_response");
 }
 const result=JSON.parse(payload);
 if(result.id!==id)throw Error("private_icloud_response_mismatch");
 return result;
}
async function openRemote(source){
 const base={"content-type":"application/json","accept":"application/json, text/event-stream","MCP-Protocol-Version":"2025-06-18"};
 const send=async(method,params,id,session)=>{
  const body={jsonrpc:"2.0",method,...(id===null?{}:{id}),...(params?{params}:{})};
  const res=await source.client.fetch(source.url,{method:"POST",headers:{...base,...(session?{"Mcp-Session-Id":session}:{})},body:JSON.stringify(body),signal:AbortSignal.timeout(20000)});
  if(id===null){if(!res.ok)throw Error("private_icloud_mcp_notify_failed");return {session:res.headers.get("Mcp-Session-Id")};}
  return {message:await decode(res,id),session:res.headers.get("Mcp-Session-Id")};
 };
 const initialize=await send("initialize",{protocolVersion:"2025-06-18",capabilities:{},clientInfo:{name:"AppleRAVEN private iCloud VPC",version:"1.0.0"}},1);
 if(initialize.message.error)throw Error("private_icloud_mcp_initialize_error");
 await send("notifications/initialized",null,null,initialize.session);
 return async(method,params)=>{
  const res=await send(method,params,crypto.randomUUID(),initialize.session);
  if(res.message.error)throw Error("private_icloud_mcp_error_"+res.message.error.code);
  return res.message.result;
 };
}
export async function icloudCatalog(env,args={}){
 const query=typeof args.query==="string"?args.query.toLowerCase().slice(0,80):"";
 const detail=await Promise.all(PROVIDERS.map(async p=>{
  const source=getSource(env,p.id);
  if(!source)return {provider:p.id,status:"not_connected",tools:[]};
  try{
   const remote=await openRemote(source);
   const listed=(await remote("tools/list",{}))?.tools||[];
   return {provider:p.id,status:"reachable",tools:listed.filter(t=>typeof t.name==="string").map(t=>({tool_name:p.id+"."+t.name,description:t.description||"",inputSchema:t.inputSchema||{type:"object",properties:{}},annotations:t.annotations||{}}))};
  }catch{return {provider:p.id,status:"unavailable_or_apple_login_required",tools:[]}}
 }));
 const all=detail.flatMap(p=>p.tools).filter(t=>!query||(t.tool_name+" "+t.description).toLowerCase().includes(query));
 const offset=Math.min(10000,Math.max(0,Number.isInteger(args.offset)?args.offset:0));
 const limit=Math.min(100,Math.max(1,Number.isInteger(args.limit)?args.limit:50));
 return {source:"apple_icloud_web",mac_required:false,providers:detail.map(x=>({name:x.provider,status:x.status,tool_count:x.tools.length})),total:all.length,tools:all.slice(offset,offset+limit),offset,limit};
}
export async function icloudInvoke(env,args={}){
 const tool=String(args.tool_name||"");
 if(!/^[a-z0-9_.:/-]{5,140}$/i.test(tool))return {error:"invalid_icloud_tool_name",status:400};
 const p=PROVIDERS.find(x=>tool.startsWith(x.id+"."));
 if(!p)return {error:"unknown_icloud_provider",status:404};
 const source=getSource(env,p.id);
 if(!source)return {error:"icloud_provider_not_connected",status:503};
 const original=tool.slice(p.id.length+1);
 const input=args.arguments??{};
 if(!input||typeof input!=="object"||Array.isArray(input)||JSON.stringify(input).length>24000)return {error:"invalid_icloud_arguments",status:413};
 // Owner-side authorization is not equivalent to authorization to mutate a library.
 // Drive changes stay blocked until an owner configures the explicit server-side flag.
 if(p.id==="icloud.drive"&&!READONLY_DRIVE.has(original)&&env.ICLOUD_DRIVE_ENABLE_WRITES!=="1")
   return {error:"icloud_drive_writes_disabled",status:403};
 try{
  const remote=await openRemote(source);
  const manifest=(await remote("tools/list",{}))?.tools||[];
  if(!manifest.some(t=>t.name===original))return {error:"icloud_tool_unavailable",status:404};
  const result=await remote("tools/call",{name:original,arguments:input});
  return {tool_name:tool,result,isError:result?.isError===true};
 }catch{return {error:"icloud_service_unavailable_or_session_expired",status:503}}
}
