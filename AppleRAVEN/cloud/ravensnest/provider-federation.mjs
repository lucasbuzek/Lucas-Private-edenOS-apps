/**
 * AppleRAVEN native MCP federation, owner side.
 * Existing sources run on the Mac; no cloned implementations of their tools.
 * Every call is scoped to the signed-in AppleRAVEN owner and an explicit device grant.
 */
export const FEDERATION_TOOLS=Object.freeze([
 {name:"appleraven.providers.catalog",title:"Installed Mac MCP tool catalog",description:"Search namespaced tools provided by MCP servers actually running on an owner-paired Mac. Returns source tool names, JSON schemas and device availability.",inputSchema:{type:"object",properties:{device_id:{type:"string"},query:{type:"string"},offset:{type:"integer",minimum:0},limit:{type:"integer",minimum:1,maximum:100}},additionalProperties:false},annotations:{readOnlyHint:true,destructiveHint:false}},
 {name:"appleraven.providers.invoke",title:"Run installed Mac MCP tool",description:"Queue a call to a source MCP tool on a paired Mac. The Mac asks for local approval before calling the upstream provider; never runs on the Oracle VM.",inputSchema:{type:"object",properties:{device_id:{type:"string"},tool_name:{type:"string"},arguments:{type:"object"}},required:["device_id","tool_name"],additionalProperties:false},annotations:{readOnlyHint:false,destructiveHint:true,openWorldHint:false}},
 {name:"appleraven.providers.result",title:"Get a queued MCP tool result",description:"Read the result for an AppleRAVEN owner-authorized Mac MCP call.",inputSchema:{type:"object",properties:{command_id:{type:"string"}},required:["command_id"],additionalProperties:false},annotations:{readOnlyHint:true,destructiveHint:false}}
]);
const ID=/^mac_[a-f0-9]{24}$/;
const NAME=/^[a-z][a-z0-9_]{1,63}$/;
const COMMAND=/^cmd_[a-f0-9]{32}$/;
const fresh=t=>typeof t==="number"&&Date.now()-t<90000;
const safeJson=x=>{try{return JSON.parse(x)}catch{return null}};
function fail(error,status=400){return {error,status}}
async function ownerDevice(env,owner,id){
 if(!ID.test(id||""))return null;
 return env.DB.prepare("SELECT d.id,d.name,n.updated_at FROM devices d JOIN grants g ON g.device_id=d.id AND g.user_id=?1 AND g.capability='tools.proxy' AND g.revoked_at IS NULL LEFT JOIN node_state n ON n.node_id=d.id WHERE d.id=?2 AND d.revoked_at IS NULL LIMIT 1").bind(owner.id,id).first();
}
export async function federationCatalog(env,owner,args={}){
 const id=args.device_id||null,query=String(args.query||"").toLowerCase().slice(0,80);
 if(id&&!ID.test(id))return fail("invalid_device_id");
 const limit=Math.min(100,Math.max(1,Number.isInteger(args.limit)?args.limit:50));
 const offset=Math.min(10000,Math.max(0,Number.isInteger(args.offset)?args.offset:0));
 const rows=await env.DB.prepare("SELECT p.node_id,p.tool_name,p.description,p.schema_json,p.updated_at,d.name AS device_name,n.updated_at AS seen_at FROM appleraven_provider_tools p JOIN devices d ON d.id=p.node_id AND d.revoked_at IS NULL JOIN grants g ON g.device_id=d.id AND g.user_id=?1 AND g.capability='tools.proxy' AND g.revoked_at IS NULL LEFT JOIN node_state n ON n.node_id=d.id ORDER BY d.name,p.tool_name LIMIT 1000").bind(owner.id).all();
 const found=(rows.results||[]).filter(x=>(!id||x.node_id===id)&&(!query||(x.tool_name+" "+x.description).toLowerCase().includes(query)));
 return {total:found.length,offset,limit,tools:found.slice(offset,offset+limit).map(x=>({device_id:x.node_id,device_name:x.device_name,tool_name:x.tool_name,description:x.description,inputSchema:safeJson(x.schema_json)||{type:"object",properties:{}},online:fresh(x.seen_at),registered_at:x.updated_at}))};
}
export async function federationInvoke(env,owner,args={}){
 const id=args.device_id,name=args.tool_name;
 const d=await ownerDevice(env,owner,id);
 if(!d)return fail("device_not_granted",403);
 if(!fresh(d.updated_at))return fail("device_offline",503);
 if(typeof name!=="string"||!NAME.test(name))return fail("invalid_tool_name");
 const t=await env.DB.prepare("SELECT tool_name FROM appleraven_provider_tools WHERE node_id=?1 AND tool_name=?2").bind(id,name).first();
 if(!t)return fail("tool_not_registered",404);
 const params=args.arguments??{};
 if(!params||typeof params!=="object"||Array.isArray(params))return fail("arguments_must_be_object");
 const serialized=JSON.stringify(params);
 if(serialized.length>24000)return fail("arguments_too_large",413);
 const count=await env.DB.prepare("SELECT COUNT(*) AS n FROM appleraven_proxy_commands WHERE node_id=?1 AND status IN ('queued','claimed') AND created_at>?2").bind(id,Date.now()-600000).first();
 if(Number(count?.n)>20)return fail("too_many_pending_calls",429);
 const now=Date.now(),cid="cmd_"+[...crypto.getRandomValues(new Uint8Array(16))].map(x=>x.toString(16).padStart(2,"0")).join("");
 await env.DB.prepare("INSERT INTO appleraven_proxy_commands(id,node_id,owner_id,tool_name,args_json,status,created_at,expires_at) VALUES(?1,?2,?3,?4,?5,'queued',?6,?7)").bind(cid,id,owner.id,name,serialized,now,now+600000).run();
 return {command_id:cid,device_id:id,tool_name:name,status:"queued",next:"appleraven.providers.result"};
}
export async function federationResult(env,owner,args={}){
 const id=args.command_id;
 if(typeof id!=="string"||!COMMAND.test(id))return fail("invalid_command_id");
 const r=await env.DB.prepare("SELECT c.id,c.node_id,c.tool_name,c.status,c.result_json,c.is_error,c.created_at,c.completed_at FROM appleraven_proxy_commands c JOIN devices d ON d.id=c.node_id AND d.revoked_at IS NULL JOIN grants g ON g.device_id=d.id AND g.user_id=?1 AND g.capability='tools.proxy' AND g.revoked_at IS NULL WHERE c.id=?2 AND c.owner_id=?1").bind(owner.id,id).first();
 if(!r)return fail("command_not_found",404);
 return {command_id:r.id,device_id:r.node_id,tool_name:r.tool_name,status:r.status,created_at:r.created_at,completed_at:r.completed_at,isError:r.is_error===1,result:r.result_json?safeJson(r.result_json):null};
}
