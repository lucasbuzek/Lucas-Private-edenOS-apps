/**
 * AppleRAVEN separate device-ingress CANDIDATE, not the Access-protected owner
 * MCP. Public enrollment is one-time challenge gated; actual permission is
 * granted ONLY by the existing owner Access MCP. Rate-limit /v1/pair/start
 * on Cloudflare before deployment. No generic shell, file or desktop tools.
 */
const MAX=2048,TTL=600000,LIMIT=40;
const RESP={'content-type':'application/json','cache-control':'no-store','x-content-type-options':'nosniff'};
const json=(v,s=200)=>new Response(JSON.stringify(v),{status:s,headers:RESP});
const alphabet='ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
function hex(n){return[...crypto.getRandomValues(new Uint8Array(n))].map(x=>x.toString(16).padStart(2,'0')).join('')}
function code(){return[...crypto.getRandomValues(new Uint8Array(12))].map(n=>alphabet[n%alphabet.length]).join('')}
async function sha(s){return[...new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(s)))].map(x=>x.toString(16).padStart(2,'0')).join('')}
async function body(req){if((req.headers.get('content-type')||'').split(';')[0].trim()!=='application/json')throw Error('content-type');if(Number(req.headers.get('content-length')||0)>MAX)throw Error('size');const raw=await req.text();if(raw.length>MAX)throw Error('size');const val=JSON.parse(raw);if(!val||typeof val!=='object'||Array.isArray(val))throw Error('object');return val}
const h64=s=>typeof s==='string'&&/^[a-f0-9]{64}$/.test(s);
const pairId=s=>typeof s==='string'&&/^pair_[a-f0-9]{32}$/.test(s);
async function device(req,env){
 const h=req.headers.get('authorization')||'';
 if(!h.startsWith('Bearer ')||!h64(h.slice(7)))return null;
 const hashed=await sha(h.slice(7));
 return env.DB.prepare("SELECT id,name FROM devices WHERE credential_sha256=?1 AND revoked_at IS NULL AND kind='device'").bind(hashed).first();
}
async function granted(env,id){
 const row=await env.DB.prepare("SELECT COUNT(1) AS n FROM grants WHERE device_id=?1 AND capability='shortcuts.list' AND revoked_at IS NULL").bind(id).first();
 return Number(row?.n)>0;
}
export default {async fetch(request,env){
 const p=new URL(request.url).pathname,now=Date.now();
 if(p==='/health'&&request.method==='GET')return json({service:'AppleRAVEN device bridge',stage:'candidate',online_mac_not_implied:true});
 if(request.method!=='POST'||!p.startsWith('/v1/'))return json({error:'not_found'},404);
 if(request.headers.get('origin'))return json({error:'browser_origin_denied'},403);
 let b;try{b=await body(request)}catch{return json({error:'invalid_request'},400)}
 try{
  if(p==='/v1/pair/start'){
   if(!h64(b.challenge)||typeof b.device_name!=='string'||!b.device_name.trim()||b.device_name.length>64)return json({error:'invalid_challenge'},400);
   const row=await env.DB.prepare('SELECT COUNT(*) AS n FROM appleraven_pair_challenges WHERE expires_at>?1 AND redeemed_at IS NULL').bind(now).first();
   if(Number(row?.n)>=LIMIT)return json({error:'pairing_temporarily_full'},429);
   const id='pair_'+hex(16),c=code();
   await env.DB.prepare('INSERT INTO appleraven_pair_challenges(id,code_hash,client_proof,device_name,created_at,expires_at) VALUES(?1,?2,?3,?4,?5,?6)').bind(id,await sha(c),b.challenge,b.device_name.trim().slice(0,64),now,now+TTL).run();
   return json({request_id:id,code:c,expires_in:600,verification_url:'https://appleraven-private.lucasravensnest.workers.dev/pair'});
  }
  if(p==='/v1/pair/status'){
   if(!pairId(b.request_id)||!h64(b.client_secret))return json({error:'unauthorized'},401);
   const row=await env.DB.prepare('SELECT * FROM appleraven_pair_challenges WHERE id=?1').bind(b.request_id).first();
   if(!row||row.client_proof!==await sha(b.client_secret))return json({error:'unauthorized'},401);
   if(row.expires_at<now)return json({status:'expired'},410);
   if(!row.approved_by)return json({status:'pending'});
   if(row.redeemed_at)return json({status:'revoked'},410);
   const id='mac_'+hex(12),token=hex(32),hashed=await sha(token);
   const m=await env.DB.prepare('UPDATE appleraven_pair_challenges SET redeemed_at=?1,device_id=?2 WHERE id=?3 AND redeemed_at IS NULL AND approved_by IS NOT NULL AND expires_at>=?1').bind(now,id,row.id).run();
   if(m.meta?.changes!==1)return json({status:'revoked'},410);
   try{await env.DB.batch([
     env.DB.prepare("INSERT INTO devices(id,name,kind,credential_sha256,created_by,created_at) VALUES(?1,?2,'device',?3,?4,?5)").bind(id,row.device_name,hashed,row.approved_by,now),
     env.DB.prepare("INSERT INTO grants(id,user_id,device_id,capability,created_at,created_by) VALUES(?1,?2,?3,'shortcuts.list',?4,?5)").bind('gr_'+hex(12),row.approved_by,id,now,row.approved_by)
   ])}catch{return json({error:'enrollment_transaction_failed'},503)}
   return json({status:'approved',device_token:token,device_id:id});
  }
  if(!['/v1/device/state','/v1/device/next','/v1/device/result'].includes(p))return json({error:'not_found'},404);
  const d=await device(request,env);if(!d||!await granted(env,d.id))return json({error:'unauthorized'},401);
  if(p==='/v1/device/state'){
   if(typeof b.hostname!=='string'||typeof b.os!=='string'||!Array.isArray(b.capabilities)||!b.capabilities.every(x=>x==='shortcuts.list'))return json({error:'invalid_state'},400);
   const meta=JSON.stringify({hostname:b.hostname.slice(0,64),os:b.os.slice(0,25),agent:String(b.agent||'').slice(0,24)});
   const state=JSON.stringify({capabilities:{'shortcuts.list':{available:b.capabilities.includes('shortcuts.list')}}});
   await env.DB.prepare('INSERT INTO node_state(node_id,meta,state,updated_at) VALUES(?1,?2,?3,?4) ON CONFLICT(node_id) DO UPDATE SET meta=excluded.meta,state=excluded.state,updated_at=excluded.updated_at').bind(d.id,meta,state,now).run();
   return json({ok:true,online:true});
  }
  if(p==='/v1/device/next'){
   const item=await env.DB.prepare("SELECT id,capability FROM actions WHERE node_id=?1 AND status='queued' AND created_at>?2 AND capability='shortcuts.list' ORDER BY created_at LIMIT 1").bind(d.id,now-120000).first();
   if(!item)return json({action:null});
   const claimed=await env.DB.prepare("UPDATE actions SET status='claimed',claimed_at=?1 WHERE id=?2 AND status='queued'").bind(now,item.id).run();
   if(claimed.meta?.changes!==1)return json({action:null});
   return json({id:item.id,capability:'shortcuts.list'});
  }
  if(p==='/v1/device/result'){
   if(typeof b.id!=='string'||!/^act_[a-f0-9]{20}$/.test(b.id)||typeof b.ok!=='boolean'||!b.result||typeof b.result!=='object')return json({error:'invalid_result'},400);
   const output=JSON.stringify(b.result).slice(0,3500);
   const done=await env.DB.prepare("UPDATE actions SET status=?1,completed_at=?2,result=?3 WHERE id=?4 AND node_id=?5 AND status='claimed' AND capability='shortcuts.list'").bind(b.ok?'succeeded':'failed',now,output,b.id,d.id).run();
   if(done.meta?.changes!==1)return json({error:'invalid_action_state'},409);
   return json({ok:true});
  }
 }catch{return json({error:'backend_unavailable'},503)}
 return json({error:'not_found'},404);
}};