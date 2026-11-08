import {authorize,json} from "../../_lib/auth.js";
export async function onRequestGet(context){const r=await authorize(context);if(r.error)return r.error;return json({account:r.user.email,display_name:r.user.name,role:r.user.role,storage:"D1 personal workspace",features:["apps","tasks","notes","text documents"],authenticated:true})}
