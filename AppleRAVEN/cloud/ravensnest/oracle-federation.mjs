/**
 * Oracle MCP coordinator client for AppleRAVEN's existing signed-owner Worker.
 * Oracle runs cloud MCP servers, not native Mac actions. Only configured
 * Cloudflare Access service-token tunnel is contacted; never public localhost.
 */
export const CLOUD_TOOLS=Object.freeze([
 {name:"appleraven.cloud.catalog",title:"Oracle multi-agent MCP catalog",description:"Discover live cloud MCP connector tools aggregated by the owner-controlled always-on Oracle gateway.",inputSchema:{type:"object",properties:{query:{type:"string"},offset:{type:"integer",minimum:0},limit:{type:"integer",minimum:1,maximum:100}},additionalProperties:false},annotations:{readOnlyHint:true,destructiveHint:false}},
 {name:"appleraven.cloud.invoke",title:"Invoke Oracle cloud connector",description:"Invoke a registered cloud MCP tool by exact name through the owner's Oracle gateway. Underlying upstream OAuth scopes and side effects apply.",inputSchema:{type:"object",properties:{tool_name:{type:"string"},arguments:{type:"object"}},required:["tool_name"],additionalProperties:false},annotations:{readOnlyHint:false,destructiveHint:true,openWorldHint:true}}
]);
const fail=(error,status=400)=>({error,status});
function endpoint(env){
 const url=env.ORACLE_GATEWAY_URL;
 if(typeof url!=="string"||!url.startsWith("https://")||url.length>250)return null;
 let u;try{u=new URL(url)}catch{return null}
 if(u.username||u.password||u.hash||u.search||u.pathname!=="/mcp")return null;
 if(!env.ORACLE_ACCESS_CLIENT_ID||!env.ORACLE_ACCESS_CLIENT_SECRET)return null;
 return u.href;
}
async function parseResponse(response,id){
 if(!response.ok)throw Error("remote_gateway_http_"+response.status);
 const text=await response.text();
 if(text.length>250000)throw Error("remote_result_too_large");
 const ct=response.headers.get("content-type")||"";
 if(ct.includes("text/event-stream")){
  for(const line of text.split(/\r?\n/)){
   if(!line.startsWith("data:"))continue;
   const payload=line.slice(5).trim();
   if(payload==="[DONE]")continue;
   try{const data=JSON.parse(payload);if(data.id===id)return data}catch{}
  }
  throw Error("remote_sse_result_missing");
 }
 const data=JSON.parse(text);
 if(data.id!==id)throw Error("remote_jsonrpc_id_mismatch");
 return data;
}
async function rpc(env){
 const url=endpoint(env);
 if(!url)throw Error("oracle_gateway_not_configured");
 const access={"CF-Access-Client-Id":env.ORACLE_ACCESS_CLIENT_ID,"CF-Access-Client-Secret":env.ORACLE_ACCESS_CLIENT_SECRET};
 const headers={...access,"content-type":"application/json","accept":"application/json, text/event-stream","MCP-Protocol-Version":"2025-06-18"};
 const send=async (method,params,id,session)=>{
  const payload={jsonrpc:"2.0",method,...(id===null?{}:{id}),...(params?{params}:{})};
  const res=await fetch(url,{method:"POST",headers:{...headers,...(session?{"Mcp-Session-Id":session}:{})},body:JSON.stringify(payload),signal:AbortSignal.timeout(25000)});
  if(id===null){if(!res.ok)throw Error("remote_initialized_failed");return {session:res.headers.get("Mcp-Session-Id")};}
  return {message:await parseResponse(res,id),session:res.headers.get("Mcp-Session-Id")};
 };
 const init=await send("initialize",{protocolVersion:"2025-06-18",capabilities:{},clientInfo:{name:"AppleRAVEN Oracle cloud federation",version:"0.2.0"}},1);
 if(init.message.error)throw Error("oracle_gateway_initialize_rejected");
 const session=init.session;
 await send("notifications/initialized",null,null,session);
 return async(method,params)=>{
  const id=crypto.randomUUID();
  const r=await send(method,params,id,session);
  if(r.message.error)throw Error("oracle_gateway_mcp_error_"+r.message.error.code);
  return r.message.result;
 };
}
export async function cloudCatalog(env,args={}){
 try{
  const remote=await rpc(env);
  const t=(await remote("tools/list",{}))?.tools||[];
  const q=String(args.query||"").toLowerCase().slice(0,80);
  const filtered=t.filter(x=>typeof x.name==="string"&&(!q||(x.name+" "+(x.description||"")).toLowerCase().includes(q)));
  const offset=Math.min(10000,Math.max(0,Number.isInteger(args.offset)?args.offset:0));
  const limit=Math.min(100,Math.max(1,Number.isInteger(args.limit)?args.limit:50));
  return {total:filtered.length,offset,limit,tools:filtered.slice(offset,offset+limit).map(x=>({tool_name:x.name,description:x.description||"",inputSchema:x.inputSchema||{type:"object",properties:{}}}))};
 }catch(e){return fail(e.message==="oracle_gateway_not_configured"?"oracle_gateway_not_configured":"oracle_gateway_unavailable",503)}
}
export async function cloudInvoke(env,args={}){
 if(!/^[a-z0-9_./:-]{2,120}$/i.test(args.tool_name||""))return fail("invalid_cloud_tool_name");
 const p=args.arguments??{};
 if(!p||typeof p!=="object"||Array.isArray(p)||JSON.stringify(p).length>24000)return fail("invalid_or_large_arguments",413);
 try{
  const remote=await rpc(env);
  const list=(await remote("tools/list",{}))?.tools||[];
  if(!list.some(x=>x.name===args.tool_name))return fail("cloud_tool_unavailable",404);
  const result=await remote("tools/call",{name:args.tool_name,arguments:p});
  return {tool_name:args.tool_name,result,isError:result?.isError===true};
 }catch(e){return fail(e.message==="oracle_gateway_not_configured"?"oracle_gateway_not_configured":"oracle_gateway_unavailable",503)}
}
