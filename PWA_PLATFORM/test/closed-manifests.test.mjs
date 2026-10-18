import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {validateManifest} from '../scripts/validate-manifest.mjs';
import {validateFleet} from '../scripts/validate-fleet.mjs';

const read=name=>JSON.parse(readFileSync(new URL('../examples/'+name,import.meta.url),'utf8'));

test('separate HERMES and CRESUS Cloudflare closed-testing manifests pass required security contract',()=>{
  const h=read('hermes.cloudflare.closed.manifest.json');
  const c=read('cresus.worker.manifest.json');
  assert.equal(validateManifest(h).ok,true);
  assert.equal(validateManifest(c).ok,true);
  assert.equal(validateFleet([h,c]).ok,true);
  assert.notEqual(h.app.id,c.app.id);
  assert.equal(h.deployment.closedTesting.ownerApprovalRequired,true);
  assert.equal(c.deployment.closedTesting.publicWaitlistSeparateFromPrivateApp,true);
});

test('closed-testing cannot omit Turnstile, owner approval or all-assets protection',()=>{
  for(const field of ['ownerApprovalRequired','turnstileRequired','allAppAssetsProtected',
    'publicWaitlistSeparateFromPrivateApp']){
    const h=read('hermes.cloudflare.closed.manifest.json');
    h.deployment.closedTesting[field]=false;
    const r=validateManifest(h);
    assert.equal(r.ok,false);
    assert.ok(r.errors.some(x=>x.includes(field)));
  }
});

test('closed-testing profile cannot switch to unverified login without explicit Cloudflare Access',()=>{
  const h=read('hermes.cloudflare.closed.manifest.json');
  h.deployment.auth.provider='supabase';
  assert.equal(validateManifest(h).ok,false);
});
