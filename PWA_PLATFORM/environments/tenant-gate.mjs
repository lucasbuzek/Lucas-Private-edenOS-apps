import {validatePrivateSuiteScope} from './private-suites.mjs';
/**
 * Reusable app/tenant membership boundary.
 * Identity, membership, and provider connection are trusted adapters;
 * this module never creates identities or enables a connector by default.
 */
export function createSuiteTenantGate({plan,authenticate,membership,providers}) {
  if(!validatePrivateSuiteScope(plan).ok ||
     typeof authenticate!=='function'||typeof membership!=='function'||typeof providers!=='function')
    throw new TypeError('Verified identity, per-tenant membership and provider adapters required');
  return Object.freeze({
    async resolve(request,{environment,suite,tenantId,capability,consent=false}={}) {
      const env=plan.environments.find(x=>x.id===environment);
      const context=env?.suites?.find(x=>x.id===suite);
      if(!context || !/^[a-z][a-z0-9-]{1,59}$/.test(tenantId||'') ||
         !/^[a-z][a-z0-9-]{1,59}$/.test(capability||''))
        return {state:'DENIED',reason:'INVALID_SCOPE'};
      const declared=new Set([
        ...(context.domains||[]),
        ...(env.requiredConnectors||[]).map(x=>x.toLowerCase()),
      ]);
      if(!declared.has(capability))
        return {state:'DENIED',reason:'CAPABILITY_NOT_DECLARED'};
      let person;
      try{person=await authenticate(request)}catch{}
      if(!person?.id||!person.email)return {state:'DENIED',reason:'LOGIN_REQUIRED'};
      let grant;
      try{grant=await membership({subject:person.id,environment,suite,tenantId})}catch{}
      if(grant?.allowed!==true || grant.environment!==environment ||
         grant.suite!==suite || grant.tenantId!==tenantId)
        return {state:'DENIED',reason:'TENANT_MEMBERSHIP_REQUIRED'};
      const external=['workincodex','bifrost-local','bifrost-online'].includes(capability);
      if(external && consent!==true)return {state:'DENIED',reason:'EXPLICIT_CONNECTOR_CONSENT_REQUIRED'};
      let provider;
      try{provider=await providers({person,environment,suite,tenantId,capability})}catch{}
      if(provider?.connected!==true||provider?.accepted!==true ||
         !['local','free-tier','user-connected'].includes(provider.costClass))
        return {state:'UNAVAILABLE',reason:'NO_VERIFIED_PROVIDER'};
      return {state:'AUTHORIZED',providerId:provider.id,
        scope:{environment,suite,tenantId,capability}};
    }
  });
}
