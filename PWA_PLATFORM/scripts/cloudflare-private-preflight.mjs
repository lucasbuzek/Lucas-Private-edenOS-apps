#!/usr/bin/env node
import {isCliMain} from './cli-main.mjs';
import {collectPrivateCloudflareInventory,assessPrivateCloudflareInventory}
  from '../deployment/cloudflare-private-readiness.mjs';

/** Prints only sanitized aggregate gate outcomes. Never echoes auth, account ID,
 * Cloudflare raw responses, policies, family email addresses or project secrets.
 */
export async function runPrivatePreflight({
  accountId=process.env.CLOUDFLARE_ACCOUNT_ID,
  apiToken=process.env.CLOUDFLARE_API_TOKEN,
  fetchImpl=fetch,
}={}) {
  if(!accountId||!apiToken){
    return {status:'BLOCKED_NOT_DEPLOYABLE',
      evidenceType:'NO_USABLE_CONFIGURED_API_IDENTITY',
      deployAllowed:false,blockers:['AUTHENTICATED_ACCOUNT_ID_AND_TOKEN_REQUIRED']};
  }
  try{
    const raw=await collectPrivateCloudflareInventory({
      accountId,apiToken,fetchImpl,
    });
    return assessPrivateCloudflareInventory(raw);
  }catch{
    return {status:'BLOCKED_NOT_DEPLOYABLE',
      evidenceType:'READ_ONLY_CLOUDFLARE_QUERY_FAILED',
      deployAllowed:false,blockers:['CLOUDFLARE_READ_ONLY_VERIFICATION_FAILED']};
  }
}
if(isCliMain(import.meta.url)){
  const result=await runPrivatePreflight();
  process.stdout.write(JSON.stringify(result,null,2)+'\n');
  // Even a fully configured Cloudflare account is not physical sign-in /
  // artifact acceptance evidence. There is intentionally no passing exit code
  // in an unauthenticated standalone preflight.
  process.exitCode=2;
}
