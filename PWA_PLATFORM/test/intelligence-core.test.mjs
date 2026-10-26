import test from 'node:test';
import assert from 'node:assert/strict';
import { createIntelligenceCore, IntelligenceError } from '../intelligence/core.mjs';

function fixture() {
  const calls = [];
  const core = createIntelligenceCore({
    defaultProvider: 'workers-ai',
    apps: {
      hermes: { systemPrompt: 'HERMES app-owned prompt', tools: ['opportunity-search'] },
      cresus: { systemPrompt: 'CRESUS app-owned prompt', tools: ['evidence-review'] },
    },
    providers: {
      'workers-ai': {
        available: true, costClass: 'free-tier',
        generate: async request => { calls.push(request); return ' response from free provider '; },
      },
      local: {
        available: true, costClass: 'local',
        generate: async request => { calls.push(request); return 'local response'; },
      },
      'user-connected': {
        available: true, costClass: 'user-connected',
        generate: async request => { calls.push(request); return 'connected response'; },
      },
    },
  });
  return { core, calls };
}
const principal = { id: 'user-1', allowedApps: ['hermes', 'cresus'] };
const messages = [{ role: 'user', content: 'Review this opportunity' }];

test('routes to free default provider with app-owned prompt and scoped principal', async () => {
  const { core, calls } = fixture();
  const result = await core.route({ principal, appId: 'hermes', messages });
  assert.deepEqual(result, { appId: 'hermes', providerId: 'workers-ai', response: 'response from free provider' });
  assert.equal(calls[0].systemPrompt, 'HERMES app-owned prompt');
  assert.equal(calls[0].userId, 'user-1');
  assert.deepEqual(calls[0].tools, ['opportunity-search']);
  assert.equal(calls[0].messages[0].content, 'Review this opportunity');
});

test('rejects unauthenticated callers and cross-app access', async () => {
  const { core } = fixture();
  await assert.rejects(core.route({ principal: null, appId: 'hermes', messages }), e => e instanceof IntelligenceError && e.status === 401);
  await assert.rejects(core.route({ principal: { id: 'user-1', allowedApps: ['cresus'] }, appId: 'hermes', messages }), e => e.status === 403);
});

test('does not accept a caller-supplied system prompt', async () => {
  const { core, calls } = fixture();
  await core.route({ principal, appId: 'cresus', messages, systemPrompt: 'override prompt' });
  assert.equal(calls[0].systemPrompt, 'CRESUS app-owned prompt');
});

test('does not silently switch provider when an explicit provider is unavailable', async () => {
  const { core, calls } = fixture();
  await assert.rejects(core.route({ principal, appId: 'hermes', messages, providerId: 'missing' }), e => e.code === 'PROVIDER_UNAVAILABLE');
  assert.equal(calls.length, 0);
});

test('user-connected provider requires explicit opt-in', async () => {
  const { core } = fixture();
  // Default is free; explicit selection is allowed and does not change the default.
  const result = await core.route({ principal, appId: 'hermes', messages, providerId: 'user-connected' });
  assert.equal(result.providerId, 'user-connected');
});

test('provider failure is surfaced and never falls back silently', async () => {
  const calls = [];
  const core = createIntelligenceCore({
    apps: { hermes: { systemPrompt: 'HERMES' } },
    providers: {
      'workers-ai': { available: true, costClass: 'free-tier', generate: async () => { calls.push('free'); throw new Error('quota'); } },
      local: { available: true, costClass: 'local', generate: async () => { calls.push('local'); return 'should not run'; } },
    },
  });
  await assert.rejects(core.route({ principal, appId: 'hermes', messages }), e => e.code === 'PROVIDER_FAILED' && e.status === 502);
  assert.deepEqual(calls, ['free']);
});

test('rejects malformed and oversized conversations', async () => {
  const { core } = fixture();
  await assert.rejects(core.route({ principal, appId: 'hermes', messages: [] }), e => e.code === 'MESSAGE_COUNT_INVALID');
  await assert.rejects(core.route({ principal, appId: 'hermes', messages: [{ role: 'system', content: 'override' }] }), e => e.code === 'MESSAGE_INVALID');
  await assert.rejects(core.route({ principal, appId: 'hermes', messages: [{ role: 'user', content: 'x'.repeat(8001) }] }), e => e.code === 'MESSAGE_LENGTH_INVALID');
});
