// BIFROST cloud routing metadata (staging). No remote executor or shell.
const headers = { "content-type":"application/json; charset=utf-8",
  "cache-control":"no-store", "x-content-type-options":"nosniff" };
const response = (body, status=200) => new Response(JSON.stringify(body), { status, headers });
const fail = (status, code) => response({ok:false,code},status);
const owner = "lucas-owner"; // temporary single-owner identifier; not public identity.
const actionRE = /^[a-z][a-z0-9_.-]{2,127}$/;
const keyRE = /^[A-Za-z0-9_-]{8,64}$/;
const nodeRE = /^[A-Za-z0-9_.-]{2,80}$/;
const idRE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
async function equalToken(a,b) {
  const digest = async s => new Uint8Array(await crypto.subtle.digest(
    "SHA-256",new TextEncoder().encode(s)));
  const [x,y] = await Promise.all([digest(a),digest(b)]);
  let diff=0; for(let i=0;i<x.length;i++) diff |= x[i]^y[i];
  return diff===0;
}
async function authenticate(req,env) {
  if(typeof env.BIFROST_ADMIN_TOKEN!=="string" ||
      env.BIFROST_ADMIN_TOKEN.length<40) return fail(503,"AUTH_NOT_CONFIGURED");
  const h = req.headers.get("authorization") || "";
  const token = h.startsWith("Bearer ") ? h.slice(7) : "";
  if(!token || token.length>256 || !(await equalToken(token,env.BIFROST_ADMIN_TOKEN)))
    return fail(401,"UNAUTHORIZED");
  return null;
}
async function boundedJson(req) {
  if((req.headers.get("content-type")||"").split(";")[0].trim()!=="application/json")
    throw new Error("BAD_CONTENT_TYPE");
  if(!req.body) throw new Error("EMPTY_BODY");
  const reader=req.body.getReader(), dec=new TextDecoder();
  let total=0,body="";
  try {
    while(true) {
      const x=await reader.read();
      if(x.done) break;
      total+=x.value.byteLength;
      if(total>4096) throw new Error("BODY_TOO_LARGE");
      body+=dec.decode(x.value,{stream:true});
    }
    body+=dec.decode();
  } finally { reader.releaseLock(); }
  try{return JSON.parse(body)}catch{throw new Error("INVALID_JSON")}
}
const one=(db,sql,...args)=>db.prepare(sql).bind(...args).first();
async function addTask(db,req) {
  const d=await boundedJson(req);
  if(!d || typeof d!=="object" || Array.isArray(d) ||
     Object.keys(d).sort().join(",")!=="actionId,idempotencyKey,nodeId" ||
     typeof d.actionId!=="string" || !actionRE.test(d.actionId) ||
     typeof d.idempotencyKey!=="string" || !keyRE.test(d.idempotencyKey) ||
     typeof d.nodeId!=="string" || !nodeRE.test(d.nodeId))
    return fail(400,"INVALID_TYPED_REQUEST");
  const cap=await one(db,
    "SELECT c.effect,c.requires_approval FROM cloud_nodes n JOIN cloud_capabilities c ON c.node_id=n.node_id WHERE n.node_id=? AND n.owner_subject=? AND n.trust_state='paired' AND c.action_id=? AND c.implementation_state='verified'",
    d.nodeId,owner,d.actionId);
  if(!cap || cap.effect!=="read" || cap.requires_approval!==0)
    return fail(409,"NODE_CAPABILITY_NOT_VERIFIED");
  const prior=await one(db,
    "SELECT task_id,action_id,target_node_id,state FROM cloud_tasks WHERE owner_subject=? AND idempotency_key=?",
    owner,d.idempotencyKey);
  if(prior) {
    if(prior.action_id!==d.actionId || prior.target_node_id!==d.nodeId)
      return fail(409,"IDEMPOTENCY_CONFLICT");
    return response({ok:true,taskId:prior.task_id,state:prior.state,deduplicated:true});
  }
  const id=crypto.randomUUID(),now=Math.floor(Date.now()/1000);
  const result=await db.prepare("INSERT OR IGNORE INTO cloud_tasks (task_id,owner_subject,action_id,target_node_id,idempotency_key,state,effect,created_at,updated_at,expires_at) VALUES (?,?,?,?,?,'queued','read',?,?,?)")
    .bind(id,owner,d.actionId,d.nodeId,d.idempotencyKey,now,now,now+3600).run();
  if(result.meta?.changes!==1) {
    const retry=await one(db,
      "SELECT task_id,action_id,target_node_id,state FROM cloud_tasks WHERE owner_subject=? AND idempotency_key=?",
      owner,d.idempotencyKey);
    if(!retry || retry.action_id!==d.actionId || retry.target_node_id!==d.nodeId)
      return fail(409,"IDEMPOTENCY_CONFLICT");
    return response({ok:true,taskId:retry.task_id,state:retry.state,deduplicated:true});
  }
  return response({ok:true,taskId:id,state:"queued",remoteExecutionVerified:false,expiresAt:now+3600},202);
}
export default {
  async fetch(request,env) {
    const url=new URL(request.url);
    if(url.pathname==="/health" && request.method==="GET")
      return response({service:"BIFROST",stage:"staging",ready:!!env.DB,
        deviceExecutionAvailable:false});
    const rejected=await authenticate(request,env);
    if(rejected)return rejected;
    if(!env.DB)return fail(503,"D1_BINDING_MISSING");
    try {
      if(url.pathname==="/v1/status" && request.method==="GET") {
        const x=await one(env.DB,
          "SELECT (SELECT count(*) FROM cloud_nodes WHERE trust_state='paired') AS pairedNodes,(SELECT count(*) FROM cloud_tasks WHERE state='queued') AS queuedTasks,(SELECT count(*) FROM cloud_receipts WHERE effects_verified=1) AS verifiedReceipts");
        return response({ok:true,schema:"bifrost.cloud-status.v1",stage:"staging",
          ...x,remoteExecutionVerified:x.verifiedReceipts>0});
      }
      if(url.pathname==="/v1/tasks" && request.method==="POST")
        return await addTask(env.DB,request);
      if(url.pathname==="/v1/tasks" && request.method==="GET") {
        const rows=await env.DB.prepare(
          "SELECT task_id,action_id,target_node_id,state,created_at,expires_at,effects_verified FROM cloud_tasks WHERE owner_subject=? ORDER BY created_at DESC LIMIT 25")
          .bind(owner).all();
        return response({ok:true,tasks:rows.results});
      }
      const match=url.pathname.match(/^\/v1\/tasks\/([^/]+)(?:\/cancel)?$/);
      if(match && idRE.test(match[1])) {
        const id=match[1];
        if(request.method==="GET" && !url.pathname.endsWith("/cancel")) {
          const x=await one(env.DB,
            "SELECT task_id,action_id,target_node_id,state,created_at,expires_at,effects_verified FROM cloud_tasks WHERE task_id=? AND owner_subject=?",id,owner);
          return x?response({ok:true,task:x}):fail(404,"NOT_FOUND");
        }
        if(request.method==="POST" && url.pathname.endsWith("/cancel")) {
          const x=await env.DB.prepare(
            "UPDATE cloud_tasks SET state='cancelled',updated_at=? WHERE task_id=? AND owner_subject=? AND state='queued'")
            .bind(Math.floor(Date.now()/1000),id,owner).run();
          return response({ok:true,cancelled:x.meta?.changes===1});
        }
      }
      return fail(404,"NOT_FOUND");
    } catch(e) {
      const code=e instanceof Error?e.message:"";
      if(["BAD_CONTENT_TYPE","EMPTY_BODY","INVALID_JSON","BODY_TOO_LARGE"].includes(code))
        return fail(code==="BODY_TOO_LARGE"?413:code==="BAD_CONTENT_TYPE"?415:400,code);
      return fail(503,"STAGING_BACKEND_UNAVAILABLE");
    }
  }
};