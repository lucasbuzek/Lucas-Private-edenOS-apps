import test from 'node:test';
import assert from 'node:assert/strict';
import { resolveInside } from '../scripts/deploy.mjs';

test('deployment paths stay inside the configured project root', () => {
  assert.match(resolveInside('/tmp/app', 'dist'), /\/tmp\/app\/dist$/);
  assert.throws(() => resolveInside('/tmp/app', '../outside'), /safe relative path/);
  assert.throws(() => resolveInside('/tmp/app', '/outside'), /safe relative path/);
  assert.throws(() => resolveInside('/tmp/app', 'dist\\assets'), /safe relative path/);
});

test('deployment paths reject traversal-like segments instead of normalizing them', () => {
  assert.throws(() => resolveInside('/tmp/app', 'dist/../secret'), /safe relative path/);
  assert.throws(() => resolveInside('/tmp/app', 'some..folder'), /safe relative path/);
});
