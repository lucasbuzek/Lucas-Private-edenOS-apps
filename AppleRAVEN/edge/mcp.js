/**
 * AppleRAVEN remote MCP overlay for the original lucas-raven Pages API.
 * The caller MUST supply an authenticated non-legacy Cloudflare Access user,
 * from the ORIGINAL human() verifier; grant filtering uses original allowed().
 * This module does not mint identity, store secrets, or connect to a Mac by itself.
 * Source lineage: BIFROST/web/lucas-raven/functions/api/[[path]].js
 */
export const VERSION = '2026-07-28';
const MAX_BODY = 65536;
const MAX_TOOL_RESPONSE = 32000;
const TOOL_LIST = Object.freeze([
  {name:'appleraven.nodes.status',title:'Authorized Apple device status',description:'Read verified presence and capabilities of enrolled devices accessible to this identity.',inputSchema:{type:'object',properties:{},additionalProperties:false},annotations:{readOnlyHint:true,destructiveHint:false,openWorldHint:false}},
  {name:'appleraven.actions.status',title:'Authorized action status',description:'Read one previously requested action only if this identity holds its device and capability grant.',inputSchema:{type:'object',properties:{id:{type:'string',pattern:'^act_[a-f0-9]{20}$'}},required:['id'],additionalProperties:false},annotations:{readOnlyHint:true,destructiveHint:false,openWorldHint:false}}
]);
const json=(body,status=200,headers={})=>new Response(JSON.stringify(body),{status,headers:{'Content-Type':'application/json','Cache-Control':'no-store','X-Content-Type-Options':'nosniff',...headers}});
const err=(id,code,message)=>({jsonrpc:'2.0',id,error:{code,message}});
const reply=(id,result)=>json({jsonrpc:'2.0',id,result:{resultType:'complete',...result,_meta:{'io.modelcontextprotocol/serverInfo':{name:'AppleRAVEN Remote',version:'0.1.0'}}}});
const accepts=(request)=>{const s=request.headers.get('accept')||'';return s.includes('application/json')&&s.includes('text/event-stream')};
function validMeta(x){return x&&typeof x==='object'&&!Array.isArray(x)&&x['io.modelcontextprotocol/protocolVersion']===VERSION&&x['io.modelcontextprotocol/clientCapabilities']&&typeof x['io.modelcontextprotocol/clientCapabilities']==='object'&&!Array.isArray(x['io.modelcontextprotocol/clientCapabilities'])&&typeof x['io.modelcontextprotocol/clientInfo']?.name==='string'&&!!x['io.modelcontextprotocol/clientInfo'].name&&typeof x['io.modelcontextprotocol/clientInfo']?.version==='string'&&!!x['io.modelcontextprotocol/clientInfo'].version}
const success=(value)=>({content:[{type:'text',text:JSON.stringify(value).slice(0,MAX_TOOL_RESPONSE)}],isError:false});
export async function handleAppleRavenMCP({request,env,user,visibleState,allowed}){
  // No legacy bearer-key compatibility. Real user must have a verified Access
  // assertion and a non-revoked local user record; preserve distinct profiles.
  if(!user?.id||user.legacy||!user.subject||user.disabled_at)return json({error:'oauth-required'},401,{'WWW-Authenticate':'Bearer realm="AppleRAVEN"'});
  // The original owner role can inspect every tenant via the admin API; this
  // *MCP* never inherits that authority. Each device/capability needs its own
  // explicit, current grant, including for the owner and Council variants.
  const grants=Array.isArray(user.grants)?user.grants:[];
  const granted=(node,cap)=>grants.some(g=>g.device_id===node && !g.revoked_at && (!cap || g.capability===cap || g.capability==='*'));
  if(request.method!=='POST')return json({error:'method not allowed'},405);
  const origin=request.headers.get('origin');
  if(origin && origin!==new URL(request.url).origin)return json({error:'origin denied'},403);
  if(request.headers.get('MCP-Protocol-Version')!==VERSION||!accepts(request))return json({error:'invalid MCP headers'},400);
  if(!(request.headers.get('Content-Type')||'').toLowerCase().startsWith('application/json'))return json({error:'unsupported content type'},415);
  const n=Number(request.headers.get('Content-Length'));
  if(Number.isFinite(n)&&n>MAX_BODY)return json({error:'body too large'},413);
  let body;
  try{const raw=await request.text();if(raw.length>MAX_BODY)return json({error:'body too large'},413);body=JSON.parse(raw)}catch{return json({error:'invalid JSON'},400)}
  if(!body||typeof body!=='object'||Array.isArray(body)||body.jsonrpc!=='2.0'||typeof body.method!=='string')return json({error:'invalid request'},400);
  const id=body.id;
  if(body.method.startsWith('notifications/')&&id===undefined)return new Response(null,{status:202,headers:{'Cache-Control':'no-store'}});
  if(!(typeof id==='string'||typeof id==='number'&&!Number.isNaN(id)))return json({error:'missing id'},400);
  const p=body.params||{};
  if(!p||typeof p!=='object'||Array.isArray(p)||!validMeta(p._meta))return json(err(id,-32602,'invalid request metadata'),400);
  if(request.headers.get('Mcp-Method')!==body.method)return json(err(id,-32602,'method header mismatch'),400);
  if(body.method==='server/discover')return reply(id,{supportedVersions:[VERSION],capabilities:{tools:{listChanged:false}},instructions:'Private AppleRAVEN: every operation requires an authorized identity and grants.'});
  if(body.method==='tools/list')return reply(id,{tools:TOOL_LIST,ttlMs:0,cacheScope:'private'});
  if(body.method!=='tools/call')return json(err(id,-32601,'method not found'),404);
  if(request.headers.get('Mcp-Name')!==p.name)return json(err(id,-32602,'tool header mismatch'),400);
  if(typeof p.name!=='string'||!TOOL_LIST.some(t=>t.name===p.name))return json(err(id,-32601,'tool unavailable'),404);
  const args=p.arguments||{};
  if(!args||typeof args!=='object'||Array.isArray(args))return json(err(id,-32602,'invalid arguments'),400);
  let result;
  if(p.name==='appleraven.nodes.status'){
    if(Object.keys(args).length)return json(err(id,-32602,'unexpected arguments'),400);
    const state=await visibleState(env,Date.now(),user); // original grant-filtered state
    const nodes=(state.nodes||[]).filter(x=>granted(x.node_id)).map(x=>({node_id:x.node_id,online:x.online,age_s:x.age_s,meta:x.meta,state:x.state}));
    result={nodes,available_devices:nodes.length};
  }else{
    if(Object.keys(args).length!==1||typeof args.id!=='string'||!/^act_[a-f0-9]{20}$/.test(args.id))return json(err(id,-32602,'invalid action identifier'),400);
    const record=await env.DB.prepare('SELECT id,node_id,capability,status,created_at,completed_at,result FROM actions WHERE id=?1').bind(args.id).first();
    if(!record||!granted(record.node_id,record.capability)||!allowed(user,record.node_id,record.capability,false))return json(err(id,-32004,'not found'),404);
    result={id:record.id,node_id:record.node_id,capability:record.capability,status:record.status,created_at:record.created_at,completed_at:record.completed_at,result:record.result?JSON.parse(record.result):null};
  }
  return reply(id,success(result));
}
