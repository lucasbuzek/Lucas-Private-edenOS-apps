#!/usr/bin/env node
import { readFileSync, accessSync, constants, realpathSync, statSync } from 'node:fs';
import { basename, delimiter, join, resolve, sep } from 'node:path';
import { isCliMain } from './cli-main.mjs';
import { validateManifest } from './validate-manifest.mjs';
import { resolveInside } from '../deployment/workspace.mjs';

function executable(name, env) {
  if (!/^[a-zA-Z0-9-]+$/.test(name)) return false;
  const suffixes = process.platform === 'win32' ? ['.exe', '.cmd', '.bat'] : [''];
  for (const dir of (env.PATH || '').split(delimiter)) {
    if (!dir) continue;
    for (const ext of suffixes) {
      try { accessSync(join(dir, name + ext), constants.X_OK); return true; }
      catch { /* not installed in this PATH location */ }
    }
  }
  return false;
}

/** Read-only assessment: configuration presence does not verify hosting ownership. */
export function assessReadiness(manifest, { appRoot, env = process.env, hasCommand = name => executable(name, env) } = {}) {
  const valid = validateManifest(manifest);
  const blockers = [];
  const add = (code, detail) => blockers.push({ code, detail });
  if (!valid.ok) for (const error of valid.errors) add('INVALID_MANIFEST', error);

  const id = manifest?.app?.id || null;
  const deployment = manifest?.deployment || {};
  let projectRoot = null;
  if (!appRoot) add('APP_SOURCE_MISSING', 'Specify the canonical app checkout for this specific deployment');
  else try {
    const root = realpathSync(appRoot);
    const configured = realpathSync(resolveInside(root, manifest.source.projectDirectory));
    if (configured !== root && !configured.startsWith(root + sep)) throw new Error('Source path escapes application root');
    if (!statSync(configured).isDirectory()) throw new Error('Expected application directory is not a directory');
    projectRoot = configured;
  } catch { add('APP_SOURCE_MISSING', 'The application-specific projectDirectory is absent or unsafe'); }

  const preflightConfigured = valid.ok && Boolean(projectRoot);
  const previewIssues = [];
  const previewBlock = (code, detail) => previewIssues.push({ code, detail });
  if (!deployment.targetId) previewBlock('HOST_TARGET_UNVERIFIED', 'Exact existing hosting target ID is not set');
  if (!deployment.siteUrl) previewBlock('HOST_ORIGIN_UNVERIFIED', 'Exact HTTPS application origin is not set');

  if (deployment.provider === 'cloudflare-workers') {
    previewBlock('WORKER_PREVIEW_ISOLATION_UNKNOWN',
      'A separate Worker, D1 database and protected Access application are required before a preview is supported');
  } else if (deployment.provider === 'netlify') {
    if (!deployment.expectedName) previewBlock('HOST_NAME_UNVERIFIED', 'Exact Netlify site name is not configured');
    if (!env.NETLIFY_AUTH_TOKEN) previewBlock('HOST_CREDENTIAL_UNAVAILABLE', 'Netlify API token not present in the deployment environment');
    if (!hasCommand('netlify')) previewBlock('HOST_CLI_UNAVAILABLE', 'Netlify CLI is not installed on this deployment runner');
  } else if (deployment.provider === 'cloudflare-pages') {
    if (!env.CLOUDFLARE_API_TOKEN || !/^[a-f0-9]{32}$/i.test(env.CLOUDFLARE_ACCOUNT_ID || '')) {
      previewBlock('HOST_CREDENTIAL_UNAVAILABLE', 'Cloudflare Pages API token/account ID are not configured');
    }
    if (!hasCommand('wrangler')) previewBlock('HOST_CLI_UNAVAILABLE', 'Wrangler CLI is not installed on this deployment runner');
  }

  for (const name of manifest?.source?.requiredHostedPublicEnv || []) {
    if (!env[name]) previewBlock('AUTH_CLIENT_CONFIGURATION_UNAVAILABLE',
      'Required client-side public auth setting missing: ' + name);
  }
  const closedTest = deployment.accessMode === 'closed-testing';
  if (closedTest) previewBlock('CLOSED_TEST_LIVE_ACCEPTANCE_UNVERIFIED',
    'Waitlist Turnstile, admin approve/deny, Access policy, origin bypass, separate D1 and account login must pass live physical tests');

  return {
    appId: id, deploymentProvider: deployment.provider || null,
    preflightConfigured, previewConfigured: preflightConfigured && previewIssues.length === 0,
    hostingTargetApiVerified: false,
    closedTesting: closedTest ? {
      ownerAdminLogin:'UNKNOWN', waitlistTurnstile:'UNKNOWN', approvalAndDenial:'UNKNOWN',
      accessGroupAlignment:'UNKNOWN', directOriginBypass:'UNKNOWN',
      perAppDataIsolation:'UNKNOWN',
    } : null,
    liveAccountLogin: 'UNKNOWN', crossUserIsolation: 'UNKNOWN', liveIntelligenceCapability: 'UNKNOWN',
    blockers: [...blockers, ...previewIssues],
    nextGate: !preflightConfigured ? 'APP_SOURCE_PREFLIGHT' :
      previewIssues.length > 0 ? 'HOST_CONFIGURATION_AND_READ_ONLY_TARGET_VERIFICATION' :
      'READ_ONLY_HOST_TARGET_VERIFICATION_BEFORE_PREVIEW',
  };
}

if (isCliMain(import.meta.url)) {
  const args = process.argv.slice(2);
  const get = key => { const i = args.indexOf(key); return i < 0 ? null : args[i + 1]; };
  try {
    const manifestPath = get('--manifest');
    if (!manifestPath) throw new Error('Usage: node scripts/readiness.mjs --manifest <app.json> --app-root <path>');
    const manifest = JSON.parse(readFileSync(resolve(manifestPath), 'utf8'));
    console.log(JSON.stringify(assessReadiness(manifest, {appRoot:get('--app-root')}), null, 2));
  } catch (error) { console.error(error.message); process.exitCode = 2; }
}
