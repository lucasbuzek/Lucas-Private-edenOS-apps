import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, symlinkSync, existsSync, rmSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { stageApplication } from '../deployment/workspace.mjs';

test('isolate sources and exclude credentials, preexisting builds, caches and symlinks', () => {
  const source = mkdtempSync(join(tmpdir(), 'edenos-pwa-test-'));
  const project = join(source, 'web');
  mkdirSync(project);
  mkdirSync(join(project, 'node_modules'));
  mkdirSync(join(project, 'dist'));
  writeFileSync(join(project, 'index.html'), 'original');
  writeFileSync(join(project, '.env'), 'SECRET=do-not-copy');
  writeFileSync(join(project, '.npmrc'), '//registry.example/:_authToken=do-not-copy');
  writeFileSync(join(project, 'node_modules', 'cache'), 'unwanted');
  writeFileSync(join(project, 'dist', 'old.html'), 'unwanted');
  symlinkSync(join(source, 'private'), join(project, 'private-symlink'));
  let stage;
  try {
    stage = stageApplication(source, 'web');
    assert.equal(readFileSync(join(stage.staged, 'index.html'), 'utf8'), 'original');
    assert.equal(existsSync(join(stage.staged, '.env')), false);
    assert.equal(existsSync(join(stage.staged, '.npmrc')), false);
    assert.equal(existsSync(join(stage.staged, 'node_modules')), false);
    assert.equal(existsSync(join(stage.staged, 'dist')), false);
    assert.equal(existsSync(join(stage.staged, 'private-symlink')), false);
    writeFileSync(join(stage.staged, 'index.html'), 'candidate');
    assert.equal(readFileSync(join(project, 'index.html'), 'utf8'), 'original');
    const stagePath = stage.staged;
    stage.dispose();
    assert.equal(existsSync(stagePath), false);
    stage.dispose();
  } finally {
    stage?.dispose();
    rmSync(source, { recursive: true, force: true });
  }
});

test('an app project path cannot follow symlink outside its source root', () => {
  const source = mkdtempSync(join(tmpdir(), 'edenos-pwa-test-'));
  try {
    symlinkSync(tmpdir(), join(source, 'outside'));
    assert.throws(() => stageApplication(source, 'outside'), /escapes application root/);
  } finally {
    rmSync(source, { recursive: true, force: true });
  }
});
