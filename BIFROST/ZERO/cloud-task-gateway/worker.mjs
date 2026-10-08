// BIFROST ZERO cloud-only task gateway. Deploy as Cloudflare Worker.
// Required secrets: GITHUB_TOKEN (fine-grained issues:write/read), GATEWAY_TOKEN.
// Required vars: GITHUB_OWNER, GITHUB_REPO, ALLOWED_ORIGIN.
// Does NOT claim to invoke Codex Cloud: executor integration is separately gated.
const reply=(data,status=200,origin="")=>new Response(JSON.stringify(data),{status,headers:{"content-type":"application/json","cache-control":"no-store","access-control-allow-origin":origin,"vary":"Origin"}});
const validRepo=s=>/^[a-zA-Z0-9_.-]+$/.test(s||"");
export default {async fetch(request,env){
 const origin=request.headers.get("Origin")||"";
 const allowed=env.ALLOWED_ORIGIN||"";
 if(request.method==="OPTIONS") return new Response(null,{status:204,headers:{"access-control-allow-origin":origin===allowed?origin:"","access-control-allow-methods":"GET,POST,OPTIONS","access-control-allow-headers":"Authorization,Content-Type","vary":"Origin"}});
 if(origin!==allowed||!allowed) return reply({error:"origin_denied"},403);
 if(!env.GATEWAY_TOKEN||request.headers.get("Authorization")!==`Bearer ${env.GATEWAY_TOKEN}`) return reply({error:"unauthorized"},401,origin);
 if(!validRepo(env.GITHUB_OWNER)||!validRepo(env.GITHUB_REPO)||!env.GITHUB_TOKEN) return reply({error:"configuration_missing"},503,origin);
 const url=new URL(request.url),root=`https://api.github.com/repos/${env.GITHUB_OWNER}/${env.GITHUB_REPO}`;
 const github=async(path,options={})=>{const r=await fetch(root+path,{...options,headers:{"Accept":"application/vnd.github+json","Authorization":`Bearer ${env.GITHUB_TOKEN}`,"X-GitHub-Api-Version":"2022-11-28","User-Agent":"bifrost-zero-gateway",...(options.headers||{})}});const body=await r.json().catch(()=>({}));return {status:r.status,body};};
 if(request.method==="POST"&&url.pathname==="/tasks"){
  let input;try{input=await request.json()}catch{return reply({error:"invalid_json"},400,origin)}
  if(typeof input?.title!=="string"||typeof input?.instruction!=="string"||input.title.length<3||input.title.length>120||input.instruction.length<10||input.instruction.length>16000) return reply({error:"invalid_task"},400,origin);
  const result=await github("/issues",{method:"POST",body:JSON.stringify({title:"[BIFROST ZERO] "+input.title,body:"## Requested task\n\n"+input.instruction+"\n\n## Execution\nStatus: QUEUED_FOR_EXECUTOR — Codex execution is NOT connected.\nSource: authorized PWA gateway.",labels:[]})});
  return reply(result.status===201?{id:result.body.number,url:result.body.html_url,status:"QUEUED_FOR_EXECUTOR"}:{error:"github_failed",details:result.body.message},result.status===201?201:502,origin);
 }
 const match=url.pathname.match(/^\/tasks\/(\d+)$/);
 if(request.method==="GET"&&match){const result=await github("/issues/"+match[1]);return reply(result.status===200?{id:result.body.number,title:result.body.title,url:result.body.html_url,state:result.body.state,status:"QUEUED_FOR_EXECUTOR",note:"GitHub issue state is not Codex execution state"}:{error:"not_found"},result.status===200?200:404,origin);}
 return reply({error:"not_found"},404,origin);
}};