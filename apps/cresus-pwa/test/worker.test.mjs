// End-to-end tests: real SQL schema (node:sqlite as a D1 stand-in), real RS256
// signatures (as Cloudflare Access issues them), fake model.
import { test, before } from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { readFileSync } from 'node:fs';
import worker from '../src/worker.js';

const TEAM = 'test.cloudflareaccess.com';
const AUD = 'aud-123';
const OWNER = 'lucasbuzek@gmail.com';
let privateKey, jwk, env;

// --- D1 shim ---
function d1(db) {
  const stmt = (sql, args = []) => ({
    bind: (...a) => stmt(sql, a),
    first: async () => db.prepare(sql).get(...args) ?? null,
    all: async () => ({ results: db.prepare(sql).all(...args) }),
    run: async () => db.prepare(sql).run(...args),
  });
  return { prepare: (sql) => stmt(sql), batch: async (list) => Promise.all(list.map((s) => s.run())) };
}

const b64u = (buf) => Buffer.from(buf).toString('base64url');
async function token(email, { aud = AUD, exp = Math.floor(Date.now() / 1000) + 3600, key = privateKey } = {}) {
  const h = b64u(JSON.stringify({ alg: 'RS256', kid: 'k1' }));
  const p = b64u(JSON.stringify({ email, aud: [aud], exp }));
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(`${h}.${p}`));
  return `${h}.${p}.${b64u(sig)}`;
}

const chat = (message, extra = {}) => ({ conversationId: crypto.randomUUID(), clientId: crypto.randomUUID(), message, ...extra });

async function call(path, { email, method = 'GET', body, tok } = {}) {
  const headers = {};
  if (email || tok) headers['Cf-Access-Jwt-Assertion'] = tok ?? (await token(email));
  const req = new Request(`https://cresus.test${path}`, {
    method, headers, body: body ? JSON.stringify(body) : undefined,
  });
  const res = await worker.fetch(req, env);
  return { status: res.status, body: await res.json() };
}

