import test from 'node:test';
import assert from 'node:assert/strict';
import { workersAIAdapter, geminiFreeTierAdapter } from '../intelligence/providers.mjs';

test('Workers AI adapter uses the app-owned system prompt and message history', async () => {
  let captured;
  const adapter = workersAIAdapter({
    model: 'test-model',
    binding: { run: async (model, input) => { captured = { model, input }; return { response: 'ok' }; } },
  });
  assert.equal(adapter.available, true);
  assert.equal(adapter.costClass, 'free-tier');
  assert.equal(await adapter.generate({ systemPrompt: 'HERMES policy', messages: [{ role: 'user', content: 'hello' }] }), 'ok');
  assert.equal(captured.model, 'test-model');
  assert.deepEqual(captured.input.messages, [
    { role: 'system', content: 'HERMES policy' },
    { role: 'user', content: 'hello' },
  ]);
});

test('Workers AI adapter is unavailable without a runtime binding', () => {
  assert.equal(workersAIAdapter({}).available, false);
});

test('Gemini adapter keeps its key server-side and normalizes provider history', async () => {
  let captured;
  const adapter = geminiFreeTierAdapter({
    apiKey: 'test-secret',
    model: 'test-model',
    fetchImpl: async (url, init) => {
      captured = { url: String(url), init };
      return new Response(JSON.stringify({ candidates: [{ content: { parts: [{ text: 'reply' }] } }] }), { status: 200 });
    },
  });
  assert.equal(adapter.available, true);
  assert.equal(await adapter.generate({ systemPrompt: 'CRESUS policy', messages: [{ role: 'assistant', content: 'prior' }, { role: 'user', content: 'next' }] }), 'reply');
  assert.match(captured.url, /test-model:generateContent$/);
  assert.equal(captured.init.headers['x-goog-api-key'], 'test-secret');
  assert.deepEqual(JSON.parse(captured.init.body).contents, [
    { role: 'model', parts: [{ text: 'prior' }] },
    { role: 'user', parts: [{ text: 'next' }] },
  ]);
});

test('Gemini adapter surfaces quota/failure rather than hiding it', async () => {
  const adapter = geminiFreeTierAdapter({
    apiKey: 'test-secret',
    fetchImpl: async () => new Response('quota', { status: 429 }),
  });
  await assert.rejects(adapter.generate({ systemPrompt: 'app', messages: [{ role: 'user', content: 'x' }] }), /HTTP 429/);
});
