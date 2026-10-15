#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { isAbsolute, resolve, sep } from 'node:path';
import { pathToFileURL } from 'node:url';
import { validateManifest } from './validate-manifest.mjs';

export function resolveInside(root, relative) {
  if (typeof relative !== 'string' || !relative.trim() || isAbsolute(relative) || relative.includes('..') || relative.includes('\\')) {
    throw new Error('Path must be a safe relative path');
  }
  const base = resolve(root);
  const target = resolve(base, relative);
  if (target !== base && !target.startsWith(base + sep)) throw new Error('Path escapes its configured root');
  return target;
}

function commandParts(value, name) {
  if (!Array.isArray(value) || value.length === 0 || value.some(part => typeof part !== 'string' || !part.trim())) {
    throw new Error(name + ' must be a non-empty argv array');
  }
  return value;
}

function run(command, cwd, env = process.env) {
  const [program, ...args] = commandParts(command, 'command');
  const result = spawnSync(program, args, { cwd, env, encoding: 'utf8', maxBuffer: 8 * 1024 * 1024, shell: false });
  if (result.stdout) process.stdout.write(result.stdout);
  if (result.stderr) process.stderr.write(result.stderr);
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error('Command failed (' + result.status + '): ' + program);
  return result.stdout || '';
}

function extractPreviewUrl(output, provider) {
  for (const line of output.split(/\r?\n/).reverse()) {
    try {
      const parsed = JSON.parse(line);
      const candidate = parsed.deploy_url || parsed.deployUrl || parsed.url;
      if (typeof candidate === 'string' && /^https:\/\//.test(candidate)) return candidate;
    } catch {}
  }
  const host = provider === 'netlify'
    ? /https:\/\/[a-z0-9-]+(?:--[a-z0-9-]+)?\.netlify\.app\b/i
    : /https:\/\/[a-z0-9.-]+\.pages\.dev\b/i;
  return output.match(host)?.[0] || null;
}

function deployPreview(manifest, outputDirectory, cwd, env) {
  let command;
  if (manifest.deployment.provider === 'netlify') {
    command = ['npx', '--yes', 'netlify-cli', 'deploy', '--dir', outputDirectory, '--json'];
  } else if (manifest.deployment.provider === 'cloudflare-pages') {
    const project = manifest.deployment.projectName;
    if (typeof project !== 'string' || !project.trim()) throw new Error('deployment.projectName is required for Cloudflare Pages');
    command = ['npx', '--yes', 'wrangler', 'pages', 'deploy', outputDirectory, '--project-name', project, '--branch', 'edenos-candidate'];
  } else {
    throw new Error('Unsupported hosting provider');
  }
  const output = run(command, cwd, env);
  const url = extractPreviewUrl(output, manifest.deployment.provider);
  if (!url) throw new Error('Preview deployment returned no verifiable HTTPS URL');
  return url;
}

export async function execute({ manifest, appRoot, publishPreview = false }) {
  const checked = validateManifest(manifest);
  if (!checked.ok) throw new Error('Manifest rejected: ' + checked.errors.join('; '));
  if (!appRoot) throw new Error('--app-root is required');
  const root = resolve(appRoot);
  if (!existsSync(root)) throw new Error('App root does not exist: ' + root);
  const project = resolveInside(root, manifest.source.projectDirectory);
  if (!existsSync(project)) throw new Error('Configured app project directory does not exist: ' + project);

  const env = { ...process.env, VITE_EDEN_PWA_AUTH_REQUIRED: 'true' };
  run(manifest.source.installCommand, project, env);
  run(manifest.source.testCommand, project, env);
  run(manifest.source.buildCommand, project, env);

  const outputDirectory = resolveInside(project, manifest.source.outputDirectory);
  const html = resolveInside(outputDirectory, 'index.html');
  const webManifest = resolveInside(outputDirectory, 'manifest.webmanifest');
  if (!existsSync(html) || !existsSync(webManifest)) {
    throw new Error('Build output must contain index.html and manifest.webmanifest');
  }

  // Must prove the hosted login gate on the built artifact before any preview is published.
  run(manifest.source.authVerificationCommand, project, {
    ...env,
    EXPECTED_HOSTED_AUTH_SCREEN: 'login',
  });

  const result = { appId: manifest.app.id, version: manifest.app.version, outputDirectory, localAuthSmoke: 'PASS' };
  if (!publishPreview) {
    console.log('PWA_PREFLIGHT_PASS: tests, build output and hosted-auth smoke test passed. No deployment performed.');
    return result;
  }

  const previewUrl = deployPreview(manifest, outputDirectory, project, env);
  run(manifest.source.authVerificationCommand, project, {
    ...env,
    EDEN_PWA_PUBLIC_URL: previewUrl,
    EXPECTED_HOSTED_AUTH_SCREEN: 'login',
  });
  result.previewUrl = previewUrl;
  result.remoteAuthSmoke = 'PASS';
  console.log('PWA_PREVIEW_VERIFIED: ' + previewUrl);
  console.log('Production promotion is intentionally not performed by this candidate.');
  return result;
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const args = process.argv.slice(2);
  const valueAfter = flag => { const i = args.indexOf(flag); return i >= 0 ? args[i + 1] : null; };
  const manifestPath = valueAfter('--manifest');
  const appRoot = valueAfter('--app-root');
  const publishPreview = args.includes('--publish-preview');
  if (!manifestPath || !appRoot || args.some((x, i) => ['--manifest', '--app-root'].includes(x) && !args[i + 1])) {
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
