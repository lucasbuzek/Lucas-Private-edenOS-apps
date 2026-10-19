import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, symlinkSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { isCliMain } from '../scripts/cli-main.mjs';

const project = resolve(import.meta.dirname,'..');
const manifest = join(project,'examples/hermes.cloudflare.closed.manifest.json');

function executeAlias(scriptName, args=[]) {
  const temp=mkdtempSync(join(tmpdir(),'edenos-cli-alias-'));
  try {
    const alias=join(temp,'npm-bin-link');
    symlinkSync(join(project,'scripts',scriptName),alias);
    return spawnSync(process.execPath,[alias,...args],{encoding:'utf8',timeout:5000});
  } finally {rmSync(temp,{recursive:true,force:true});}
}

test('CLI entrypoint resolves installed npm symlink instead of silently doing nothing',()=>{
  const status=executeAlias('validate-manifest.mjs',[manifest]);
  assert.equal(status.status,0,status.stderr);
  assert.match(status.stdout,/EDENOS PWA manifest valid/);
  const missing=executeAlias('validate-manifest.mjs');
  assert.equal(missing.status,2);
  assert.match(missing.stderr,/Usage:/);
});

test('all five command executables remain functional through symlinks',()=>{
  const namespace=executeAlias('prepare-private-pages.mjs');
  assert.equal(namespace.status,0,namespace.stderr);
  assert.equal(JSON.parse(namespace.stdout).namespace,'edenosprivate');

  const fleet=executeAlias('validate-fleet.mjs',[
    join(project,'examples/hermes.cloudflare.closed.manifest.json'),
    join(project,'examples/cresus.worker.manifest.json'),
  ]);
  assert.equal(fleet.status,0,fleet.stderr);
  assert.match(fleet.stdout,/fleet profiles valid/);

  const readiness=executeAlias('readiness.mjs',['--manifest',manifest]);
  assert.equal(readiness.status,0,readiness.stderr);
  assert.equal(JSON.parse(readiness.stdout).appId,'hermes');

  const deploy=executeAlias('deploy.mjs');
  assert.equal(deploy.status,2);
  assert.match(deploy.stderr,/Usage:/);
});

test('imported helper never treats a different module as an executable CLI',()=>{
  assert.equal(isCliMain(new URL('../scripts/cli-main.mjs',import.meta.url).href),false);
  assert.equal(isCliMain(import.meta.url,'/nonexistent/edenos-pwa-namespace'),false);
});
