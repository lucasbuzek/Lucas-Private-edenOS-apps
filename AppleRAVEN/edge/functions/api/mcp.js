/**
 * Reused Raven Pages application: an authenticated MCP route alongside the
 * ORIGINAL /api/state, /api/admin, /api/node and /api/actions routes.
 * No separate user, pairing, grant or action database is created.
 * Cloudflare Access verification occurs in original human(); no legacy bearer.
 */
import {human, allowed, visibleState} from './[[path]].js';
import {handleAppleRavenMCP} from '../../mcp.js';
export async function onRequest({request, env}) {
  const user = await human(request, env, Date.now());
  return handleAppleRavenMCP({request,env,user,allowed,visibleState});
}
