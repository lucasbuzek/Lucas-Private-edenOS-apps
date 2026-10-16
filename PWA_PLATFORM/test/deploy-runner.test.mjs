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
      installCommand: ['node', 'fixture.mjs', 'install'],
      testCommand: ['node', 'fixture.mjs', 'test'],
      buildCommand: ['node', 'fixture.mjs', 'build'],
      authVerificationCommand: ['node', 'fixture.mjs', 'auth'],
      outputDirectory: 'dist'
    },
    deployment: {
      provider: 'netlify',
      siteUrl: '',
      auth: { required: true, provider: 'supabase', publicClientConfigRequired: true, serverSideAuthorizationRequired: true }
    },
    intelligence: {
      mode: 'shared-core-adapter',
      endpoint: '',
      paidApiDependency: false,
      providers: ['workers-ai'],
      fallbackPolicy: 'explicit-status-no-silent-provider-switch'
    },
    data: { domainAuthority: 'Fixture PWA', ownership: 'app-owned', migration: 'preserve-existing-data', crossUserIsolationRequired: true }
  };
  try {
    const result = await execute({ manifest, appRoot, publishPreview: false });
    assert.equal(result.localAuthSmoke, 'PASS');
    assert.equal(existsSync(resolve(output, 'index.html')), true);
    assert.equal(existsSync(resolve(output, 'manifest.webmanifest')), true);
  } finally {
    rmSync(output, { recursive: true, force: true });
  }
});

test('path helper rejects traversal', () => {
  assert.match(resolveInside('/tmp/app', 'dist'), /dist$/);
  assert.throws(() => resolveInside('/tmp/app', '../outside'));
});
