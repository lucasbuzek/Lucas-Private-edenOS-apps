import test from 'node:test';
import assert from 'node:assert/strict';
import { generateKeyPair, SignJWT } from 'jose';
import { createCloudflareAccessAuthenticator, createSupabaseAuthenticator } from '../authentication/jwt.mjs';
import { createIntelligenceWorker } from '../intelligence/worker.mjs';
import { createIntelligenceCore } from '../intelligence/core.mjs';

const { privateKey, publicKey } = await generateKeyPair('RS256');
async function signedToken({ issuer, audience, role, type } = {}) {
  return new SignJWT({ sub: 'person-1', email: 'member@example.com', ...(role ? { role } : {}), ...(type ? { type } : {}) })
    .setProtectedHeader({ alg: 'RS256' }).setIssuer(issuer).setAudience(audience)
    .setIssuedAt().setNotBefore(Math.floor(Date.now() / 1000) - 10).setExpirationTime('5m').sign(privateKey);
}
function worker(appId, authenticate) {
  return createIntelligenceWorker({
    appId, authenticate,
    core: createIntelligenceCore({
      apps: {
        hermes: { systemPrompt: 'HERMES-only prompt', allowedProviders: ['local'] },
        cresus: { systemPrompt: 'CRESUS-only prompt', allowedProviders: ['local'] },
      },
      providers: { local: { available: true, costClass: 'local', generate: async req => 'responded for ' + req.appId } },
    }),
  });
}
const body = appId => JSON.stringify({ appId, providerId: 'local', messages: [{ role: 'user', content: 'question' }] });
const req = (bodyText, header = {}) => new Request('https://app.test/api/intelligence', {
  method: 'POST', headers: { 'content-type': 'application/json', ...header }, body: bodyText,
});

test('CRESUS Access token cannot open HERMES endpoint; both require independent membership', async () => {
  const cresusAuth = createCloudflareAccessAuthenticator({
    appId: 'cresus', teamDomain: 'team.cloudflareaccess.com', audience: 'cresus-aud',
    authorize: async () => ({ allowed: true }), jwks: async () => publicKey,
  });
  const cresusWorker = worker('cresus', cresusAuth);
  const token = await signedToken({ issuer: 'https://team.cloudflareaccess.com', audience: 'cresus-aud', type: 'app' });
  assert.equal((await cresusWorker.fetch(req(body('cresus')))).status, 401);
  const valid = await cresusWorker.fetch(req(body('cresus'), { 'cf-access-jwt-assertion': token }));
  assert.equal(valid.status, 200);
  assert.equal((await valid.json()).response, 'responded for cresus');
  const wrongApp = await cresusWorker.fetch(req(body('hermes'), { 'cf-access-jwt-assertion': token }));
  assert.equal(wrongApp.status, 403);
  const hermesAuth = createCloudflareAccessAuthenticator({
    appId: 'hermes', teamDomain: 'team.cloudflareaccess.com', audience: 'hermes-aud',
    authorize: async () => ({ allowed: true }), jwks: async () => publicKey,
  });
  assert.equal((await worker('hermes', hermesAuth).fetch(req(body('hermes'), { 'cf-access-jwt-assertion': token }))).status, 401);
});

test('HERMES Supabase JWT can call HERMES only after its own membership check', async () => {
  let allowed = false;
  const auth = createSupabaseAuthenticator({
    appId: 'hermes', projectUrl: 'https://hermes.supabase.co',
    authorize: async () => ({ allowed }),
    jwks: async () => publicKey,
  });
  const token = await signedToken({ issuer: 'https://hermes.supabase.co/auth/v1', audience: 'authenticated', role: 'authenticated' });
  const hermes = worker('hermes', auth);
  assert.equal((await hermes.fetch(req(body('hermes'), { authorization: 'Bearer ' + token }))).status, 401);
  allowed = true;
  assert.equal((await hermes.fetch(req(body('hermes'), { authorization: 'Bearer ' + token }))).status, 200);
  assert.equal((await hermes.fetch(req(body('cresus'), { authorization: 'Bearer ' + token }))).status, 403);
});
