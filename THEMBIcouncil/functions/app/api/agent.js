import {authorize,json} from "../../_lib/auth.js";

// Nanobot's session_id separates conversations, NOT users or tool permissions.
// Each Council principal MUST have a physically separate agent instance/API origin.
const PERSONAS=new Set(["Heartbi","Fitbi","Dreambi","Bossbi","Roambi","Storybi","SexyBi","Terry"]);
function endpoint(value) {
  try {
    const u=new URL(String(value||""));
    if(u.protocol!=="https:"||u.username||u.password||u.search||u.hash||u.pathname!=="/v1/chat/completions")return null;
    if(!/^[a-z0-9-]+(?:\.[a-z0-9-]+)+$/i.test(u.hostname)||u.hostname.endsWith(".local")||u.hostname==="localhost")return null;
    return u;
  } catch {return null}
}
async function sessionKey(user,persona){
  const data=new TextEncoder().encode("THEMBIcouncil:"+user.subject+":"+persona);
  const digest=await crypto.subtle.digest("SHA-256",data);
  return "tc_"+[...new Uint8Array(digest)].map(x=>x.toString(16).padStart(2,"0")).join("").slice(0,40);
}
export async function onRequestGet() { return json({error:"method_not_allowed"},405,{"Allow":"POST"}); }
export async function onRequestHead() { return new Response(null,{status:405,headers:{"Allow":"POST","Cache-Control":"no-store"}}); }
export async function onRequestPost(context) {
  const access=await authorize(context);
  if(access.error)return access.error;
  const user=access.user,env=context.env;
  let raw;
  try {
    raw=await context.request.text();
    if(new TextEncoder().encode(raw).length>9000)return json({error:"request_too_large"},413);
  }catch{return json({error:"invalid_request"},400)}
  let b;
  try{b=JSON.parse(raw)}catch{return json({error:"invalid_json"},400)}
  const message=b?.message,persona=b?.persona||"Heartbi";
  if(typeof message!=="string"||!message.trim()||message.length>4000||!PERSONAS.has(persona))return json({error:"invalid_message_or_persona"},400);
  if(persona==="SexyBi"&&user.role!=="owner_admin")return json({error:"persona_owner_only"},403);
  const own=user.role==="owner_admin"?"THEMBI":"LUCAS",other=own==="THEMBI"?"LUCAS":"THEMBI";
  const url=endpoint(env[own+"_AGENT_URL"]),otherUrl=endpoint(env[other+"_AGENT_URL"]);
  const token=String(env[own+"_AGENT_KEY"]||"");
  if(!url||token.length<24||env[own+"_AGENT_TYPE"]!=="nanobot")return json({error:"agent_runtime_not_connected"},503);
  // Do not allow two people to use a shared nanobot workspace, even with different session IDs.
  if(otherUrl&&otherUrl.origin===url.origin)return json({error:"agent_isolation_not_configured"},503);
  const payload={messages:[{role:"user",content:message}],session_id:await sessionKey(user,persona),stream:false};
  let response;
  try{
    response=await fetch(url.href,{method:"POST",headers:{"Content-Type":"application/json","Accept":"application/json","Authorization":"Bearer "+token},body:JSON.stringify(payload),redirect:"error",signal:AbortSignal.timeout(50000)});
  }catch{return json({error:"agent_unavailable_result_unknown_do_not_retry_side_effects"},503)}
  if(!response.ok)return json({error:"agent_upstream_error",upstream_status:response.status},502);
  let data;
  try {
    const text=await response.text();
    if(text.length>180000)return json({error:"agent_response_too_large"},502);
    data=JSON.parse(text);
  }catch{return json({error:"agent_invalid_response"},502)}
  const reply=data?.choices?.[0]?.message?.content;
  if(typeof reply!=="string"||!reply.trim())return json({error:"agent_missing_response"},502);
  return json({reply:reply.slice(0,20000),persona,source:"nanobot",action_verification:"check_individual_MCP_job_receipts"});
}
