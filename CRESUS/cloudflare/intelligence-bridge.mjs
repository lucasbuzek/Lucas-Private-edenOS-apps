// CRESUS provider-choice command bridge candidate.
// Mount in the existing authenticated Cloudflare Worker; do not expose as a public route.
// The caller MUST authenticate the CRESUS user and supply userId from a verified session.
// No ChatGPT subscription credentials or unsupported Codex endpoints are accepted.
const json=(value,status=200)=>new Response(JSON.stringify(value),{status,headers:{"content-type":"application/json","cache-control":"no-store"}});
const providers=new Set(["codex_cloud","workers_ai","external"]);
const actions=new Set(["research","compare","analyze","summarize"]);
const MAX_PROMPT=12000;
export function validateCommand(value){
 if(!value||typeof value!=="object"||Array.isArray(value))throw Error("invalid_command");
 const {action,instruction}=value;
 if(!actions.has(action)||typeof instruction!=="string"||instruction.trim().length<8||instruction.length>MAX_PROMPT)throw Error("invalid_command");
 return {action,instruction:instruction.trim()};
}
export function validateProvider(value){
 if(!providers.has(value))throw Error("unsupported_provider");
 return value;
}
export function normalizeResult(provider,body){
 return {provider,status:"completed",output:body,completedAt:new Date().toISOString()};
}
// A command is created by the caller's intent parser, or by Workers AI with a strict JSON schema.
// Never execute model-generated arbitrary URLs, HTTP methods, shell commands, or financial trades.
export async function dispatchCresusCommand({userId,provider,command,env,sessionProvider}){
 if(typeof userId!=="string"||!userId.trim())return json({error:"unauthenticated"},401);
 try{provider=validateProvider(provider);command=validateCommand(command);}catch(e){return json({error:e.message},400);}
 if(provider!==sessionProvider)return json({error:"provider_not_authorized_for_user"},403);
 if(provider==="codex_cloud"){
   // No supported subscription-account task submission endpoint has been verified.
   // Fail closed rather than silently creating a GitHub issue or charging API credits.
   return json({error:"codex_cloud_connector_unverified",status:"NOT_DISPATCHED",retryable:false},501);
 }
 if(provider==="workers_ai"){
   if(!env?.AI||!env?.CRESUS_WORKERS_AI_MODEL)return json({error:"workers_ai_not_configured"},503);
   try{
     const response=await env.AI.run(env.CRESUS_WORKERS_AI_MODEL,{messages:[
       {role:"system",content:"You are a CRESUS research assistant. Never claim real-time market data without sourced evidence. Never execute trades. Identify unknowns explicitly."},
       {role:"user",content:command.instruction}
     ]});
     return json(normalizeResult(provider,response));
   }catch{return json({error:"provider_execution_failed"},502);}
 }
 // External providers require a separately audited, allowlisted adapter, never a user-supplied URL.
 return json({error:"external_provider_not_configured",status:"NOT_DISPATCHED"},501);
}
export const CRESUS_PROVIDER_OPTIONS=[
 {id:"codex_cloud",label:"Codex Cloud",connection:"unverified",selectable:false},
 {id:"workers_ai",label:"Cloudflare Workers AI",connection:"requires_configuration",selectable:true},
 {id:"external",label:"Other AI provider",connection:"requires_adapter",selectable:false}
];
// UI: first-login selection can be skipped; Settings can change provider.
// Store provider per authenticated user, server-side. Do not store tokens in localStorage.
// Only invoke dispatchCresusCommand with the provider read from the user's server-side record.
