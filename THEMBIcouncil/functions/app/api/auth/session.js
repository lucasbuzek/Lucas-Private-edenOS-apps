import {json,exactOrigin,digestToken,issueSession,roleFor,sessionToken} from "../../../_lib/auth.js";
function validSupabase(url){try{const u=new URL(url);return u.protocol==="https:"&&/^[a-z0-9-]+\.supabase\.co$/.test(u.hostname)&&u.pathname==="/" ?u.origin:null}catch{return null}}
export async function onRequestPost(context){
 const {request,env}=context;
 if(!exactOrigin(request))return json({error:"invalid_request_origin"},403);
 if(env.COUNCIL_PRODUCT_AUTH!=="enabled"||!env.COUNCIL_DB)return json({error:"product_auth_not_ready"},503);
 const base=validSupabase(String(env.SUPABASE_URL||"")),apikey=String(env.SUPABASE_ANON_KEY||"");
 if(!base||!apikey)return json({error:"identity_provider_not_configured"},503);
 if(Number(request.headers.get("Content-Length")||0)>16000)return json({error:"invalid_token"},400);
 let token;try{const body=await request.json();token=body?.access_token}catch{return json({error:"invalid_request"},400)}
 if(typeof token!=="string"||token.length<80||token.length>12000)return json({error:"invalid_token"},400);
 let result;try{result=await fetch(base+"/auth/v1/user",{headers:{apikey,Authorization:"Bearer "+token,Accept:"application/json"},redirect:"error"})}catch{return json({error:"identity_unavailable"},503)}
 if(!result.ok)return json({error:"identity_verification_failed"},401);
 let user;try{user=await result.json()}catch{return json({error:"identity_response_invalid"},503)}
 const email=String(user?.email||"").trim().toLowerCase(),subject=String(user?.id||"");
 if(!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)||!subject||!user?.email_confirmed_at)return json({error:"verified_account_required"},403);
 const providers=Array.isArray(user?.app_metadata?.providers)?user.app_metadata.providers:[user?.app_metadata?.provider].filter(Boolean);
 const provider=providers.includes("google")?"google":providers.includes("apple")?"apple":null;
 if(!provider)return json({error:"google_or_apple_sign_in_required"},403);
 const role=roleFor(email,env);if(!role)return json({error:"not_invited"},403);
 const plain=sessionToken(),tokenHash=await digestToken(plain),ts=Date.now(),exp=ts+604800000;
 await env.COUNCIL_DB.prepare("INSERT INTO council_sessions(token_hash,email,subject,provider,expires_at,created_at) VALUES(?1,?2,?3,?4,?5,?6)").bind(tokenHash,email,subject,provider,exp,ts).run();
 return json({ok:true,role,email,expires_at:exp},200,{"Set-Cookie":issueSession(plain)});
}
