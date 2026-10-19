import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { validateManifest } from '../scripts/validate-manifest.mjs';

const valid = JSON.parse(await readFile(new URL('../examples/hermes.manifest.json', import.meta.url), 'utf8'));

test('accepts the authenticated HERMES pilot manifest', () => {
  assert.deepEqual(validateManifest(valid), { ok: true, errors: [] });
});

test('rejects a PWA that does not require login', () => {
  const m = structuredClone(valid);
  m.deployment.auth.required = false;
  assert.ok(validateManifest(m).errors.some(e => e.includes('must be true')));
});

test('rejects UI-only authentication without server-side authorization', () => {
  const m = structuredClone(valid);
  m.deployment.auth.serverSideAuthorizationRequired = false;
  assert.ok(validateManifest(m).errors.some(e => e.includes('server-side authorization')));
});

test('rejects a paid API dependency', () => {
  const m = structuredClone(valid);
  m.intelligence.paidApiDependency = true;
  assert.ok(validateManifest(m).errors.some(e => e.includes('paidApiDependency')));
});

test('rejects unapproved or unknown providers', () => {
  const m = structuredClone(valid);
  m.intelligence.providers = ['unknown-paid-provider'];
  assert.ok(validateManifest(m).errors.some(e => e.includes('unsupported provider')));
});

test('rejects disabled cross-user data isolation', () => {
  const m = structuredClone(valid);
  m.data.crossUserIsolationRequired = false;
  assert.ok(validateManifest(m).errors.some(e => e.includes('cross-user data isolation')));
});

test('rejects credential values in deployment manifests', () => {
  const m = structuredClone(valid);
  m.intelligence.api_key = 'should-not-be-here';
  assert.ok(validateManifest(m).errors.some(e => e.includes('credential values')));
});

test('rejects non-standalone apps and missing domain authority', () => {
  const m = structuredClone(valid);
  m.app.standalone = false;
  m.data.domainAuthority = '';
  const result = validateManifest(m);
  assert.ok(result.errors.some(e => e.includes('standalone')));
  assert.ok(result.errors.some(e => e.includes('domainAuthority')));
});

test('CRESUS Worker manifest remains an independently authenticated deployment', async () => {
  const cresus = JSON.parse(await readFile(new URL('../examples/cresus.worker.manifest.json', import.meta.url), 'utf8'));
  assert.deepEqual(validateManifest(cresus), { ok: true, errors: [] });
  assert.notEqual(cresus.app.id, valid.app.id);
  assert.notEqual(cresus.deployment.provider, valid.deployment.provider);
  assert.equal(cresus.deployment.kind, 'worker-pwa');
  assert.equal(cresus.deployment.auth.crossAppSessionsAllowed, false);
});

test('rejects Worker deployment with a static auth profile', async () => {
  const cresus = JSON.parse(await readFile(new URL('../examples/cresus.worker.manifest.json', import.meta.url), 'utf8'));
  cresus.deployment.auth.provider = 'supabase';
  assert.equal(validateManifest(cresus).ok, false);
});
