import {authorize,json} from "../../_lib/auth.js";

// This is ONE existing FreeLLMAPI router for all Council principals.
// Per-client keys limit inference access; personal files/memory stay in the
// principal's separate Council application and nanobot agent.
const MODELS=new Set(["auto","auto:smart","auto:fast","auto:balanced","auto:reliable","fusion","qwen3.8-27b","qwen3.6-27b","qwen3.5-397b","qwen3.5-9b","mistral-small-3.2-24b","gpt-oss-120b","gpt-oss-20b","llama-3.3-70b"]);
function gateway(value){
  try{
    const u=new URL(String(value||""));
    if(u.protocol!=="https:"||u.username||u.password||u.search||u.hash||u.pathname!=="/v1/chat/completions")return null;
    if(!/^[a-z0-9-]+(?:\.[a-z0-9-]+)+$/i.test(u.hostname)||u.hostname==="localhost"||u.hostname.endsWith(".local"))return null;
    return u.href;
  }catch{return null}
}
function keyFor(user,env){
  const p=user.role==="owner_admin"?"THEMBI":"LUCAS";
  const key=String(env[p+"_FREELLMAPI_CLIENT_KEY"]||"");
  // Require a per-client inference credential, never the unified admin key.
  return /^sk-cp-[a-f0-9]{48}$/.test(key)?key:null;
}
export async function onRequestGet(){return json({error:"method_not_allowed"},405,{"Allow":"POST"});}
export async function onRequestHead(){return new Response(null,{status:405,headers:{"Allow":"POST","Cache-Control":"no-store"}});}
export async function onRequestPost(context){
  const access=await authorize(context);
  if(access.error)return access.error;
  const env=context.env,url=gateway(env.FREELLMAPI_GATEWAY_URL),key=keyFor(access.user,env);
  if(!url||!key)return json({error:"shared_router_client_not_connected"},503);
  let text;
  try{text=await context.request.text();if(new TextEncoder().encode(text).length>6500)return json({error:"request_too_large"},413);}
  catch{return json({error:"invalid_request"},400)}
  let body;try{body=JSON.parse(text)}catch{return json({error:"invalid_json"},400)}
  const message=body?.message,model=body?.model||"auto";
  if(typeof message!=="string"||!message.trim()||message.length>4000||typeof model!=="string"||!MODELS.has(model))
    return json({error:"invalid_message_or_model"},400);
  const payload={
    model,
    messages:[
      {role:"system",content:"You are an AI inference component supporting THEMBIcouncil. Answer the user's question. Do not claim to have accessed private files, performed actions, or used tools unless tool execution receipts are provided. This inference response is not a completed personal-agent task."},
      {role:"user",content:message}
    ],stream:false,max_tokens:1000
  };
  let response;
  try{response=await fetch(url,{method:"POST",headers:{"Content-Type":"application/json","Accept":"application/json","Authorization":"Bearer "+key},body:JSON.stringify(payload),redirect:"error",signal:AbortSignal.timeout(45000)});}
  catch{return json({error:"inference_unavailable"},503)}
  if(!response.ok)return json({error:"router_rejected_request",upstream_status:response.status},502);
  let data;try{
    const raw=await response.text();
    if(raw.length>150000)return json({error:"router_response_too_large"},502);
    data=JSON.parse(raw);
  }catch{return json({error:"invalid_router_response"},502)}
  const answer=data?.choices?.[0]?.message?.content;
  if(typeof answer!=="string"||!answer.trim())return json({error:"router_no_answer"},502);
  return json({reply:answer.slice(0,18000),model:data.model||model,mode:"inference_only",source:"shared_freellmapi",agent_action:false});
}
