/**
 * AppleRAVEN beta owner-only internal bridge.
 * Connects RAVEN member-authenticated Pages MCP to the existing paired Mac queue.
 * NOT a public MCP; denies requests without a signed short-lived server-to-server message.
 * Read-only allowlist ONLY. Does not install, pair or grant devices.
 */
const HEAD={ "content-type":"application/json; charset=utf-8", "cache-control":"no-store", "x-content-type-options":"nosniff" };
const json=(value,status=200)=>new Response(JSON.stringify(value),{status,headers:HEAD});
const ALLOWED=new Set(["status","shortcuts_list"]);
const COMMAND=/^cmd_[a-f0-9]{32}$/;
const digest=async key=>crypto.subtle.importKey("raw",new TextEncoder().encode(key),{name:"HMAC",hash:"SHA-256"},false,["verify"]);
const fromHex=x=>Uint8Array.from(x.match(/../g)||[],z=>parseInt(z,16));
async function authenticate(req,env,raw){
 const key=env.APPLERAVEN_BRIDGE_KEY,header=req.headers.get("x-appleraven-bridge-signature")||"";
 if(typeof key!=="string"||key.length<48||!/^[a-f0-9]{64}$/.test(header))return null;
 try{if(!await crypto.subtle.verify("HMAC",await digest(key),fromHex(header),new TextEncoder().encode(raw)))return null;}catch{return null;}
 let msg;try{msg=JSON.parse(raw)}catch{return null}
 if(!msg||typeof msg!=="object"||Array.isArray(msg)||!Number.isSafeInteger(msg.ts)||Math.abs(Date.now()-msg.ts)>60000||typeof msg.nonce!=="string"||!/^[0-9a-f-]{36}$/.test(msg.nonce))return null;
 if(typeof msg.owner_email!=="string"||msg.owner_email.toLowerCase()!=="lucasbuzek@gmail.com")return null;
 if(!["devices","catalog","invoke","result"].includes(msg.action))return null;
 try{
  const r=await env.DB.prepare("INSERT OR IGNORE INTO appleraven_bridge_nonces(nonce,created_at) VALUES(?1,?2)").bind(msg.nonce,Date.now()).run();
  if(r.meta?.changes!==1)return null;
 }catch{return null}
 return msg;
}
const query=async (env,sql,...args)=>(await env.DB.prepare(sql).bind(...args).all()).results||[];
async function owner(env){
 return env.DB.prepare("SELECT u.id FROM users u WHERE lower(u.email)='lucasbuzek@gmail.com' AND u.role='owner' AND u.disabled_at IS NULL ORDER BY (SELECT COUNT(*) FROM grants g WHERE g.user_id=u.id AND g.revoked_at IS NULL) DESC LIMIT 1").first();
}
async function devices(env,ownerId){
 const x=await query(env,"SELECT d.id,d.name,n.updated_at AS last_seen FROM devices d JOIN grants g ON g.device_id=d.id AND g.user_id=?1 AND g.capability='tools.proxy' AND g.revoked_at IS NULL LEFT JOIN node_state n ON n.node_id=d.id WHERE d.revoked_at IS NULL ORDER BY d.created_at DESC LIMIT 10",ownerId);
 return x.map(d=>({id:d.id,name:d.name,online:typeof d.last_seen==="number"&&Date.now()-d.last_seen<90000}));
}
async function handle(msg,env){
 const user=await owner(env);if(!user)return json({error:"owner_unavailable"},403);
 const d=await devices(env,user.id),p=msg.params&&typeof msg.params==="object"&&!Array.isArray(msg.params)?msg.params:{};
 if(msg.action==="devices")return json({devices:d});
 if(msg.action==="catalog"){
  const name=p.device_id,dv=d.find(x=>x.id===name);
  if(!dv)return json({error:"device_not_granted"},403);
  const tools=await query(env,"SELECT tool_name,description FROM appleraven_provider_tools WHERE node_id=?1 AND tool_name IN ('status','shortcuts_list') ORDER BY tool_name",name);
  return json({device:dv,tools});
 }
 if(msg.action==="invoke"){
  const dv=d.find(x=>x.id===p.device_id);
  if(!dv)return json({error:"device_not_granted"},403);
  if(!dv.online)return json({error:"device_offline"},503);
  if(!ALLOWED.has(p.tool_name)||p.arguments&&Object.keys(p.arguments).length)return json({error:"tool_not_allowed"},403);
  const has=await env.DB.prepare("SELECT 1 AS allowed FROM appleraven_provider_tools WHERE node_id=?1 AND tool_name=?2").bind(dv.id,p.tool_name).first();
  if(!has)return json({error:"tool_not_registered"},404);
  const count=await env.DB.prepare("SELECT COUNT(*) AS n FROM appleraven_proxy_commands WHERE node_id=?1 AND status IN ('queued','claimed') AND created_at>?2").bind(dv.id,Date.now()-600000).first();
  if(Number(count?.n)>20)return json({error:"too_many_pending_actions"},429);
  const id="cmd_"+Array.from(crypto.getRandomValues(new Uint8Array(16)),x=>x.toString(16).padStart(2,"0")).join("");
  const now=Date.now();
  await env.DB.prepare("INSERT INTO appleraven_proxy_commands(id,node_id,owner_id,tool_name,args_json,status,created_at,expires_at) VALUES(?1,?2,?3,?4,'{}','queued',?5,?6)").bind(id,dv.id,user.id,p.tool_name,now,now+120000).run();
  return json({command_id:id,device_id:dv.id,tool_name:p.tool_name,status:"queued"});
 }
 if(msg.action==="result"){
  if(!COMMAND.test(p.command_id||""))return json({error:"invalid_command_id"},400);
  const r=await env.DB.prepare("SELECT id,node_id,tool_name,status,result_json,is_error,completed_at FROM appleraven_proxy_commands WHERE id=?1 AND owner_id=?2").bind(p.command_id,user.id).first();
  if(!r||!ALLOWED.has(r.tool_name)||!d.find(x=>x.id===r.node_id))return json({error:"command_not_found"},404);
  let result=null;try{result=r.result_json?JSON.parse(r.result_json):null}catch{}
  return json({command_id:r.id,status:r.status,tool_name:r.tool_name,isError:r.is_error===1,completed_at:r.completed_at,result});
 }
 return json({error:"unknown_action"},404);
}
export default {async fetch(req,env){
 const path=new URL(req.url).pathname;
 if(path==="/health"&&req.method==="GET")return json({service:"AppleRAVEN internal bridge",status:"available",owner_details_disclosed:false});
 if(path!=="/v1/bridge"||req.method!=="POST"||req.headers.get("origin"))return json({error:"not_found"},404);
 if((req.headers.get("content-type")||"").split(";")[0]!=="application/json")return json({error:"unsupported_content_type"},415);
 const raw=await req.text();if(raw.length>4096)return json({error:"body_too_large"},413);
 const msg=await authenticate(req,env,raw);if(!msg)return json({error:"unauthorized"},401);
 try{return await handle(msg,env)}catch{return json({error:"internal_bridge_error"},503)}
}};
