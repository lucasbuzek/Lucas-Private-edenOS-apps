import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { assessReadiness } from '../scripts/readiness.mjs';

const manifest = name => JSON.parse(readFileSync(new URL('../examples/' + name, import.meta.url), 'utf8'));
const codes = status => status.blockers.map(v => v.code);

test('existing CRESUS source is eligible for a non-mutating isolated preflight, not Worker publishing', () => {
  const m = manifest('cresus.worker.manifest.json');
  const r = assessReadiness(m, {
    appRoot: resolve('test/fixtures/pwa-app'), env: {}, hasCommand: () => false,
  });
  assert.equal(r.previewConfigured, false);
  assert.ok(codes(r).includes('APP_SOURCE_MISSING'));
  assert.ok(codes(r).includes('WORKER_PREVIEW_ISOLATION_UNKNOWN'));
  assert.equal(r.liveAccountLogin, 'UNKNOWN');
});

test('HERMES profile distinguishes missing source checkout from missing Netlify identity and OAuth settings', () => {
  const m = manifest('hermes.manifest.json');
  const r = assessReadiness(m, {appRoot:resolve('test/fixtures/pwa-app'), env:{}, hasCommand:()=>false});
  assert.equal(r.preflightConfigured, false);
  for(const code of ['APP_SOURCE_MISSING','HOST_TARGET_UNVERIFIED','HOST_ORIGIN_UNVERIFIED',
    'HOST_NAME_UNVERIFIED','HOST_CREDENTIAL_UNAVAILABLE','HOST_CLI_UNAVAILABLE','AUTH_CLIENT_CONFIGURATION_UNAVAILABLE']) {
    assert.ok(codes(r).includes(code), 'missing: '+code);
  }
  assert.equal(r.liveIntelligenceCapability, 'UNKNOWN');
});

test('configured preview is not misreported as an authenticated or verified hosting target', () => {
  const m = manifest('hermes.manifest.json');
  m.source.projectDirectory = '.';
  m.deployment.targetId = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
  m.deployment.expectedName = 'hermes-private';
  m.deployment.siteUrl = 'https://hermes-private.netlify.app';
  const r = assessReadiness(m, {
    appRoot: resolve('test/fixtures/pwa-app'),
    env: {NETLIFY_AUTH_TOKEN:'test',VITE_SUPABASE_URL:'https://example.supabase.co',VITE_SUPABASE_ANON_KEY:'test',PATH:process.env.PATH},
    hasCommand:()=>true,
  });
  assert.equal(r.preflightConfigured,true);
  assert.equal(r.previewConfigured,true);
  assert.equal(r.hostingTargetApiVerified,false);
  assert.equal(r.liveAccountLogin,'UNKNOWN');
  assert.equal(r.crossUserIsolation,'UNKNOWN');
  assert.equal(r.nextGate,'READ_ONLY_HOST_TARGET_VERIFICATION_BEFORE_PREVIEW');
});

test('invalid manifests fail closed before declaring preflight readiness', () => {
  const m = manifest('hermes.manifest.json');
  m.app.standalone = false;
  const r = assessReadiness(m, {appRoot:resolve('test/fixtures/pwa-app'),env:{}});
  assert.equal(r.preflightConfigured,false);
  assert.ok(codes(r).includes('INVALID_MANIFEST'));
});

test('readiness output includes no credential values', () => {
  const m = manifest('hermes.manifest.json');
  const r = assessReadiness(m, {appRoot:resolve('test/fixtures/pwa-app'),
    env: {NETLIFY_AUTH_TOKEN:'SUPERSECRET',VITE_SUPABASE_ANON_KEY:'SUPERSECRET',VITE_SUPABASE_URL:'https://example.supabase.co'},
    hasCommand:()=>false});
  assert.equal(JSON.stringify(r).includes('SUPERSECRET'), false);
});
