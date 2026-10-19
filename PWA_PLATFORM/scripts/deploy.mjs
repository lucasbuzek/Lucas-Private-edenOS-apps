#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { existsSync, lstatSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { isCliMain } from './cli-main.mjs';
import { createHash } from 'node:crypto';
import { validateManifest } from './validate-manifest.mjs';
import { resolveInside, stageApplication } from '../deployment/workspace.mjs';
import { previewCommand, extractPreviewUrl } from '../deployment/hosts.mjs';
import { verifyHostingTarget } from '../deployment/verify-target.mjs';
export { resolveInside };

const BUILD_ENV_NAMES = new Set(['PATH','HOME','TMPDIR','LANG','LC_ALL','CI','NODE_ENV',
  'HTTP_PROXY','HTTPS_PROXY','NO_PROXY','http_proxy','https_proxy','no_proxy',
  'NPM_CONFIG_CACHE','npm_config_cache','SSL_CERT_FILE','NODE_EXTRA_CA_CERTS']);

function isolatedBuildEnv(manifest) {
  // Only public build keys explicitly declared by this application's manifest
  // may enter the build. No general-purpose API tokens enter install/test/build.
  const declaredPublic = new Set([
    ...(manifest.source.publicBuildEnv || []),
    ...(manifest.source.requiredHostedPublicEnv || []),
  ]);
  const filtered = Object.fromEntries(
    Object.entries(process.env).filter(([key]) => BUILD_ENV_NAMES.has(key) || declaredPublic.has(key))
  );
  return { ...filtered, ...manifest.source.hostedAuthEnvironment };
}

function previewHostEnv(manifest, buildEnv) {
  const needed = manifest.source.requiredHostedPublicEnv || [];
  for (const name of needed) {
    if (typeof process.env[name] !== 'string' || process.env[name].trim() === '') {
      throw new Error('Required public hosted auth configuration is unavailable: ' + name);
    }
  }
  const provider = manifest.deployment.provider;
  if (provider === 'netlify' && !process.env.NETLIFY_AUTH_TOKEN) {
    throw new Error('Non-interactive Netlify preview requires an authorized NETLIFY_AUTH_TOKEN');
  }
  if (provider === 'cloudflare-pages' && !process.env.CLOUDFLARE_API_TOKEN) {
    throw new Error('Non-interactive Cloudflare preview requires an authorized CLOUDFLARE_API_TOKEN');
  }
  return {
    ...buildEnv,
    ...(provider === 'netlify' ? { NETLIFY_AUTH_TOKEN: process.env.NETLIFY_AUTH_TOKEN } : {}),
    ...(provider === 'cloudflare-pages'
      ? { CLOUDFLARE_API_TOKEN: process.env.CLOUDFLARE_API_TOKEN, ...(process.env.CLOUDFLARE_ACCOUNT_ID
        ? { CLOUDFLARE_ACCOUNT_ID: process.env.CLOUDFLARE_ACCOUNT_ID } : {}) } : {}),
  };
}

function run(argv, cwd, env) {
  if (!Array.isArray(argv) || !argv.length || argv.some(s => typeof s !== 'string' || !s.trim())) {
    throw new Error('Command must be a non-empty argv array');
  }
  const [program, ...args] = argv;
  const result = spawnSync(program, args, {
    cwd, env, encoding: 'utf8', maxBuffer: 4 * 1024 * 1024,
    shell: false, timeout: 300000, windowsHide: true,
  });
  if (result.stdout) process.stdout.write(result.stdout);
  if (result.stderr) process.stderr.write(result.stderr);
  if (result.error) throw new Error('Command failed or timed out: ' + program + ': ' + result.error.message);
  if (result.status !== 0) throw new Error('Command failed (' + result.status + '): ' + program);
  return result.stdout || '';
}

