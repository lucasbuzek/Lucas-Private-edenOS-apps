import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {validatePrivateSuiteScope} from '../environments/private-suites.mjs';
import {createSuiteTenantGate} from '../environments/tenant-gate.mjs';
const file=new URL('../environments/private-suite-contract.json',import.meta.url);
const plan=()=>JSON.parse(readFileSync(file,'utf8'));
function gate(allowed=true,connected=true) {
 return createSuiteTenantGate({
  plan:plan(),
  authenticate:async()=>({id:'parent1',email:'verified@example.com'}),
  membership:async scope=>({allowed,environment:scope.environment,
    suite:scope.suite,tenantId:scope.tenantId}),
  providers:async()=>({id:'trusted-adapter',connected,accepted:true,costClass:'local'}),
 });
}
const req=new Request('https://slindokuhle.edenosprivate.pages.dev');

test('ELYSIUM retains standalone Personal and Business for wife and parents, but no false deployment',()=>{
 const p=plan();
 assert.deepEqual(validatePrivateSuiteScope(p),{ok:true,errors:[]});
 const e=p.environments[0];
 for(const role of ['owner','wife','mother','father'])assert.ok(e.intendedAudienceRoles.includes(role));
 assert.equal(e.suites.length,2);
 assert.equal(e.liveFeatureCoverageVerified,false);
 assert.equal(p.delivery.fullFeaturesRequired,true);
});

test('Slindokuhle parent household and business remain independent with complete declared domains',()=>{
 const p=plan();const s=p.environments[1];
 assert.deepEqual(s.suites.map(x=>x.id),['parent-household','transport-business']);
 const domains=new Set(s.suites.flatMap(x=>x.domains));
 for(const d of ['logistics','transport','tenders','procurement','finance','farm','garage','maintenance']){
   const present=d==='farm'?domains.has('farm')||domains.has('farm-operations'):
     d==='garage'?domains.has('garage')||domains.has('fleet-maintenance'):domains.has(d);
   assert.ok(present,'missing '+d);
 }
 assert.equal(s.separatedHouseholdAndBusinessTenants,true);
 assert.equal(p.delivery.realSourceModulesConnected,false);
});

test('tenants require signed-in app membership independently for each suite and entity',async()=>{
 const denied=gate(false);
 const context={environment:'slindokuhle',suite:'transport-business',
   tenantId:'business-a',capability:'transport'};
 const output=await denied.resolve(req,context);
 assert.equal(output.state,'DENIED');
 assert.equal(output.reason,'TENANT_MEMBERSHIP_REQUIRED');
 const allowed=await gate().resolve(req,context);
 assert.equal(allowed.state,'AUTHORIZED');
 assert.equal(allowed.scope.tenantId,'business-a');
 assert.equal(allowed.scope.suite,'transport-business');
});

test('local, online and WORKinCODEX connectors need explicit user consent and accepted provider',async()=>{
 const context={environment:'elysium',suite:'personal',tenantId:'home-a',
  capability:'workincodex'};
 const g=gate();
 assert.equal((await g.resolve(req,context)).reason,'EXPLICIT_CONNECTOR_CONSENT_REQUIRED');
 assert.equal((await g.resolve(req,{...context,consent:true})).state,'AUTHORIZED');
 assert.equal((await gate(true,false).resolve(req,{...context,consent:true})).state,'UNAVAILABLE');
});

test('the profile contract cannot claim acceptance or cross-tenant data sharing',()=>{
 for(const edit of [
   p=>p.delivery.publicDeploymentAllowed=true,
   p=>p.environments[0].liveLoginVerified=true,
   p=>p.environments[1].suites.pop(),
   p=>p.security.crossTenantDefaultDeny=false,
 ]){const p=plan();edit(p);assert.equal(validatePrivateSuiteScope(p).ok,false);}
});


test('one tenant cannot request a capability absent from its declared suite',async()=>{
 const result=await gate().resolve(req,{environment:'slindokuhle',suite:'parent-household',
   tenantId:'parents-house',capability:'bank-transfer',consent:true});
 assert.equal(result.state,'DENIED');
 assert.equal(result.reason,'CAPABILITY_NOT_DECLARED');
});
