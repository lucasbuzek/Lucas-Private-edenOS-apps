#!/usr/bin/env node
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const fail = (errors) => ({ ok: false, errors });
const ID = /^[a-z][a-z0-9-]{1,47}$/;
const VERSION = /^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/;
const PROVIDERS = new Set(['workers-ai', 'gemini-free-tier', 'local', 'user-connected']);
const HOSTS = new Set(['netlify', 'cloudflare-pages']);
const AUTH = new Set(['supabase', 'cloudflare-access', 'oidc']);

export function validateManifest(m) {
  const errors = [];
  const need = (condition, message) => { if (!condition) errors.push(message); };
  need(m && typeof m === 'object' && !Array.isArray(m), 'manifest must be a JSON object');
  if (!m || typeof m !== 'object' || Array.isArray(m)) return fail(errors);

  need(m.schemaVersion === 1, 'schemaVersion must be 1');
  need(m.app && ID.test(m.app.id || ''), 'app.id must be a stable lowercase hyphenated identifier');
  need(typeof m.app?.name === 'string' && m.app.name.trim().length > 0, 'app.name is required');
  need(typeof m.app?.version === 'string' && VERSION.test(m.app.version), 'app.version must be semantic version text');
  need(m.app?.standalone === true, 'app.standalone must be true');

  need(typeof m.source?.repository === 'string' && /^https:\/\//.test(m.source.repository), 'source.repository must be an HTTPS URL');
  const validCommand = value => Array.isArray(value) && value.length > 0 && value.every(part => typeof part === 'string' && part.trim().length > 0);
  need(typeof m.source?.projectDirectory === 'string' && m.source.projectDirectory.trim().length > 0, 'source.projectDirectory is required');
  need(validCommand(m.source?.installCommand), 'source.installCommand must be an argv array');
  need(validCommand(m.source?.buildCommand), 'source.buildCommand must be an argv array; shell commands are not accepted');
  need(validCommand(m.source?.testCommand), 'source.testCommand must be an argv array');
  need(validCommand(m.source?.authVerificationCommand), 'source.authVerificationCommand must be an argv array and verify the hosted login gate');
  need(typeof m.source?.outputDirectory === 'string' && m.source.outputDirectory.trim().length > 0 && !m.source.outputDirectory.startsWith('/') && !m.source.outputDirectory.includes('..') && !m.source.outputDirectory.includes('\\'), 'source.outputDirectory must be a safe relative path');

  need(HOSTS.has(m.deployment?.provider), 'deployment.provider must be netlify or cloudflare-pages');
  need(typeof m.deployment?.siteUrl === 'string', 'deployment.siteUrl must be a string (empty is allowed before deployment)');
  need(m.deployment?.auth?.required === true, 'deployment.auth.required must be true; unauthenticated hosted PWAs are not permitted');
  need(AUTH.has(m.deployment?.auth?.provider), 'deployment.auth.provider must be supabase, cloudflare-access, or oidc');
  need(m.deployment?.auth?.publicClientConfigRequired === true, 'auth must explicitly declare public client configuration requirements');
  need(m.deployment?.auth?.serverSideAuthorizationRequired === true, 'auth must require server-side authorization, not UI-only login');

  need(m.intelligence?.mode === 'shared-core-adapter', 'intelligence.mode must use the reusable shared-core adapter contract');
  need(m.intelligence?.paidApiDependency === false, 'intelligence.paidApiDependency must be false');
  need(Array.isArray(m.intelligence?.providers) && m.intelligence.providers.length > 0, 'intelligence.providers must list at least one allowed provider');
  if (Array.isArray(m.intelligence?.providers)) {
    for (const p of m.intelligence.providers) need(PROVIDERS.has(p), 'unsupported provider: ' + String(p));
  }
  need(m.intelligence?.fallbackPolicy === 'explicit-status-no-silent-provider-switch', 'fallback policy must make provider selection/failure explicit');

  need(typeof m.data?.domainAuthority === 'string' && m.data.domainAuthority.trim().length > 0, 'data.domainAuthority is required');
  need(m.data?.ownership === 'app-owned', 'data.ownership must preserve app-owned data authority');
  need(m.data?.migration === 'preserve-existing-data', 'data.migration must preserve existing data');
  need(m.data?.crossUserIsolationRequired === true, 'cross-user data isolation must be explicitly required');

  const serialized = JSON.stringify(m);
  // Secrets belong in host secret stores, never in manifests or browser bundles.
  const secretField = /"(?:api[_-]?key|client[_-]?secret|access[_-]?token|refresh[_-]?token|private[_-]?key)"\s*:\s*"(?!")/i;
  need(!secretField.test(serialized), 'manifest must not contain credential values; use provider/host secret storage');

  return errors.length ? fail(errors) : { ok: true, errors: [] };
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const file = process.argv[2];
  if (!file) {
    console.error('Usage: node scripts/validate-manifest.mjs <manifest.json>');
    process.exitCode = 2;
  } else {
    try {
      const manifest = JSON.parse(await readFile(resolve(file), 'utf8'));
      const result = validateManifest(manifest);
      if (!result.ok) {
        console.error('EDENOS PWA manifest rejected:');
        for (const error of result.errors) console.error('- ' + error);
        process.exitCode = 1;
      } else {
        console.log('EDENOS PWA manifest valid: ' + manifest.app.id + ' v' + manifest.app.version);
      }
    } catch (error) {
      console.error('Cannot read manifest: ' + error.message);
      process.exitCode = 2;
    }
  }
}
