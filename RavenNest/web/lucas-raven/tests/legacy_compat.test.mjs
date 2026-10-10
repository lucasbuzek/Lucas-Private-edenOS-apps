import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {webcrypto} from 'node:crypto';

if (!globalThis.crypto) globalThis.crypto = webcrypto;
const source = readFileSync(new URL('../functions/api/[[path]].js', import.meta.url), 'utf8');
const api = await import('data:text/javascript;base64,' + Buffer.from(source).toString('base64'));
const digest = async value => Buffer.from(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(value))).toString('hex');

class LegacyDB {
  constructor({missingModern = true} = {}) {
    this.missingModern = missingModern;
    this.nodes = new Map();
    this.actions = new Map();
  }
  prepare(sql) {
    const db = this;
    return {bind(...args) { return {
      async first() { return db.first(sql, args); },
      async all() { return db.all(sql, args); },
      async run() { return db.run(sql, args); },
    }; }};
  }
  async batch(statements) { for (const statement of statements) await statement.run(); }
  modern(sql) {
    if (this.missingModern && /\b(users|devices|grants|audit|device_enrollments)\b/i.test(sql)) {
      throw new Error('no such table: users/devices/grants/audit');
    }
  }
  async first(sql, args) {
    this.modern(sql);
    if (sql.startsWith('SELECT * FROM node_state')) return this.nodes.get(args[0]) || null;
    if (sql.startsWith('SELECT COUNT(*)')) return {n: [...this.actions.values()].filter(a => a.node_id === args[0] && ['queued', 'claimed'].includes(a.status)).length};
    if (sql.startsWith('SELECT * FROM actions WHERE id=')) return this.actions.get(args[0]) || null;
    if (sql.startsWith('SELECT capability FROM actions')) return this.actions.get(args[0]) || null;
    if (sql.startsWith('UPDATE actions SET status=\'claimed\'')) {
      const row = [...this.actions.values()].filter(a => a.node_id === args[1] && a.status === 'queued').sort((a, b) => a.created_at - b.created_at)[0];
      if (!row) return null;
      row.status = 'claimed'; row.claimed_at = args[0];
      return {id: row.id, capability: row.capability, params: row.params};
    }
    return null;
  }
  async all(sql, args) {
    this.modern(sql);
    if (sql.startsWith('SELECT * FROM actions WHERE node_id=')) return {results: [...this.actions.values()].filter(a => a.node_id === args[0])};
    return {results: []};
  }
  async run(sql, args) {
    this.modern(sql);
    if (sql.startsWith('INSERT INTO node_state')) {
      this.nodes.set(args[0], {node_id: args[0], meta: args[1], state: args[2], updated_at: args[3]});
      return {meta: {changes: 1}};
    }
    if (sql.startsWith('INSERT INTO actions')) {
      this.actions.set(args[0], {id: args[0], node_id: args[1], capability: args[2], params: args[3], status: 'queued', origin: args[4], created_at: args[5], claimed_at: null, completed_at: null, result: null});
      return {meta: {changes: 1}};
    }
    if (sql.startsWith('UPDATE actions SET status=?1')) {
      const row = this.actions.get(args[3]);
      if (!row || row.node_id !== args[4] || row.status !== 'claimed') return {meta: {changes: 0}};
      row.status = args[0]; row.completed_at = args[1]; row.result = args[2];
      return {meta: {changes: 1}};
    }
    return {meta: {changes: 0}};
  }
}

const request = (path, {method = 'GET', key, body, headers = {}} = {}) => new Request(`https://example.invalid/api/${path}`, {
  method, headers: {...headers, ...(key ? {authorization: `Bearer ${key}`} : {}), ...(body ? {'content-type': 'application/json'} : {})},
  body: body ? JSON.stringify(body) : undefined,
});
const call = (env, path, options) => api.onRequest({request: request(path, options), env, params: {path: path.split('/')}});

async function legacyEnv(flag) {
  const operator = 'o'.repeat(48), node = 'n'.repeat(48), DB = new LegacyDB();
  const env = {DB, OPERATOR_KEY_SHA256: await digest(operator), NODE_KEY_SHA256: await digest(node)};
  if (flag !== undefined) env.LEGACY_OPERATOR_ENABLED = flag;
  return {env, DB, operator, node};
}

