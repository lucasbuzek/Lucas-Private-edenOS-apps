import test from 'node:test';
import assert from 'node:assert/strict';
import { openAICompatibleAdapter } from '../intelligence/openai-compatible.mjs';

test('explicit remote OpenAI-compatible provider sends only server-configured model/endpoint and key', async () => {
  let captured;
  const provider = openAICompatibleAdapter({
    endpoint: 'https://model.example/v1',
    model: 'free-test-model',
    apiKey: 'server-side-test-key',
    fetchImpl: async (url, opts) => {
      captured = { url, opts };
      return new Response(JSON.stringify({ choices: [{ message: { content: 'Evidence answer' } }] }), { status: 200 });
    },
  });
  assert.equal(provider.available, true);
  const response = await provider.generate({
    systemPrompt: 'HERMES system',
    messages: [{ role: 'user', content: 'analyze' }],
    endpoint: 'https://attacker.example',
    model: 'attacker-selected',
  });
  assert.equal(response, 'Evidence answer');
  assert.equal(captured.url, 'https://model.example/v1/chat/completions');
  assert.equal(captured.opts.redirect, 'error');
  assert.equal(captured.opts.headers.authorization, 'Bearer server-side-test-key');
  assert.equal(JSON.parse(captured.opts.body).model, 'free-test-model');
  assert.deepEqual(JSON.parse(captured.opts.body).messages, [
    { role: 'system', content: 'HERMES system' },
    { role: 'user', content: 'analyze' },
  ]);
});

test('local Ollama-compatible endpoint permits HTTP loopback only under local policy', async () => {
  const generate = async () => new Response(JSON.stringify({ choices: [{ message: { content: 'local' } }] }));
  assert.equal(openAICompatibleAdapter({ endpoint: 'http://127.0.0.1:11434/v1', model: 'm', costClass: 'local', fetchImpl: generate }).available, true);
  assert.equal(openAICompatibleAdapter({ endpoint: 'http://127.0.0.1:11434/v1', model: 'm', costClass: 'user-connected', fetchImpl: generate }).available, false);
  assert.equal(openAICompatibleAdapter({ endpoint: 'http://192.168.1.12:11434/v1', model: 'm', costClass: 'local', fetchImpl: generate }).available, false);
  assert.equal(openAICompatibleAdapter({ endpoint: 'https://user:pass@example.com/v1', model: 'm', fetchImpl: generate }).available, false);
  assert.equal(openAICompatibleAdapter({ endpoint: 'https://model.example/v1?secret=a', model: 'm', fetchImpl: generate }).available, false);
});

test('provider does not automatically retry or route elsewhere when upstream fails', async () => {
  let attempts = 0;
  const provider = openAICompatibleAdapter({
    endpoint: 'https://provider.example/v1', model: 'm',
    fetchImpl: async () => { attempts += 1; return new Response('rate limited', { status: 429 }); },
  });
  await assert.rejects(() => provider.generate({ systemPrompt: 'system', messages: [{ role: 'user', content: 'hello' }] }), /HTTP 429/);
  assert.equal(attempts, 1);
});

test('provider capabilities start unverified and require explicit evidence-gated configuration', () => {
  assert.deepEqual(openAICompatibleAdapter({ endpoint: 'https://model.example/v1', model: 'm' }).verifiedCapabilities, []);
  assert.deepEqual(openAICompatibleAdapter({
    endpoint: 'https://model.example/v1', model: 'm', verifiedCapabilities: ['research'],
  }).verifiedCapabilities, ['research']);
});
