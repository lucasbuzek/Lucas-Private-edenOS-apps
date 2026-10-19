import test from 'node:test';
import assert from 'node:assert/strict';
import { generateKeyPair, SignJWT } from 'jose';
import { createCloudflareAccessAuthenticator, createSupabaseAuthenticator } from '../authentication/jwt.mjs';

const { publicKey, privateKey } = await generateKeyPair('RS256');
const attackerKeys = await generateKeyPair('RS256');
const accessIssuer = 'https://test.cloudflareaccess.com';
const supabaseIssuer = 'https://demo.supabase.co/auth/v1';
const sign = async (claims, { issuer, audience, key = privateKey, exp = Math.floor(Date.now() / 1000) + 300 } = {}) =>
  new SignJWT(claims).setProtectedHeader({ alg: 'RS256', kid: 'test' })
    .setIssuer(issuer).setAudience(audience).setIssuedAt().setNotBefore(Math.floor(Date.now() / 1000) - 5)
    .setExpirationTime(exp).sign(key);

const allowed = async () => ({ allowed: true, allowedProviders: ['user-connected'] });
const request = (token, where = 'cf-access-jwt-assertion') => new Request('https://hermes.test/api/intelligence', {
  headers: token ? { [where]: token } : {},
});

test('Cloudflare Access app JWT is verified before app-specific authorization', async () => {
  let calls = [];
  const auth = createCloudflareAccessAuthenticator({
    appId: 'cresus', teamDomain: 'test.cloudflareaccess.com', audience: 'cresus-aud',
    authorize: async args => { calls.push(args); return allowed(); },
    jwks: async () => publicKey,
  });
  const token = await sign({ sub: 'user-1', email: 'Person@Example.com', type: 'app' },
    { issuer: accessIssuer, audience: 'cresus-aud' });
  assert.equal(await auth(request(null)), null);
  assert.deepEqual(await auth(request(token)), {
    id: 'user-1', email: 'person@example.com', allowedApps: ['cresus'], allowedProviders: ['user-connected'],
  });
  assert.deepEqual(calls, [{ appId: 'cresus', userId: 'user-1', email: 'person@example.com' }]);
  assert.equal((await auth(request(null, 'cookie'))), null);
  const withCookie = await auth(request('CF_Authorization=' + token, 'cookie'));
  assert.deepEqual(withCookie.allowedApps, ['cresus']);
});

test('Access authenticator rejects wrong audience, wrong issuer, expired, forged, service token and disabled user', async () => {
  const auth = createCloudflareAccessAuthenticator({
    appId: 'cresus', teamDomain: 'test.cloudflareaccess.com', audience: 'cresus-aud',
    authorize: allowed, jwks: async () => publicKey,
  });
  const claims = { sub: 'user-1', email: 'person@example.com', type: 'app' };
  const good = { issuer: accessIssuer, audience: 'cresus-aud' };
  assert.equal(await auth(request(await sign(claims, { ...good, audience: 'hermes-aud' }))), null);
  assert.equal(await auth(request(await sign(claims, { ...good, issuer: 'https://evil.cloudflareaccess.com' }))), null);
  assert.equal(await auth(request(await sign(claims, { ...good, exp: 1 }))), null);
  assert.equal(await auth(request(await sign(claims, { ...good, key: attackerKeys.privateKey }))), null);
  assert.equal(await auth(request(await sign({ sub: '', type: 'app' }, good))), null);
  assert.equal(await auth(request(await sign({ sub: '', type: 'app', common_name: 'machine' }, good))), null);
  assert.equal(await auth(request(await sign({ ...claims, type: 'org' }, good))), null);

  const disabled = createCloudflareAccessAuthenticator({
    appId: 'cresus', teamDomain: 'test.cloudflareaccess.com', audience: 'cresus-aud',
    authorize: async () => ({ allowed: false }), jwks: async () => publicKey,
  });
  assert.equal(await disabled(request(await sign(claims, good))), null);
});

test('Supabase user JWT is verified for the exact app and must pass membership resolution', async () => {
  const auth = createSupabaseAuthenticator({
    appId: 'hermes', projectUrl: 'https://demo.supabase.co', authorize: allowed,
    jwks: async () => publicKey,
  });
  const token = await sign({ sub: 'account-42', role: 'authenticated', email: 'person@example.com' },
    { issuer: supabaseIssuer, audience: 'authenticated' });
  assert.deepEqual(await auth(request(token, 'authorization')), null);
  const bearer = new Request('https://hermes.test/api/intelligence', { headers: { authorization: 'Bearer ' + token } });
  assert.deepEqual(await auth(bearer), {
    id: 'account-42', email: 'person@example.com', allowedApps: ['hermes'], allowedProviders: ['user-connected'],
  });
});

test('Supabase rejects anonymous/service JWTs, other issuers and expired sessions', async () => {
  const auth = createSupabaseAuthenticator({
    appId: 'hermes', projectUrl: 'https://demo.supabase.co', authorize: allowed, jwks: async () => publicKey,
  });
  const signed = async (claims, extra = {}) => new Request('https://hermes.test/api/intelligence', {
    headers: { authorization: 'Bearer ' + await sign(claims, { issuer: supabaseIssuer, audience: 'authenticated', ...extra }) },
  });
  assert.equal(await auth(await signed({ sub: 'u', role: 'service_role' })), null);
  assert.equal(await auth(await signed({ sub: 'u', role: 'anon' })), null);
  assert.equal(await auth(await signed({ sub: 'u', role: 'authenticated' }, { issuer: accessIssuer })), null);
  assert.equal(await auth(await signed({ sub: 'u', role: 'authenticated' }, { exp: 1 })), null);
});

test('incomplete issuer / authorization setup cannot create an authentication adapter', () => {
  assert.throws(() => createCloudflareAccessAuthenticator({ appId: 'cresus', teamDomain: 'REPLACE.example.net', audience: 'a', authorize: allowed }),
    /verified Cloudflare Access team domain/);
  assert.throws(() => createSupabaseAuthenticator({ appId: 'hermes', projectUrl: 'http://localhost:54321', authorize: allowed }),
    /verified Supabase project HTTPS URL/);
  assert.throws(() => createCloudflareAccessAuthenticator({ appId: 'cresus', teamDomain: 'test.cloudflareaccess.com', audience: 'a' }),
    /membership authorizer/);
});
