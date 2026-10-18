import test from 'node:test';
import assert from 'node:assert/strict';
import { verifyHostingTarget } from '../deployment/verify-target.mjs';

const NETLIFY_ID = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
const ACCOUNT_ID = '0123456789abcdef0123456789abcdef';
const netlify = () => ({
  app: { id: 'hermes' },
  deployment: {
    provider: 'netlify', kind: 'static-pwa', targetId: NETLIFY_ID,
    expectedName: 'hermes-private', siteUrl: 'https://hermes-private.netlify.app',
  },
});
const pages = () => ({
  app: { id: 'cresus' },
  deployment: {
    provider: 'cloudflare-pages', kind: 'static-pwa', targetId: 'cresus-private',
    siteUrl: 'https://cresus-private.pages.dev',
  },
});
const ok = payload => new Response(JSON.stringify(payload), { status: 200, headers: {'content-type':'application/json'} });

test('Netlify site verification requires exact ID, expected name and HTTPS origin', async () => {
  const site = { id: NETLIFY_ID, name: 'hermes-private', ssl_url: 'https://hermes-private.netlify.app' };
  let requests = [];
  const result = await verifyHostingTarget(netlify(), {
    env: { NETLIFY_AUTH_TOKEN: 'test-credential' },
    fetchImpl: async (url, options) => { requests.push({url,options}); return ok(site); },
  });
  assert.equal(result.targetId, NETLIFY_ID);
  assert.equal(result.verifiedOrigin, 'hermes-private.netlify.app');
  assert.equal(requests.length, 1);
  assert.equal(requests[0].url, 'https://api.netlify.com/api/v1/sites/' + NETLIFY_ID);
  assert.equal(requests[0].options.method, 'GET');
  assert.equal(requests[0].options.redirect, 'error');
  assert.equal(requests[0].options.headers.authorization, 'Bearer test-credential');
});

test('Netlify rejects mismatched account/project/hostname without attempting deployment', async () => {
  const m = netlify();
  const fetchImpl = async () => ok({ id: NETLIFY_ID, name: 'other-app', ssl_url: 'https://other-app.netlify.app' });
  await assert.rejects(verifyHostingTarget(m, { env: {NETLIFY_AUTH_TOKEN:'test'}, fetchImpl }), /did not match/);
  m.deployment.siteUrl = 'http://hermes-private.netlify.app';
  await assert.rejects(verifyHostingTarget(m, { env: {NETLIFY_AUTH_TOKEN:'test'}, fetchImpl }), /HTTPS siteUrl/);
  m.deployment.siteUrl = 'https://hermes-private.netlify.app';
  delete m.deployment.expectedName;
  await assert.rejects(verifyHostingTarget(m, { env: {NETLIFY_AUTH_TOKEN:'test'}, fetchImpl }), /expectedName/);
});

test('Cloudflare Pages verifies account-scoped existing project and nonproduction branch', async () => {
  let request;
  const fetchImpl = async (url, opts) => {
    request = {url, opts};
    return ok({ success: true, result: { name:'cresus-private', subdomain:'cresus-private.pages.dev', production_branch:'main' } });
  };
  const result = await verifyHostingTarget(pages(), {
    env: { CLOUDFLARE_API_TOKEN: 'test', CLOUDFLARE_ACCOUNT_ID: ACCOUNT_ID }, fetchImpl,
  });
  assert.equal(result.targetId, 'cresus-private');
  assert.equal(request.url, 'https://api.cloudflare.com/client/v4/accounts/' + ACCOUNT_ID + '/pages/projects/cresus-private');
  assert.equal(request.opts.method, 'GET');
});

test('Cloudflare Pages fails closed on unverified project or production branch collision', async () => {
  const env = { CLOUDFLARE_API_TOKEN: 'test', CLOUDFLARE_ACCOUNT_ID: ACCOUNT_ID };
  const bad = async () => ok({ success: true, result: { name:'someone-else', subdomain:'cresus-private.pages.dev', production_branch:'main' } });
  await assert.rejects(verifyHostingTarget(pages(), {env,fetchImpl:bad}), /verification|check failed/i);
  const unsafe = async () => ok({ success: true, result: { name:'cresus-private', subdomain:'cresus-private.pages.dev', production_branch:'edenos-pwa-preview-cresus' } });
  await assert.rejects(verifyHostingTarget(pages(), {env,fetchImpl:unsafe}), /check failed/);
});

test('No publishing identity check without host credentials or valid target', async () => {
  let called = false;
  const fetchImpl = async () => { called = true; return ok({}); };
  await assert.rejects(verifyHostingTarget(netlify(), { env:{}, fetchImpl }), /credentials are unavailable/);
  assert.equal(called,false);
  await assert.rejects(verifyHostingTarget(pages(), { env:{CLOUDFLARE_API_TOKEN:'test'},fetchImpl }), /account ID/);
  assert.equal(called,false);
  const m=netlify();m.deployment.targetId='';
  await assert.rejects(verifyHostingTarget(m,{env:{},fetchImpl}), /existing app-specific/);
  assert.equal(called,false);
});

test('Provider API authentication failures and malformed responses refuse publishing', async () => {
  const env={NETLIFY_AUTH_TOKEN:'test'};
  await assert.rejects(verifyHostingTarget(netlify(),{env,fetchImpl:async()=>new Response('',{status:403})}), /HTTP 403/);
  await assert.rejects(verifyHostingTarget(netlify(),{env,fetchImpl:async()=>ok({})}), /did not match/);
});
