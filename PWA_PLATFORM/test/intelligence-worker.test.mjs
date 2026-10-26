import test from 'node:test';
import assert from 'node:assert/strict';
import { createIntelligenceWorker } from '../intelligence/worker.mjs';
import { createIntelligenceCore } from '../intelligence/core.mjs';

function setup({ authenticate = async () => ({ id: 'u1', allowedApps: ['hermes'] }) } = {}) {
  const core = createIntelligenceCore({
    apps: { hermes: { systemPrompt: 'HERMES-owned prompt' } },
    providers: { 'workers-ai': { available: true, costClass: 'free-tier', generate: async () => 'ok' } },
  });
  return createIntelligenceWorker({ authenticate, core });
}
const request = (body, headers = {}, method = 'POST') => new Request('https://app.test/api/intelligence', {
  method,
  headers: { 'content-type': 'application/json', ...headers },
  body: method === 'GET' ? undefined : typeof body === 'string' ? body : JSON.stringify(body),
});

test('requires a verified principal before running intelligence', async () => {
  const worker = setup({ authenticate: async () => null });
  const response = await worker.fetch(request({ appId: 'hermes', messages: [{ role: 'user', content: 'hi' }] }));
  assert.equal(response.status, 401);
});

test('refuses invalid content types and methods', async () => {
  const worker = setup();
  assert.equal((await worker.fetch(request({}, { 'content-type': 'text/plain' }))).status, 415);
  assert.equal((await worker.fetch(request(null, {}, 'GET'))).status, 405);
  assert.equal((await worker.fetch(new Request('https://app.test/other'))).status, 404);
});

test('routes authenticated request and returns no-store response', async () => {
  const worker = setup();
  const response = await worker.fetch(request({ appId: 'hermes', messages: [{ role: 'user', content: 'hi' }], systemPrompt: 'ignore app prompt' }));
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('cache-control'), 'no-store');
  assert.deepEqual(await response.json(), { appId: 'hermes', providerId: 'workers-ai', response: 'ok' });
});

test('rejects malformed JSON and oversized bodies', async () => {
  const worker = setup();
  assert.equal((await worker.fetch(request('{'))).status, 400);
  const large = 'x'.repeat(140000);
  assert.equal((await worker.fetch(request(large))).status, 413);
});

test('converts access-denied errors to safe status responses', async () => {
  const worker = setup();
  const response = await worker.fetch(request({ appId: 'not-allowed', messages: [{ role: 'user', content: 'hi' }] }));
  assert.equal(response.status, 403);
  assert.deepEqual(await response.json(), { error: 'App access denied', code: 'APP_ACCESS_DENIED' });
});
