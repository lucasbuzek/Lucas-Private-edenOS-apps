import {json,exactOrigin,digestToken,issueSession,roleFor,sessionToken} from "../_lib/auth.js";
function validBase(input){try{const url=new URL(String(input));return url.protocol==="https:"&&/^[a-z0-9-]+\.supabase\.co$/.test(url.hostname)&&url.pathname==="/"?url.origin:null}catch{return null}}
export async function onRequestPost(context){
 const {request,env}=context;
 if(!exactOrigin(request))return json({error:"invalid_request_origin"},403);
 if(env.COUNCIL_PRODUCT_AUTH!=="enabled"||!env.COUNCIL_DB)return json({error:"login_not_configured"},503);
 const url=validBase(env.SUPABASE_URL),apiKey=String(env.SUPABASE_ANON_KEY||"");
 if(!url||!apiKey)return json({error:"login_not_configured"},503);
 if(Number(request.headers.get("Content-Length")||0)>10000)return json({error:"invalid_code"},400);
 let input;try{input=await request.json()}catch{return json({error:"invalid_request"},400)}
 const code=String(input?.code||""),verifier=String(input?.code_verifier||"");
 if(!/^[a-zA-Z0-9_-]{16,4096}$/.test(code)||!/^[a-zA-Z0-9_-]{43,128}$/.test(verifier))return json({error:"invalid_code"},400);
 let exchanged;try{exchanged=await fetch(url+"/auth/v1/token?grant_type=pkce",{method:"POST",headers:{"Content-Type":"application/json",apikey:apiKey},body:JSON.stringify({auth_code:code,code_verifier:verifier}),redirect:"error"})}catch{return json({error:"identity_provider_unavailable"},503)}
 if(!exchanged.ok)return json({error:"login_code_rejected"},401);
 let session;try{session=await exchanged.json()}catch{return json({error:"invalid_provider_response"},503)}
 const accessToken=session?.access_token;
 if(typeof accessToken!=="string"||accessToken.length<80||accessToken.length>15000)return json({error:"invalid_provider_token"},503);
 let verified;try{verified=await fetch(url+"/auth/v1/user",{headers:{apikey:apiKey,Authorization:"Bearer "+accessToken,Accept:"application/json"},redirect:"error"})}catch{return json({error:"identity_verification_unavailable"},503)}
 if(!verified.ok)return json({error:"identity_verification_failed"},401);
 let user;try{user=await verified.json()}catch{return json({error:"identity_response_invalid"},503)}
 const email=String(user?.email||"").toLowerCase().trim(),subject=String(user?.id||"");
 if(!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)||!subject||!user?.email_confirmed_at)return json({error:"verified_email_required"},403);
 const providers=Array.isArray(user?.app_metadata?.providers)?user.app_metadata.providers:[user?.app_metadata?.provider].filter(Boolean);
 const provider=providers.includes("google")?"google":providers.includes("apple")?"apple":null;
 if(!provider)return json({error:"google_or_apple_login_required"},403);
 const role=roleFor(email,env);if(!role)return json({error:"account_not_invited"},403);
 const token=sessionToken(),digest=await digestToken(token),created=Date.now(),expires=created+604800000;
 await env.COUNCIL_DB.prepare("INSERT INTO council_sessions(token_hash,email,subject,provider,expires_at,created_at) VALUES(?1,?2,?3,?4,?5,?6)").bind(digest,email,subject,provider,expires,created).run();
 return json({ok:true,role,email,expires_at:expires},200,{"Set-Cookie":issueSession(token)});
}
