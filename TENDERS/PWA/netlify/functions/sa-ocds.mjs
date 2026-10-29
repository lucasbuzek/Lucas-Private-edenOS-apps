import { fetchSaOcds } from "../../src/saOcds.js";
const headers={"cache-control":"no-store","x-content-type-options":"nosniff","referrer-policy":"no-referrer"};
export default async function handler(request) {
  if(request.method!=="GET")return Response.json({error:"Method not allowed"},{status:405,headers:{...headers,allow:"GET"}});
  const url=new URL(request.url);
  const from=url.searchParams.get("dateFrom"),to=url.searchParams.get("dateTo");
  try {
    const data=await fetchSaOcds({from,to});
    return Response.json(data,{status:200,headers});
  } catch(error) {
    const invalid=/ISO dates|maximum 31-day range|Pagination limit/.test(String(error.message));
    return Response.json({error:invalid?"Invalid bounded date range.":"Official source unavailable or returned unrecognised data.",verified:false},{status:invalid?400:502,headers});
  }
}
export const config={path:"/api/official/sa-ocds"};
