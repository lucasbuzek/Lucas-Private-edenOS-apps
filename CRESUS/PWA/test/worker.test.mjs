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

async function call(path, { email, method = 'GET', body, tok, origin } = {}) {
  const headers = {};
  if (origin) headers.Origin = origin;
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
  assert.deepEqual(r.body, { email: OWNER, role: 'admin', owner: true, developmentAlpha: false, usedToday: 0, dailyLimit: null });
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

test('legacy users retain the existing Workers AI provider until setup is saved',async()=>{
  const old=await call('/api/intelligence',{email:'third@gmail.com'});
  // Disabled users stay disabled even if they have never completed onboarding.
  assert.equal(old.status,403);
  const created=await call('/api/admin/users',{email:OWNER,method:'POST',body:{email:'legacy@example.com'}});
  assert.equal(created.status,200);
  const before=await call('/api/intelligence',{email:'legacy@example.com'});
  assert.equal(before.status,200);
  assert.equal(before.body.configured,false);
  assert.equal(before.body.provider,'workers-ai');
  const answer=await call('/api/chat',{email:'legacy@example.com',method:'POST',body:chat('legacy default works')});
  assert.equal(answer.status,200);
  assert.equal((await call('/api/intelligence',{email:'legacy@example.com',method:'PUT',body:{provider:'none'}})).status,200);
  assert.equal((await call('/api/chat',{email:'legacy@example.com',method:'POST',body:chat('disabled by user choice')})).status,409);
});

test('DEVELOPMENT_ALPHA removes CRESUS quotas without removing authentication or upstream constraints', async()=>{
  const original=env.DEVELOPMENT_ALPHA;
  env.DEVELOPMENT_ALPHA='true';
  try{
    const me=await call('/api/me',{email:'wife@gmail.com'});
    assert.equal(me.status,200);
    assert.equal(me.body.developmentAlpha,true);
    assert.equal(me.body.dailyLimit,null);
    const d=await call('/api/admin/users',{email:OWNER});
    assert.equal(d.body.developmentAlpha,true);
    assert.equal(d.body.maxUsers,null);
    assert.equal(d.body.dailyMessageLimit,null);
    assert.equal((await call('/api/admin/settings',{email:OWNER,method:'PUT',body:{maxUsers:1}})).status,409);
    // The member had exhausted a 2-message cap in commercial behavior tests.
    assert.equal((await call('/api/chat',{email:'wife@gmail.com',method:'POST',body:chat('alpha unrestricted')})).status,200);
    assert.equal((await call('/api/admin/users',{email:OWNER,method:'POST',body:{email:'alpha-tester@example.com'}})).status,200);
    assert.equal((await call('/api/me',{email:'alpha-tester@example.com'})).status,200);
    assert.equal((await call('/api/me')).status,401);
    assert.equal((await call('/api/conversations',{email:'stranger@example.com'})).status,403);
  }finally{if(original===undefined)delete env.DEVELOPMENT_ALPHA;else env.DEVELOPMENT_ALPHA=original;}
});

test('watchlist is durable per user, with cross-listing identity and duplicate protection',async()=>{
  const owner=OWNER,member='wife@gmail.com';
  const create=await call('/api/watchlist',{email:owner,method:'POST',body:{ticker:'brk.b',mic:'xnys',currency:'usd',name:'Berkshire Hathaway B',notes:'Review latest filing'}});
  assert.equal(create.status,201);
  const {id,ticker,mic,currency}=create.body.entry;
  assert.deepEqual([ticker,mic,currency],['BRK.B','XNYS','USD']);
  const list=await call('/api/watchlist',{email:owner});
  assert.equal(list.status,200);
  assert.equal(list.body.entries.some(x=>x.id===id),true);
  assert.equal(list.body.pricesAvailable,false);
  assert.equal((await call('/api/watchlist',{email:owner,method:'POST',body:{ticker:'brk.b',mic:'xnys'}})).status,409);
  // Same ticker at a distinct exchange is not silently collapsed.
  assert.equal((await call('/api/watchlist',{email:owner,method:'POST',body:{ticker:'brk.b',mic:'xnas'}})).status,201);
  assert.equal((await call('/api/watchlist',{email:member})).body.entries.some(x=>x.id===id),false);
  assert.equal((await call('/api/watchlist/'+id,{email:member,method:'DELETE'})).status,404);
  assert.equal((await call('/api/watchlist/'+id,{email:member,method:'PATCH',body:{notes:'attack'}})).status,404);
  const edit=await call('/api/watchlist/'+id,{email:owner,method:'PATCH',body:{notes:'Verify 10-K and evidence clock'}});
  assert.equal(edit.status,200);
  assert.match(edit.body.entry.notes,/Verify 10-K/);
  assert.equal((await call('/api/watchlist/'+id,{email:owner,method:'PATCH',body:{ticker:'FAKE'}})).status,400);
  assert.equal((await call('/api/watchlist/'+id,{email:owner,method:'DELETE'})).status,200);
  assert.equal((await call('/api/watchlist/'+id,{email:owner,method:'DELETE'})).status,404);
});

test('watchlist prevents ambiguous malformed listing data, cross-site mutation and unauthenticated reads',async()=>{
  assert.equal((await call('/api/watchlist')).status,401);
  assert.equal((await call('/api/watchlist',{email:'stranger@gmail.com'})).status,403);
  for(const invalid of [
    {ticker:'NYSE:BOGUS; DROP TABLE users'},
    {ticker:'AAPL',mic:'NY'},
    {ticker:'AAPL',currency:'US'},
    {ticker:'AAPL',isin:'INVALID'},
    {ticker:''},
    {ticker:'AAPL',name:'x'.repeat(121)}
  ]){
    assert.equal((await call('/api/watchlist',{email:OWNER,method:'POST',body:invalid})).status,400);
  }
  assert.equal((await call('/api/watchlist',{email:OWNER,method:'POST',origin:'https://evil.example',body:{ticker:'AAPL'}})).status,403);
  assert.equal((await call('/api/watchlist',{email:OWNER,method:'POST',origin:'https://cresus.test',body:{ticker:'VALID',mic:'XNAS'}})).status,201);
  assert.equal((await call('/api/watchlist',{email:OWNER,method:'POST',body:{ticker:'AAPL',notes:'x'.repeat(2001)}})).status,400);
});

test('current opportunity discovery is routed to Expert with explicit missing live evidence',async()=>{
  let system='';
  const run=env.AI.run;
  env.AI.run=async(model,options)=>{system=options.messages[0].content;return run(model,options)};
  try{
    const r=await call('/api/chat',{email:OWNER,method:'POST',body:chat('Find current investment opportunities today',{mode:'simple'})});
    assert.equal(r.status,200);
    assert.equal(r.body.mode,'expert');
    assert.match(system,/Requested depth: EXPERT/);
    assert.match(system,/Live web search: DISABLED/);
    assert.match(system,/Do not invent quotes/);
  }finally{env.AI.run=run}
});

test('portfolio positions are user-scoped, durable and preserve exact decimal strings',async()=>{
  assert.equal((await call('/api/portfolio')).status,401);
  assert.equal((await call('/api/portfolio',{email:'stranger@gmail.com'})).status,403);
  const owner=OWNER,member='wife@gmail.com';
  const post=await call('/api/portfolio',{email:owner,method:'POST',
    body:{accountLabel:'Retirement',ticker:'brk.b',mic:'xnys',currency:'usd',quantity:'12.00000001',unitCost:'403.12345678',name:'Berkshire B',notes:'Manual tax lot summary'}});
  assert.equal(post.status,201);
  const p=post.body.position;
  assert.deepEqual([p.ticker,p.mic,p.currency,p.quantity,p.unit_cost,p.account_label],
    ['BRK.B','XNYS','USD','12.00000001','403.12345678','Retirement']);
  const listing=await call('/api/portfolio',{email:owner});
  assert.equal(listing.status,200);
  assert.equal(listing.body.brokerConnected,false);
  assert.equal(listing.body.livePrices,false);
  assert.equal(listing.body.positions.some(x=>x.id===p.id),true);
  assert.equal((await call('/api/portfolio',{email:member})).body.positions.some(x=>x.id===p.id),false);
  assert.equal((await call('/api/portfolio/'+p.id,{email:member,method:'PATCH',body:{quantity:'99'}})).status,404);
  assert.equal((await call('/api/portfolio/'+p.id,{email:member,method:'DELETE'})).status,404);
  assert.equal((await call('/api/portfolio',{email:owner,method:'POST',
    body:{accountLabel:'Retirement',ticker:'BRK.B',mic:'XNYS',currency:'USD',quantity:'1'}})).status,409);
  assert.equal((await call('/api/portfolio',{email:owner,method:'POST',
    body:{accountLabel:'Broker 2',ticker:'BRK.B',mic:'XNYS',quantity:'1'}})).status,201);
  assert.equal((await call('/api/portfolio',{email:owner,method:'POST',
    body:{accountLabel:'Retirement',ticker:'BRK.B',mic:'XNAS',quantity:'1'}})).status,201);
  const edit=await call('/api/portfolio/'+p.id,{email:owner,method:'PATCH',
    body:{quantity:'0.00000001',unitCost:'0',currency:'USD',notes:'corrected user entry'}});
  assert.equal(edit.status,200);
  assert.equal(edit.body.position.quantity,'0.00000001');
  assert.equal(edit.body.position.unit_cost,'0');
  assert.equal(edit.body.position.notes,'corrected user entry');
  assert.equal((await call('/api/portfolio/'+p.id,{email:owner,method:'PATCH',body:{ticker:'FAKE'}})).status,400);
  assert.equal((await call('/api/portfolio/'+p.id,{email:owner,method:'DELETE'})).status,200);
  assert.equal((await call('/api/portfolio/'+p.id,{email:owner,method:'DELETE'})).status,404);
});

test('portfolio rejects wrong numeric precision, ambiguity and cross-origin mutation',async()=>{
  for(const bad of [
    {ticker:'AAPL',quantity:'0'},
    {ticker:'AAPL',quantity:'-1'},
    {ticker:'AAPL',quantity:'1e3'},
    {ticker:'AAPL',quantity:'1.000000001'},
    {ticker:'AAPL',quantity:0.2},
    {ticker:'AAPL',quantity:'1',unitCost:'2.50'},
    {ticker:'AAPL',quantity:'1',unitCost:'-2',currency:'USD'},
    {ticker:'AAPL',quantity:'1',mic:'NY'},
    {ticker:'AAPL',quantity:'1',accountLabel:'x'.repeat(81)},
    {ticker:'AAPL',quantity:'1',notes:'x'.repeat(2001)}
  ]){
    const r=await call('/api/portfolio',{email:OWNER,method:'POST',body:bad});
    assert.equal(r.status,400,JSON.stringify(bad));
  }
  assert.equal((await call('/api/portfolio',{email:OWNER,method:'POST',origin:'https://other.example',
    body:{ticker:'AAPL',quantity:'1'}})).status,403);
  const ok=await call('/api/portfolio',{email:OWNER,method:'POST',origin:'https://cresus.test',
    body:{ticker:'AAPL',mic:'XNAS',quantity:'1.5',notes:'Self-reported'}});
  assert.equal(ok.status,201);
  assert.equal((await call('/api/portfolio/'+ok.body.position.id,{email:OWNER,method:'PATCH',
    body:{currency:''}})).status,200);
});

test('CRESUS export includes owned chats, watchlist and manual positions, excluding other user data',async()=>{
  const saved=await call('/api/watchlist',{email:OWNER,method:'POST',
    body:{ticker:'EXPT',mic:'XNAS',notes:'OWNER_PRIVATE_WATCHLIST_NOTE'}});
  assert.equal(saved.status,201);
  const other=await call('/api/portfolio',{email:'wife@gmail.com',method:'POST',
    body:{ticker:'WIFE1',quantity:'2',notes:'OTHER_USER_PRIVATE_POSITION'}});
  assert.equal(other.status,201);
  const req=new Request('https://cresus.test/api/export',{headers:{
    'Cf-Access-Jwt-Assertion':await token(OWNER)
  }});
  const res=await worker.fetch(req,env);
  assert.equal(res.status,200);
  const md=await res.text();
  assert.match(md,/Saved watchlist \(JSON\)/);
  assert.match(md,/Manually entered portfolio positions \(JSON\)/);
  assert.match(md,/OWNER_PRIVATE_WATCHLIST_NOTE/);
  assert.match(md,/"quantity": "1.5"/);
  assert.doesNotMatch(md,/OTHER_USER_PRIVATE_POSITION/);
  assert.doesNotMatch(md,/WIFE1/);
});

test('ZACCHAEUS manual income supports exact sums and separate evidence states',async()=>{
  assert.equal((await call('/api/income')).status,401);
  assert.equal((await call('/api/income',{email:'stranger@gmail.com'})).status,403);
  const input=(amount,status,currency='USD')=>({accountLabel:'Manual',ticker:'ZTEST',mic:'XNAS',currency,amount,status,effectiveAt:'2026-02-03',sourcePublishedAt:'2026-02-01',description:'Self-entered event'});
  const one=await call('/api/income',{email:OWNER,method:'POST',body:input('0.1','paid')});
  assert.equal(one.status,201);
  const two=await call('/api/income',{email:OWNER,method:'POST',body:input('0.2','reconciled')});
  assert.equal(two.status,201);
  const declared=await call('/api/income',{email:OWNER,method:'POST',body:input('0.3','declared')});
  assert.equal(declared.status,201);
  const forward=await call('/api/income',{email:OWNER,method:'POST',body:input('0.4','forward_indicated','EUR')});
  assert.equal(forward.status,201);
  const estimated=await call('/api/income',{email:OWNER,method:'POST',body:input('0.5','estimated')});
  assert.equal(estimated.status,201);
  const cancelled=await call('/api/income',{email:OWNER,method:'POST',body:input('0','cancelled')});
  assert.equal(cancelled.status,201);
  const r=await call('/api/income',{email:OWNER});
  assert.equal(r.status,200);
  assert.equal(r.body.verifiedCash,false);
  assert.equal(r.body.fxConversion,false);
  assert.ok(r.body.totals.some(x=>x.currency==='USD'&&x.basis==='REALIZED'&&x.amount==='0.3'));
  assert.ok(r.body.totals.some(x=>x.currency==='USD'&&x.basis==='DECLARED'&&x.amount==='0.3'));
  assert.ok(r.body.totals.some(x=>x.currency==='EUR'&&x.basis==='FORWARD_INDICATED'&&x.amount==='0.4'));
  assert.ok(r.body.totals.some(x=>x.currency==='USD'&&x.basis==='ESTIMATED'&&x.amount==='0.5'));
  assert.ok(r.body.totals.some(x=>x.currency==='USD'&&x.basis==='EXCEPTION'&&x.amount==='0'));
  assert.equal((await call('/api/income',{email:'wife@gmail.com'})).body.events.some(x=>x.id===one.body.event.id),false);
  const e=one.body.event;
  assert.match(e.known_at,/^\d{4}-\d{2}-\d{2}T/);
  assert.equal(e.effective_at,'2026-02-03');
  assert.notEqual(e.known_at.slice(0,10),e.effective_at);
  const p=await call('/api/income/'+e.id,{email:'wife@gmail.com',method:'DELETE'});
  assert.equal(p.status,404);
});

test('ZACCHAEUS validates event sources and exact date/currency/amount',async()=>{
  const valid={ticker:'ANNUAL',currency:'ZAR',amount:'1.00000001',status:'estimated',effectiveAt:'2026-09-30'};
  for(const bad of [
    {...valid,amount:'-1'}, {...valid,amount:'1e5'}, {...valid,amount:'1.000000001'},
    {...valid,amount:1.2}, {...valid,amount:'1000000000000'},
    {...valid,currency:''}, {...valid,currency:'US'}, {...valid,status:'unknown'},
    {...valid,effectiveAt:'2026-02-30'}, {...valid,payDate:'2026-12-32'},
    {...valid,sourcePublishedAt:'2026-13-01'}, {...valid,notes:'X'.repeat(2001)}
  ]) {
    const result=await call('/api/income',{email:OWNER,method:'POST',body:bad});
    assert.equal(result.status,400,JSON.stringify(bad));
  }
  assert.equal((await call('/api/income',{email:OWNER,method:'POST',origin:'https://evil.example',body:valid})).status,403);
  const positive=await call('/api/income',{email:OWNER,method:'POST',origin:'https://cresus.test',body:valid});
  assert.equal(positive.status,201);
  assert.equal(positive.body.event.amount,'1.00000001');
  assert.equal((await call('/api/income',{email:OWNER,method:'POST',body:{...valid,effectiveAt:'2024-02-29'}})).status,201);
});

test('ZACCHAEUS optimistic revision guards and income export isolation',async()=>{
  const original=await call('/api/income',{email:OWNER,method:'POST',body:{
    ticker:'ZEND',currency:'USD',amount:'0.125',status:'declared',effectiveAt:'2026-06-01',
    notes:'OWNER_INCOME_EVIDENCE_RECEIPT'
  }});
  assert.equal(original.status,201);
  const e=original.body.event;
  const patch=async(email,revision,body)=>{
    const req=new Request('https://cresus.test/api/income/'+e.id,{
      method:'PATCH',headers:{'Cf-Access-Jwt-Assertion':await token(email),'If-Match':String(revision),'Origin':'https://cresus.test'},
      body:JSON.stringify(body)
    });
    const response=await worker.fetch(req,env);
    return {status:response.status,body:await response.json()};
  };
  assert.equal((await patch('wife@gmail.com',1,{amount:'8'})).status,404);
  assert.equal((await patch(OWNER,0,{amount:'8'})).status,409);
  const updated=await patch(OWNER,1,{amount:'0.25',status:'paid',notes:'OWNER_INCOME_EVIDENCE_RECEIPT'});
  assert.equal(updated.status,200);
  assert.equal(updated.body.event.revision,2);
  assert.equal(updated.body.event.amount,'0.25');
  assert.equal((await patch(OWNER,1,{status:'reconciled'})).status,409);
  assert.equal((await patch(OWNER,2,{currency:'EUR'})).status,400);
  const other=await call('/api/income',{email:'wife@gmail.com',method:'POST',body:{
    ticker:'PRIVATE',currency:'EUR',amount:'42',status:'estimated',effectiveAt:'2026-08-04',
    notes:'OTHER_PERSON_INCOME_SECRET'
  }});
  assert.equal(other.status,201);
  const request=new Request('https://cresus.test/api/export',{headers:{'Cf-Access-Jwt-Assertion':await token(OWNER)}});
  const exported=await worker.fetch(request,env);
  assert.equal(exported.status,200);
  const markdown=await exported.text();
  assert.match(markdown,/Manually entered income events \(JSON\)/);
  assert.match(markdown,/OWNER_INCOME_EVIDENCE_RECEIPT/);
  assert.doesNotMatch(markdown,/OTHER_PERSON_INCOME_SECRET/);
  assert.equal((await call('/api/income/'+e.id,{email:OWNER,method:'DELETE'})).status,200);
  assert.equal((await call('/api/income/'+e.id,{email:OWNER,method:'DELETE'})).status,404);
});
