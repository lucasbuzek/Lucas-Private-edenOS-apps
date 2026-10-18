import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { validateFleet } from '../scripts/validate-fleet.mjs';

const load = name => JSON.parse(readFileSync(new URL('../examples/' + name, import.meta.url), 'utf8'));
const samples = () => [load('hermes.manifest.json'), load('cresus.worker.manifest.json')];

test('two independently hosted apps are accepted as distinct deployment profiles', () => {
  assert.deepEqual(validateFleet(samples()), { ok: true, errors: [] });
});

test('two apps cannot share one hosting project target even if IDs differ', () => {
  const profiles = samples();
  profiles[0].deployment.provider = 'cloudflare-workers';
  profiles[0].deployment.kind = 'worker-pwa';
  profiles[0].deployment.workerConfigPath = 'wrangler.toml';
  profiles[0].deployment.previewConfigPath = 'wrangler.preview.toml';
  profiles[0].deployment.auth.provider = 'cloudflare-access';
  profiles[0].deployment.targetId = 'same-project';
  profiles[1].deployment.targetId = 'same-project';
  assert.ok(validateFleet(profiles).errors.some(error => error.includes('share hosting target')));
});

test('two apps cannot share the same HTTPS origin or product ID', () => {
  const profiles = samples();
  profiles[0].deployment.siteUrl = 'https://same.example';
  profiles[1].deployment.siteUrl = 'https://same.example';
  assert.ok(validateFleet(profiles).errors.some(error => error.includes('share hosted origin')));
  profiles[1].app.id = 'hermes';
  assert.ok(validateFleet(profiles).errors.some(error => error.includes('Duplicate app identity')));
});
