/** AppleRAVEN private, CF Access gated MCP route.
 * Reuses original Raven signed-jwt human() identity and per-device grant filters.
 * IMPORTANT: Access JWT is NOT interoperable OAuth access-token validation.
 * This candidate deliberately refuses anonymous / old operator-key access.
 */
import {human,allowed,visibleState} from './api/[[path]].js';
import {handleAppleRavenMCP} from '../mcp.js';

export async function onRequest({request,env}){
  if(!env?.DB||!env.ACCESS_TEAM_DOMAIN||!env.ACCESS_AUD){
    return new Response(JSON.stringify({error:'identity service not configured'}),{status:503,headers:{'content-type':'application/json','cache-control':'no-store'}});
  }
  // Cloudflare Access must be independently configured to restrict /mcp.
  // human() verifies Access JWT signature, iss, aud, exp and DB user.
  let u;
  try{u=await human(request,env,Date.now());}catch{return new Response(null,{status:401});}
  // Deny a legacy operator key, even if original Raven API still supports it.
  if(!u||!u.id||u.legacy||!u.subject)return new Response(JSON.stringify({error:'verified user required'}),{status:401,headers:{'content-type':'application/json','cache-control':'no-store'}});
  return handleAppleRavenMCP({request,env,user:u,visibleState,allowed});
}
