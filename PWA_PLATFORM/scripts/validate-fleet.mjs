#!/usr/bin/env node
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { isCliMain } from './cli-main.mjs';
import { validateManifest } from './validate-manifest.mjs';

/** Inspect independently configured apps without combining their deployments. */
export function validateFleet(manifests) {
  const errors = [];
  const ids = new Set();
  const targets = new Map();
  const origins = new Map();

  for (const [index, manifest] of manifests.entries()) {
    const checked = validateManifest(manifest);
    for (const error of checked.errors) errors.push('manifest ' + (index + 1) + ': ' + error);
    const appId = manifest?.app?.id;
    if (ids.has(appId)) errors.push('Duplicate app identity: ' + appId);
    if (appId) ids.add(appId);
    const deployment = manifest?.deployment;
    if (!deployment || !appId) continue;
    if (deployment.targetId) {
      const target = deployment.provider + '/' + deployment.targetId.toLowerCase();
      const other = targets.get(target);
      if (other && other !== appId) errors.push('Two apps share hosting target: ' + other + ' and ' + appId);
      targets.set(target, appId);
    }
    if (deployment.siteUrl) {
      try {
        const origin = new URL(deployment.siteUrl).origin.toLowerCase();
        const other = origins.get(origin);
        if (other && other !== appId) errors.push('Two apps share hosted origin: ' + other + ' and ' + appId);
        origins.set(origin, appId);
      } catch { /* Individual validator reports invalid URL. */ }
    }
  }
  return { ok: errors.length === 0, errors };
}

if (isCliMain(import.meta.url)) {
  const paths = process.argv.slice(2);
  if (!paths.length) {
    console.error('Usage: node scripts/validate-fleet.mjs <app-a.json> <app-b.json> [...]');
    process.exitCode = 2;
  } else {
    try {
      const manifests = paths.map(p => JSON.parse(readFileSync(resolve(p), 'utf8')));
      const result = validateFleet(manifests);
      if (!result.ok) {
        for (const error of result.errors) console.error(error);
        process.exitCode = 1;
      } else console.log('EDENOS fleet profiles valid; identities and configured targets are distinct (' + manifests.length + ')');
    } catch (error) {
      console.error(error.message);
      process.exitCode = 2;
    }
  }
}
