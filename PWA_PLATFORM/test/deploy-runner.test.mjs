import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, rmSync } from 'node:fs';
import { resolve } from 'node:path';
import { execute, resolveInside } from '../scripts/deploy.mjs';

test('deployment preflight installs, tests, builds and verifies hosted auth before any publish', async () => {
  const appRoot = resolve('test/fixtures/pwa-app');
  const output = resolve(appRoot, 'dist');
  rmSync(output, { recursive: true, force: true });
  const manifest = {
    schemaVersion: 1,
    app: { id: 'fixture-pwa', name: 'Fixture PWA', version: '0.1.0', standalone: true },
    source: {
      repository: 'https://example.invalid/fixture-pwa',
      projectDirectory: '.',
      hostedAuthEnvironment: { VITE_EDEN_PWA_AUTH_REQUIRED: 'true' },
      installCommand: ['node', 'fixture.mjs', 'install'],
      testCommand: ['node', 'fixture.mjs', 'test'],
      buildCommand: ['node', 'fixture.mjs', 'build'],
      authVerificationCommand: ['node', 'fixture.mjs', 'auth'],
      outputDirectory: 'dist'
    },
    deployment: {
      provider: 'netlify',
      kind: 'static-pwa',
      targetId: '',
      siteUrl: '',
      auth: { required: true, provider: 'supabase', publicClientConfigRequired: true, serverSideAuthorizationRequired: true, crossAppSessionsAllowed: false }
    },
    intelligence: {
      mode: 'shared-core-adapter',
      defaultProvider: null,
      endpoint: '',
      paidApiDependency: false,
      providers: ['workers-ai'],
      fallbackPolicy: 'explicit-status-no-silent-provider-switch'
    },
    data: { domainAuthority: 'Fixture PWA', ownership: 'app-owned', migration: 'preserve-existing-data', crossUserIsolationRequired: true }
  };
  const original = process.env.EDEN_PWA_TEST_PRIVATE_KEY;
  process.env.EDEN_PWA_TEST_PRIVATE_KEY = 'must-never-reach-app-build';
  try {
    const result = await execute({ manifest, appRoot, publishPreview: false });
    assert.equal(result.declaredAuthTests, 'PASS');
    assert.equal(result.liveAccountLogin, 'UNKNOWN');
    assert.equal(result.tenantIsolation, 'UNKNOWN');
    assert.match(result.artifactFingerprint, /^[0-9a-f]{64}$/);
    assert.equal(result.sourceIsolated, true);
    assert.equal(result.previewDeployed, false);
    assert.equal(existsSync(output), false, 'built output must stay in disposable staging');
    assert.equal(existsSync(resolve(appRoot, 'build-marker.txt')), false, 'build must not modify original source');
  } finally {
    if (original === undefined) delete process.env.EDEN_PWA_TEST_PRIVATE_KEY;
    else process.env.EDEN_PWA_TEST_PRIVATE_KEY = original;
    rmSync(output, { recursive: true, force: true });
  }
});

test('path helper rejects traversal', () => {
  assert.match(resolveInside('/tmp/app', 'dist'), /dist$/);
  assert.throws(() => resolveInside('/tmp/app', '../outside'));
});
