import {json} from "../_lib/auth.js";
export async function onRequestGet(context){
 const env=context.env;let url=String(env.SUPABASE_URL||"");
 try{const parsed=new URL(url);if(parsed.protocol!=="https:"||!/^[a-z0-9-]+\.supabase\.co$/.test(parsed.hostname))url="";else url=parsed.origin}catch{url=""}
 const key=String(env.SUPABASE_ANON_KEY||"");
 const ready=env.COUNCIL_PRODUCT_AUTH==="enabled"&&!!url&&!!key&&!!env.COUNCIL_DB;
 return json({ready,provider:"supabase",url:ready?url:null,publishable_key:ready?key:null,options:["google","apple"]});
}
