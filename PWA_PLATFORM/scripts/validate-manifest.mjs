#!/usr/bin/env node
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const ID = /^[a-z][a-z0-9-]{1,47}$/;
const VERSION = /^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/;
const HOSTS = new Set(['netlify', 'cloudflare-pages', 'cloudflare-workers']);
const AUTH = new Set(['supabase', 'cloudflare-access', 'oidc']);
const PROVIDERS = new Set(['workers-ai', 'gemini-free-tier', 'local', 'user-connected', 'openai-compatible']);
const COMMANDS = ['installCommand', 'buildCommand', 'testCommand', 'authVerificationCommand'];
const SAFE_ENV = /^VITE_[A-Z][A-Z0-9_]*$/;

function safeRelative(value) {
  return typeof value === 'string' && value.trim().length > 0 &&
    !value.startsWith('/') && !value.includes('\\') && !value.split('/').includes('..') &&
    !value.split('/').includes('') && !value.includes('\0');
}

export function validateManifest(m) {
  const errors = [];
  const need = (condition, message) => { if (!condition) errors.push(message); };
  if (!m || typeof m !== 'object' || Array.isArray(m)) return { ok: false, errors: ['manifest must be a JSON object'] };

  need(m.schemaVersion === 1, 'schemaVersion must be 1');
  need(ID.test(m.app?.id || ''), 'app.id must be stable lowercase hyphenated text');
  need(typeof m.app?.name === 'string' && m.app.name.trim() !== '', 'app.name is required');
  need(typeof m.app?.version === 'string' && VERSION.test(m.app.version), 'app.version must be semantic');
  need(m.app?.standalone === true, 'app.standalone must be true');

  need(typeof m.source?.repository === 'string' && /^https:\/\/[^/]+/.test(m.source.repository), 'source.repository must be HTTPS');
  need(safeRelative(m.source?.projectDirectory), 'source.projectDirectory must be a safe relative path');
  need(safeRelative(m.source?.outputDirectory), 'source.outputDirectory must be a safe relative path');
  for (const name of COMMANDS) {
    const value = m.source?.[name];
    need(Array.isArray(value) && value.length > 0 && value.every(x => typeof x === 'string' && x.trim().length > 0), 'source.' + name + ' must be a non-empty argv array');
  }
  for (const field of ['requiredHostedPublicEnv', 'publicBuildEnv']) {
    const declared = m.source?.[field] ?? [];
    need(Array.isArray(declared) &&
      declared.every(x => typeof x === 'string' && SAFE_ENV.test(x)) &&
      new Set(declared).size === declared.length,
      'source.' + field + ' must list unique approved public build variable names');
  }
  const d = m.deployment || {};
  const hostedEnv = m.source?.hostedAuthEnvironment;
  const requiresBuildFlag = d.kind === 'static-pwa';
  need(hostedEnv && typeof hostedEnv === 'object' && !Array.isArray(hostedEnv) &&
       (!requiresBuildFlag || Object.keys(hostedEnv).length > 0),
    'source.hostedAuthEnvironment must describe app-specific hosted login flags (static sites require at least one)');
  if (hostedEnv && typeof hostedEnv === 'object' && !Array.isArray(hostedEnv)) {
    for (const [key, value] of Object.entries(hostedEnv)) {
      need(SAFE_ENV.test(key) && typeof value === 'string' && ['true', 'required', 'hosted'].includes(value),
        'hostedAuthEnvironment requires an approved public build flag and enabling value');
    }
  }

  need(HOSTS.has(d.provider), 'deployment.provider must be netlify, cloudflare-pages or cloudflare-workers');
  need(d.kind === (d.provider === 'cloudflare-workers' ? 'worker-pwa' : 'static-pwa'), 'deployment.kind must match hosting profile');
  need(typeof d.targetId === 'string', 'deployment.targetId must be declared (empty until target verified)');
  if (typeof d.targetId === 'string' && d.targetId.length > 0) {
    need(/^[a-zA-Z0-9][a-zA-Z0-9_-]{1,127}$/.test(d.targetId), 'deployment.targetId must be a valid explicit existing project identifier');
  }
  need(typeof d.siteUrl === 'string', 'deployment.siteUrl must be a string (empty until verified)');
  if (d.siteUrl) {
    try { need(new URL(d.siteUrl).protocol === 'https:', 'deployment.siteUrl must be HTTPS'); }
    catch { need(false, 'deployment.siteUrl must be a valid HTTPS URL'); }
  }
  if (d.kind === 'worker-pwa') {
    need(safeRelative(d.workerConfigPath), 'deployment.workerConfigPath must identify this app’s existing Wrangler configuration');
    need(safeRelative(d.previewConfigPath), 'deployment.previewConfigPath must identify a separate candidate-only Wrangler configuration');
    need(d.provider === 'cloudflare-workers', 'worker-pwa requires cloudflare-workers');
  }

  if (d.accessMode === 'closed-testing') {
    const capabilities=m.intelligence?.requiredCapabilities;
    need(Array.isArray(capabilities) && capabilities.length>0 &&
      capabilities.every(v=>typeof v==='string' && /^[a-z][a-z0-9-]+$/.test(v)),
      'Closed-testing intelligence must declare meaningful app-specific requiredCapabilities');
    const rules = d.closedTesting;
    for (const field of ['required','ownerApprovalRequired','turnstileRequired',
      'publicWaitlistSeparateFromPrivateApp','allAppAssetsProtected']) {
      need(rules?.[field] === true, 'deployment.closedTesting.'+field+' must be true in closed-testing mode');
    }
    need(d.auth?.provider === 'cloudflare-access', 'Closed Cloudflare pilot requires per-app Access JWT verification');
  }
  if (d.desiredPagesEntry) {
    const entry=d.desiredPagesEntry;
    need(d.accessMode === 'closed-testing', 'Pages namespace intent requires closed-testing policy');
    need(entry.projectIntent === 'edenosprivate', 'Pages namespace project must match the approved private namespace');
    need(entry.branchIntent === m.app?.id, 'Pages preview branch must match the app identity');
    need(entry.requestedUrl === 'https://' + m.app?.id + '.edenosprivate.pages.dev',
      'Pages branch preview requested URL must be app-specific and canonical');
    need(entry.status === 'UNVERIFIED_NOT_PROVISIONED', 'Pages intent must not claim provisioned or deployed status');
    need(entry.branchAndHashPreviewsRequireAccess === true,
      'Every branch and immutable Pages preview needs Cloudflare Access');
    need(entry.independentAppRuntimeAndDataRequired === true,
      'Pages namespace cannot combine standalone app runtimes and data');
  }
  need(d.auth?.required === true, 'deployment.auth.required must be true');
  need(AUTH.has(d.auth?.provider), 'deployment.auth.provider must identify a supported identity verifier');
  need(d.auth?.publicClientConfigRequired === true, 'auth must declare public client configuration');
  need(d.auth?.serverSideAuthorizationRequired === true, 'auth must require server-side authorization');
  need(d.auth?.crossAppSessionsAllowed === false, 'auth.crossAppSessionsAllowed must be false (separate app policies)');
  if (d.kind === 'worker-pwa') {
    need(d.auth?.provider === 'cloudflare-access', 'worker-pwa pilot requires Cloudflare Access JWT verification');
  }

  const intelligence = m.intelligence || {};
  need(intelligence.mode === 'shared-core-adapter', 'intelligence.mode must be shared-core-adapter');
  need(intelligence.paidApiDependency === false, 'intelligence.paidApiDependency must be false');
  need(intelligence.defaultProvider === null, 'intelligence.defaultProvider must be null until a capable tested provider is explicitly configured');
  need(Array.isArray(intelligence.providers) && intelligence.providers.length > 0, 'intelligence.providers must be a non-empty list');
  if (Array.isArray(intelligence.providers)) for (const provider of intelligence.providers) {
    need(PROVIDERS.has(provider), 'unsupported provider: ' + String(provider));
  }
  need(intelligence.fallbackPolicy === 'explicit-status-no-silent-provider-switch', 'provider failure must be explicit without silent fallback');

  need(m.data?.domainAuthority === m.app?.name, 'data.domainAuthority must equal this app identity');
  need(m.data?.ownership === 'app-owned', 'data.ownership must remain app-owned');
  need(m.data?.migration === 'preserve-existing-data', 'data.migration must preserve existing data');
  need(m.data?.crossUserIsolationRequired === true, 'cross-user data isolation must be explicitly required');

  const serialized = JSON.stringify(m);
  const secrets = /"(?:api[_-]?key|client[_-]?secret|access[_-]?token|refresh[_-]?token|private[_-]?key)"\s*:\s*"[^"]+"/i;
  need(!secrets.test(serialized), 'manifest must not contain credential values');
  return { ok: errors.length === 0, errors };
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const file = process.argv[2];
  if (!file) { console.error('Usage: node scripts/validate-manifest.mjs <manifest.json>'); process.exitCode = 2; }
  else {
    try {
      const manifest = JSON.parse(await readFile(resolve(file), 'utf8'));
      const result = validateManifest(manifest);
      if (!result.ok) { console.error('Manifest rejected:\n' + result.errors.join('\n')); process.exitCode = 1; }
      else console.log('EDENOS PWA manifest valid: ' + manifest.app.id + ' v' + manifest.app.version);
    } catch (error) { console.error(error.message); process.exitCode = 2; }
  }
}
