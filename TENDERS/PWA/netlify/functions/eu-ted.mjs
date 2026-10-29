import {fetchTedPublic} from "../../src/ted.js";
const headers={"cache-control":"no-store","x-content-type-options":"nosniff","referrer-policy":"no-referrer"};
export default async function handler(req){
  if(req.method!=="GET")return Response.json({error:"Method not allowed"},{status:405,headers:{...headers,allow:"GET"}});
  const url=new URL(req.url);
  const country=url.searchParams.get("country")||"SVK";
  try{
    const data=await fetchTedPublic({country});
    return Response.json(data,{headers,status:200});
  }catch(e){
    const invalid=/Unsupported country scope|query bounds exceeded/.test(String(e.message));
    return Response.json({error:invalid?"Unsupported country.":"TED public source unavailable or unrecognised.",verified:false},{headers,status:invalid?400:502});
  }
}
export const config={path:"/api/official/eu-ted"};
