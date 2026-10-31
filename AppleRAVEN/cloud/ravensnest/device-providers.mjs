/**
 * AppleRAVEN outbound-only paired Mac provider federation ingress.
 * Called ONLY after existing per-device bearer authentication succeeds.
 * Never accept access tokens, arbitrary OS commands or direct unauthenticated jobs.
 */
const NAME=/^[a-z][a-z0-9_]{1,63}$/;
const COMMAND=/^cmd_[a-f0-9]{32}$/;
const json=(body,status=200)=>new Response(JSON.stringify(body),{status,headers:{"content-type":"application/json","cache-control":"no-store","x-content-type-options":"nosniff"}});
const safeParse=s=>{try{return JSON.parse(s)}catch{return null}};
async function authorized(env,id){
 const x=await env.DB.prepare("SELECT COUNT(*) AS n FROM grants WHERE device_id=?1 AND capability='tools.proxy' AND revoked_at IS NULL").bind(id).first();
 return Number(x?.n)>0;
}
export async function handleDeviceProviders(request,env,device,path){
 if(!await authorized(env,device.id))return json({error:"device_proxy_permission_not_granted"},403);
 if(request.method!=="POST"||request.headers.get("origin"))return json({error:"forbidden"},403);
 const raw=await request.text();
 if(raw.length>220000)return json({error:"request_too_large"},413);
 let b=safeParse(raw);
 if(!b||typeof b!=="object"||Array.isArray(b))return json({error:"invalid_json"},400);
 const now=Date.now();
 if(path==="/v1/device/providers/register"){
  if(!Array.isArray(b.tools)||b.tools.length>320)return json({error:"invalid_catalog"},400);
  const unique=new Set(),statements=[];
  for(const t of b.tools){
   if(!t||typeof t!=="object"||!NAME.test(t.name)||unique.has(t.name))return json({error:"invalid_tool_name"},400);
   unique.add(t.name);
   const schema=t.inputSchema;
   if(!schema||typeof schema!=="object"||Array.isArray(schema)||schema.type!=="object")return json({error:"invalid_tool_schema"},400);
   const serialized=JSON.stringify(schema);
   if(serialized.length>6000)return json({error:"tool_schema_too_large"},413);
   const description=String(t.description||t.name).slice(0,800);
   statements.push(env.DB.prepare("INSERT INTO appleraven_provider_tools(node_id,tool_name,description,schema_json,updated_at) VALUES(?1,?2,?3,?4,?5) ON CONFLICT(node_id,tool_name) DO UPDATE SET description=excluded.description,schema_json=excluded.schema_json,updated_at=excluded.updated_at").bind(device.id,t.name,description,serialized,now));
  }
  // Replace the previous manifest only after every new tool has passed validation.
  await env.DB.prepare("DELETE FROM appleraven_provider_tools WHERE node_id=?1").bind(device.id).run();
  for(let i=0;i<statements.length;i+=40)await env.DB.batch(statements.slice(i,i+40));
  return json({ok:true,registered:statements.length});
 }
 if(path==="/v1/device/providers/next"){
  const old=await env.DB.prepare("SELECT id FROM appleraven_proxy_commands WHERE node_id=?1 AND status='queued' AND expires_at<=?2 LIMIT 50").bind(device.id,now).all();
  if(old.results?.length)await env.DB.prepare("UPDATE appleraven_proxy_commands SET status='expired',completed_at=?1 WHERE node_id=?2 AND status='queued' AND expires_at<=?1").bind(now,device.id).run();
  const c=await env.DB.prepare("SELECT id,tool_name,args_json FROM appleraven_proxy_commands WHERE node_id=?1 AND status='queued' AND expires_at>?2 ORDER BY created_at LIMIT 1").bind(device.id,now).first();
  if(!c)return json({command:null});
  const changed=await env.DB.prepare("UPDATE appleraven_proxy_commands SET status='claimed',claimed_at=?1 WHERE id=?2 AND node_id=?3 AND status='queued'").bind(now,c.id,device.id).run();
  if(changed.meta?.changes!==1)return json({command:null});
  return json({command:{id:c.id,name:c.tool_name,arguments:safeParse(c.args_json)||{}}});
 }
 if(path==="/v1/device/providers/result"){
  if(!COMMAND.test(b.command_id||"")||typeof b.isError!=="boolean"||!b.result||typeof b.result!=="object")return json({error:"invalid_result"},400);
  const serialized=JSON.stringify(b.result);
  if(serialized.length>180000)return json({error:"result_too_large_use_chunked_transfer"},413);
  const changed=await env.DB.prepare("UPDATE appleraven_proxy_commands SET status='done',completed_at=?1,result_json=?2,is_error=?3 WHERE id=?4 AND node_id=?5 AND status='claimed'").bind(now,serialized,b.isError?1:0,b.command_id,device.id).run();
  if(changed.meta?.changes!==1)return json({error:"stale_or_unknown_command"},409);
  return json({ok:true});
 }
 return json({error:"not_found"},404);
}
