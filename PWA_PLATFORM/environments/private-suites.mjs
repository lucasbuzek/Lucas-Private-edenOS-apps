/** Validates the recovered ELYSIUM and Slindokuhle scope without asserting live capability. */
export function validatePrivateSuiteScope(plan) {
  const errors=[];
  if(plan?.schemaVersion!==1 ||
     plan.status!=='CANON_RECOVERED_IMPLEMENTATION_NOT_VERIFIED' ||
     !Array.isArray(plan.environments))return {ok:false,errors:['Invalid private suite scope']};
  const suiteIds={
    elysium:['personal','business'],
    slindokuhle:['parent-household','transport-business'],
  };
  for(const [envId,needed] of Object.entries(suiteIds)) {
    const e=plan.environments.find(x=>x.id===envId);
    if(!e){errors.push('Missing '+envId);continue}
    if(e.pagesAlias!==envId+'.edenosprivate.pages.dev' ||
       e.currentAccess!=='OWNER_ONLY_UNTIL_PHYSICAL_ACCEPTANCE' ||
       e.liveLoginVerified!==false || e.liveFeatureCoverageVerified!==false)
      errors.push('Unverified '+envId+' source claiming access or readiness');
    if(!needed.every(id=>e.suites?.some(s=>s.id===id&&s.independentlyUseful===true)))
      errors.push('Missing separate standalone suite for '+envId);
    if(!['BIFROST-local','BIFROST-online','WORKinCODEX'].every(x=>e.requiredConnectors?.includes(x)))
      errors.push('Missing declared connectors for '+envId);
  }
  if(plan.environments.length!==2 || plan.security?.crossTenantDefaultDeny!==true ||
     plan.security?.verifiedIdentityRequired!==true ||
     plan.security?.tenantSpecificMembershipRequired!==true ||
     plan.delivery?.physicalAcceptancePassed!==false ||
     plan.delivery?.publicDeploymentAllowed!==false ||
     plan.delivery?.realSourceModulesConnected!==false)
    errors.push('Unsafe suite isolation or readiness claims');
  return {ok:errors.length===0,errors};
}