function verifyOutput(stagedRoot, outputRelative) {
  const output = resolveInside(stagedRoot, outputRelative);
  const html = resolveInside(output, 'index.html');
  const manifest = resolveInside(output, 'manifest.webmanifest');
  for (const path of [output, html, manifest]) {
    if (!existsSync(path) || lstatSync(path).isSymbolicLink()) throw new Error('Missing or unsafe PWA output: ' + path);
  }
  if (!lstatSync(html).isFile() || !lstatSync(manifest).isFile()) throw new Error('PWA output files must be regular files');
  const parsed = JSON.parse(readFileSync(manifest, 'utf8'));
  if (!parsed || typeof parsed.name !== 'string' || !parsed.name.trim()) {
    throw new Error('PWA web manifest must declare a name');
  }
  // Inspect only the mandatory files; avoid recording private application contents.
  const digest = createHash('sha256').update(readFileSync(html)).update(readFileSync(manifest)).digest('hex');
  return { outputDirectory: output, artifactFingerprint: digest };
}

export async function execute({ manifest, appRoot, publishPreview = false } = {}) {
  const checked = validateManifest(manifest);
  if (!checked.ok) throw new Error('Manifest rejected: ' + checked.errors.join('; '));
  if (publishPreview) {
    // Refuse before running any installation/build hooks when the target or credentials are not identified.
    previewCommand(manifest, '__STAGED_OUTPUT__');
    previewHostEnv(manifest, isolatedBuildEnv(manifest));
    // Verify existing, expected site identity with read-only hosting APIs BEFORE
    // executing any app-owned installation/build code or uploading artifacts.
    await verifyHostingTarget(manifest);
  }
  const workspace = stageApplication(appRoot, manifest.source.projectDirectory);
  try {
    const env = isolatedBuildEnv(manifest);
    run(manifest.source.installCommand, workspace.staged, env);
    run(manifest.source.testCommand, workspace.staged, env);
    run(manifest.source.buildCommand, workspace.staged, env);
    const verified = verifyOutput(workspace.staged, manifest.source.outputDirectory);
    run(manifest.source.authVerificationCommand, workspace.staged, {
      ...env, EXPECTED_HOSTED_AUTH_SCREEN: 'login',
    });
    const result = {
      appId: manifest.app.id,
      version: manifest.app.version,
      provider: manifest.deployment.provider,
      artifactFingerprint: verified.artifactFingerprint,
      declaredAuthTests: 'PASS',
      liveAccountLogin: 'UNKNOWN',
      tenantIsolation: 'UNKNOWN',
      sourceIsolated: true,
      previewDeployed: false,
    };
    if (!publishPreview) {
      console.log('PWA_PREFLIGHT_PASS: isolated tests, build output and app-declared authentication tests passed. Live account login remains UNKNOWN. No deployment performed.');
      return result;
    }
    const command = previewCommand(manifest, verified.outputDirectory);
    const output = run(command, workspace.staged, previewHostEnv(manifest, env));
    const previewUrl = extractPreviewUrl(output, manifest.deployment.provider);
    if (!previewUrl) throw new Error('Preview host returned no accepted HTTPS preview URL');
    result.previewUrl = previewUrl;
    result.previewDeployed = true;
    run(manifest.source.authVerificationCommand, workspace.staged, {
      ...env, EDEN_PWA_PUBLIC_URL: previewUrl, EXPECTED_HOSTED_AUTH_SCREEN: 'login',
    });
    result.remoteLoginScreenSmoke = 'PASS';
    // OAuth round trips, cross-user isolation, server-side Access and provider intelligence remain separate release gates.
    console.log('PWA_PREVIEW_LOGIN_SCREEN_TESTED: ' + previewUrl);
    console.log('Production, account-login and AI-provider acceptance remain UNVERIFIED.');
    return result;
  } finally {
    workspace.dispose();
  }
}

if (isCliMain(import.meta.url)) {
  const args = process.argv.slice(2);
  const after = flag => { const at = args.indexOf(flag); return at < 0 ? null : args[at + 1]; };
  const manifestPath = after('--manifest');
  const appRoot = after('--app-root');
  const publishPreview = args.includes('--publish-preview');
  if (!manifestPath || !appRoot) {
    console.error('Usage: node scripts/deploy.mjs --manifest <manifest.json> --app-root <app-checkout> [--publish-preview]');
    process.exitCode = 2;
  } else {
    try {
      const manifest = JSON.parse(readFileSync(resolve(manifestPath), 'utf8'));
      await execute({ manifest, appRoot, publishPreview });
    } catch (error) {
      console.error('PWA_DEPLOYMENT_BLOCKED: ' + error.message);
      process.exitCode = 1;
    }
  }
}
