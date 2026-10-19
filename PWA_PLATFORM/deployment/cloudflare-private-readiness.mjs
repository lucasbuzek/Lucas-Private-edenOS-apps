/**
 * Cloudflare account inventory is a READ-ONLY preflight, never deployment proof.
 * API failures are UNKNOWN, not successful empty results. No secret is returned.
 */
const PRIVATE = 'edenosprivate';
const PORTAL = 'edenosportal';
const REQUIRED_HOSTS = Object.freeze([
  PRIVATE+'.pages.dev',
  '*.'+PRIVATE+'.pages.dev',
]);
const ACCOUNT_ID=/^[a-f0-9]{32}$/;
function resultOf(record) {
  if (record?.status===200 && record.body?.success===true)
    return {ok:true,data:record.body.result};
  return {ok:false,httpStatus:record?.status??'UNKNOWN'};
}
function accessDomain(item) {
  const entries=[item?.domain];
  if(Array.isArray(item?.destinations))
    for(const x of item.destinations)
      entries.push(typeof x?.uri==='string'?x.uri:x?.hostname);
  return entries.filter(x=>typeof x==='string').map(x=>
    x.toLowerCase().replace(/^https?:\/\//,'').split('/')[0].replace(/:\d+$/,'')
  );
}
export function assessPrivateCloudflareInventory(evidence) {
  if(!evidence || typeof evidence!=='object')throw new TypeError('Read-only account inventory required');
  const pages=evidence.pages||{};
  const privateResult=resultOf(pages[PRIVATE]);
  const portalResult=resultOf(pages[PORTAL]);
  const accessResult=resultOf(evidence.accessApps);
  const zonesResult=resultOf(evidence.zones);
  const routingResult=resultOf(evidence.routingRules);

  const privateExists=privateResult.ok && privateResult.data?.name===PRIVATE;
  const portalExists=portalResult.ok && portalResult.data?.name===PORTAL;
  const privateEmpty=privateExists && !privateResult.data?.latest_deployment;
  const applications=accessResult.ok && Array.isArray(accessResult.data)
    ? accessResult.data : null;
  const zones=zonesResult.ok && Array.isArray(zonesResult.data)
    ? zonesResult.data : null;
  const routes=routingResult.ok && Array.isArray(routingResult.data)
    ? routingResult.data : null;
  const protectedHosts=REQUIRED_HOSTS.map(host=>({
    hostname:host,
    matchedApplication:applications===null ? 'UNKNOWN'
      : applications.some(app=>accessDomain(app).includes(host)),
    policyAndOwnerAcceptance:'UNKNOWN',
  }));
  const blockers=[];
  if(!privateExists)
    blockers.push('PRIVATE_PAGES_PROJECT_UNVERIFIED');
  if(portalResult.ok && !portalExists)
    blockers.push('PORTAL_PAGES_PROJECT_IDENTITY_MISMATCH');
  else if(portalResult.httpStatus===404)
    blockers.push('PORTAL_PAGES_PROJECT_NOT_CREATED');
  else if(!portalExists)
    blockers.push('PORTAL_PAGES_PROJECT_UNVERIFIED');
  if(applications===null)blockers.push('ACCESS_APPLICATIONS_API_UNVERIFIED');
  else if(applications.length===0)blockers.push('NO_ACCESS_APPLICATIONS');
  for(const target of protectedHosts) {
    if(target.matchedApplication!==true)
      blockers.push('ACCESS_HOST_UNVERIFIED:'+target.hostname);
  }
  if(zones===null)blockers.push('OWNED_DNS_ZONES_UNVERIFIED');
  else if(zones.length===0)blockers.push('NO_ACTIVE_OWNED_DNS_ZONE_FOR_EMAIL');
  if(routes===null)blockers.push('EMAIL_ROUTING_API_UNVERIFIED');
  // THESE gates require actual controlled-owner sessions, not API metadata.
  blockers.push('OWNER_ACCESS_POLICY_NOT_PHYSICALLY_ACCEPTED');
  blockers.push('PREVIEW_HASH_AND_DIRECT_ORIGIN_NOT_PHYSICALLY_ACCEPTED');
  blockers.push('SENDER_DOMAIN_AND_RECIPIENT_DELIVERY_NOT_PHYSICALLY_ACCEPTED');
  blockers.push('REAL_SOFTWARE_RELEASE_AND_DEVICE_DOWNLOAD_NOT_ACCEPTED');
  return Object.freeze({
    status:'BLOCKED_NOT_DEPLOYABLE',
    evidenceType:'AUTHENTICATED_READ_ONLY_ACCOUNT_INVENTORY',
    privatePages:{exists:privateExists,empty:privateEmpty,verified:privateResult.ok},
    portalPages:{exists:portalExists,verified:portalResult.ok,
      absent:portalResult.httpStatus===404},
    accessApps:{readable:applications!==null,count:applications?.length??null,
      protectedHosts},
    dns:{readable:zones!==null,activeZoneCount:zones?.length??null},
    emailRouting:{readable:routes!==null,count:routes?.length??null},
    ownerLogin:'UNKNOWN',senderDelivery:'UNKNOWN',
    releasedSoftware:'UNKNOWN',deployAllowed:false,blockers,
  });
}

/**
 * Exact GET-only Cloudflare API inventory. Caller supplies token separately
 * (for example from an authorized Wrangler session). Never include it in logs
 * or any result. Zones and apps include account-sensitive details internally,
 * but assessPrivateCloudflareInventory returns only safe aggregate metadata.
 */
export async function collectPrivateCloudflareInventory({
  accountId,apiToken,fetchImpl=fetch,origin='https://api.cloudflare.com/client/v4',
}={}) {
  if(!ACCOUNT_ID.test(accountId||'')||
    typeof apiToken!=='string'||apiToken.length<12||
    typeof fetchImpl!=='function'||origin!=='https://api.cloudflare.com/client/v4')
    throw new TypeError('Explicit trusted Cloudflare account identity, authenticated bearer and GET transport required');
  const headers={
    authorization:'Bearer '+apiToken,
    accept:'application/json',
    'user-agent':'EDENOS-private-preflight/0.3',
  };
  const get=async path=>{
    const reqUrl=origin+path;
    let reply;
    try{reply=await fetchImpl(reqUrl,{method:'GET',headers,redirect:'error',
      signal:AbortSignal.timeout(12000)});}
    catch{return {status:'NETWORK_UNAVAILABLE'};}
    let body=null;
    if(reply.status===200){
      try{body=await reply.json();}catch{return {status:'INVALID_JSON'};}
    }
    return {status:reply.status,body};
  };
  const a='/accounts/'+accountId;
  const [privatePages,portalPages,accessApps,zones,routingRules]=await Promise.all([
    get(a+'/pages/projects/'+PRIVATE),
    get(a+'/pages/projects/'+PORTAL),
    get(a+'/access/apps?per_page=100'),
    get('/zones?per_page=100&status=active'),
    get(a+'/email/routing/rules?per_page=100'),
  ]);
  return {pages:{[PRIVATE]:privatePages,[PORTAL]:portalPages},
    accessApps,zones,routingRules};
}
