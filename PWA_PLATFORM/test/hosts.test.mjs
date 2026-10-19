import test from 'node:test';
import assert from 'node:assert/strict';
import { previewCommand, extractPreviewUrl } from '../deployment/hosts.mjs';

const mk = (provider, targetId = 'verified-app-site') => ({
  app: { id: 'hermes' },
  deployment: { provider, targetId, kind: provider === 'cloudflare-workers' ? 'worker-pwa' : 'static-pwa' },
});

test('Netlify preview explicitly targets one existing site and cannot invoke production', () => {
  const command = previewCommand(mk('netlify'), '/tmp/staged/dist');
  assert.deepEqual(command, ['netlify', 'deploy', '--site', 'verified-app-site', '--dir', '/tmp/staged/dist', '--no-build', '--json']);
  assert.equal(command.includes('--prod'), false);
  assert.equal(command.includes('--open'), false);
  assert.equal(command.includes('--site-name'), false);
});

test('Cloudflare Pages preview uses separate non-production branch', () => {
  const command = previewCommand(mk('cloudflare-pages'), '/tmp/staged/dist');
  assert.deepEqual(command, ['wrangler', 'pages', 'deploy', '/tmp/staged/dist', '--project-name', 'verified-app-site', '--branch', 'edenos-pwa-preview-hermes']);
  const unsafe = mk('cloudflare-pages');
  unsafe.deployment.productionBranch = 'edenos-pwa-preview-hermes';
  assert.throws(() => previewCommand(unsafe, '/tmp/staged/dist'), /equals the production branch/);
});

test('worker deployments and missing targets fail before any CLI invocation', () => {
  assert.throws(() => previewCommand(mk('cloudflare-workers'), '/tmp/staged/public'), /isolated preview Worker/);
  assert.throws(() => previewCommand(mk('netlify', ''), '/tmp/staged/dist'), /explicit existing/);
  assert.throws(() => previewCommand(mk('netlify', 'invalid site'), '/tmp/staged/dist'), /explicit existing/);
});

test('CLI output must contain an HTTPS URL on the selected hosting domain', () => {
  assert.equal(extractPreviewUrl(JSON.stringify({ deploy_url: 'https://random--hermes.netlify.app' }), 'netlify'), 'https://random--hermes.netlify.app');
  assert.equal(extractPreviewUrl('https://edenos-pwa-preview-hermes.hermes.pages.dev', 'cloudflare-pages'), 'https://edenos-pwa-preview-hermes.hermes.pages.dev');
  assert.equal(extractPreviewUrl(JSON.stringify({ deploy_url: 'http://random--hermes.netlify.app' }), 'netlify'), null);
  assert.equal(extractPreviewUrl(JSON.stringify({ deploy_url: 'https://malicious.example' }), 'netlify'), null);
  assert.equal(extractPreviewUrl(JSON.stringify({ deploy_url: 'https://random--hermes.netlify.app.evil.example' }), 'netlify'), null);
});