test('legacy operator and node paths work end to end without modern tables', async () => {
  const {env, DB, operator, node} = await legacyEnv();
  let response = await call(env, 'node/state', {method: 'POST', key: node, body: {node_id: 'lucas-macbook', actions: ['power.keepawake.start', 'power.keepawake.stop'], state: {capabilities: {}}}});
  assert.equal(response.status, 200);

  response = await call(env, 'state', {key: operator});
  assert.equal(response.status, 200);
  const state = await response.json();
  for (const key of ['now', 'catalog', 'nodes', 'actions']) assert.ok(Object.hasOwn(state, key));

  const ids = [];
  for (const [capability, params] of [['power.keepawake.start', {minutes: 30}], ['power.keepawake.stop', {}]]) {
    response = await call(env, 'actions', {method: 'POST', key: operator, body: {capability, params}});
    assert.equal(response.status, 202);
    const queued = await response.json();
    assert.equal(queued.status, 'queued');
    assert.equal(DB.actions.get(queued.id).node_id, 'lucas-macbook');
    ids.push(queued.id);
  }
  response = await call(env, `actions/${ids[0]}`, {key: operator});
  assert.equal(response.status, 200);
  assert.equal((await response.json()).id, ids[0]);
  assert.equal((await call(env, 'state', {key: 'wrong'.repeat(8)})).status, 401);

  response = await call(env, 'node/claim', {method: 'POST', key: node, body: {node_id: 'lucas-macbook'}});
  assert.equal(response.status, 200);
  const claimed = (await response.json()).action;
  assert.equal(claimed.id, ids[0]);
  response = await call(env, 'node/result', {method: 'POST', key: node, body: {node_id: 'lucas-macbook', id: claimed.id, ok: true, result: {done: true}}});
  assert.equal(response.status, 200);
  assert.equal(DB.actions.get(claimed.id).status, 'succeeded');
  for (const path of ['node/state', 'node/claim', 'node/result']) {
    response = await call(env, path, {method: 'POST', key: node, body: {node_id: 'other-node', id: ids[1], ok: true}});
    assert.equal(response.status, 403);
    assert.deepEqual(await response.json(), {error: 'node not enrolled'});
  }
});

test('legacy operator retirement does not retire the legacy node', async () => {
  const {env, operator, node} = await legacyEnv('0');
  assert.equal((await call(env, 'state', {key: operator})).status, 401);
  assert.equal((await call(env, 'node/state', {method: 'POST', key: node, body: {node_id: 'lucas-macbook', actions: [], state: {}}})).status, 200);
});

test('unset Access is legacy-only and an asserted email header grants nothing', async () => {
  const {env} = await legacyEnv('1');
  let response = await call(env, 'state');
  assert.equal(response.status, 401);
  response = await call(env, 'state', {headers: {'Cf-Access-Authenticated-User-Email': 'owner@example.invalid'}});
  assert.equal(response.status, 401);
  response = await call(env, 'admin/users', {headers: {'Cf-Access-Authenticated-User-Email': 'owner@example.invalid'}});
  assert.equal(response.status, 401);
});

test('missing multi-user tables return a closed JSON error', async () => {
  const {env} = await legacyEnv();
  const keys = await crypto.subtle.generateKey({name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256'}, true, ['sign', 'verify']);
  const jwk = await crypto.subtle.exportKey('jwk', keys.publicKey); jwk.kid = 'legacy-compat';
  const encode = value => Buffer.from(JSON.stringify(value)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  const unsigned = `${encode({alg: 'RS256', kid: jwk.kid})}.${encode({iss: 'https://team.example.invalid', aud: 'aud', sub: 'subject', email: 'person@example.invalid', exp: now + 60})}`;
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', keys.privateKey, new TextEncoder().encode(unsigned));
  const token = `${unsigned}.${Buffer.from(signature).toString('base64url')}`;
  const previousFetch = globalThis.fetch;
  globalThis.fetch = async () => new Response(JSON.stringify({keys: [jwk]}), {status: 200});
  try {
    Object.assign(env, {ACCESS_TEAM_DOMAIN: 'team.example.invalid', ACCESS_AUD: 'aud'});
    const response = await call(env, 'admin/users', {headers: {'cf-access-jwt-assertion': token}});
    assert.equal(response.status, 500);
    assert.deepEqual(await response.json(), {error: 'internal error'});
  } finally { globalThis.fetch = previousFetch; }
});
