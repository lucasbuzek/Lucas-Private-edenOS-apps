/**
 * AppleRAVEN additive signed-Access OWNER-only pairing and two bounded native
 * Shortcuts tools. Caller must verify Cloudflare Access JWT and getOwner first.
 */
export const PAIR_TOOLS=Object.freeze([
{name:'appleraven.shortcuts.list',title:'List Mac Shortcuts',description:'Queue read-only Shortcuts listing on an already enrolled online Mac.',inputSchema:{type:'object',properties:{device_id:{type:'string',pattern:'^mac_[a-f0-9]{24}$'}},required:['device_id'],additionalProperties:false},annotations:{readOnlyHint:false,destructiveHint:false,openWorldHint:false}},
{name:'appleraven.actions.status',title:'Read my Mac action',description:'Read an action result submitted by this authenticated owner.',inputSchema:{type:'object',properties:{id:{type:'string',pattern:'^act_[a-f0-9]{20}$'}},required:['id'],additionalProperties:false},annotations:{readOnlyHint:true,destructiveHint:false,openWorldHint:false}}
]);
const H={'cache-control':'no-store','x-content-type-options':'nosniff'};
const json=(v,s=200)=>new Response(JSON.stringify(v),{status:s,headers:{'content-type':'application/json',...H}});
const sha=async s=>[...new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(s)))].map(x=>x.toString(16).padStart(2,'0')).join('');
const random=n=>[...crypto.getRandomValues(new Uint8Array(n))].map(x=>x.toString(16).padStart(2,'0')).join('');
const CODE=/^[A-HJ-NP-Z2-9]{12}$/,DEVICE=/^mac_[a-f0-9]{24}$/,ACTION=/^act_[a-f0-9]{20}$/;
const page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,nofollow"><title>AppleRAVEN — Pair my Mac</title><style>body{max-width:600px;margin:8vh auto;padding:20px;font:16px system-ui;background:#111821;color:#f7f7f3}input,button{font:inherit;padding:12px;border-radius:8px}input{display:block;width:95%;background:#0e1922;color:white;border:1px solid #789}button{background:#45667a;color:white;margin-top:15px}p{line-height:1.5}</style><h1>AppleRAVEN — Pair my Mac</h1><p>Owner only. Enter the code from your Mac. This grants Shortcuts listing and permission for the Mac to advertise installed, existing MCP providers. Provider calls (including Terminal, files, Mail, desktop and Xcode if you install those MCPs) require local Mac approval before execution. Sign in with the existing AppleRAVEN Cloudflare Access identity.</p><label for="code">Mac pairing code</label><input id="code" maxlength="12" autocomplete="off" autocapitalize="characters" spellcheck="false"><button id="approve">Approve Mac + MCP providers</button><p role="status" id="status"></p><script>document.getElementById("approve").onclick=async()=>{const c=document.getElementById("code").value.trim().toUpperCase(),s=document.getElementById("status");s.textContent="Checking…";try{const r=await fetch("/pair/approve",{method:"POST",headers:{"content-type":"application/json","x-appleraven-pairing":"owner-approve"},body:JSON.stringify({code:c}),credentials:"same-origin"});s.textContent=r.ok?"Approved. Finish setup on your Mac.":"Not approved. Check code and owner login."}catch{s.textContent="Connection failed. No pairing occurred."}}</script></html>';
export async function handleOwnerPair(request,env,owner){
 const url=new URL(request.url);
 if(url.pathname==='/pair'&&request.method==='GET')return new Response(page,{headers:{'content-type':'text/html; charset=utf-8','content-security-policy':"default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; connect-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",...H}});
 if(url.pathname!=='/pair/approve'||request.method!=='POST')return json({error:'not_found'},404);
 if(request.headers.get('origin')!==url.origin||request.headers.get('x-appleraven-pairing')!=='owner-approve'||(request.headers.get('content-type')||'').split(';')[0]!=='application/json')return json({error:'forbidden'},403);
 if(Number(request.headers.get('content-length')||0)>300)return json({error:'invalid_request'},400);
 let b;try{const t=await request.text();if(t.length>300)throw Error('size');b=JSON.parse(t)}catch{return json({error:'invalid_request'},400)}
 const code=String(b?.code||'').trim().toUpperCase();if(!CODE.test(code))return json({error:'invalid_code'},400);
 const now=Date.now();
 try{
  const row=await env.DB.prepare('SELECT id FROM appleraven_pair_challenges WHERE code_hash=?1 AND approved_by IS NULL AND redeemed_at IS NULL AND expires_at>=?2').bind(await sha(code),now).first();
  if(!row)return json({error:'code_expired_or_unknown'},404);
  const update=await env.DB.prepare('UPDATE appleraven_pair_challenges SET approved_by=?1,approved_at=?2 WHERE id=?3 AND approved_by IS NULL AND redeemed_at IS NULL AND expires_at>=?2').bind(owner.id,now,row.id).run();
  if(update.meta?.changes!==1)return json({error:'code_already_used'},409);
  return json({approved:true});
 }catch{return json({error:'pairing_store_unavailable'},503)}
}
async function access(env,owner,deviceId){
 if(!DEVICE.test(deviceId))return false;
 const row=await env.DB.prepare("SELECT d.id,n.updated_at FROM devices d INNER JOIN grants g ON g.device_id=d.id LEFT JOIN node_state n ON n.node_id=d.id WHERE d.id=?1 AND d.revoked_at IS NULL AND g.user_id=?2 AND g.capability='shortcuts.list' AND g.revoked_at IS NULL LIMIT 1").bind(deviceId,owner.id).first();
 return Boolean(row&&Number(row.updated_at)>0&&Date.now()-row.updated_at<90000);
}
export async function queueShortcuts(env,owner,deviceId){
 if(!await access(env,owner,deviceId))return{error:'device_offline_or_not_granted',status:403};
 const r=await env.DB.prepare("SELECT COUNT(*) AS n FROM actions WHERE node_id=?1 AND capability='shortcuts.list' AND status IN ('queued','claimed') AND created_at>?2").bind(deviceId,Date.now()-600000).first();
 if(Number(r?.n)>0)return{error:'another_action_pending',status:429};
 const id='act_'+random(10),now=Date.now();
 await env.DB.prepare("INSERT INTO actions(id,node_id,capability,params,status,origin,created_at) VALUES(?1,?2,'shortcuts.list','{}','queued',?3,?4)").bind(id,deviceId,JSON.stringify({owner_id:owner.id}),now).run();
 return{id,device_id:deviceId,status:'queued',capability:'shortcuts.list'};
}
export async function readAction(env,owner,id){
 if(!ACTION.test(id))return{error:'invalid_action',status:400};
 const row=await env.DB.prepare('SELECT a.id,a.node_id,a.capability,a.status,a.result,a.origin,a.created_at,a.completed_at,d.revoked_at FROM actions a INNER JOIN devices d ON d.id=a.node_id WHERE a.id=?1').bind(id).first();
 if(!row||row.revoked_at||row.capability!=='shortcuts.list')return{error:'not_found',status:404};
 let actor=null;try{actor=JSON.parse(row.origin)}catch{}
 const g=await env.DB.prepare("SELECT COUNT(*) AS n FROM grants WHERE user_id=?1 AND device_id=?2 AND capability='shortcuts.list' AND revoked_at IS NULL").bind(owner.id,row.node_id).first();
 if(actor?.owner_id!==owner.id||!g?.n)return{error:'not_found',status:404};
 return{id:row.id,status:row.status,created_at:row.created_at,completed_at:row.completed_at,result:row.result?JSON.parse(row.result):null};
}