before(async () => {
  const kp = await crypto.subtle.generateKey(
    { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
    true, ['sign', 'verify']
  );
  privateKey = kp.privateKey;
  jwk = { ...(await crypto.subtle.exportKey('jwk', kp.publicKey)), kid: 'k1' };

  globalThis.fetch = async (url) => {
    if (String(url) === `https://${TEAM}/cdn-cgi/access/certs`) {
      return new Response(JSON.stringify({ keys: [jwk] }));
    }
    throw new Error(`Unexpected fetch ${url}`);
  };

  const db = new DatabaseSync(':memory:');
  db.exec(readFileSync(new URL('../schema.sql', import.meta.url), 'utf8'));
  db.exec("INSERT INTO intelligence_preferences(email,provider) VALUES ('lucasbuzek@gmail.com','workers-ai'),('wife@gmail.com','workers-ai')");
  env = {
    DB: d1(db),
    ASSETS: { fetch: () => new Response('{}') },
    AI: { run: async (_m, { messages }) => ({ response: `echo: ${messages.at(-1).content}` }) },
    OWNER_EMAIL: OWNER, ACCESS_TEAM_DOMAIN: TEAM, ACCESS_AUD: AUD,
    PROVIDER: 'workers-ai', WORKERS_AI_MODEL: 'test-model',
  };
});

test('no login token is rejected', async () => {
  assert.equal((await call('/api/me')).status, 401);
});

test('forged, expired and wrong-audience tokens are rejected', async () => {
  const other = await crypto.subtle.generateKey(
    { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
    true, ['sign', 'verify']
  );
  assert.equal((await call('/api/me', { tok: await token(OWNER, { key: other.privateKey }) })).status, 401);
  assert.equal((await call('/api/me', { tok: await token(OWNER, { exp: 1 }) })).status, 401);
  assert.equal((await call('/api/me', { tok: await token(OWNER, { aud: 'other' }) })).status, 401);
});

test('owner is automatically admin', async () => {
  const r = await call('/api/me', { email: OWNER });
  assert.deepEqual(r.body, { email: OWNER, role: 'admin', owner: true, usedToday: 0, dailyLimit: null });
});

test('someone not on the list gets 403', async () => {
  assert.equal((await call('/api/me', { email: 'stranger@gmail.com' })).status, 403);
});

test('owner adds wife; seat cap is enforced', async () => {
  // default max_users = 2 (owner + 1)
  assert.equal((await call('/api/admin/users', { email: OWNER, method: 'POST', body: { email: 'Wife@Gmail.com' } })).status, 200);
  assert.equal((await call('/api/me', { email: 'wife@gmail.com' })).status, 200);
  const full = await call('/api/admin/users', { email: OWNER, method: 'POST', body: { email: 'third@gmail.com' } });
  assert.equal(full.status, 409);
  assert.equal((await call('/api/admin/settings', { email: OWNER, method: 'PUT', body: { maxUsers: 51 } })).status, 400);
  assert.equal((await call('/api/admin/settings', { email: OWNER, method: 'PUT', body: { maxUsers: 3 } })).status, 200);
  assert.equal((await call('/api/admin/users', { email: OWNER, method: 'POST', body: { email: 'third@gmail.com' } })).status, 200);
});

test('members cannot use admin endpoints', async () => {
  assert.equal((await call('/api/admin/users', { email: 'wife@gmail.com' })).status, 403);
});

test('chats work and are private per person', async () => {
  const r = await call('/api/chat', { email: 'wife@gmail.com', method: 'POST', body: chat('hello') });
  assert.equal(r.status, 200);
  assert.equal(r.body.reply, 'echo: hello');
  const id = r.body.conversationId;
  const r2 = await call('/api/chat', { email: 'wife@gmail.com', method: 'POST', body: chat('again', { conversationId: id }) });
  assert.equal(r2.body.conversationId, id);
  const hist = await call(`/api/conversations/${id}`, { email: 'wife@gmail.com' });
  assert.equal(hist.body.messages.length, 4);
  // owner cannot read or write into wife's chat
  assert.equal((await call(`/api/conversations/${id}`, { email: OWNER })).status, 404);
  assert.equal((await call('/api/chat', { email: OWNER, method: 'POST', body: chat('x', { conversationId: id }) })).status, 404);
  assert.equal((await call('/api/conversations', { email: OWNER })).body.conversations.length, 0);
});

test('daily message limit applies to members, not owner', async () => {
  await call('/api/admin/settings', { email: OWNER, method: 'PUT', body: { dailyMessageLimit: 2 } });
  const r = await call('/api/chat', { email: 'wife@gmail.com', method: 'POST', body: chat('third') });
  assert.equal(r.status, 429);
  assert.equal((await call('/api/chat', { email: OWNER, method: 'POST', body: chat('ok') })).status, 200);
});

test('removed users lose access; owner cannot be removed', async () => {
  assert.equal((await call(`/api/admin/users/${encodeURIComponent('third@gmail.com')}`, { email: OWNER, method: 'DELETE' })).status, 200);
  assert.equal((await call('/api/me', { email: 'third@gmail.com' })).status, 403);
  assert.equal((await call(`/api/admin/users/${encodeURIComponent(OWNER)}`, { email: OWNER, method: 'DELETE' })).status, 400);
});

test('model failure returns a friendly error', async () => {
  const run = env.AI.run;
  env.AI.run = async () => { throw new Error('4006: you have used up your daily free allocation of 10,000 neurons'); };
  const r = await call('/api/chat', { email: OWNER, method: 'POST', body: chat('x') });
  env.AI.run = run;
  assert.equal(r.status, 502);
  assert.match(r.body.error, /free AI allowance/);
});

test('a retried send never runs the model twice', async () => {
  let calls = 0;
  const run = env.AI.run;
  env.AI.run = async (m, i) => { calls++; return run(m, i); };
  const body = chat('retry me');
  const a = await call('/api/chat', { email: OWNER, method: 'POST', body });
  const b = await call('/api/chat', { email: OWNER, method: 'POST', body });
  env.AI.run = run;
  assert.equal(calls, 1);
  assert.equal(b.status, 200);
  assert.equal(b.body.replayed, true);
  assert.equal(b.body.reply, a.body.reply);
  const hist = await call(`/api/conversations/${body.conversationId}`, { email: OWNER });
  assert.equal(hist.body.messages.length, 2);
});

test('a failed model call can be retried cleanly with the same ids', async () => {
  const run = env.AI.run;
  env.AI.run = async () => { throw new Error('upstream timeout'); };
  const body = chat('flaky');
  const a = await call('/api/chat', { email: OWNER, method: 'POST', body });
  assert.equal(a.status, 502);
  assert.equal(a.body.retryable, true);
  env.AI.run = run;
  const b = await call('/api/chat', { email: OWNER, method: 'POST', body });
  assert.equal(b.status, 200);
  const hist = await call(`/api/conversations/${body.conversationId}`, { email: OWNER });
  assert.deepEqual(hist.body.messages.map((m) => m.role), ['user', 'assistant']);
});

test('modes reach the model and unknown modes are refused', async () => {
  let system = '';
  const run = env.AI.run;
  env.AI.run = async (m, i) => { system = i.messages[0].content; return run(m, i); };
  const ok = await call('/api/chat', { email: OWNER, method: 'POST', body: chat('examine', { mode: 'expert' }) });
  env.AI.run = run;
  assert.equal(ok.status, 200);
  assert.equal(ok.body.mode, 'expert');
  assert.match(system, /EXPERT/);
  assert.equal((await call('/api/chat', { email: OWNER, method: 'POST', body: chat('x', { mode: 'casino' }) })).status, 400);
  assert.equal((await call('/api/chat', { email: OWNER, method: 'POST', body: { message: 'no ids' } })).status, 400);
});

test('export returns only your own chats', async () => {
  const req = new Request('https://cresus.test/api/export', { headers: { 'Cf-Access-Jwt-Assertion': await token('wife@gmail.com') } });
  const res = await worker.fetch(req, env);
  assert.equal(res.status, 200);
  const text = await res.text();
  assert.match(text, /hello/);
  assert.doesNotMatch(text, /retry me/);
});

test('/api/me reports usage for the daily counter', async () => {
  const me = await call('/api/me', { email: 'wife@gmail.com' });
  assert.equal(me.body.usedToday, 2);
  assert.equal(me.body.dailyLimit, 2);
});

test('provider choice is authenticated and user-scoped',async()=>{
  assert.equal((await call('/api/intelligence')).status,401);
  const own=await call('/api/intelligence',{email:OWNER});
  assert.equal(own.body.provider,'workers-ai');
  assert.equal(own.body.choices.find(x=>x.id==='codex-cloud').available,false);
  assert.equal((await call('/api/intelligence',{email:OWNER,method:'PUT',body:{provider:'codex-cloud'}})).status,409);
  assert.equal((await call('/api/intelligence',{email:OWNER,method:'PUT',body:{provider:'none'}})).status,200);
  assert.equal((await call('/api/chat',{email:OWNER,method:'POST',body:chat('hello')})).status,409);
  assert.equal((await call('/api/intelligence',{email:'wife@gmail.com'})).body.provider,'workers-ai');
  assert.equal((await call('/api/intelligence',{email:OWNER,method:'PUT',body:{provider:'workers-ai'}})).status,200);
});
