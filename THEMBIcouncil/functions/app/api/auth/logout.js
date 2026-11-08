import {json,exactOrigin,rawToken,digestToken,clearSession} from "../../../_lib/auth.js";
export async function onRequestPost(context){
 if(!exactOrigin(context.request))return json({error:"invalid_request_origin"},403);
 const token=rawToken(context.request);
 if(token&&context.env.COUNCIL_DB){const digest=await digestToken(token);await context.env.COUNCIL_DB.prepare("DELETE FROM council_sessions WHERE token_hash=?1").bind(digest).run()}
 return json({signed_out:true},200,{"Set-Cookie":clearSession()});
}
