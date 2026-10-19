import test from 'node:test';
import assert from 'node:assert/strict';
import {runPrivatePreflight} from '../scripts/cloudflare-private-preflight.mjs';

test('Cloudflare preflight never assumes a provider account or hidden credentials',async()=>{
  const result=await runPrivatePreflight({accountId:null,apiToken:null});
  assert.equal(result.deployAllowed,false);
  assert.ok(result.blockers.includes('AUTHENTICATED_ACCOUNT_ID_AND_TOKEN_REQUIRED'));
});
test('malformed credentials do not leak or qualify as deployed',async()=>{
  const result=await runPrivatePreflight({
    accountId:'not-a-real-account',
    apiToken:'private-placeholder-credential',
    fetchImpl:async()=>{throw Error('should never call provider');},
  });
  assert.equal(result.deployAllowed,false);
  assert.doesNotMatch(JSON.stringify(result),/private-placeholder-credential/);
});
test('read-only API errors are unknown and stay blocked',async()=>{
  const result=await runPrivatePreflight({
    accountId:'c'.repeat(32),apiToken:'private-placeholder-credential',
    fetchImpl:async()=>{throw Error('temporary outage');},
  });
  assert.equal(result.status,'BLOCKED_NOT_DEPLOYABLE');
  assert.equal(result.deployAllowed,false);
  assert.ok(result.blockers.includes('ACCESS_APPLICATIONS_API_UNVERIFIED'));
  assert.doesNotMatch(JSON.stringify(result),/private-placeholder-credential/);
});
